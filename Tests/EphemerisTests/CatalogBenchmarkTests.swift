//
//  CatalogBenchmarkTests.swift
//  EphemerisTests
//
//  Timing for whole-catalog operations on a realistic 15,000-satellite synthetic catalog.
//
//  These are opt-in because they are slow in debug builds. Run them in release mode:
//      EPHEMERIS_BENCHMARK=1 swift test -c release --filter CatalogBenchmarkTests
//

import Foundation
import XCTest
@testable import Ephemeris

final class CatalogBenchmarkTests: XCTestCase {

    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

    /// Runs a block once and returns how long it took, in seconds.
    private func time(_ label: String, _ block: () async throws -> Void) async rethrows -> Double {
        let start = Date()
        try await block()
        let seconds = Date().timeIntervalSince(start)
        print(String(format: "BENCHMARK %-42@ %8.3f s", label as NSString, seconds))
        return seconds
    }

    func testBenchmark_fullCatalogOperations() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["EPHEMERIS_BENCHMARK"] == "1",
                          "Set EPHEMERIS_BENCHMARK=1 and build with -c release to run catalog benchmarks")

        // Given
        let elementSets = SyntheticCatalog.elementSets(count: 15_000)
        let start = SyntheticCatalog.epoch.addingTimeInterval(86400)
        print("BENCHMARK cores: \(ProcessInfo.processInfo.activeProcessorCount)")

        // When/Then
        var catalog = SatelliteCatalog(elementSets: [])
        _ = await time("build catalog (15,000 SGP4 initializations)") {
            catalog = SatelliteCatalog(elementSets: elementSets)
        }
        XCTAssertEqual(catalog.satellites.count, 15_000)

        _ = await time("positions at one instant") {
            _ = await catalog.positions(at: start)
        }
        _ = await time("look angles at one instant (what's up)") {
            _ = await catalog.lookAngles(from: louisville, at: start, minElevationDeg: 0)
        }

        let candidates = catalog.satellites.filter { $0.canRise(forLatitudeDeg: louisville.latitudeDeg, minElevationDeg: 10) }
        print("BENCHMARK visibility filter keeps \(candidates.count) of \(catalog.satellites.count) for latitude 38.25°")

        var passCount = 0
        _ = await time("passes over 24 h, 10° minimum, 60 s step") {
            passCount = await catalog.passes(for: louisville, from: start, to: start.addingTimeInterval(86400),
                                             minElevationDeg: 10, stepSeconds: 60).count
        }
        print("BENCHMARK passes found: \(passCount)")
    }
}

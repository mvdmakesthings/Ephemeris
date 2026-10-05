//
//  SatelliteCatalogTests.swift
//  EphemerisTests
//
//  Loading, lookup and filtering for SatelliteCatalog, and whole-catalog propagation
//  checked against propagating each satellite on its own. All data is local: Vallado's
//  verification TLEs, the shared mock TLEs, and the synthetic catalog.
//

import Foundation
import XCTest
@testable import Ephemeris

final class SatelliteCatalogTests: XCTestCase {

    // MARK: - Helpers

    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

    private func verificationTLEText() throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "SGP4-VER", withExtension: "TLE", subdirectory: "Resources"))
        return try String(contentsOf: url, encoding: .ascii)
    }

    private func syntheticCatalog(count: Int) -> SatelliteCatalog {
        SatelliteCatalog(elementSets: SyntheticCatalog.elementSets(count: count))
    }

    // MARK: - Loading

    func testInit_fromVerificationTLEFile_shouldKeepUsableSetsAndExplainTheRest() throws {
        // Given
        // 33 element sets: three have deliberately bad checksums, and satellite 20413
        // appears twice with different epochs
        let text = try verificationTLEText()

        // When
        let catalog = SatelliteCatalog(tleText: text)

        // Then
        XCTAssertEqual(catalog.satellites.count, 29)
        XCTAssertEqual(catalog.satellites.count + catalog.rejections.count, 33)

        let checksumFailures = catalog.rejections.filter {
            if case .invalidTLE(.invalidChecksum) = $0.reason { return true }
            return false
        }
        XCTAssertEqual(checksumFailures.count, 3)

        let superseded = catalog.rejections.filter {
            if case .superseded = $0.reason { return true }
            return false
        }
        XCTAssertEqual(superseded.map(\.catalogNumber), [20413])
    }

    func testInit_withDuplicateCatalogNumbers_shouldKeepTheNewestEpoch() throws {
        // Given
        let older = try MockTLEs.ISSSample()
        let newerText = """
            ISS (ZARYA)
            1 25544U 98067A   20098.82871450  .00000874  00000-0  24271-4 0  9993
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let newer = try TwoLineElement(from: newerText)

        // When
        let catalog = SatelliteCatalog(elementSets: [newer, older])

        // Then
        XCTAssertEqual(catalog.satellites.count, 1)
        XCTAssertEqual(catalog[catalogNumber: 25544]?.elements.epoch, newer.epoch)
        XCTAssertEqual(catalog.rejections.first?.reason, .superseded(byEpoch: newer.epoch))
    }

    func testInit_withSGP4XPElements_shouldRejectWithReason() throws {
        // Given
        var fields = try XCTUnwrap(SyntheticCatalog.fieldSets(count: 1).first)
        fields["EPHEMERIS_TYPE"] = "4"
        let xp = try OrbitMeanElementsMessage(fields: fields)

        // When
        let catalog = SatelliteCatalog(elementSets: [xp])

        // Then
        XCTAssertTrue(catalog.satellites.isEmpty)
        XCTAssertEqual(catalog.rejections.first?.reason, .cannotPropagate(.unsupportedEphemerisType(4)))
    }

    func testInit_fromOMMWithOneBadRecord_shouldLoadTheOthers() throws {
        // Given
        let csv = """
            OBJECT_NAME,OBJECT_ID,EPOCH,MEAN_MOTION,ECCENTRICITY,INCLINATION,RA_OF_ASC_NODE,ARG_OF_PERICENTER,MEAN_ANOMALY,NORAD_CAT_ID,BSTAR
            GOOD,2020-001A,2023-04-25T10:45:30.642912,15.5,.001,51.6,10,20,30,90001,.0001
            BAD,2020-002A,not-a-date,15.5,.001,51.6,10,20,30,90002,.0001
            """

        // When
        let catalog = try SatelliteCatalog(omm: csv)

        // Then
        XCTAssertEqual(catalog.satellites.map(\.catalogNumber), [90001])
        XCTAssertEqual(catalog.rejections.first?.reason, .invalidOMM(.invalidValue(field: "EPOCH", value: "not-a-date")))
    }

    func testParseEach_forTLEDocument_shouldPairNamesWithElementSets() throws {
        // Given
        let text = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            1 26536U 00055A   20116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            ORPHAN LINE ONE
            1 99999U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
            """

        // When
        let results = TwoLineElement.parseEach(text)

        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(try results[0].get().name, "ISS (ZARYA)")
        XCTAssertEqual(try results[1].get().name, "")
        XCTAssertEqual(try results[1].get().catalogNumber, 26536)
        XCTAssertThrowsError(try results[2].get())
    }

    // MARK: - Lookup and Filters

    func testLookup_byCatalogNumberDesignatorAndName_shouldFindSatellites() throws {
        // Given
        let catalog = SatelliteCatalog(elementSets: [try MockTLEs.ISSSample(), try MockTLEs.NOAASample()])

        // When/Then
        XCTAssertEqual(catalog[catalogNumber: 25544]?.name, "ISS (ZARYA)")
        XCTAssertNil(catalog[catalogNumber: 1])
        XCTAssertEqual(catalog.satellite(internationalDesignator: "98067A")?.catalogNumber, 25544)
        XCTAssertEqual(catalog.satellite(internationalDesignator: "1998-067A")?.catalogNumber, 25544)
        XCTAssertEqual(catalog.satellites(named: "noaa").map(\.catalogNumber), [26536])
    }

    func testRegime_shouldClassifyCommonOrbits() throws {
        // Given/When
        let iss = try CatalogSatellite(elements: try MockTLEs.ISSSample())
        let geo = try CatalogSatellite(elements: try MockTLEs.geostationarySample())
        let molniya = try CatalogSatellite(elements: try TwoLineElement(from: """
            1 22674U 93035D   06176.55909107  .00002121  00000-0  29868-3 0  6569
            2 22674  63.5035 354.4452 7541712 253.3264  18.7754  1.96679808 93877
            """))
        // GPS-like: 2.0056 rev/day, near circular
        let gps = try CatalogSatellite(elements: try TwoLineElement(from: """
            1 28129U 03058A   06175.57071136 -.00000104  00000-0  10000-3 0   459
            2 28129  54.7298 324.8098 0048506 266.2640  93.1663  2.00562768 18443
            """))

        // Then
        XCTAssertEqual(iss.regime, .lowEarth)
        XCTAssertEqual(geo.regime, .geosynchronous)
        XCTAssertEqual(molniya.regime, .highlyElliptical)
        XCTAssertEqual(gps.regime, .mediumEarth)
    }

    func testExcludingStale_shouldDropOldElementSets() throws {
        // Given
        let catalog = SatelliteCatalog(elementSets: [try MockTLEs.ISSSample(), try MockTLEs.NOAASample()])
        // ISS epoch 2020-04-06, NOAA 16 epoch 2020-04-25
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2020-04-27T00:00:00Z"))

        // When
        let fresh = catalog.excludingStale(olderThan: 7 * 86400, at: date)

        // Then
        XCTAssertEqual(fresh.satellites.map(\.catalogNumber), [26536])
    }

    // MARK: - Whole-Catalog Propagation

    func testPositions_shouldMatchPropagatingEachSatelliteAlone() async throws {
        // Given
        let catalog = syntheticCatalog(count: 2000)
        let date = SyntheticCatalog.epoch.addingTimeInterval(3 * 86400)

        // When
        let positions = await catalog.positions(at: date)

        // Then
        // Concurrent results must be identical, and in catalog order
        let expected = catalog.satellites.compactMap { satellite in
            (try? satellite.propagator.calculatePosition(at: date)).map { (satellite.catalogNumber, $0) }
        }
        XCTAssertEqual(positions.count, expected.count)
        for (result, reference) in zip(positions, expected) {
            XCTAssertEqual(result.satellite.catalogNumber, reference.0)
            XCTAssertEqual(result.position, reference.1)
        }
    }

    func testStateVectors_shouldMatchPropagatingEachSatelliteAlone() async throws {
        // Given
        let catalog = syntheticCatalog(count: 500)
        let date = SyntheticCatalog.epoch.addingTimeInterval(86400)

        // When
        let states = await catalog.stateVectors(at: date)

        // Then
        XCTAssertEqual(states.count, catalog.satellites.count)
        for result in states {
            XCTAssertEqual(result.state, try result.satellite.propagator.stateVector(at: date))
        }
    }

    func testLookAngles_shouldMatchBruteForceAndBeSortedHighestFirst() async throws {
        // Given
        // Brute force: every satellite, no geometric pre-filter
        let catalog = syntheticCatalog(count: 3000)
        let date = SyntheticCatalog.epoch.addingTimeInterval(36 * 3600)

        // When
        let overhead = await catalog.lookAngles(from: louisville, at: date, minElevationDeg: 0)

        // Then
        let bruteForce = Set(catalog.satellites.compactMap { satellite -> Int? in
            guard let topo = try? satellite.propagator.topocentric(at: date, for: louisville),
                  topo.elevationDeg >= 0 else { return nil }
            return satellite.catalogNumber
        })
        XCTAssertEqual(Set(overhead.map(\.satellite.catalogNumber)), bruteForce)
        XCTAssertFalse(overhead.isEmpty)
        let elevations = overhead.map(\.topocentric.elevationDeg)
        XCTAssertEqual(elevations, elevations.sorted(by: >))
    }

    func testPasses_shouldMatchPerSatellitePredictionInTimeOrder() async throws {
        // Given
        let catalog = syntheticCatalog(count: 300)
        let start = SyntheticCatalog.epoch.addingTimeInterval(86400)
        let end = start.addingTimeInterval(6 * 3600)

        // When
        let passes = await catalog.passes(for: louisville, from: start, to: end, minElevationDeg: 10)

        // Then
        var expected: [SatellitePass] = []
        for satellite in catalog.satellites {
            let windows = try satellite.propagator.predictPasses(for: louisville, from: start, to: end,
                                                                 minElevationDeg: 10, stepSeconds: 60)
            expected += windows.map { SatellitePass(satellite: satellite, pass: $0) }
        }
        XCTAssertEqual(passes.count, expected.count)
        XCTAssertFalse(passes.isEmpty)
        let times = passes.map(\.pass.aos.time)
        XCTAssertEqual(times, times.sorted())
        XCTAssertEqual(Set(passes.map { "\($0.satellite.catalogNumber)@\($0.pass.aos.time.timeIntervalSince1970)" }),
                       Set(expected.map { "\($0.satellite.catalogNumber)@\($0.pass.aos.time.timeIntervalSince1970)" }))
    }

    func testEmptyCatalog_shouldReturnEmptyResults() async {
        // Given
        let catalog = SatelliteCatalog(elementSets: [])

        // When/Then
        let positions = await catalog.positions(at: Date())
        let overhead = await catalog.lookAngles(from: louisville, at: Date())
        XCTAssertTrue(positions.isEmpty)
        XCTAssertTrue(overhead.isEmpty)
    }

    // MARK: - Visibility Filter

    func testCanRise_shouldNeverRejectASatelliteThatActuallyRises() throws {
        // Given
        // Brute force over a day: if a satellite is ever seen above the minimum elevation,
        // the geometric filter must have allowed it. Also check the filter does real work.
        let catalog = syntheticCatalog(count: 400)
        let latitudes: [Double] = [0, 38.25, 55, 70, 85, -65]
        var rejectedCount = 0

        for latitude in latitudes {
            let observer = Observer(latitudeDeg: latitude, longitudeDeg: 20, altitudeMeters: 0)
            for satellite in catalog.satellites {
                // When
                let allowed = satellite.canRise(forLatitudeDeg: latitude, minElevationDeg: 10)
                if allowed { continue }
                rejectedCount += 1

                // Then
                let track = try satellite.propagator.skyTrack(for: observer, from: SyntheticCatalog.epoch,
                                                              to: SyntheticCatalog.epoch.addingTimeInterval(86400),
                                                              stepSeconds: 120)
                let highest = track.map(\.topocentric.elevationDeg).max() ?? -90
                XCTAssertLessThan(highest, 10, "Filter rejected #\(satellite.catalogNumber) at latitude \(latitude)")
            }
        }
        XCTAssertGreaterThan(rejectedCount, 100, "The filter should skip a meaningful share of the catalog")
    }

    func testCanRise_withNegativeElevation_shouldNotFilter() throws {
        // Given/When
        let equatorial = try CatalogSatellite(elements: try MockTLEs.equatorialSample())

        // Then
        XCTAssertFalse(equatorial.canRise(forLatitudeDeg: 80, minElevationDeg: 0))
        XCTAssertTrue(equatorial.canRise(forLatitudeDeg: 80, minElevationDeg: -5))
    }
}

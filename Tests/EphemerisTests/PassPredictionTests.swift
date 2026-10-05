//
//  PassPredictionTests.swift
//  EphemerisTests
//
//  Pass finding: agreement with Skyfield, window edges, and short passes.
//

import Foundation
import XCTest
@testable import Ephemeris

final class PassPredictionTests: XCTestCase {

    // MARK: - Helpers

    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

    private func date(_ iso8601: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return try XCTUnwrap(formatter.date(from: iso8601))
    }

    // MARK: - Agreement With Skyfield

    func testPredictPasses_forISSOverLouisville_shouldMatchSkyfieldEvents() throws {
        // Given
        // Skyfield EarthSatellite.find_events(observer, t0, t1, altitude_degrees=10), which
        // applies UT1 − UTC (−0.23 s); Ephemeris uses UTC, so allow a couple of seconds.
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let expected: [(rise: String, culmination: String, set: String)] = [
            ("2020-04-06T22:54:14.388Z", "2020-04-06T22:56:02.800Z", "2020-04-06T22:57:50.985Z"),
            ("2020-04-07T00:30:05.040Z", "2020-04-07T00:33:25.321Z", "2020-04-07T00:36:44.900Z"),
            ("2020-04-07T02:08:23.084Z", "2020-04-07T02:09:51.488Z", "2020-04-07T02:11:19.950Z"),
            ("2020-04-07T17:12:23.333Z", "2020-04-07T17:15:38.503Z", "2020-04-07T17:18:54.425Z"),
            ("2020-04-07T18:49:58.179Z", "2020-04-07T18:52:38.483Z", "2020-04-07T18:55:19.235Z")
        ]

        // When
        let passes = try sgp4.predictPasses(for: louisville, from: try date("2020-04-06T20:00:00.000Z"),
                                            to: try date("2020-04-07T20:00:00.000Z"), minElevationDeg: 10)

        // Then
        XCTAssertEqual(passes.count, expected.count)
        for (pass, reference) in zip(passes, expected) {
            XCTAssertEqual(pass.aos.time.timeIntervalSince(try date(reference.rise)), 0, accuracy: 2)
            XCTAssertEqual(pass.culmination.time.timeIntervalSince(try date(reference.culmination)), 0, accuracy: 2)
            XCTAssertEqual(pass.los.time.timeIntervalSince(try date(reference.set)), 0, accuracy: 2)
            XCTAssertEqual(pass.aos.elevationDeg, 10, accuracy: 0.01)
            XCTAssertEqual(pass.los.elevationDeg, 10, accuracy: 0.01)
            XCTAssertFalse(pass.beginsBeforeSearch)
            XCTAssertFalse(pass.endsAfterSearch)
        }
    }

    func testPredictPasses_culmination_shouldBeHighestPointOfPass() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let passes = try sgp4.predictPasses(for: louisville, from: sgp4.epoch,
                                            to: sgp4.epoch.addingTimeInterval(86400), minElevationDeg: 0)

        for pass in passes {
            // When
            let track = try sgp4.skyTrack(for: louisville, from: pass.aos.time, to: pass.los.time, stepSeconds: 5)

            // Then
            let sampledMaximum = track.map { $0.topocentric.elevationDeg }.max() ?? 0
            XCTAssertGreaterThanOrEqual(pass.culmination.elevationDeg, sampledMaximum - 1e-4)
        }
    }

    // MARK: - Window Edges

    func testPredictPasses_startingMidPass_shouldReportPassFlaggedAsBeginningBeforeSearch() throws {
        // Given
        // The ISS is near culmination over Louisville at 00:33 UTC on April 7
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let start = try date("2020-04-07T00:33:00.000Z")

        // When
        let passes = try sgp4.predictPasses(for: louisville, from: start, to: start.addingTimeInterval(3600),
                                            minElevationDeg: 10)

        // Then
        let first = try XCTUnwrap(passes.first)
        XCTAssertTrue(first.beginsBeforeSearch)
        XCTAssertFalse(first.endsAfterSearch)
        XCTAssertEqual(first.aos.time, start)
        XCTAssertGreaterThan(first.aos.elevationDeg, 10)
    }

    func testPredictPasses_endingMidPass_shouldReportPassFlaggedAsEndingAfterSearch() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let end = try date("2020-04-07T00:33:00.000Z")

        // When
        let passes = try sgp4.predictPasses(for: louisville, from: end.addingTimeInterval(-3600), to: end,
                                            minElevationDeg: 10)

        // Then
        let last = try XCTUnwrap(passes.last)
        XCTAssertTrue(last.endsAfterSearch)
        XCTAssertFalse(last.beginsBeforeSearch)
        XCTAssertEqual(last.los.time, end)
    }

    // MARK: - Short Passes

    func testPredictPasses_withCoarseStep_shouldStillFindPassesShorterThanTheStep() throws {
        // Given
        // At 10° minimum elevation the ISS passes last 3-7 minutes. With 10-minute sampling
        // most of them fall entirely between samples, so they are only found by checking
        // sampled elevation peaks that stay below the minimum.
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let start = try date("2020-04-06T20:00:00.000Z")
        let end = start.addingTimeInterval(86400)

        // When
        let fine = try sgp4.predictPasses(for: louisville, from: start, to: end, minElevationDeg: 10, stepSeconds: 30)
        let coarse = try sgp4.predictPasses(for: louisville, from: start, to: end, minElevationDeg: 10, stepSeconds: 600)

        // Then
        XCTAssertEqual(coarse.count, fine.count)
        for (coarsePass, finePass) in zip(coarse, fine) {
            XCTAssertEqual(coarsePass.aos.time.timeIntervalSince(finePass.aos.time), 0, accuracy: 0.5)
            XCTAssertEqual(coarsePass.los.time.timeIntervalSince(finePass.los.time), 0, accuracy: 0.5)
        }
    }

    // MARK: - PassWindow

    func testPassWindow_duration_shouldBeLOSMinusAOS() {
        // Given
        let start = Date(timeIntervalSince1970: 1_000_000)
        let pass = PassWindow(
            aos: PassWindow.Event(time: start, azimuthDeg: 90, elevationDeg: 0),
            culmination: PassWindow.Event(time: start.addingTimeInterval(300), azimuthDeg: 180, elevationDeg: 45),
            los: PassWindow.Event(time: start.addingTimeInterval(600), azimuthDeg: 270, elevationDeg: 0)
        )

        // When/Then
        XCTAssertEqual(pass.duration, 600)
    }

    func testPassWindow_codableRoundTrip_shouldPreserveAllFields() throws {
        // Given
        let start = Date(timeIntervalSince1970: 1_000_000)
        let pass = PassWindow(
            aos: PassWindow.Event(time: start, azimuthDeg: 90, elevationDeg: 10),
            culmination: PassWindow.Event(time: start.addingTimeInterval(300), azimuthDeg: 180, elevationDeg: 45),
            los: PassWindow.Event(time: start.addingTimeInterval(600), azimuthDeg: 270, elevationDeg: 10),
            beginsBeforeSearch: true
        )

        // When
        let decoded = try JSONDecoder().decode(PassWindow.self, from: try JSONEncoder().encode(pass))

        // Then
        XCTAssertEqual(decoded, pass)
    }
}

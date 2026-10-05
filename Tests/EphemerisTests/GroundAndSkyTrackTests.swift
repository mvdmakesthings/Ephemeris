//
//  GroundAndSkyTrackTests.swift
//  EphemerisTests
//
//  Sampling of ground tracks and sky tracks.
//

import Foundation
import XCTest
@testable import Ephemeris

final class GroundAndSkyTrackTests: XCTestCase {

    // MARK: - Helpers

    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

    // MARK: - Sampling

    func testGroundTrack_withEvenSteps_shouldIncludeBothEnds() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let start = sgp4.epoch

        // When
        let track = try sgp4.groundTrack(from: start, to: start.addingTimeInterval(600), stepSeconds: 60)

        // Then
        XCTAssertEqual(track.count, 11)
        XCTAssertEqual(track.first?.time, start)
        XCTAssertEqual(track.last?.time, start.addingTimeInterval(600))
    }

    func testGroundTrack_withUnevenSteps_shouldStillEndAtEndTime() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let start = sgp4.epoch
        let end = start.addingTimeInterval(250)

        // When
        let track = try sgp4.groundTrack(from: start, to: end, stepSeconds: 60)

        // Then
        // 0, 60, 120, 180, 240, then the end time at 250
        XCTAssertEqual(track.map { $0.time.timeIntervalSince(start) }, [0, 60, 120, 180, 240, 250])
    }

    func testGroundTrack_withEqualOrReversedTimes_shouldReturnOneOrNoPoints() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())

        // When/Then
        XCTAssertEqual(try sgp4.groundTrack(from: sgp4.epoch, to: sgp4.epoch).count, 1)
        XCTAssertEqual(try sgp4.groundTrack(from: sgp4.epoch, to: sgp4.epoch.addingTimeInterval(-60)).count, 0)
    }

    // MARK: - Ground Track Shape

    func testGroundTrack_forEquatorialOrbit_shouldStayNearEquator() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.equatorialSample())

        // When
        let track = try sgp4.groundTrack(from: sgp4.epoch, to: sgp4.epoch.addingTimeInterval(6000), stepSeconds: 60)

        // Then
        // Inclination 0.1°, plus up to ~0.1° of geodetic/geocentric difference
        for point in track {
            XCTAssertLessThan(abs(point.position.latitudeDeg), 0.25)
        }
    }

    func testGroundTrack_forPolarOrbit_shouldPassNearThePoles() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.polarSample())

        // When
        let track = try sgp4.groundTrack(from: sgp4.epoch, to: sgp4.epoch.addingTimeInterval(6000), stepSeconds: 30)

        // Then
        XCTAssertGreaterThan(track.map { $0.position.latitudeDeg }.max() ?? 0, 85)
        XCTAssertLessThan(track.map { $0.position.latitudeDeg }.min() ?? 0, -85)
    }

    func testGroundTrack_forGeostationaryOrbit_shouldBarelyMove() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.geostationarySample())

        // When
        let track = try sgp4.groundTrack(from: sgp4.epoch, to: sgp4.epoch.addingTimeInterval(86400), stepSeconds: 3600)

        // Then
        let longitudes = track.map { $0.position.longitudeDeg }
        XCTAssertLessThan((longitudes.max() ?? 0) - (longitudes.min() ?? 0), 1.0)
        for point in track {
            XCTAssertLessThan(abs(point.position.latitudeDeg), 0.2)
            XCTAssertEqual(point.position.altitudeKm, 35786, accuracy: 25)
        }
    }

    // MARK: - Sky Track

    func testSkyTrack_shouldMatchTopocentricAtEachSample() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let start = sgp4.epoch

        // When
        let track = try sgp4.skyTrack(for: louisville, from: start, to: start.addingTimeInterval(3600), stepSeconds: 120)

        // Then
        XCTAssertEqual(track.count, 31)
        for point in track {
            XCTAssertEqual(point.topocentric, try sgp4.topocentric(at: point.time, for: louisville))
        }
    }

    func testSkyTrack_overADay_shouldGoAboveAndBelowHorizon() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())

        // When
        let track = try sgp4.skyTrack(for: louisville, from: sgp4.epoch,
                                      to: sgp4.epoch.addingTimeInterval(86400), stepSeconds: 60)

        // Then
        XCTAssertTrue(track.contains { $0.topocentric.elevationDeg > 0 })
        XCTAssertTrue(track.contains { $0.topocentric.elevationDeg < 0 })
    }
}

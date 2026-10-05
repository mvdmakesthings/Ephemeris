//
//  EndToEndCrossCheckTests.swift
//  EphemerisTests
//
//  Cross-checks the full pipeline (TLE → SGP4 → TEME → Earth-fixed → geodetic and
//  observer look angles) against Skyfield 1.x, an independent astronomy library.
//
//  Skyfield applies UT1 − UTC (−0.23 s in April 2020) when rotating TEME into the
//  Earth-fixed frame. Ephemeris uses UTC, so Earth is rotated 0.23 s × 360.9856°/day
//  = 0.00096° less. That shifts longitudes by ~100 m and moves look angles by a few
//  hundredths of a degree at most. The tolerances below allow for exactly that.
//

import Foundation
import XCTest
@testable import Ephemeris

final class EndToEndCrossCheckTests: XCTestCase {

    // MARK: - Types

    /// Skyfield sub-satellite point at a UTC time
    private struct SubPoint {
        let time: String
        let latitude: Double
        let longitude: Double
        let heightKm: Double
    }

    /// Skyfield look angles at a UTC time
    private struct LookAngles {
        let time: String
        let azimuth: Double
        let elevation: Double
        let rangeKm: Double
        let rangeRateKmPerSec: Double
    }

    // MARK: - Helpers

    private func date(_ iso8601: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: iso8601))
    }

    // MARK: - Sub-Satellite Point

    func testCalculatePosition_forISSWithSGP4_shouldMatchSkyfield() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        // Skyfield: wgs84.subpoint_of(sat.at(t)), wgs84.height_of(sat.at(t))
        let reference = [
            SubPoint(time: "2020-04-06T20:00:00Z", latitude: 25.836226, longitude: 3.597978, heightKm: 419.8681),
            SubPoint(time: "2020-04-07T01:30:00Z", latitude: -12.027673, longitude: 112.482940, heightKm: 424.5644),
            SubPoint(time: "2020-04-07T12:15:30Z", latitude: -26.475043, longitude: -64.971844, heightKm: 429.9509)
        ]

        for expected in reference {
            // When
            let position = try sgp4.calculatePosition(at: try date(expected.time))

            // Then
            XCTAssertEqual(position.latitudeDeg, expected.latitude, accuracy: 1e-5, expected.time)
            // UT1 − UTC accounts for 0.00096° of longitude
            XCTAssertEqual(position.longitudeDeg, expected.longitude, accuracy: 0.002, expected.time)
            XCTAssertEqual(position.altitudeKm, expected.heightKm, accuracy: 0.001, expected.time)
        }
    }

    // MARK: - Observer Look Angles

    func testTopocentric_duringISSPassOverLouisville_shouldMatchSkyfield() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
        // Skyfield: (sat - observer).at(t).altaz() and frame_latlon_and_rates(observer)
        let reference = [
            LookAngles(time: "2020-04-07T00:31:00Z", azimuth: 318.347735, elevation: 17.143300,
                       rangeKm: 1136.76973, rangeRateKmPerSec: -6.453044),
            LookAngles(time: "2020-04-07T00:33:25Z", azimuth: 36.438581, elevation: 62.345803,
                       rangeKm: 471.89326, rangeRateKmPerSec: -0.051681),
            LookAngles(time: "2020-04-07T00:35:30Z", azimuth: 114.219015, elevation: 20.757426,
                       rangeKm: 1003.53887, rangeRateKmPerSec: 6.268649)
        ]

        for expected in reference {
            // When
            let topo = try sgp4.topocentric(at: try date(expected.time), for: observer)

            // Then
            XCTAssertEqual(topo.azimuthDeg, expected.azimuth, accuracy: 0.03, expected.time)
            XCTAssertEqual(topo.elevationDeg, expected.elevation, accuracy: 0.01, expected.time)
            XCTAssertEqual(topo.rangeKm, expected.rangeKm, accuracy: 0.1, expected.time)
            XCTAssertEqual(topo.rangeRateKmPerSec, expected.rangeRateKmPerSec, accuracy: 0.002, expected.time)
        }
    }
}

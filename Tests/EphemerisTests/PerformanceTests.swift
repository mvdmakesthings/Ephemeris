//
//  PerformanceTests.swift
//  EphemerisTests
//
//  Performance benchmarks for core algorithms.
//

import XCTest
@testable import Ephemeris

final class PerformanceTests: XCTestCase {

    // MARK: - TLE Parsing Performance

    func testPerformance_TLEParsing() throws {
        // Given
        let tleString = """
        ISS (ZARYA)
        1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
        2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
        """

        // When / Then
        measure {
            for _ in 0..<100 {
                _ = try? TwoLineElement(from: tleString)
            }
        }
    }

    // MARK: - Position Calculation Performance

    func testPerformance_PositionCalculation() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let date = Date()

        // When / Then
        measure {
            for _ in 0..<1000 {
                _ = try? orbit.calculatePosition(at: date)
            }
        }
    }

    // MARK: - Pass Prediction Performance

    func testPerformance_PassPrediction() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
        let now = Date()
        let tomorrow = now.addingTimeInterval(86400) // 24 hours

        // When / Then
        measure {
            _ = try? orbit.predictPasses(
                for: observer,
                from: now,
                to: tomorrow,
                minElevationDeg: 10.0
            )
        }
    }

    // MARK: - Ground Track Generation Performance

    func testPerformance_GroundTrackGeneration() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let now = Date()
        let oneOrbit = now.addingTimeInterval(orbit.orbitalPeriod)

        // When / Then
        measure {
            _ = try? orbit.groundTrack(from: now, to: oneOrbit, stepSeconds: 60)
        }
    }

    // MARK: - Topocentric Calculation Performance

    func testPerformance_TopoCentricCalculation() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
        let date = Date()

        // When / Then
        measure {
            for _ in 0..<1000 {
                _ = try? orbit.topocentric(at: date, for: observer)
            }
        }
    }

    // MARK: - Eccentric Anomaly Newton-Raphson Performance

    func testPerformance_EccentricAnomalyNewtonRaphson() {
        // Given
        let eccentricity = 0.0167 // Earth-like eccentricity
        let meanAnomaly: Degrees = 45.0

        // When / Then
        measure {
            for _ in 0..<10000 {
                _ = Orbit.calculateEccentricAnomaly(
                    eccentricity: eccentricity,
                    meanAnomaly: meanAnomaly
                )
            }
        }
    }

    // MARK: - Sky Track Generation Performance

    func testPerformance_SkyTrackGeneration() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
        let now = Date()
        let tenMinutes = now.addingTimeInterval(600)

        // When / Then
        measure {
            _ = try? orbit.skyTrack(for: observer, from: now, to: tenMinutes, stepSeconds: 10)
        }
    }
}

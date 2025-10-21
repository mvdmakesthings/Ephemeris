//
//  OrbitalElementsTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

final class OrbitalElementsTests: XCTestCase {

    // MARK: - Orbital Element Calculation Tests

    func testSemimajorAxis_withGOES16MeanMotion_shouldCalculateCorrectly() {
        // Given
        // GOES 16 Satellite
        // 42,164.9 km (26,200.0 mi)
        let knownSemimajorAxis = 42165.0 // km
        let meanMotion = 1.00271173 // Revolutions Per Day

        // When
        let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion).rounded()

        // Then
        XCTAssertEqual(semimajorAxis, knownSemimajorAxis)
    }

    func testEccentricAnomaly_withNearlyCircularOrbit_shouldCalculateCorrectly() {
        // Given
        // Test with low eccentricity (nearly circular orbit)
        // See numerical example: http://www.csun.edu/~hcmth017/master/node16.html
        let eccentricity = 0.00001
        let meanAnomaly: Degrees = 30
        let expectedEccentricAnomaly = 30.00029

        // When
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(
            eccentricity: eccentricity,
            meanAnomaly: meanAnomaly,
            accuracy: 0.0001,
            maxIterations: 500
        )

        // Then
        XCTAssertEqual(eccentricAnomaly.round(to: 5), expectedEccentricAnomaly)
    }

    func testTrueAnomaly_atPeriapsis_shouldReturnZero() throws {
        // Given
        // For E=0 (at periapsis), true anomaly should be 0
        let eccentricity = 0.1
        let eccentricAnomalyAtPeriapsis: Degrees = 0.0

        // When
        let trueAnomalyAtPeriapsis = try Orbit.calculateTrueAnomaly(
            eccentricity: eccentricity,
            eccentricAnomaly: eccentricAnomalyAtPeriapsis
        )

        // Then
        XCTAssertEqual(trueAnomalyAtPeriapsis, 0.0, accuracy: 0.001)
    }

    func testTrueAnomaly_withValidInputs_shouldReturnValidAngle() throws {
        // Given
        let eccentricity = 0.1
        let eccentricAnomaly: Degrees = 45.0

        // When
        let trueAnomaly = try Orbit.calculateTrueAnomaly(
            eccentricity: eccentricity,
            eccentricAnomaly: eccentricAnomaly
        )

        // Then
        // Test that function returns valid angles (0-360°)
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0.0)
        XCTAssertLessThanOrEqual(trueAnomaly, 360.0)
    }

    func testOrbitInitialization_fromTLE_shouldSetValidOrbitalElements() throws {
        // Given
        let tle = try MockTLEs.ISSSample()

        // When
        let orbit = Orbit(from: tle)

        // Then
        // Verify basic orbital elements are set
        XCTAssertGreaterThan(orbit.semimajorAxis, 0)
        XCTAssertGreaterThanOrEqual(orbit.eccentricity, 0)
        XCTAssertLessThanOrEqual(orbit.eccentricity, 1)
        XCTAssertGreaterThanOrEqual(orbit.inclination, 0)
        XCTAssertLessThanOrEqual(orbit.inclination, 180)
    }
}

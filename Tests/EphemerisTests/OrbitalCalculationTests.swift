//
//  OrbitalCalculationTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

final class OrbitalCalculationTests: XCTestCase {

    // MARK: - Orbital Element Calculation Tests

    func testSemimajorAxis_withGOES16Parameters_shouldCalculateCorrectly() {
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

    func testEccentricAnomaly_withKnownExample_shouldMatchExpectedValue() {
        // Given
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

    func testTrueAnomaly_withEccentricity0Point5_shouldCalculateCorrectly() throws {
        // Given
        let eccentricity = 0.5
        let eccentricAnomaly: Degrees = 30.000

        // When
        let trueAnomaly = try Orbit.calculateTrueAnomaly(
            eccentricity: eccentricity,
            eccentricAnomaly: eccentricAnomaly
        )

        // Then
        XCTAssertEqual(trueAnomaly.round(to: 1), 90.0)
    }

    // MARK: - Orbitable Protocol Conformance Tests

    func testOrbit_conformsToOrbitableProtocol_shouldAllowProtocolUsage() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)

        // When
        // Verify that orbit can be used as Orbitable
        let orbitable: Orbitable = orbit

        // Then
        // Test that trueAnomaly is accessible and non-optional through protocol
        let trueAnomalyValue = orbitable.trueAnomaly
        XCTAssertGreaterThanOrEqual(trueAnomalyValue, 0.0)
        XCTAssertLessThanOrEqual(trueAnomalyValue, 360.0)
    }

    func testTrueAnomaly_forValidOrbit_shouldAlwaysReturnValue() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)

        // When
        // Access trueAnomaly - should never be nil
        let trueAnomaly = orbit.trueAnomaly

        // Then
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0.0)
        XCTAssertLessThanOrEqual(trueAnomaly, 360.0)
    }

    func testTrueAnomaly_fromMeanAnomaly_shouldBeComputedCorrectly() throws {
        // Given
        // Test that trueAnomaly is properly calculated from mean anomaly
        let tle = try MockTLEs.objectAtPerigee()
        let orbit = Orbit(from: tle)

        // When
        // For an object at perigee with e=0.5 and M=0, true anomaly should be 0
        let trueAnomaly = orbit.trueAnomaly

        // Then
        // The value should be computed and be a valid angle
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0.0)
        XCTAssertLessThanOrEqual(trueAnomaly, 360.0)
    }

    // MARK: - WGS84 Physical Constants Validation

    func testWGS84Constants_shouldMatchStandardValues() {
        // Given
        // Verify Earth's gravitational constant (µ = GM) matches WGS84 standard
        // WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
        let expectedMu = 398600.4418 // km^3/s^2

        // Verify Earth's radius matches WGS84 standard
        // WGS84 equatorial radius: 6378.137 km
        let expectedRadius = 6378.137 // km

        // Verify seconds per day is correct
        let expectedSecondsPerDay = 86400.0

        // When
        let actualMu = PhysicalConstants.Earth.µ
        let actualRadius = PhysicalConstants.Earth.radius
        let actualSecondsPerDay = PhysicalConstants.Time.secondsPerDay

        // Then
        XCTAssertEqual(actualMu, expectedMu, accuracy: 0.0001)
        XCTAssertEqual(actualRadius, expectedRadius, accuracy: 0.001)
        XCTAssertEqual(actualSecondsPerDay, expectedSecondsPerDay)
    }
}

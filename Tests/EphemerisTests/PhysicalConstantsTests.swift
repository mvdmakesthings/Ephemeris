//
//  PhysicalConstantsTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/19/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

final class PhysicalConstantsTests: XCTestCase {

    // MARK: - Earth Constants Tests

    func testEarthConstants_gravitationalConstant_shouldMatchWGS84Standard() {
        // Given
        // WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
        let expectedMu = 398600.4418 // km^3/s^2

        // When
        let actualMu = PhysicalConstants.Earth.µ

        // Then
        XCTAssertEqual(actualMu, expectedMu, accuracy: 0.0001)
    }

    func testEarthConstants_radius_shouldMatchWGS84EquatorialRadius() {
        // Given
        // WGS84 equatorial radius: 6378.137 km
        let expectedRadius = 6378.137 // km

        // When
        let actualRadius = PhysicalConstants.Earth.radius

        // Then
        XCTAssertEqual(actualRadius, expectedRadius, accuracy: 0.001)
    }

    func testEarthConstants_meanRadius_shouldBeApproximately6371km() {
        // When
        let meanRadius = PhysicalConstants.Earth.meanRadius

        // Then
        XCTAssertEqual(meanRadius, 6371.0)
    }

    func testEarthConstants_radiansPerDay_shouldMatchValladoStandard() {
        // Given
        // Expected value from Vallado: 6.3003809866574
        let expectedRadsPerDay = 6.3003809866574

        // When
        let actualRadsPerDay = PhysicalConstants.Earth.radsPerDay

        // Then
        XCTAssertEqual(actualRadsPerDay, expectedRadsPerDay, accuracy: 0.0000001)

        // Should be slightly more than 2π (difference between solar and sidereal day)
        XCTAssertGreaterThan(actualRadsPerDay, 2.0 * .pi)
        XCTAssertEqual(actualRadsPerDay, 2.0 * .pi, accuracy: 0.02)
    }

    // MARK: - Time Constants Tests

    func testTimeConstants_secondsPerDay_shouldBe86400() {
        // When
        let secondsPerDay = PhysicalConstants.Time.secondsPerDay

        // Then
        XCTAssertEqual(secondsPerDay, 86400.0)
        XCTAssertEqual(secondsPerDay, 24.0 * 60.0 * 60.0)
    }

    func testTimeConstants_daysPerJulianCentury_shouldBe36525() {
        // When
        let daysPerCentury = PhysicalConstants.Time.daysPerJulianCentury

        // Then
        XCTAssertEqual(daysPerCentury, 36525.0)
    }

    func testTimeConstants_secondsPerHour_shouldBe3600() {
        // When
        let secondsPerHour = PhysicalConstants.Time.secondsPerHour

        // Then
        XCTAssertEqual(secondsPerHour, 3600.0)
        XCTAssertEqual(secondsPerHour, 60.0 * 60.0)
    }

    func testTimeConstants_secondsPerMinute_shouldBe60() {
        // When
        let secondsPerMinute = PhysicalConstants.Time.secondsPerMinute

        // Then
        XCTAssertEqual(secondsPerMinute, 60.0)
    }

    // MARK: - Julian Date Constants Tests

    func testJulianConstants_unixEpoch_shouldBeJD2440587Point5() {
        // Given
        // Unix epoch (Jan 1, 1970 00:00:00 UTC) should be JD 2440587.5
        let expectedUnixEpoch = 2440587.5

        // When
        let actualUnixEpoch = PhysicalConstants.Julian.unixEpoch

        // Then
        XCTAssertEqual(actualUnixEpoch, expectedUnixEpoch)
    }

    func testJulianConstants_j2000Epoch_shouldBeJD2451545() {
        // Given
        // J2000.0 epoch (Jan 1, 2000 12:00:00 TT) should be JD 2451545.0
        let expectedJ2000Epoch = 2451545.0

        // When
        let actualJ2000Epoch = PhysicalConstants.Julian.j2000Epoch

        // Then
        XCTAssertEqual(actualJ2000Epoch, expectedJ2000Epoch)
    }

    // MARK: - Calculation Constants Tests

    func testCalculationConstants_defaultAccuracy_shouldBe0Point00001() {
        // When
        let defaultAccuracy = PhysicalConstants.Calculation.defaultAccuracy

        // Then
        XCTAssertEqual(defaultAccuracy, 0.00001)
    }

    func testCalculationConstants_maxIterations_shouldBe500AndPositive() {
        // When
        let maxIterations = PhysicalConstants.Calculation.maxIterations

        // Then
        XCTAssertEqual(maxIterations, 500)
        XCTAssertGreaterThan(maxIterations, 0)
    }

    // MARK: - Angle Constants Tests

    func testAngleConstants_degreesPerCircle_shouldBe360() {
        // When
        let degreesPerCircle = PhysicalConstants.Angle.degreesPerCircle

        // Then
        XCTAssertEqual(degreesPerCircle, 360.0)
    }

    func testAngleConstants_radiansPerCircle_shouldBe2Pi() {
        // Given
        let expected2Pi = 2.0 * Double.pi

        // When
        let radiansPerCircle = PhysicalConstants.Angle.radiansPerCircle

        // Then
        XCTAssertEqual(radiansPerCircle, expected2Pi, accuracy: 0.0000001)
    }
}

//
//  PhysicalConstantsTests.swift
//  EphemerisTests
//
//  Checks the constants against their published sources and against each other.
//

import Foundation
import XCTest
@testable import Ephemeris

final class PhysicalConstantsTests: XCTestCase {

    // MARK: - Earth (WGS-84)

    func testEarth_mu_shouldMatchWGS84() {
        // Given/When/Then
        // WGS-84: GM = 3.986004418 × 10¹⁴ m³/s² = 398600.4418 km³/s²
        XCTAssertEqual(PhysicalConstants.Earth.mu, 398600.4418)
    }

    func testEarth_semiMajorAxis_shouldMatchWGS84() {
        // Given/When/Then
        // WGS-84: a = 6378137 m
        XCTAssertEqual(PhysicalConstants.Earth.semiMajorAxis, 6378.137)
    }

    func testEarth_eccentricitySquared_shouldFollowFromWGS84Flattening() {
        // Given
        // WGS-84 defines the flattening f = 1/298.257223563; e² = f(2 − f)
        let flattening = 1.0 / 298.257223563

        // When/Then
        XCTAssertEqual(PhysicalConstants.Earth.eccentricitySquared, flattening * (2 - flattening), accuracy: 1e-14)
    }

    func testEarth_rotationRate_shouldMatchSiderealRotation() {
        // Given/When/Then
        // WGS-84 defining constant, which is one rotation per sidereal day (86164.0905 s)
        XCTAssertEqual(PhysicalConstants.Earth.rotationRate, 7.292115e-5)
        XCTAssertEqual(PhysicalConstants.Earth.rotationRate, 2 * .pi / 86164.0905, accuracy: 1e-11)
    }

    // MARK: - Time and Epochs

    func testTimeAndJulianConstants_shouldMatchDefinitions() {
        // Given/When/Then
        XCTAssertEqual(PhysicalConstants.Time.secondsPerDay, 86400)
        XCTAssertEqual(PhysicalConstants.Time.secondsPerHour, 3600)
        XCTAssertEqual(PhysicalConstants.Time.daysPerJulianCentury, 36525)
        XCTAssertEqual(PhysicalConstants.Julian.unixEpoch, 2440587.5)
        XCTAssertEqual(PhysicalConstants.Julian.j2000, 2451545.0)
    }
}

//
//  PhysicalConstantsTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/19/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class PhysicalConstantsTests: XCTestCase {
    
    // MARK: - Earth Constants Tests
    
    func testEarthGravitationalConstant() throws {
        // Verify Earth's gravitational constant (µ = GM) matches WGS84 standard
        // WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
        let expectedMu = 398600.4418 // km^3/s^2
        XCTAssertEqual(PhysicalConstants.Earth.µ, expectedMu, accuracy: 0.0001,
                       "Earth's gravitational constant should match WGS84 standard")
    }
    
    func testEarthRadius() throws {
        // Verify Earth's radius matches WGS84 standard
        // WGS84 equatorial radius: 6378.137 km
        let expectedRadius = 6378.137 // km
        XCTAssertEqual(PhysicalConstants.Earth.radius, expectedRadius, accuracy: 0.001,
                       "Earth's radius should match WGS84 standard")
    }
    
    func testEarthMeanRadius() throws {
        // Mean radius should be approximately 6371 km
        XCTAssertEqual(PhysicalConstants.Earth.meanRadius, 6371.0,
                       "Earth's mean radius should be approximately 6371 km")
    }
    
    func testEarthRadiansPerDay() throws {
        // Earth rotates approximately 2π radians per sidereal day
        // Expected value from Vallado: 6.3003809866574
        XCTAssertEqual(PhysicalConstants.Earth.radsPerDay, 6.3003809866574, accuracy: 0.0000001)
        
        // Should be slightly more than 2π (difference between solar and sidereal day)
        XCTAssertGreaterThan(PhysicalConstants.Earth.radsPerDay, 2.0 * .pi)
        XCTAssertEqual(PhysicalConstants.Earth.radsPerDay, 2.0 * .pi, accuracy: 0.02)
    }
    
    // MARK: - Time Constants Tests
    
    func testSecondsPerDay() throws {
        XCTAssertEqual(PhysicalConstants.Time.secondsPerDay, 86400.0)
        XCTAssertEqual(PhysicalConstants.Time.secondsPerDay, 24.0 * 60.0 * 60.0)
    }
    
    func testDaysPerJulianCentury() throws {
        XCTAssertEqual(PhysicalConstants.Time.daysPerJulianCentury, 36525.0)
    }
    
    func testSecondsPerHour() throws {
        XCTAssertEqual(PhysicalConstants.Time.secondsPerHour, 3600.0)
        XCTAssertEqual(PhysicalConstants.Time.secondsPerHour, 60.0 * 60.0)
    }
    
    func testSecondsPerMinute() throws {
        XCTAssertEqual(PhysicalConstants.Time.secondsPerMinute, 60.0)
    }
    
    // MARK: - Julian Date Constants Tests
    
    func testJulianUnixEpoch() throws {
        // Unix epoch (Jan 1, 1970 00:00:00 UTC) should be JD 2440587.5
        XCTAssertEqual(PhysicalConstants.Julian.unixEpoch, 2440587.5)
    }
    
    func testJulianJ2000Epoch() throws {
        // J2000.0 epoch (Jan 1, 2000 12:00:00 TT) should be JD 2451545.0
        XCTAssertEqual(PhysicalConstants.Julian.j2000Epoch, 2451545.0)
    }
    
    // MARK: - Calculation Constants Tests
    
    func testDefaultAccuracy() throws {
        XCTAssertEqual(PhysicalConstants.Calculation.defaultAccuracy, 0.00001)
    }
    
    func testMaxIterations() throws {
        XCTAssertEqual(PhysicalConstants.Calculation.maxIterations, 500)
        XCTAssertGreaterThan(PhysicalConstants.Calculation.maxIterations, 0)
    }
    
    // MARK: - Angle Constants Tests
    
    func testDegreesPerCircle() throws {
        XCTAssertEqual(PhysicalConstants.Angle.degreesPerCircle, 360.0)
    }
    
    func testRadiansPerCircle() throws {
        XCTAssertEqual(PhysicalConstants.Angle.radiansPerCircle, 2.0 * .pi, accuracy: 0.0000001)
    }
}

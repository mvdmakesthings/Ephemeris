//
//  OrbitalElementsTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class OrbitalCalculationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCalculateSemimajorAxis() throws {
        // GOES 16 Satellite
        // 42,164.8 km (26,200.0 mi)
        let knownSemimajorAxis = 42165.0 // km
        let meanMotion = 1.00271173 // Revolutions Per Day
        let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion).rounded(.towardZero) // Rounded to the nearest km
        XCTAssertEqual(semimajorAxis, knownSemimajorAxis)
    }
    
    func testCalculateEccentricAnomaly() throws {
        // See numerical example: http://www.csun.edu/~hcmth017/master/node16.html
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: 0.00001, meanAnomaly: 30, accuracy: 0.0001, maxIterations: 500)
        XCTAssertEqual(eccentricAnomaly.round(to: 5), 30.00029)
    }
    
    func testCalculateTrueAnomaly() throws {
        let eccentricity = 0.5
        let trueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: eccentricity, eccentricAnomaly: 30.000)
        XCTAssertEqual(trueAnomaly.round(to: 1), 90.0)
    }
    
    func testPhysicalConstantsWGS84Compliance() throws {
        // Verify Earth's gravitational constant (µ = GM) matches WGS84 standard
        // WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
        let expectedMu = 398600.4418 // km^3/s^2
        XCTAssertEqual(PhysicalConstants.Earth.µ, expectedMu, accuracy: 0.0001, "Earth's gravitational constant should match WGS84 standard")
        
        // Verify Earth's radius matches WGS84 standard
        // WGS84 equatorial radius: 6378.137 km
        let expectedRadius = 6378.137 // km
        XCTAssertEqual(PhysicalConstants.Earth.radius, expectedRadius, accuracy: 0.001, "Earth's radius should match WGS84 standard")
        
        // Verify seconds per day is correct
        let expectedSecondsPerDay = 86400.0
        XCTAssertEqual(PhysicalConstants.Time.secondsPerDay, expectedSecondsPerDay, "Seconds per day should be 86400")
    }
    
    func testOrbitConformsToOrbitable() throws {
        // Create an orbit from a TLE
        let tle = try TwoLineElement(from: MockTLEs.iss)
        let orbit = Orbit(from: tle)
        
        // Verify the orbit can be used as an Orbitable
        let orbitable: Orbitable = orbit
        
        // Verify protocol properties are accessible
        XCTAssertGreaterThan(orbitable.semimajorAxis, 0)
        XCTAssertGreaterThanOrEqual(orbitable.eccentricity, 0)
        XCTAssertLessThan(orbitable.eccentricity, 1)
        XCTAssertGreaterThanOrEqual(orbitable.inclination, 0)
        XCTAssertLessThanOrEqual(orbitable.inclination, 180)
        XCTAssertGreaterThanOrEqual(orbitable.rightAscensionOfAscendingNode, 0)
        XCTAssertLessThan(orbitable.rightAscensionOfAscendingNode, 360)
        XCTAssertGreaterThanOrEqual(orbitable.argumentOfPerigee, 0)
        XCTAssertLessThan(orbitable.argumentOfPerigee, 360)
        XCTAssertGreaterThanOrEqual(orbitable.meanAnomaly, 0)
        XCTAssertLessThan(orbitable.meanAnomaly, 360)
        XCTAssertGreaterThan(orbitable.meanMotion, 0)
        
        // Most importantly, verify trueAnomaly is non-optional and accessible
        let trueAnomaly = orbitable.trueAnomaly
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0)
        XCTAssertLessThan(trueAnomaly, 360)
    }
    
    func testTrueAnomalyAlwaysReturnsValue() throws {
        // Create orbit from TLE
        let tle = try TwoLineElement(from: MockTLEs.iss)
        let orbit = Orbit(from: tle)
        
        // Verify trueAnomaly always returns a value (non-optional)
        let trueAnomaly = orbit.trueAnomaly
        
        // Verify it's a reasonable value
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0, "True anomaly should be >= 0 degrees")
        XCTAssertLessThan(trueAnomaly, 360, "True anomaly should be < 360 degrees")
    }
    
    func testTrueAnomalyCalculationFromMean() throws {
        // Test with different orbital scenarios
        
        // Scenario 1: Low eccentricity orbit (circular-ish like ISS)
        let tle1 = try TwoLineElement(from: MockTLEs.iss)
        let orbit1 = Orbit(from: tle1)
        let trueAnomaly1 = orbit1.trueAnomaly
        
        // For low eccentricity, true anomaly should be close to mean anomaly
        let difference1 = abs(trueAnomaly1 - orbit1.meanAnomaly)
        XCTAssertLessThan(difference1, 10, "For low eccentricity, true anomaly should be close to mean anomaly")
        
        // Scenario 2: Create a TLE with higher eccentricity (elliptical orbit)
        // Using GOES 16 which has very low eccentricity, but we'll test the calculation still works
        let tle2 = try TwoLineElement(from: MockTLEs.goes16)
        let orbit2 = Orbit(from: tle2)
        let trueAnomaly2 = orbit2.trueAnomaly
        
        // Verify calculation returns valid values
        XCTAssertGreaterThanOrEqual(trueAnomaly2, 0)
        XCTAssertLessThan(trueAnomaly2, 360)
    }
}

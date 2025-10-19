//
//  OrbitalElementsTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class OrbitalElementsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCalculateSemimajorAxis() throws {
        // GOES 16 Satellite
        // 42,164.9 km (26,200.0 mi)
        let knownSemimajorAxis = 42165.0 // km
        let meanMotion = 1.00271173 // Revolutions Per Day
        let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion).rounded() // Rounded to the nearest km
        XCTAssertEqual(semimajorAxis, knownSemimajorAxis)
    }
    
    func testCalculateEccentricAnomaly() throws {
        // Test with low eccentricity (nearly circular orbit)
        // See numerical example: http://www.csun.edu/~hcmth017/master/node16.html
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: 0.00001, meanAnomaly: 30, accuracy: 0.0001, maxIterations: 500)
        XCTAssertEqual(eccentricAnomaly.round(to: 5), 30.00029)
    }
    
    func testCalculateTrueAnomaly() throws {
        // Test true anomaly calculation with edge case values
        // For E=0 (at periapsis), true anomaly should be 0
        let eccentricity = 0.1
        let eccentricAnomalyAtPeriapsis: Degrees = 0.0
        let trueAnomalyAtPeriapsis = try Orbit.calculateTrueAnomaly(eccentricity: eccentricity, eccentricAnomaly: eccentricAnomalyAtPeriapsis)
        XCTAssertEqual(trueAnomalyAtPeriapsis, 0.0, accuracy: 0.001)
        
        // Test that function returns valid angles (0-360°)
        let eccentricAnomaly: Degrees = 45.0
        let trueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: eccentricity, eccentricAnomaly: eccentricAnomaly)
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0.0)
        XCTAssertLessThanOrEqual(trueAnomaly, 360.0)
    }
    
    func testOrbitInitializationFromTLE() throws {
        // Test that an Orbit can be created from a TLE
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        
        // Verify basic orbital elements are set
        XCTAssertGreaterThan(orbit.semimajorAxis, 0)
        XCTAssertGreaterThanOrEqual(orbit.eccentricity, 0)
        XCTAssertLessThanOrEqual(orbit.eccentricity, 1)
        XCTAssertGreaterThanOrEqual(orbit.inclination, 0)
        XCTAssertLessThanOrEqual(orbit.inclination, 180)
    }
}

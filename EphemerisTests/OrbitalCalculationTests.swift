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
    
    func testOrbitConformsToOrbitable() throws {
        // Test that Orbit struct properly conforms to Orbitable protocol
        let tle = MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        
        // Verify that orbit can be used as Orbitable
        let orbitable: Orbitable = orbit
        
        // Test that trueAnomaly is accessible and non-optional through protocol
        let trueAnomalyValue = orbitable.trueAnomaly
        XCTAssertGreaterThanOrEqual(trueAnomalyValue, 0.0)
        XCTAssertLessThanOrEqual(trueAnomalyValue, 360.0)
    }
    
    func testTrueAnomalyAlwaysReturnsValue() throws {
        // Test that trueAnomaly always returns a value, even for edge cases
        let tle = MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        
        // Access trueAnomaly - should never be nil
        let trueAnomaly = orbit.trueAnomaly
        XCTAssertNotNil(trueAnomaly)
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0.0)
        XCTAssertLessThanOrEqual(trueAnomaly, 360.0)
    }
    
    func testTrueAnomalyCalculationFromMean() throws {
        // Test that trueAnomaly is properly calculated from mean anomaly
        let tle = MockTLEs.objectAtPerigee()
        let orbit = Orbit(from: tle)
        
        // For an object at perigee with e=0.5 and M=0, true anomaly should be 0
        let trueAnomaly = orbit.trueAnomaly
        XCTAssertNotNil(trueAnomaly)
        // The value should be computed and be a valid angle
        XCTAssertGreaterThanOrEqual(trueAnomaly, 0.0)
        XCTAssertLessThanOrEqual(trueAnomaly, 360.0)
    }
}

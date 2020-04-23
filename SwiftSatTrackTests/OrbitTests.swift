//
//  OrbitTests.swift
//  SwiftSatTrackTests
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import SwiftSatTrack

class OrbitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testEpochTimeDifference() {
        let tleString =
            """
            ISS (ZARYA)
            1 25544U 98067A   70001.00000000  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = TwoLineElement(from: tleString)
        let orbit = Orbit(title: tle.name, rightAscension: tle.rightAscension, eccentricity: tle.eccentricity, argumentPeriapsis: tle.argumentOfPerigee, meanAnomaly: tle.meanAnomaly, meanMotion: tle.meanMotion, epochDate: tle.epochDate)
        let now = Date(timeInterval: (60 * 60 * 24) * 5, since: tle.epochDate)
        let epochDiff = orbit.epochTimeDifference(from: now)
        XCTAssertEqual(epochDiff, 5 * (24 * 60 * 60)) // 5 Days difference
    }
    
    func testRadiansToDegrees() throws {
        let degrees: Degree = 45.0000000001
        let radians: Radian = 0.7853981634
        
        XCTAssertEqual(Orbit.radianToDegree(radians).round(to: 10), degrees)
    }
    
    func testDegreesToRadians() throws {
        let degrees: Degree = 45.0000000001
        let radians: Radian = 0.7853981634
        
        XCTAssertEqual(Orbit.degreeToRadian(degrees).round(to: 10), radians)
    }
    
    func testMotionRadiansPerSecond() throws {
        let orbit = Orbit(title: "ISS", rightAscension: 341.58069999999998, eccentricity: 0.000388, argumentPeriapsis: 94.422300000000007, meanAnomaly: 26.119700000000002, meanMotion: 15.486858359999999, epochDate: Date())
        let motionRadsPerSec = orbit.motionRadiansPerSecond()
        XCTAssertEqual(motionRadsPerSec, 0.0011262361215500386)
    }
}

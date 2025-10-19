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
        // 42,164.8 km (26,200.0 mi)
        let knownSemimajorAxis = 42165.0 // km
        let meanMotion = 1.00271173 // Revolutions Per Day
        let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion).rounded(.towardZero)
        XCTAssertEqual(semimajorAxis, knownSemimajorAxis)
    }
    
    func testCalculateEccentricAnomaly() throws {
        
    }
    
    func testCalculateTrueAnomaly() throws {
        
    }
}

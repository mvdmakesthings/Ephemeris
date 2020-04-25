//
//  TwoLineElementTests.swift
//  SwiftSatTrackTests
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import SwiftSatTrack

class TwoLineElementTests: XCTestCase {
    
    override func setUpWithError() throws {
    
    }

    override func tearDownWithError() throws {
    
    }

    func testTLEParses() {
        let ISSTLE = MockTLEs.ISSSample()
        // Line 0
        XCTAssertEqual(ISSTLE.name, "ISS (ZARYA)")
        
        // Line 1
        XCTAssertEqual(ISSTLE.catalogNumber, 25544)
        XCTAssertEqual(ISSTLE.internationalDesignator, "98067A")
        XCTAssertEqual(ISSTLE.epochYear, 2020)
        XCTAssertEqual(ISSTLE.epochDay, 97.82871450)
        XCTAssertEqual(ISSTLE.elementSetEpochUTC, "20097.82871450")
        
        // Line 2
        XCTAssertEqual(ISSTLE.inclination, 51.6465)
        XCTAssertEqual(ISSTLE.rightAscension, 341.5807)
        XCTAssertEqual(ISSTLE.eccentricity, 0.0003880)
        XCTAssertEqual(ISSTLE.meanAnomaly, 26.1197)
        XCTAssertEqual(ISSTLE.meanMotion, 15.48685836)
        XCTAssertEqual(ISSTLE.revolutionsAtEpoch, 22095)
    }
}

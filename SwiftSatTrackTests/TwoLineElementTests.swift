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
    private var tleString: String = ""
    override func setUpWithError() throws {
        tleString =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
    }

    override func tearDownWithError() throws {
        tleString = ""
    }

    func testTLEParses() {
        let tle = TwoLineElement(from: tleString)
        // Line 0
        XCTAssertEqual(tle.name, "ISS (ZARYA)")
        
        // Line 1
        XCTAssertEqual(tle.catalogNumber, 25544)
        XCTAssertEqual(tle.internationalDesignator, "98067A")
        XCTAssertEqual(tle.elementSetEpochUTC, "20097.82871450")
        
        // Line 2
        XCTAssertEqual(tle.inclination, 51.6465)
        XCTAssertEqual(tle.rightAscension, 341.5807)
        XCTAssertEqual(tle.eccentricity, 0003880)
        XCTAssertEqual(tle.meanAnomaly, 26.1197)
        XCTAssertEqual(tle.meanMotionRevsPerDay, 15.48685836)
        XCTAssertEqual(tle.revolutionsAtEpoch, 22095)
    }

}

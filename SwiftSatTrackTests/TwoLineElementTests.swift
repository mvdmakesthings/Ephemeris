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
        XCTAssertEqual(tle.epochYear, 2020)
        XCTAssertEqual(tle.epochDay, 97.82871450)
//        XCTAssertEqual(tle.elementSetEpochUTC, "20097.82871450")
        
        // Line 2
        XCTAssertEqual(tle.inclination, 51.6465)
        XCTAssertEqual(tle.rightAscension, 341.5807)
        XCTAssertEqual(tle.eccentricity, 0.0003880)
        XCTAssertEqual(tle.meanAnomaly, 26.1197)
        XCTAssertEqual(tle.meanMotion, 15.48685836)
        XCTAssertEqual(tle.revolutionsAtEpoch, 22095)
    }
    
    func testEpochToJulianDate() {
        let tleString =
            """
            ISS (ZARYA)
            1 25544U 98067A   70001.00000000  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = TwoLineElement(from: tleString)
        let jd = tle.epochAsJulianDate()
        XCTAssertEqual(jd, 2440587.5) // Jan 1, 1970
    }
    
    func testEccestricAnomoly() {
        let tle = TwoLineElement(from: tleString)
        let orbit = Orbit(title: tle.name, rightAscension: tle.rightAscension, eccentricity: tle.eccentricity, argumentPeriapsis: tle.argumentOfPerigee, meanAnomaly: tle.meanAnomaly, meanMotion: tle.meanMotion, epochDate: tle.epochDate)
        XCTAssertEqual(orbit.eccentricAnomaly().round(to: 10), 26.1294904575)
    }
}

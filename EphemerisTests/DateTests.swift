//
//  DateTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 11/26/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class DateTests: XCTestCase {
    
    func testJulianDayFromDate() throws {
        let date = Date(timeIntervalSince1970: 0) // The beginning of time. lol
        // Known JulianDay from above date
        let knownJulianDay = 2440587.5
        
        let julianDay = Date.julianDay(from: date)
        XCTAssertEqual(julianDay, knownJulianDay)
    }
    
    func testHMSToUT() throws {
        let ut = Date.hmsToUT(hour: 2, minute: 39, second: Int(57.29))
        XCTAssertEqual(ut, 239.57)
    }
    
    func testGreenwichSiderealTime() throws {
        let jd = 2440587.5 // Jan 1, 1970
        let knownGSTrads = 1.7493372337513193
        let gst = Date.greenwichSideRealTime(from: jd)
        XCTAssertEqual(gst, knownGSTrads)
    }
}

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
    
    // MARK: - Julian Day Conversion Tests
    
    func testJulianDayFromDate() throws {
        let date = Date(timeIntervalSince1970: 0) // Jan 1, 1970 00:00:00 UTC
        // Known JulianDay from above date
        let knownJulianDay = 2440587.5
        
        let julianDay = Date.julianDay(from: date)
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }
    
    func testJulianDayFromDateWithTime() throws {
        // Test with a specific time: Jan 1, 1970 12:00:00 UTC (noon)
        let date = Date(timeIntervalSince1970: 43200) // 12 hours = 43200 seconds
        // At noon, JD should be exactly 2440588.0 (since JD starts at noon)
        let knownJulianDay = 2440588.0
        
        let julianDay = Date.julianDay(from: date)
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }
    
    func testJulianDayFromEpoch() throws {
        // Test epoch conversion for year 2000, day 1.0 (Jan 1, 2000 at midnight)
        let epochYear = 2000
        let epochDayFraction = 1.0
        
        // Expected JD for Jan 1, 2000 00:00:00 UTC
        let knownJulianDay = 2451544.5
        
        let julianDay = Date.julianDayFromEpoch(epochYear: epochYear, epochDayFraction: epochDayFraction)
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }
    
    func testJulianDayFromEpochWithFraction() throws {
        // Test epoch conversion with fractional day
        // Year 2000, day 1.5 (Jan 1, 2000 at noon)
        let epochYear = 2000
        let epochDayFraction = 1.5
        
        // Expected JD for Jan 1, 2000 12:00:00 UTC
        let knownJulianDay = 2451545.0
        
        let julianDay = Date.julianDayFromEpoch(epochYear: epochYear, epochDayFraction: epochDayFraction)
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }
    
    // MARK: - Sidereal Time Tests
    
    func testGreenwichSiderealTime() throws {
        let jd = 2440587.5 // Jan 1, 1970 00:00:00 UTC
        let knownGSTrads = 1.7493372337513193
        let gst = Date.greenwichSideRealTime(from: jd)
        XCTAssertEqual(gst, knownGSTrads, accuracy: 0.000001)
    }
    
    func testGreenwichSiderealTimeJ2000() throws {
        let jd = 2451545.0 // Jan 1, 2000 12:00:00 TT (J2000.0 epoch)
        let gst = Date.greenwichSideRealTime(from: jd)
        // GST at J2000.0 epoch should be approximately 1.753368559 radians
        XCTAssertEqual(gst, 1.753368559, accuracy: 0.001)
    }
    
    // MARK: - J2000 Conversion Tests
    
    func testToJ2000() throws {
        // Test conversion at J2000.0 epoch
        let jd = 2451545.0
        let j2000 = Date.toJ2000(from: jd)
        XCTAssertEqual(j2000, 0.0, accuracy: 0.000001)
    }
    
    func testToJ2000OneHundredYears() throws {
        // Test conversion 100 years (1 century) after J2000.0
        let jd = 2451545.0 + 36525.0 // One Julian century
        let j2000 = Date.toJ2000(from: jd)
        XCTAssertEqual(j2000, 1.0, accuracy: 0.000001)
    }
    
    // MARK: - Edge Case Tests
    
    func testJulianDayHistoricalDate() throws {
        // Test a historical date: Oct 15, 1582 (Gregorian calendar adoption)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        var components = DateComponents()
        components.year = 1582
        components.month = 10
        components.day = 15
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }
        
        let julianDay = Date.julianDay(from: date)
        // Known JD for Oct 15, 1582 00:00:00 UTC
        let knownJulianDay = 2299160.5
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.5) // Allow small tolerance for historical dates
    }
    
    func testJulianDayFutureDate() throws {
        // Test a future date: Jan 1, 2100 00:00:00 UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        var components = DateComponents()
        components.year = 2100
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to create date")
            return
        }
        
        let julianDay = Date.julianDay(from: date)
        // Known JD for Jan 1, 2100 00:00:00 UTC
        let knownJulianDay = 2488069.5
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }
}

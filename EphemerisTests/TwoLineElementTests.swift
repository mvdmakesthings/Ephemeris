//
//  TwoLineElementTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class TwoLineElementTests: XCTestCase {
    
    override func setUpWithError() throws {
    
    }

    override func tearDownWithError() throws {
    
    }

    func testTLEParses() throws {
        let ISSTLE = try MockTLEs.ISSSample()
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
    
    // MARK: - Year Parsing Tests
    
    func testYearParsingCurrentCentury() throws {
        // Test year 2020 (parsed from "20")
        let tleString2020 =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle2020 = try TwoLineElement(from: tleString2020)
        XCTAssertEqual(tle2020.epochYear, 2020, "Year 20 should parse as 2020")
        
        // Test year 2000 (parsed from "00")
        let tleString2000 =
            """
            NOAA 16 [-]
            1 26536U 00055A   00116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """
        let tle2000 = try TwoLineElement(from: tleString2000)
        XCTAssertEqual(tle2000.epochYear, 2000, "Year 00 should parse as 2000")
    }
    
    func testYearParsingPreviousCentury() throws {
        // Test year 1999 (parsed from "99")
        // This should be interpreted as 1999 since it's within the ±50 year window
        let tleString1999 =
            """
            Historical Satellite
            1 26536U 99055A   99116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """
        let tle1999 = try TwoLineElement(from: tleString1999)
        XCTAssertEqual(tle1999.epochYear, 1999, "Year 99 should parse as 1999")
        
        // Test year 76-99 range (should parse as 1976-1999)
        let tleString1980 =
            """
            Satellite from 1980
            1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999
            2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000001
            """
        let tle1980 = try TwoLineElement(from: tleString1980)
        // Year 80 with current date context
        let currentYear = Calendar.current.component(.year, from: Date())
        let century = (currentYear / 100) * 100
        var expectedYear80 = century + 80
        if expectedYear80 > currentYear + 50 {
            expectedYear80 -= 100
        }
        XCTAssertEqual(tle1980.epochYear, expectedYear80, "Year 80 should parse correctly based on ±50 year window")
    }
    
    func testYearParsingBoundaryConditions() throws {
        // Test year 56 - should be in the 2000s
        let tleString56 =
            """
            Future Satellite
            1 99999U 56001A   56001.00000000  .00000000  00000-0  00000-0 0  9999
            2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001
            """
        let tle56 = try TwoLineElement(from: tleString56)
        // With current date context, 56 will be interpreted based on current year
        // In 2025, year 56 should be 2056 (within +50 years)
        let currentYear = Calendar.current.component(.year, from: Date())
        let century = (currentYear / 100) * 100
        var expectedYear = century + 56
        if expectedYear > currentYear + 50 {
            expectedYear -= 100
        }
        XCTAssertEqual(tle56.epochYear, expectedYear, "Year 56 should be parsed correctly based on current date")
    }
    
    func testYearParsingForRecentData() throws {
        // Test that recent years are parsed correctly
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastTwoDigits = currentYear % 100
        
        let tleString =
            """
            Recent Satellite
            1 99999U 24001A   \(String(format: "%02d", lastTwoDigits))001.00000000  .00000000  00000-0  00000-0 0  9999
            2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001
            """
        let tle = try TwoLineElement(from: tleString)
        XCTAssertEqual(tle.epochYear, currentYear, "Current year should be parsed correctly")
    }
    
    func testYearParsingNoLongerAssumes1957Cutoff() throws {
        // This test verifies that the old logic (year < 57 means 2000s, year >= 57 means 1900s)
        // is no longer used. Instead, we use current date context with ±50 year window.
        //
        // The new behavior for year 57:
        // - Before 2007: 57 would parse as 1957 (2057 is > current + 50, so subtract 100)
        // - From 2007-2106: 57 parses as 2057 (within ±50 year window of current)
        // - After 2106: 57 would parse as 2157 (2057 is < current - 50, so add 100)
        //
        // This means:
        // 1. The hard-coded 1957 cutoff is gone
        // 2. Year interpretation is dynamic based on current date
        // 3. In 2057 and beyond, year 57 correctly parses as 2057
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let century = (currentYear / 100) * 100
        var expectedYear57 = century + 57
        
        // Adjust based on ±50 year window
        if expectedYear57 > currentYear + 50 {
            expectedYear57 -= 100
        } else if expectedYear57 < currentYear - 50 {
            expectedYear57 += 100
        }
        
        let tleString57 =
            """
            Test Satellite
            1 00001U 57001A   57275.00000000  .00000000  00000-0  00000-0 0  9999
            2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000001
            """
        let tle57 = try TwoLineElement(from: tleString57)
        XCTAssertEqual(tle57.epochYear, expectedYear57,
                      "Year 57 should be parsed based on current date context, not fixed 1957 cutoff")
        
        // Verify that this fixes the Y2057 bug: in 2057+, year 57 should NOT parse as 1957
        // In the current year (2025), year 57 parses as 2057
        // In 2057, year 57 will parse as 2057
        // The bug is fixed!
        if currentYear >= 2007 && currentYear <= 2106 {
            XCTAssertEqual(expectedYear57, 2057,
                          "Between 2007-2106, year 57 should parse as 2057, fixing the Y2057 bug")
        }
    }
    
    func testTLEParsingThrowsOnInvalidString() {
        let invalidTLE = "Invalid TLE String"
        XCTAssertThrowsError(try TwoLineElement(from: invalidTLE)) { error in
            guard case TLEParsingError.missingLine(let expected, let actual) = error else {
                XCTFail("Expected TLEParsingError.missingLine but got \(error)")
                return
            }
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 1)
        }
    }
    
    func testTLEParsingThrowsOnMissingLines() {
        let tleWithTwoLines =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithTwoLines)) { error in
            guard case TLEParsingError.missingLine(let expected, let actual) = error else {
                XCTFail("Expected TLEParsingError.missingLine but got \(error)")
                return
            }
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 2)
        }
    }
    
    func testTLEParsingThrowsOnInvalidCatalogNumber() {
        let tleWithInvalidCatalogNumber =
            """
            ISS (ZARYA)
            1 ABCDEU 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidCatalogNumber)) { error in
            guard case TLEParsingError.invalidNumber(let field, _) = error else {
                XCTFail("Expected TLEParsingError.invalidNumber but got \(error)")
                return
            }
            XCTAssertEqual(field, "catalogNumber")
        }
    }
    
    func testTLEParsingThrowsOnInvalidInclination() {
        let tleWithInvalidInclination =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  INVALID 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidInclination)) { error in
            guard case TLEParsingError.invalidNumber(let field, _) = error else {
                XCTFail("Expected TLEParsingError.invalidNumber but got \(error)")
                return
            }
            XCTAssertEqual(field, "inclination")
        }
    }
    
    func testTLEParsingAcceptsShortLine0() throws {
        // Line 0 (satellite name) can be any length according to TLE spec
        let tleWithShortLine0 =
            """
            ISS
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleWithShortLine0)
        XCTAssertEqual(tle.name, "ISS")
    }
    
    func testTLEParsingThrowsOnShortLine1() {
        let tleWithShortLine1 =
            """
            ISS (ZARYA)
            1 25544U
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine1)) { error in
            guard case TLEParsingError.invalidFormat(let message) = error else {
                XCTFail("Expected TLEParsingError.invalidFormat but got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Line 1"))
        }
    }
    
    func testTLEParsingThrowsOnShortLine2() {
        let tleWithShortLine2 =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine2)) { error in
            guard case TLEParsingError.invalidFormat(let message) = error else {
                XCTFail("Expected TLEParsingError.invalidFormat but got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Line 2"))
        }
    }
}

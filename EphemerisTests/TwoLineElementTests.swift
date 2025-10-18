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
    
    // MARK: - Year Parsing Tests
    
    func testYearParsingCurrentCentury() {
        // Test year 2020 (parsed from "20")
        let tleString2020 =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle2020 = TwoLineElement(from: tleString2020)
        XCTAssertEqual(tle2020.epochYear, 2020, "Year 20 should parse as 2020")
        
        // Test year 2000 (parsed from "00")
        let tleString2000 =
            """
            NOAA 16 [-]
            1 26536U 00055A   00116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """
        let tle2000 = TwoLineElement(from: tleString2000)
        XCTAssertEqual(tle2000.epochYear, 2000, "Year 00 should parse as 2000")
    }
    
    func testYearParsingPreviousCentury() {
        // Test year 1999 (parsed from "99")
        // This should be interpreted as 1999 since it's within the ±50 year window
        let tleString1999 =
            """
            Historical Satellite
            1 26536U 99055A   99116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """
        let tle1999 = TwoLineElement(from: tleString1999)
        XCTAssertEqual(tle1999.epochYear, 1999, "Year 99 should parse as 1999")
        
        // Test year 1957 (Sputnik 1 - first satellite) (parsed from "57")
        let tleString1957 =
            """
            Sputnik 1
            1 00001U 57001A   57275.00000000  .00000000  00000-0  00000-0 0  9999
            2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000001
            """
        let tle1957 = TwoLineElement(from: tleString1957)
        XCTAssertEqual(tle1957.epochYear, 1957, "Year 57 should parse as 1957 (Sputnik 1)")
    }
    
    func testYearParsingBoundaryConditions() {
        // Test year 56 - should be in the 2000s
        let tleString56 =
            """
            Future Satellite
            1 99999U 56001A   56001.00000000  .00000000  00000-0  00000-0 0  9999
            2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001
            """
        let tle56 = TwoLineElement(from: tleString56)
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
    
    func testYearParsingForRecentData() {
        // Test that recent years are parsed correctly
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastTwoDigits = currentYear % 100
        
        let tleString =
            """
            Recent Satellite
            1 99999U 24001A   \(String(format: "%02d", lastTwoDigits))001.00000000  .00000000  00000-0  00000-0 0  9999
            2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001
            """
        let tle = TwoLineElement(from: tleString)
        XCTAssertEqual(tle.epochYear, currentYear, "Current year should be parsed correctly")
    }
    
    func testYearParsingNoLongerAssumes1957Cutoff() {
        // This test verifies that the old logic (year < 57 means 2000s, year >= 57 means 1900s)
        // is no longer used. Instead, we use current date context.
        // For example, in 2060, year "57" should parse as 2057, not 1957.
        
        // With the new logic, year 57 will be:
        // - In 2025: 1957 (current century + 57 = 2057, which is > 2025 + 50, so subtract 100)
        // - In 2057: 2057 (current century + 57 = 2057, which is exactly current year)
        // - In 2060: 2057 (current century + 57 = 2057, which is within current year - 50)
        
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
        let tle57 = TwoLineElement(from: tleString57)
        XCTAssertEqual(tle57.epochYear, expectedYear57,
                      "Year 57 should be parsed based on current date context, not fixed 1957 cutoff")
    }
}

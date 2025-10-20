//
//  TwoLineElementTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
import Spectre
@testable import Ephemeris

let twoLineElementTests: ((ContextType) -> Void) = {
    $0.describe("Two Line Element") {
        
        $0.it("parses TLE correctly") {
            let ISSTLE = try MockTLEs.ISSSample()
            // Line 0
            try expect(ISSTLE.name == "ISS (ZARYA)")
            
            // Line 1
            try expect(ISSTLE.catalogNumber == 25544)
            try expect(ISSTLE.internationalDesignator == "98067A")
            try expect(ISSTLE.epochYear == 2020)
            try expect(ISSTLE.epochDay == 97.82871450)
            try expect(ISSTLE.elementSetEpochUTC == "20097.82871450")
            
            // Line 2
            try expect(ISSTLE.inclination == 51.6465)
            try expect(ISSTLE.rightAscension == 341.5807)
            try expect(ISSTLE.eccentricity == 0.0003880)
            try expect(ISSTLE.meanAnomaly == 26.1197)
            try expect(ISSTLE.meanMotion == 15.48685836)
            try expect(ISSTLE.revolutionsAtEpoch == 22095)
        }
        
        // MARK: - Year Parsing Tests
        
        $0.context("year parsing") {
            $0.it("parses current century years correctly") {
                // Test year 2020 (parsed from "20")
                let tleString2020 =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                    """
                let tle2020 = try TwoLineElement(from: tleString2020)
                try expect(tle2020.epochYear == 2020)
                
                // Test year 2000 (parsed from "00")
                let tleString2000 =
                    """
                    NOAA 16 [-]
                    1 26536U 00055A   00116.52380576 -.00000007  00000-0  19116-4 0  9998
                    2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
                    """
                let tle2000 = try TwoLineElement(from: tleString2000)
                try expect(tle2000.epochYear == 2000)
            }
            
            $0.it("parses previous century years correctly") {
                // Test year 1999 (parsed from "99")
                // This should be interpreted as 1999 since it's within the ±50 year window
                let tleString1999 =
                    """
                    Historical Satellite
                    1 26536U 99055A   99116.52380576 -.00000007  00000-0  19116-4 0  9998
                    2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
                    """
                let tle1999 = try TwoLineElement(from: tleString1999)
                try expect(tle1999.epochYear == 1999)
                
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
                try expect(tle1980.epochYear == expectedYear80)
            }
            
            $0.it("parses boundary condition years correctly") {
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
                try expect(tle56.epochYear == expectedYear)
            }
            
            $0.it("parses recent years correctly") {
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
                try expect(tle.epochYear == currentYear)
            }
            
            $0.it("no longer assumes 1957 cutoff") {
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
                try expect(tle57.epochYear == expectedYear57)
                
                // Verify that this fixes the Y2057 bug: in 2057+, year 57 should NOT parse as 1957
                // In the current year (2025), year 57 parses as 2057
                // In 2057, year 57 will parse as 2057
                // The bug is fixed!
                if currentYear >= 2007 && currentYear <= 2106 {
                    try expect(expectedYear57 == 2057)
                }
            }
        }
        
        // MARK: - Error Handling Tests
        
        $0.context("error handling") {
            $0.it("throws on invalid TLE string") {
                let invalidTLE = "Invalid TLE String"
                do {
                    _ = try TwoLineElement(from: invalidTLE)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .missingLine(let expected, let actual) = error {
                        try expect(expected == 3)
                        try expect(actual == 1)
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
            
            $0.it("throws on missing lines") {
                let tleWithTwoLines =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    """
                do {
                    _ = try TwoLineElement(from: tleWithTwoLines)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .missingLine(let expected, let actual) = error {
                        try expect(expected == 3)
                        try expect(actual == 2)
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
            
            $0.it("throws on invalid catalog number") {
                let tleWithInvalidCatalogNumber =
                    """
                    ISS (ZARYA)
                    1 ABCDEU 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                    """
                do {
                    _ = try TwoLineElement(from: tleWithInvalidCatalogNumber)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .invalidNumber(let field, _) = error {
                        try expect(field == "catalogNumber")
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
            
            $0.it("throws on invalid inclination") {
                let tleWithInvalidInclination =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    2 25544  INVALID 341.5807 0003880  94.4223  26.1197 15.48685836220958
                    """
                do {
                    _ = try TwoLineElement(from: tleWithInvalidInclination)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .invalidNumber(let field, _) = error {
                        try expect(field == "inclination")
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
            
            $0.it("accepts short line 0") {
                // Line 0 (satellite name) can be any length according to TLE spec
                let tleWithShortLine0 =
                    """
                    ISS
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                    """
                let tle = try TwoLineElement(from: tleWithShortLine0)
                try expect(tle.name == "ISS")
            }
            
            $0.it("throws on short line 1") {
                let tleWithShortLine1 =
                    """
                    ISS (ZARYA)
                    1 25544U
                    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                    """
                do {
                    _ = try TwoLineElement(from: tleWithShortLine1)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .invalidFormat(let message) = error {
                        try expect(message.contains("Line 1"))
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
            
            $0.it("throws on short line 2") {
                let tleWithShortLine2 =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    2 25544
                    """
                do {
                    _ = try TwoLineElement(from: tleWithShortLine2)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .invalidFormat(let message) = error {
                        try expect(message.contains("Line 2"))
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
        }
    }
}


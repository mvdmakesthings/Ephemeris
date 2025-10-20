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
    // MARK: - Helper Methods
    
    /// Calculate TLE checksum for a line (modulo-10)
    func calculateChecksum(for line: String) -> Int {
        var sum = 0
        let maxIndex = min(68, line.count)
        for i in 0..<maxIndex {
            let index = line.index(line.startIndex, offsetBy: i)
            let char = line[index]
            if char.isNumber {
                sum += Int(String(char)) ?? 0
            } else if char == "-" {
                sum += 1
            }
        }
        return sum % 10
    }
    
    /// Fix the checksum of a TLE line by calculating and replacing the last digit
    func fixChecksum(for line: String) -> String {
        guard line.count >= 69 else { return line }
        let checksum = calculateChecksum(for: line)
        let prefix = String(line.prefix(68))
        return prefix + String(checksum)
    }
    
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
                    1 26536U 00055A   00116.52380576 -.00000007  00000-0  19116-4 0  9996
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
                    1 26536U 99055A   99116.52380576 -.00000007  00000-0  19116-4 0  9992
                    2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
                    """
                let tle1999 = try TwoLineElement(from: tleString1999)
                try expect(tle1999.epochYear == 1999)
                
                // Test year 76-99 range (should parse as 1976-1999)
                let tleString1980 =
                    """
                    Satellite from 1980
                    1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999
                    2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005
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
                let line1 = "1 99999U 56001A   56001.00000000  .00000000  00000-0  00000-0 0  9999"
                let line2 = "2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001"
                let tleString56 =
                    """
                    Future Satellite
                    \(fixChecksum(for: line1))
                    \(fixChecksum(for: line2))
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
                
                let line1 = "1 99999U 24001A   \(String(format: "%02d", lastTwoDigits))001.00000000  .00000000  00000-0  00000-0 0  9999"
                let line2 = "2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001"
                let tleString =
                    """
                    Recent Satellite
                    \(fixChecksum(for: line1))
                    \(fixChecksum(for: line2))
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(tle.epochYear == currentYear)
            }
            
            $0.it("no longer assumes 1957 cutoff") {
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
                    1 00001U 57001A   57275.00000000  .00000000  00000-0  00000-0 0  9990
                    2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005
                    """
                let tle57 = try TwoLineElement(from: tleString57)
                try expect(tle57.epochYear == expectedYear57)
                
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
                let line2 = "2 25544  INVALID 341.5807 0003880  94.4223  26.1197 15.48685836220958"
                let tleWithInvalidInclination =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    \(fixChecksum(for: line2))
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
        
        // MARK: - Checksum Validation Tests
        
        $0.context("checksum validation") {
            $0.it("validates correct checksums") {
                // The ISS sample has valid checksums
                let tle = try MockTLEs.ISSSample()
                try expect(tle.catalogNumber == 25544)
            }
            
            $0.it("throws on invalid line 1 checksum") {
                // Line 1 with incorrect checksum (last digit changed from 2 to 0)
                let tleWithInvalidChecksum =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9990
                    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                    """
                do {
                    _ = try TwoLineElement(from: tleWithInvalidChecksum)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .invalidChecksum(let line, let expected, let actual) = error {
                        try expect(line == 1)
                        try expect(expected == 0)
                        try expect(actual == 2)
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
            
            $0.it("throws on invalid line 2 checksum") {
                // Line 2 with incorrect checksum (last digit changed from 8 to 0)
                let tleWithInvalidChecksum =
                    """
                    ISS (ZARYA)
                    1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                    2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220950
                    """
                do {
                    _ = try TwoLineElement(from: tleWithInvalidChecksum)
                    throw failure("Should have thrown error")
                } catch let error as TLEParsingError {
                    if case .invalidChecksum(let line, let expected, let actual) = error {
                        try expect(line == 2)
                        try expect(expected == 0)
                        try expect(actual == 8)
                    } else {
                        throw failure("Wrong error type")
                    }
                }
            }
        }
        
        // MARK: - Scientific Notation Parsing Tests
        
        $0.context("scientific notation parsing") {
            $0.it("parses BSTAR drag term") {
                // Test parsing BSTAR drag term in scientific notation
                // Format: 12345-3 means 0.12345 × 10⁻³ = 0.00012345
                let tle = try MockTLEs.ISSSample()
                try expect(abs(tle.bstarDragTerm - 0.000024271) < 1e-9)
            }
            
            $0.it("parses BSTAR with positive exponent") {
                // Test BSTAR with positive exponent: 12345+2 means 0.12345 × 10² = 12.345
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  12345+2 0  9998"
                let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
                let tleString =
                    """
                    Test Satellite
                    \(fixChecksum(for: line1))
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.bstarDragTerm - 12.345) < 1e-9)
            }
            
            $0.it("parses BSTAR with zero value") {
                // Test BSTAR with zero value: 00000-0 or 00000+0
                let line1 = "1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999"
                let line2 = "2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005"
                let tleString =
                    """
                    Test Satellite
                    \(line1)
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.bstarDragTerm - 0.0) < 1e-12)
            }
            
            $0.it("parses mean motion second derivative") {
                // Test parsing second derivative in scientific notation
                let tle = try MockTLEs.ISSSample()
                try expect(abs(tle.meanMotionSecondDerivative - 0.0) < 1e-12)
            }
            
            $0.it("parses non-zero mean motion second derivative") {
                // Test second derivative with non-zero value: 12345-5 means 0.12345 × 10⁻⁵
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  12345-5  24271-4 0  9999"
                let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
                let tleString =
                    """
                    Test Satellite
                    \(fixChecksum(for: line1))
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.meanMotionSecondDerivative - 0.0000012345) < 1e-12)
            }
        }
        
        // MARK: - Negative Value Handling Tests
        
        $0.context("negative value handling") {
            $0.it("parses negative first derivative") {
                // Test negative first derivative (orbital decay)
                let tle = try MockTLEs.NOAASample()
                try expect(abs(tle.meanMotionFirstDerivative - (-0.00000007)) < 1e-12)
            }
            
            $0.it("parses positive first derivative") {
                // Test positive first derivative
                let tle = try MockTLEs.ISSSample()
                try expect(abs(tle.meanMotionFirstDerivative - 0.00000874) < 1e-12)
            }
            
            $0.it("parses negative second derivative") {
                // Test negative second derivative: -12345-5
                let line1 = "1 25544U 98067A   20097.82871450  .00000874 -12345-5  24271-4 0  9993"
                let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
                let tleString =
                    """
                    Test Satellite
                    \(fixChecksum(for: line1))
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.meanMotionSecondDerivative - (-0.0000012345)) < 1e-12)
            }
            
            $0.it("parses negative BSTAR drag term") {
                // Test negative BSTAR drag term: -12345-3
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0 -12345-3 0  9997"
                let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
                let tleString =
                    """
                    Test Satellite
                    \(fixChecksum(for: line1))
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.bstarDragTerm - (-0.00012345)) < 1e-12)
            }
        }
        
        // MARK: - Eccentricity Validation Tests
        
        $0.context("eccentricity validation") {
            $0.it("validates normal eccentricity values") {
                // Test valid eccentricity (less than 1.0)
                let tle = try MockTLEs.ISSSample()
                try expect(tle.eccentricity < 1.0)
                try expect(abs(tle.eccentricity - 0.0003880) < 1e-7)
            }
            
            $0.it("validates high eccentricity values") {
                // Test high but valid eccentricity (e.g., 0.9 for highly elliptical orbit)
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
                let line2 = "2 25544  51.6465 341.5807 9000000  94.4223  26.1197 15.48685836220959"
                let tleString =
                    """
                    Test Satellite
                    \(line1)
                    \(fixChecksum(for: line2))
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.eccentricity - 0.9000000) < 1e-7)
                try expect(tle.eccentricity < 1.0)
            }
            
            $0.it("validates maximum eccentricity values") {
                // Test that eccentricity >= 1.0 is handled
                // 9999999 would be parsed as 0.9999999
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
                let line2 = "2 25544  51.6465 341.5807 9999999  94.4223  26.1197 15.48685836220950"
                let tleString =
                    """
                    Test Satellite
                    \(line1)
                    \(fixChecksum(for: line2))
                    """
                
                // This should succeed as 0.9999999 < 1.0
                let tle = try? TwoLineElement(from: tleString)
                try expect(tle != nil)
                try expect(tle!.eccentricity < 1.0)
            }
        }
        
        // MARK: - Fixed-Width Format Edge Cases
        
        $0.context("fixed-width format edge cases") {
            $0.it("parses fields with leading spaces") {
                // Test that fields with leading spaces are parsed correctly
                let line1 = "1  5544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9999"
                let line2 = "2  5544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220959"
                let tleString =
                    """
                    Test Satellite
                    \(fixChecksum(for: line1))
                    \(fixChecksum(for: line2))
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(tle.catalogNumber == 5544)
            }
            
            $0.it("parses fields with trailing spaces") {
                // TLE format is fixed-width, so trailing spaces should be trimmed
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992  "
                let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958  "
                let tleString =
                    """
                    Test Satellite
                    \(line1)
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(tle.catalogNumber == 25544)
            }
            
            $0.it("parses small catalog numbers") {
                // Test parsing with single-digit catalog number
                let line1 = "1 00001U 57001A   57275.00000000  .00000000  00000-0  00000-0 0  9990"
                let line2 = "2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005"
                let tleString =
                    """
                    Sputnik 1
                    \(line1)
                    \(line2)
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(tle.catalogNumber == 1)
            }
            
            $0.it("parses zero eccentricity") {
                // Test parsing of circular orbit (eccentricity = 0)
                let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
                let line2 = "2 25544  51.6465 341.5807 0000000  94.4223  26.1197 15.48685836220954"
                let tleString =
                    """
                    Test Satellite
                    \(line1)
                    \(fixChecksum(for: line2))
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(abs(tle.eccentricity - 0.0) < 1e-12)
            }
            
            $0.it("parses fields with all zeros") {
                // Test parsing TLE with many zero fields
                let line1 = "1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999"
                let line2 = "2 00001  00.0000 000.0000 0000000 000.0000 000.0000 15.00000000000000"
                let tleString =
                    """
                    Test Zero Fields
                    \(line1)
                    \(fixChecksum(for: line2))
                    """
                let tle = try TwoLineElement(from: tleString)
                try expect(tle.catalogNumber == 1)
                try expect(tle.inclination == 0.0)
                try expect(tle.rightAscension == 0.0)
                try expect(tle.eccentricity == 0.0)
                try expect(tle.argumentOfPerigee == 0.0)
                try expect(tle.meanAnomaly == 0.0)
                try expect(tle.bstarDragTerm == 0.0)
                try expect(tle.meanMotionSecondDerivative == 0.0)
            }
        }
    }
}

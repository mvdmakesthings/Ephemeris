//
//  TwoLineElement.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Errors that can occur during TLE parsing.
///
/// These errors provide detailed information about what went wrong when
/// parsing a Two-Line Element string, including field names and expected values.
public enum TLEParsingError: Error, LocalizedError {
    /// The TLE format is invalid or malformed
    case invalidFormat(String)
    /// A field contains an invalid number
    case invalidNumber(field: String, value: String)
    /// The TLE has the wrong number of lines (expected 3)
    case missingLine(expected: Int, actual: Int)
    /// String subscripting attempted with invalid range
    case invalidStringRange(field: String, range: String)
    /// Line checksum validation failed
    case invalidChecksum(line: Int, expected: Int, actual: Int)
    /// Eccentricity value is out of valid range (must be < 1.0)
    case invalidEccentricity(value: Double)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return "Invalid TLE format: \(message)"
        case .invalidNumber(let field, let value):
            return "Invalid number in field '\(field)': '\(value)' is not a valid number"
        case .missingLine(let expected, let actual):
            return "Invalid TLE: expected \(expected) lines but got \(actual)"
        case .invalidStringRange(let field, let range):
            return "Invalid string range for field '\(field)': \(range)"
        case .invalidChecksum(let line, let expected, let actual):
            return "Invalid checksum for line \(line): expected \(expected) but got \(actual)"
        case .invalidEccentricity(let value):
            return "Invalid eccentricity: \(value) must be less than 1.0"
        }
    }
}

/// Represents a Two-Line Element (TLE) set for an Earth-orbiting satellite.
///
/// The Two-Line Element format is a standard data format encoding orbital elements
/// of an Earth-orbiting object for a given point in time (the epoch). TLE data is
/// published by NORAD and is used worldwide for satellite tracking.
///
/// ## TLE Format
/// A TLE consists of three lines:
/// - **Line 0**: Satellite name (common name from catalog)
/// - **Line 1**: Catalog number, epoch, ballistic coefficient, drag terms
/// - **Line 2**: Orbital elements (inclination, RAAN, eccentricity, argument of perigee, mean anomaly, mean motion)
///
/// ## Example TLE
/// ```
/// ISS (ZARYA)
/// 1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
/// 2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
/// ```
///
/// ## Usage
/// ```swift
/// let tleString = """
/// ISS (ZARYA)
/// 1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
/// 2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
/// """
/// let tle = try TwoLineElement(from: tleString)
/// print("Satellite: \(tle.name)")
/// print("Inclination: \(tle.inclination)°")
/// ```
///
/// ## Where to Get TLE Data
/// - [CelesTrak](https://celestrak.com/NORAD/elements/)
/// - [Space-Track.org](https://www.space-track.org/) (requires registration)
///
/// - Note: Reference: https://en.wikipedia.org/wiki/Two-line_element_set
public struct TwoLineElement {
    // MARK: - Line 0
    /// Object's common name based on information from the satellite catalog.
    public var name: String
    
    // MARK: - Line 1
    /// Satellite catalog number
    var catalogNumber: Int
    /// International Designator
    var internationalDesignator: String
    /// Element Set Epoch (UTC)
    /// - Note: Spaces are acceptable in columns 21 & 22
    var elementSetEpochUTC: String
    
    /// Epoch Year (YYYY)
    var epochYear: Int
    
    /// Epoch Day as Julian Day fraction
    var epochDay: Double
    
    /// First derivative of mean motion (revolutions/day²)
    var meanMotionFirstDerivative: Double
    
    /// Second derivative of mean motion (revolutions/day³)
    var meanMotionSecondDerivative: Double
    
    /// BSTAR drag term (1/earth radii)
    var bstarDragTerm: Double
    
    // MARK: - Line 2
    /// Orbit Inclination ( i )
    var inclination: Degrees
    /// Right Ascension of Ascending Node ( Ω )
    var rightAscension: Degrees
    /// Eccentricity ( e )
    var eccentricity: Double
    /// Argument of Perigee (degrees)
    var argumentOfPerigee: Degrees
    /// Mean Anomaly (degrees)
    var meanAnomaly: Degrees
    /// Mean Motion (revolutions/day), the number of orbits the object completes in a total day.
    var meanMotion: Double
    /// Revolution Number at Epoch
    var revolutionsAtEpoch: Int
    
    /// Creates a TwoLineElement by parsing a TLE string.
    ///
    /// Parses a standard three-line TLE format string and extracts all orbital elements.
    /// The parser validates checksums, line lengths, and data ranges to ensure the TLE
    /// is well-formed.
    ///
    /// - Parameter tle: A three-line string in NORAD TLE format
    /// - Throws: `TLEParsingError` if the TLE is malformed, has invalid checksums,
    ///           or contains out-of-range values
    ///
    /// ## Example
    /// ```swift
    /// let tleString = """
    /// ISS (ZARYA)
    /// 1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
    /// 2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
    /// """
    /// let tle = try TwoLineElement(from: tleString)
    /// ```
    ///
    /// ## Validation Performed
    /// - Line count must be exactly 3
    /// - Lines 1 and 2 must be at least 69 characters
    /// - Checksum validation for lines 1 and 2
    /// - Eccentricity must be less than 1.0
    /// - All numeric fields must parse correctly
    ///
    /// - Note: The parser uses a ±50 year window for 2-digit year interpretation,
    ///         making it suitable for historical and future TLE data
    public init(from tle: String) throws {

        let lines = tle.components(separatedBy: "\n")
        guard lines.count == 3 else {
            throw TLEParsingError.missingLine(expected: 3, actual: lines.count)
        }
        
        let line0: String = lines[0]
        let line1: String = lines[1]
        let line2: String = lines[2]
        
        // Validate line lengths for Line 1 and Line 2 (Line 0 is satellite name and can vary)
        guard line1.count >= 69 else {
            throw TLEParsingError.invalidFormat("Line 1 is too short (expected at least 69 characters)")
        }
        guard line2.count >= 69 else {
            throw TLEParsingError.invalidFormat("Line 2 is too short (expected at least 69 characters)")
        }
        
        // Validate checksums
        try Self.validateChecksum(line: line1, lineNumber: 1)
        try Self.validateChecksum(line: line2, lineNumber: 2)
                
        // Line 0 - Satellite name (can be any length, padded or truncated to fit)
        self.name = line0.count >= 25 ? line0[0...24].string : line0
        
        // Line 1
        let catalogNumberString = line1[2...6].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let catalogNum = Int(catalogNumberString) else {
            throw TLEParsingError.invalidNumber(field: "catalogNumber", value: catalogNumberString)
        }
        self.catalogNumber = catalogNum
        
        self.internationalDesignator = line1[9...16].string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let epochUTCString = line1[18...31].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.elementSetEpochUTC = epochUTCString
        
        let epochYearString = line1[18...19].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let epochYearInt = Int(epochYearString) else {
            throw TLEParsingError.invalidNumber(field: "epochYear", value: epochYearString)
        }
        // Parse 2-digit year relative to current date using ±50 year window.
        // Satellites weren't launched until 1957 (Sputnik 1).
        // This approach works for historical data and automatically adjusts for future dates.
        self.epochYear = Self.parse2DigitYear(epochYearInt)

        let epochDayString = line1[20...31].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let epochDayValue = Double(epochDayString) else {
            throw TLEParsingError.invalidNumber(field: "epochDay", value: epochDayString)
        }
        self.epochDay = epochDayValue
        
        // Parse mean motion first derivative (can be negative)
        let meanMotionFirstDerivativeString = line1[33...42].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let meanMotionFirstDerivativeValue = Double(meanMotionFirstDerivativeString) else {
            throw TLEParsingError.invalidNumber(field: "meanMotionFirstDerivative", value: meanMotionFirstDerivativeString)
        }
        self.meanMotionFirstDerivative = meanMotionFirstDerivativeValue
        
        // Parse mean motion second derivative (scientific notation with assumed decimal)
        let meanMotionSecondDerivativeString = line1[44...51].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.meanMotionSecondDerivative = try Self.parseScientificNotation(
            meanMotionSecondDerivativeString,
            fieldName: "meanMotionSecondDerivative"
        )
        
        // Parse BSTAR drag term (scientific notation with assumed decimal)
        let bstarString = line1[53...60].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.bstarDragTerm = try Self.parseScientificNotation(
            bstarString,
            fieldName: "bstarDragTerm"
        )
        
        // Line 2
        let inclinationString = line2[8...15].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let inclinationValue = Degrees(inclinationString) else {
            throw TLEParsingError.invalidNumber(field: "inclination", value: inclinationString)
        }
        self.inclination = inclinationValue
        
        let rightAscensionString = line2[17...24].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let rightAscensionValue = Degrees(rightAscensionString) else {
            throw TLEParsingError.invalidNumber(field: "rightAscension", value: rightAscensionString)
        }
        self.rightAscension = rightAscensionValue
        
        let eccentricityString = line2[26...32].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let eccentricityValue = Degrees("0.\(eccentricityString)") else {
            throw TLEParsingError.invalidNumber(field: "eccentricity", value: eccentricityString)
        }
        // Validate eccentricity is less than 1.0
        guard eccentricityValue < 1.0 else {
            throw TLEParsingError.invalidEccentricity(value: eccentricityValue)
        }
        self.eccentricity = eccentricityValue
        
        let argumentOfPerigee = line2[34...41].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let argumentOfPerigeeValue = Degrees(argumentOfPerigee) else {
            throw TLEParsingError.invalidNumber(field: "argumentOfPerigee", value: argumentOfPerigee)
        }
        self.argumentOfPerigee = argumentOfPerigeeValue
        
        let meanAnomalyString = line2[43...50].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let meanAnomalyValue = Degrees(meanAnomalyString) else {
            throw TLEParsingError.invalidNumber(field: "meanAnomaly", value: meanAnomalyString)
        }
        self.meanAnomaly = meanAnomalyValue
        
        let meanMotionString = line2[52...62].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let meanMotionValue = Double(meanMotionString) else {
            throw TLEParsingError.invalidNumber(field: "meanMotion", value: meanMotionString)
        }
        self.meanMotion = meanMotionValue
        
        let revolutionsAtEpochString = line2[63...67].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let revolutionsAtEpochValue = Int(revolutionsAtEpochString) else {
            throw TLEParsingError.invalidNumber(field: "revolutionsAtEpoch", value: revolutionsAtEpochString)
        }
        self.revolutionsAtEpoch = revolutionsAtEpochValue
    }
    
    // MARK: - Helper Methods
    
    /// Parse 2-digit year relative to current date
    ///
    /// The TLE format uses 2-digit years, requiring interpretation logic to determine the century.
    /// This method assumes the epoch is within ±50 years of the current year.
    ///
    /// - Parameter twoDigitYear: A 2-digit year value (00-99)
    /// - Returns: A 4-digit year value
    ///
    /// - Note: This approach handles historical satellites (1957-1999) and automatically
    ///         adjusts for future dates as long as TLE data is reasonably current.
    ///
    /// Examples:
    /// - In 2025: year 20 → 2020, year 57 → 2057, year 99 → 1999
    /// - In 2057: year 20 → 2020, year 57 → 2057, year 99 → 2099
    private static func parse2DigitYear(_ twoDigitYear: Int) -> Int {
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        
        let century = (currentYear / 100) * 100
        var year = century + twoDigitYear
        
        // If resulting year is more than 50 years in the future,
        // assume it's from the previous century
        if year > currentYear + 50 {
            year -= 100
        }
        // If resulting year is more than 50 years in the past,
        // assume it's from the next century
        else if year < currentYear - 50 {
            year += 100
        }
        
        return year
    }
    
    /// Validate the modulo-10 checksum for a TLE line
    ///
    /// The checksum is computed by summing all numeric digits (0-9) in the line,
    /// treating minus signs (-) as having a value of 1, and taking modulo 10.
    /// The last character of the line should equal this computed checksum.
    ///
    /// - Parameters:
    ///   - line: The TLE line to validate (either line 1 or line 2)
    ///   - lineNumber: The line number (1 or 2) for error reporting
    /// - Throws: TLEParsingError.invalidChecksum if checksum validation fails
    private static func validateChecksum(line: String, lineNumber: Int) throws {
        guard line.count >= 69 else {
            throw TLEParsingError.invalidFormat("Line \(lineNumber) is too short for checksum validation")
        }
        
        // The checksum is the last character (column 69, index 68)
        let checksumChar = line[68...68].string
        guard let expectedChecksum = Int(checksumChar) else {
            throw TLEParsingError.invalidFormat("Line \(lineNumber) checksum character is not a digit")
        }
        
        // Calculate checksum from columns 1-68
        var sum = 0
        for i in 0..<68 {
            let char = line[i...i].string
            if let digit = Int(char) {
                sum += digit
            } else if char == "-" {
                sum += 1
            }
            // All other characters (letters, spaces, +, .) are ignored
        }
        
        let calculatedChecksum = sum % 10
        
        guard calculatedChecksum == expectedChecksum else {
            throw TLEParsingError.invalidChecksum(
                line: lineNumber,
                expected: expectedChecksum,
                actual: calculatedChecksum
            )
        }
    }
    
    /// Parse a number in TLE scientific notation format
    ///
    /// TLE format uses a compact scientific notation with an assumed decimal point:
    /// - Format: ±XXXXX±Y where the decimal point is assumed after the sign
    /// - Example: "12345-3" → +0.12345 × 10⁻³ = 0.00012345
    /// - Example: "-12345-3" → -0.12345 × 10⁻³ = -0.00012345
    /// - Example: "00000-0" → 0.0
    ///
    /// - Parameters:
    ///   - string: The string to parse in TLE scientific notation
    ///   - fieldName: The field name for error reporting
    /// - Returns: The parsed double value
    /// - Throws: TLEParsingError.invalidNumber if parsing fails
    private static func parseScientificNotation(_ string: String, fieldName: String) throws -> Double {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle empty or all-zero cases
        if trimmed.isEmpty {
            return 0.0
        }
        
        // Handle the special case of all spaces or "00000-0" or "00000+0"
        if trimmed.allSatisfy({ $0 == "0" || $0 == " " || $0 == "-" || $0 == "+" }) {
            return 0.0
        }
        
        // Split on the exponent sign (look for last + or - that's not at the start)
        var mantissaSign = 1.0
        var mantissaString = ""
        var exponentString = ""
        
        // Find the position of the exponent sign (last + or - that's not at position 0)
        var exponentSignIndex: Int?
        for i in 1..<trimmed.count {
            let char = trimmed[i...i].string
            if char == "+" || char == "-" {
                exponentSignIndex = i
            }
        }
        
        if let expIndex = exponentSignIndex {
            // Extract mantissa and exponent parts
            mantissaString = trimmed[0..<expIndex].string
            exponentString = trimmed[expIndex...].string
            
            // Handle the sign of the mantissa (first character)
            if mantissaString.hasPrefix("-") {
                mantissaSign = -1.0
                mantissaString = String(mantissaString.dropFirst())
            } else if mantissaString.hasPrefix("+") {
                mantissaString = String(mantissaString.dropFirst())
            } else if mantissaString.hasPrefix(" ") {
                mantissaString = mantissaString.trimmingCharacters(in: .whitespaces)
            }
            
            // Parse mantissa (assumed decimal point at the beginning)
            guard let mantissaValue = Double("0." + mantissaString) else {
                throw TLEParsingError.invalidNumber(field: fieldName, value: string)
            }
            
            // Parse exponent
            guard let exponentValue = Int(exponentString) else {
                throw TLEParsingError.invalidNumber(field: fieldName, value: string)
            }
            
            // Compute the final value: ±0.mantissa × 10^exponent
            return mantissaSign * mantissaValue * pow(10.0, Double(exponentValue))
        } else {
            // No exponent sign found, try parsing as a regular number
            guard let value = Double(trimmed) else {
                throw TLEParsingError.invalidNumber(field: fieldName, value: string)
            }
            return value
        }
    }
}

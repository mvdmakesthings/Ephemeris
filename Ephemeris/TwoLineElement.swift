//
//  TwoLineElement.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Two-Line Element Format is data format encoding a list of orbital elements of an Earth-orbiting object for a given point in time (epoch).
///
/// - Link: https://en.wikipedia.org/wiki/Two-line_element_set
///
/// - Note: Example TLE String:
///     ISS (ZARYA)
///     1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
///     2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958

/// Errors that can occur during TLE parsing
public enum TLEParsingError: Error, LocalizedError {
    case invalidFormat(String)
    case invalidNumber(field: String, value: String)
    case missingLine(expected: Int, actual: Int)
    case invalidStringRange(field: String, range: String)
    
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
        }
    }
}

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
        // Satillites weren't lauched until 1957 (Sputnik 1) so this will work... until 2057 when we will need
        // to figure out something else. 💩 Y2K for TwoLineElement standards!
        self.epochYear = (epochYearInt < 57) ? 2000 + epochYearInt : 1900 + epochYearInt

        let epochDayString = line1[20...31].string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let epochDayValue = Double(epochDayString) else {
            throw TLEParsingError.invalidNumber(field: "epochDay", value: epochDayString)
        }
        self.epochDay = epochDayValue
        
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
}

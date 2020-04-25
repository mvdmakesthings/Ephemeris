//
//  TwoLineElement.swift
//  SwiftSatTrack
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
struct TwoLineElement {
    // MARK: - Line 0
    /// Object's common name based on information from the satellite catalog.
    var name: String
    
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
    
    /// Epoch Day as fraction
    var epochDay: Double
    
    /// Epoch Date
    var epochDate: Date = Date()
    
    // MARK: - Line 2
    /// Orbit Inclination ( i )
    var inclination: Degree
    /// Right Ascension of Ascending Node ( Ω )
    var rightAscension: Degree
    /// Eccentricity ( e )
    var eccentricity: Double
    /// Argument of Perigee (degrees)
    var argumentOfPerigee: Degree
    /// Mean Anomaly (degrees)
    var meanAnomaly: Degree
    /// Mean Motion (revolutions/day), the number of orbits the object completes in a total day.
    var meanMotion: Double
    /// Revolution Number at Epoch
    var revolutionsAtEpoch: Int
    
    init(from tle: String) {

        let lines = tle.components(separatedBy: "\n")
        guard lines.count == 3 else { fatalError("Not properly formatted TLE data") }
        
        let line0: String = lines[0]
        let line1: String = lines[1]
        let line2: String = lines[2]
                
        // Line 0
        self.name = line0[0...24].string
        
        // Line 1
        let catalogNumberString = line1[2...6].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.catalogNumber = Int(catalogNumberString)!
        
        self.internationalDesignator = line1[9...16].string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let epochUTCString = line1[18...31].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.elementSetEpochUTC = epochUTCString
        
        let epochYearInt = Int(line1[18...19].string.trimmingCharacters(in: .whitespacesAndNewlines))!
        self.epochYear = (epochYearInt < 70) ? 2000 + epochYearInt : 1900 + epochYearInt

        let epochDayString = line1[20...31].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.epochDay = Double(epochDayString)!

        // TODO: FIX THIS
        self.epochDate = Date()
        
        // Line 2
        let inclinationString = line2[8...15].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.inclination = Degree(inclinationString)!
        
        let rightAscensionString = line2[17...24].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.rightAscension = Degree(rightAscensionString)!
        
        let eccentricityString = line2[26...32].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.eccentricity = Degree("0.\(eccentricityString)")!
        
        let argumentOfPerigee = line2[34...41].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.argumentOfPerigee = Degree(argumentOfPerigee)!
        
        let meanAnomalyString = line2[43...50].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.meanAnomaly = Degree(meanAnomalyString)!
        
        let meanMotionString = line2[52...62].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.meanMotion = Double(meanMotionString)!
        
        let revolutionsAtEpochString = line2[63...67].string.trimmingCharacters(in: .whitespacesAndNewlines)
        self.revolutionsAtEpoch = Int(revolutionsAtEpochString)!
    }
}

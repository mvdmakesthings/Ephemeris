//
//  MockTLEs.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
@testable import Ephemeris

struct MockTLEs {

    /// Replace the last character of a TLE data line with its modulo-10 checksum.
    ///
    /// The checksum sums every digit in columns 1-68, counts each minus sign as 1,
    /// and takes the result modulo 10. Lets tests build TLE lines with arbitrary
    /// field values without hand-computing checksums.
    static func fixChecksum(for line: String) -> String {
        guard line.count >= 69 else { return line }
        let sum = line.prefix(68).reduce(0) { total, char in
            if let digit = char.wholeNumberValue { return total + digit }
            return char == "-" ? total + 1 : total
        }
        return String(line.prefix(68)) + String(sum % 10)
    }

    static func ISSSample() throws -> TwoLineElement {
        let tleString =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        return try TwoLineElement(from: tleString)
    }
    
    /// Synthetic near-circular orbit at 0.1° inclination (15 rev/day)
    static func equatorialSample() throws -> TwoLineElement {
        try TwoLineElement(from: """
            TEST EQUATORIAL
            1 99999U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
            2 99999   0.1000   0.0000 0001000   0.0000   0.0000 15.00000000000016
            """)
    }

    /// Synthetic near-circular polar orbit (14 rev/day)
    static func polarSample() throws -> TwoLineElement {
        try TwoLineElement(from: """
            TEST POLAR
            1 88888U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9996
            2 88888  90.0000   0.0000 0001000   0.0000   0.0000 14.00000000000018
            """)
    }

    /// Synthetic geostationary orbit (one revolution per sidereal day)
    static func geostationarySample() throws -> TwoLineElement {
        try TwoLineElement(from: """
            TEST GEO
            1 77777U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
            2 77777   0.0500   0.0000 0000100   0.0000   0.0000  1.00273790000013
            """)
    }

    static func NOAASample() throws -> TwoLineElement {
        let tleString =
            """
            NOAA 16 [-]
            1 26536U 00055A   20116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """
        return try TwoLineElement(from: tleString)
    }
    
    static func objectAtPerigee() throws -> TwoLineElement {
        let tleString =
            """
            Object At Perigee
            1 26536U 00055A   20116.52380576 -.00000007  00000-0  19116-4 0  9998
            2 26536  00.0000 000.0000 5000000 000.0000 000.0000 15.00000000000005
            """
        return try TwoLineElement(from: tleString)
    }
}

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

    static func ISSSample() throws -> TwoLineElement {
        let tleString =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        return try TwoLineElement(from: tleString)
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
            2 26536  00.0000 000.0000 5000000 000.0000 000.0000 15.00000000000000
            """
        return try TwoLineElement(from: tleString)
    }
}

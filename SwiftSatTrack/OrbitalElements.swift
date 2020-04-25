//
//  OrbitalElements.swift
//  SwiftSatTrack
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

struct OrbitalElements {
    
    // MARK: - Size of Orbit
    let semimajorAxis: Double
    
    // MARK: - Shape of Orbit
    let eccentricity: Double
    
    // MARK: - Orientation of Orbit
    let inclination: Degree
    let rightAscensionOfAscendingNode: Degree
    let argumentOfPerigee: Degree
    
    // MARK: - Position of Craft
    let trueAnomaly: Degree
}

//
//  PhysicalConstants.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 11/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

public struct PhysicalConstants {
    /// Earth's Physical Constants
    public struct Earth {
        private init() {}
        
        /// (µ = GM) Earth's gravitational constant (Km^3/s^2)
        public static let µ: Double = 398613.52
        
        /// Earth's radius in Kilometers
        public static let radius: Double = 6378.0
    }
}

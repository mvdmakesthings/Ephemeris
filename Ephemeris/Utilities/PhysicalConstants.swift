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
    /// Based on WGS 84 World Geodetic System.
    ///
    /// - Note: WGS 84 is an Earth-centered, Earth-fixed terrestrial reference system and geodetic datum. WGS 84 is based on a consistent set of constants and model parameters that describe the Earth's size, shape, and gravity and geomagnetic fields. WGS 84 is the standard U.S. Department of Defense definition of a global reference system for geospatial information and is the reference system for the Global Positioning System (GPS). It is compatible with the International Terrestrial Reference System (ITRS)
    /// - Note: http://www.unoosa.org/pdf/icg/2012/template/WGS_84.pdf
    /// - Note: WGS 72 was also considered: https://apps.dtic.mil/dtic/tr/fulltext/u2/a110165.pdf
    public struct Earth {
        private init() {}
        
        /// (µ = GM) Earth's gravitational constant (Km^3/s^2)
        public static let µ: Double = 3.986004418 * pow(10, 14) / 1000

        
        /// Earth's radius in Kilometers
        public static let radius: Double = 6378137.0 / 1000
        
        /// Number of rads earth rotates in 1 solar day
        /// - Note: Taken from "Methods of Astrondynamics, A Computer Approach (v3) " by Capt David Vallado, Department of Astronautics, U.S. Air Force Academy https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach
        public static let radsPerDay: Double = 6.3003809866574
    }
    
    /// Time-related constants
    public struct Time {
        private init() {}
        
        /// Number of seconds in one solar day
        public static let secondsPerDay: Double = 86400.0
        
        /// Days in one Julian century
        public static let daysPerJulianCentury: Double = 36525.0
    }
    
    /// Julian date reference points
    public struct Julian {
        private init() {}
        
        /// Julian Day Number for Unix Epoch (Jan 1, 1970 00:00:00 UTC)
        public static let unixEpoch: Double = 2440587.5
        
        /// Julian Day Number for J2000.0 Epoch (Jan 1, 2000 12:00:00 TT)
        public static let j2000Epoch: Double = 2451545.0
    }
    
    /// Calculation-related constants
    public struct Calculation {
        private init() {}
        
        /// Default convergence accuracy for iterative calculations
        public static let defaultAccuracy: Double = 0.00001
        
        /// Maximum iterations for convergence algorithms
        public static let maxIterations: Int = 500
    }
    
    /// Angle-related constants
    public struct Angle {
        private init() {}
        
        /// Degrees in a full circle
        public static let degreesPerCircle: Double = 360.0
        
        /// Radians in a full circle (2π)
        public static let radiansPerCircle: Double = 2.0 * .pi
    }
}

//
//  PhysicalConstants.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 11/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Physical and mathematical constants used in orbital calculations.
///
/// This structure provides a centralized collection of constants based on the WGS84
/// (World Geodetic System 1984) standard and other astronomical references. All values
/// are well-documented with their sources and units.
///
/// ## Categories
/// - **Earth**: Gravitational constant, radius, rotation rate
/// - **Time**: Conversion factors for days, hours, minutes, seconds
/// - **Julian**: Reference epochs for date calculations
/// - **Calculation**: Default parameters for iterative algorithms
/// - **Angle**: Angular measurement constants
///
/// ## Example Usage
/// ```swift
/// let radius = PhysicalConstants.Earth.radius
/// let mu = PhysicalConstants.Earth.µ
/// let secondsPerDay = PhysicalConstants.Time.secondsPerDay
/// ```
///
/// - Note: WGS 84 is the standard U.S. Department of Defense definition of a global
///         reference system and is compatible with the International Terrestrial Reference System (ITRS)
/// - Note: References:
///   - http://www.unoosa.org/pdf/icg/2012/template/WGS_84.pdf
///   - https://apps.dtic.mil/dtic/tr/fulltext/u2/a110165.pdf (WGS 72)
public struct PhysicalConstants {
    
    /// Earth's Physical Constants
    /// Based on WGS 84 World Geodetic System.
    ///
    /// - Note: WGS 84 is an Earth-centered, Earth-fixed terrestrial reference system and geodetic datum. WGS 84 is based on a consistent set of constants and model parameters that describe the Earth's size, shape, and gravity and geomagnetic fields. WGS 84 is the standard U.S. Department of Defense definition of a global reference system for geospatial information and is the reference system for the Global Positioning System (GPS). It is compatible with the International Terrestrial Reference System (ITRS)
    /// - Note: http://www.unoosa.org/pdf/icg/2012/template/WGS_84.pdf
    /// - Note: WGS 72 was also considered: https://apps.dtic.mil/dtic/tr/fulltext/u2/a110165.pdf
    public struct Earth {
        private init() {}
        
        /// (µ = GM) Earth's gravitational constant (km^3/s^2)
        /// WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
        public static let µ: Double = 398600.4418

        /// Earth's radius in Kilometers
        public static let radius: Double = 6378137.0 / 1000
        
        /// Mean radius of Earth in kilometers (simplified sphere model)
        /// - Note: For precise calculations, use `radius` (WGS84 equatorial radius)
        public static let meanRadius: Double = 6371.0
        
        /// WGS-84 semi-major axis (equatorial radius) in kilometers
        /// This is the same as `radius` but explicitly named for geodetic calculations
        public static let semiMajorAxis: Double = 6378.137
        
        /// WGS-84 semi-minor axis (polar radius) in kilometers
        public static let semiMinorAxis: Double = 6356.7523142
        
        /// WGS-84 flattening factor (f = (a - b) / a)
        /// Describes the ellipsoidal shape of Earth
        public static let flattening: Double = 1.0 / 298.257223563
        
        /// WGS-84 first eccentricity squared (e² = (a² - b²) / a²)
        /// Used in geodetic to ECEF coordinate conversions
        public static let eccentricitySquared: Double = 6.69437999014e-3
        
        /// Number of rads earth rotates in 1 solar day
        /// - Note: Taken from "Methods of Astrodynamics, A Computer Approach (v3) " by Capt David Vallado, Department of Astronautics, U.S. Air Force Academy https://www.academia.edu/20528856/Methods_of_Astrodynamics_a_Computer_Approach
        public static let radsPerDay: Double = 6.3003809866574
    }
    
    /// Time conversion constants
    public struct Time {
        private init() {}
        
        /// Seconds in one solar day
        public static let secondsPerDay: Double = 86400.0
        
        /// Days in one Julian century
        public static let daysPerJulianCentury: Double = 36525.0
        
        /// Seconds in one hour
        public static let secondsPerHour: Double = 3600.0
        
        /// Seconds in one minute
        public static let secondsPerMinute: Double = 60.0
    }
    
    /// Julian date reference points
    public struct Julian {
        private init() {}
        
        /// Julian Day Number for Unix Epoch (Jan 1, 1970 00:00:00 UTC)
        public static let unixEpoch: Double = 2440587.5
        
        /// Julian Day Number for J2000.0 Epoch (Jan 1, 2000 12:00:00 TT)
        public static let j2000Epoch: Double = 2451545.0
    }
    
    /// Constants for iterative calculations
    public struct Calculation {
        private init() {}
        
        /// Default convergence accuracy for iterative calculations
        public static let defaultAccuracy: Double = 0.00001
        
        /// Maximum iterations for convergence algorithms
        public static let maxIterations: Int = 500
    }
    
    /// Angular measurement constants
    public struct Angle {
        private init() {}
        
        /// Degrees in a full circle
        public static let degreesPerCircle: Double = 360.0
        
        /// Radians in a full circle (2π)
        public static let radiansPerCircle: Double = 2.0 * .pi
    }
}

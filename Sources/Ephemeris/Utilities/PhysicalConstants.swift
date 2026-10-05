//
//  PhysicalConstants.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 11/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Physical and astronomical constants used throughout Ephemeris.
///
/// Earth values follow WGS-84, the reference system used by GPS. The SGP4 propagator
/// uses its own WGS-72 constants (see `GravityModel`), because TLEs are fitted with them.
///
/// ## Example Usage
/// ```swift
/// let mu = PhysicalConstants.Earth.mu
/// let equatorialRadius = PhysicalConstants.Earth.semiMajorAxis
/// ```
///
/// - Note: References:
///   - NIMA TR8350.2, "Department of Defense World Geodetic System 1984"
///   - Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.)
public enum PhysicalConstants {

    /// Earth's size, shape, gravity and rotation (WGS-84).
    public enum Earth {
        /// Gravitational parameter μ = GM (km³/s²)
        ///
        /// WGS-84 value: 3.986004418 × 10¹⁴ m³/s²
        public static let mu: Double = 398600.4418

        /// Semi-major axis of the WGS-84 ellipsoid: the equatorial radius (km)
        public static let semiMajorAxis: Double = 6378.137

        /// First eccentricity squared of the WGS-84 ellipsoid, e² = (a² − b²) / a²
        public static let eccentricitySquared: Double = 6.69437999014e-3

        /// Earth's rotation rate relative to the stars, ω⊕ (rad/s)
        ///
        /// WGS-84 defining constant: 7.292115 × 10⁻⁵ rad/s, one turn per sidereal day
        /// (86164.09 s).
        public static let rotationRate: Double = 7.292115e-5
    }

    /// Time conversion constants.
    public enum Time {
        /// Seconds in one day
        public static let secondsPerDay: Double = 86400.0

        /// Seconds in one hour
        public static let secondsPerHour: Double = 3600.0

        /// Days in one Julian century
        public static let daysPerJulianCentury: Double = 36525.0
    }

    /// Reference epochs as Julian dates.
    public enum Julian {
        /// Julian date of the Unix epoch, 1970-01-01 00:00:00 UTC
        public static let unixEpoch: JulianDate = 2440587.5

        /// Julian date of the J2000.0 epoch, 2000-01-01 12:00:00 TT
        public static let j2000: JulianDate = 2451545.0
    }
}

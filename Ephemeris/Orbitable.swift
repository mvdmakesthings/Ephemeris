//
//  Orbitable.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 11/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

public protocol Orbitable {
    // MARK: - Size of Orbit
    /// Describes half of the size of the orbit path from Perigee to Apogee.
    /// Denoted by ( a ) in (km)
    var semimajorAxis: Double { get }
    
    // MARK: - Shape of Orbit
    /// Describes the shape of the orbital path.
    /// Denoted by ( e ) with a value between 0 and 1.
    var eccentricity: Double { get }
    
    // MARK: - Orientation of Orbit
    /// The "tilt" in degrees from the vectors perpandicular to the orbital and equatorial planes
    /// Denoted by ( i ) and is in degrees 0–180°
    var inclination: Degrees { get }
    
    /// The "swivel" of the orbital plane in degrees in reference to the vernal equinox to the 'node' that cooresponds
    /// with the object passing the equator in a northernly direction.
    /// Denoted by ( Ω ) in degrees
    var rightAscensionOfAscendingNode: Degrees { get }
    
    /// Describes the orientation of perigee on the orbital plane with reference to the right ascension of the ascending node
    /// Denoted by ( ω ) in degrees
    var argumentOfPerigee: Degrees { get }
    
    // MARK: - Position of Craft
    
    /// The true angle between the position of the craft relative to perigee along the orbital path.
    /// Denoted as (ν or θ)
    /// Range between 0–360°
    var trueAnomaly: Degrees { get }
    
    /// The position of the craft with respect to the mean motion.
    /// Denoted as (M)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     n = mean motion
    ///     t = time in motion
    ///     M = Current mean anomaly
    ///     M(Δt) = n(Δt) + M
    var meanAnomaly: Degrees { get }
    
    /// The average speed an object moves throughout an orbit.
    /// Denoted as (n)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     M = Gravitational Constant of Earth (3.986004418e^5 km^3/ s^2)
    ///     a = Semimajor axis
    ///     Mean Motion (n) = sqrt( M / a^3 )
    var meanMotion: Double { get }
}

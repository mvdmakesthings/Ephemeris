//
//  Observer.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents an Earth-based observer at a specific geographic location.
///
/// `Observer` defines a location on Earth's surface using geodetic coordinates
/// (latitude, longitude, altitude) from which satellite observations can be made.
/// This is the foundation for calculating topocentric (observer-relative) coordinates
/// and predicting satellite passes.
///
/// ## Example Usage
/// ```swift
/// // Observer in Louisville, Kentucky
/// let observer = Observer(
///     latitudeDeg: 38.2542,
///     longitudeDeg: -85.7594,
///     altitudeMeters: 140
/// )
/// ```
///
/// - Note: Coordinates use the WGS-84 geodetic system, which is the standard
///         for GPS and satellite tracking applications.
public struct Observer {
    /// Geodetic latitude in degrees (-90 to 90).
    /// Positive values indicate north of the equator, negative values indicate south.
    public let latitudeDeg: Double
    
    /// Geodetic longitude in degrees (-180 to 180).
    /// Positive values indicate east of the prime meridian, negative values indicate west.
    public let longitudeDeg: Double
    
    /// Altitude above the WGS-84 ellipsoid in meters.
    /// This is height above the reference ellipsoid, not necessarily above sea level.
    public let altitudeMeters: Double
    
    /// Creates an observer at a specific geographic location.
    ///
    /// - Parameters:
    ///   - latitudeDeg: Geodetic latitude in degrees (-90 to 90)
    ///   - longitudeDeg: Geodetic longitude in degrees (-180 to 180)
    ///   - altitudeMeters: Altitude above WGS-84 ellipsoid in meters
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// ```
    public init(latitudeDeg: Double, longitudeDeg: Double, altitudeMeters: Double) {
        self.latitudeDeg = latitudeDeg
        self.longitudeDeg = longitudeDeg
        self.altitudeMeters = altitudeMeters
    }
}

/// Represents topocentric (observer-relative) coordinates of a satellite.
///
/// `Topocentric` describes a satellite's position as seen from a specific observer
/// location on Earth. The coordinates use the horizontal coordinate system, which
/// is intuitive for tracking and pointing antennas or telescopes.
///
/// ## Coordinate System
/// - **Azimuth**: Horizontal angle measured clockwise from north (0° = North, 90° = East, 180° = South, 270° = West)
/// - **Elevation**: Vertical angle above the horizon (0° = horizon, 90° = zenith, negative = below horizon)
/// - **Range**: Straight-line distance from observer to satellite in kilometers
/// - **Range Rate**: Rate of change of range in km/s (positive = moving away, negative = approaching)
///
/// ## Example Usage
/// ```swift
/// let topo = try orbit.topocentric(at: Date(), for: observer)
/// print("Az: \(topo.azimuthDeg)°, El: \(topo.elevationDeg)°")
/// print("Range: \(topo.rangeKm) km, Rate: \(topo.rangeRateKmPerSec) km/s")
/// ```
public struct Topocentric {
    /// Azimuth angle in degrees (0-360).
    /// Measured clockwise from true north: 0° = North, 90° = East, 180° = South, 270° = West.
    public let azimuthDeg: Double
    
    /// Elevation angle in degrees (-90 to 90).
    /// Angle above the horizon: 0° = horizon, 90° = zenith, negative = below horizon.
    public let elevationDeg: Double
    
    /// Slant range (distance) from observer to satellite in kilometers.
    public let rangeKm: Double
    
    /// Range rate (rate of change of distance) in kilometers per second.
    /// Positive values indicate the satellite is moving away from the observer,
    /// negative values indicate the satellite is approaching.
    public let rangeRateKmPerSec: Double
    
    /// Creates topocentric coordinates.
    ///
    /// - Parameters:
    ///   - azimuthDeg: Azimuth angle in degrees (0-360)
    ///   - elevationDeg: Elevation angle in degrees (-90 to 90)
    ///   - rangeKm: Distance in kilometers
    ///   - rangeRateKmPerSec: Range rate in km/s
    public init(azimuthDeg: Double, elevationDeg: Double, rangeKm: Double, rangeRateKmPerSec: Double) {
        self.azimuthDeg = azimuthDeg
        self.elevationDeg = elevationDeg
        self.rangeKm = rangeKm
        self.rangeRateKmPerSec = rangeRateKmPerSec
    }
}

/// Represents a complete satellite pass over an observer's location.
///
/// `PassWindow` captures the key events during a satellite's visible pass:
/// acquisition of signal (AOS), maximum elevation, and loss of signal (LOS).
/// This information is essential for planning observations, ground station contacts,
/// and amateur radio communications.
///
/// ## Example Usage
/// ```swift
/// let passes = try orbit.predictPasses(for: observer, from: now, to: tomorrow)
/// for pass in passes {
///     print("AOS: \(pass.aos.time) at \(pass.aos.azimuthDeg)°")
///     print("MAX: \(pass.max.time) at \(pass.max.elevationDeg)° elevation")
///     print("LOS: \(pass.los.time) at \(pass.los.azimuthDeg)°")
///     print("Duration: \(pass.duration) seconds")
/// }
/// ```
public struct PassWindow {
    /// Represents a point during a satellite pass with time and azimuth.
    public struct Point {
        /// The time of this point in the pass.
        public let time: Date
        
        /// The azimuth angle in degrees at this time (0-360).
        public let azimuthDeg: Double
        
        /// Creates a pass point.
        ///
        /// - Parameters:
        ///   - time: The time of this point
        ///   - azimuthDeg: The azimuth angle in degrees
        public init(time: Date, azimuthDeg: Double) {
            self.time = time
            self.azimuthDeg = azimuthDeg
        }
    }
    
    /// Acquisition of Signal (AOS) - when the satellite rises above the minimum elevation.
    public let aos: Point
    
    /// Maximum elevation point with time, elevation, and azimuth.
    public let max: (time: Date, elevationDeg: Double, azimuthDeg: Double)
    
    /// Loss of Signal (LOS) - when the satellite drops below the minimum elevation.
    public let los: Point
    
    /// Duration of the pass in seconds.
    public var duration: TimeInterval {
        return los.time.timeIntervalSince(aos.time)
    }
    
    /// Creates a pass window.
    ///
    /// - Parameters:
    ///   - aos: Acquisition of signal point
    ///   - max: Maximum elevation tuple (time, elevation, azimuth)
    ///   - los: Loss of signal point
    public init(aos: Point, max: (time: Date, elevationDeg: Double, azimuthDeg: Double), los: Point) {
        self.aos = aos
        self.max = max
        self.los = los
    }
}

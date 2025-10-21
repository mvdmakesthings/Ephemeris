//
//  Topocentric.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

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
    // MARK: - Properties

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

    // MARK: - Initialization

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

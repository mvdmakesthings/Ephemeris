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
/// - Note: This type is frozen for ABI stability. New functionality will be added
///         through extension methods rather than new stored properties.
/// - Note: Coordinates use the WGS-84 geodetic system, which is the standard
///         for GPS and satellite tracking applications.
@frozen public struct Observer {
    // MARK: - Properties

    /// Geodetic latitude in degrees (-90 to 90).
    /// Positive values indicate north of the equator, negative values indicate south.
    public let latitudeDeg: Double

    /// Geodetic longitude in degrees (-180 to 180).
    /// Positive values indicate east of the prime meridian, negative values indicate west.
    public let longitudeDeg: Double

    /// Altitude above the WGS-84 ellipsoid in meters.
    /// This is height above the reference ellipsoid, not necessarily above sea level.
    public let altitudeMeters: Double

    // MARK: - Initialization

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

// MARK: - Codable Conformance

extension Observer: Codable {}

// MARK: - Equatable and Hashable Conformance

extension Observer: Equatable, Hashable {}

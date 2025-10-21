//
//  Position.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents a geographic position with latitude, longitude, and altitude.
///
/// This structure holds the calculated position of a satellite at a specific time,
/// expressed in geographic coordinates relative to Earth's surface using the
/// WGS-84 geodetic system.
///
/// ## Example Usage
/// ```swift
/// let position = try orbit.calculatePosition(at: Date())
/// print("Latitude: \(position.latitude)°")
/// print("Longitude: \(position.longitude)°")
/// print("Altitude: \(position.altitude) km")
/// ```
///
/// - Note: This type is frozen for ABI stability. New functionality will be added
///         through extension methods rather than new stored properties.
/// - Note: All coordinates use the WGS-84 geodetic reference system
@frozen public struct GeodeticPosition {
    // MARK: - Properties

    /// Latitude in degrees (-90 to 90), where positive values indicate north
    public let latitude: Double

    /// Longitude in degrees (-180 to 180), where positive values indicate east
    public let longitude: Double

    /// Altitude in kilometers above Earth's surface
    public let altitude: Double

    // MARK: - Initialization

    /// Creates a position with the specified coordinates.
    ///
    /// - Parameters:
    ///   - latitude: Latitude in degrees (-90 to 90)
    ///   - longitude: Longitude in degrees (-180 to 180)
    ///   - altitude: Altitude in kilometers above Earth's surface
    public init(latitude: Double, longitude: Double, altitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}

// MARK: - Codable Conformance

extension GeodeticPosition: Codable {}

// MARK: - Equatable Conformance

extension GeodeticPosition: Equatable {}

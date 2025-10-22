//
//  SkyTrack.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents a single point along a satellite's sky track as seen from an observer.
///
/// A sky track shows the path traced by the satellite across the observer's sky
/// in horizontal coordinates (azimuth and elevation). This is useful for planning
/// observations, pointing antennas, and visualizing satellite passes.
///
/// ## Example Usage
/// ```swift
/// let skyTrack = orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 10)
/// for point in skyTrack {
///     print("\(point.time): Az \(point.azimuthDeg)°, El \(point.elevationDeg)°")
/// }
/// ```
///
/// - Note: This type is frozen for ABI stability. New functionality will be added
///         through extension methods rather than new stored properties.
@frozen public struct SkyTrackPoint {
    // MARK: - Properties

    /// The time of this sky track point
    public let time: Date

    /// Azimuth angle in degrees (0-360), measured clockwise from north
    public let azimuthDeg: Double

    /// Elevation angle in degrees (-90 to 90), angle above the horizon
    public let elevationDeg: Double

    // MARK: - Initialization

    /// Creates a sky track point.
    ///
    /// - Parameters:
    ///   - time: The time of this point
    ///   - azimuthDeg: Azimuth angle in degrees
    ///   - elevationDeg: Elevation angle in degrees
    ///
    /// - Note: Marked as `@inlinable` for performance in hot paths such as
    ///         sky track generation loops.
    @inlinable
    public init(time: Date, azimuthDeg: Double, elevationDeg: Double) {
        self.time = time
        self.azimuthDeg = azimuthDeg
        self.elevationDeg = elevationDeg
    }
}

// MARK: - Codable Conformance

extension SkyTrackPoint: Codable {}

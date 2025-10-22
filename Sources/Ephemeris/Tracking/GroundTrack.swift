//
//  GroundTrack.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents a single point along a satellite's ground track.
///
/// A ground track shows the path traced by the satellite's sub-satellite point
/// (the point on Earth's surface directly below the satellite) over time.
/// This is useful for visualizing satellite coverage, planning observations,
/// and understanding orbital mechanics.
///
/// ## Example Usage
/// ```swift
/// let groundTrack = orbit.groundTrack(from: start, to: end, stepSeconds: 60)
/// for point in groundTrack {
///     print("\(point.time): \(point.latitudeDeg)°N, \(point.longitudeDeg)°E")
/// }
/// ```
///
/// - Note: This type is frozen for ABI stability. New functionality will be added
///         through extension methods rather than new stored properties.
@frozen public struct GroundTrackPoint {
    // MARK: - Properties

    /// The time of this ground track point
    public let time: Date

    /// Geodetic latitude in degrees (-90 to 90)
    public let latitudeDeg: Double

    /// Geodetic longitude in degrees (-180 to 180)
    public let longitudeDeg: Double

    // MARK: - Initialization

    /// Creates a ground track point.
    ///
    /// - Parameters:
    ///   - time: The time of this point
    ///   - latitudeDeg: Geodetic latitude in degrees
    ///   - longitudeDeg: Geodetic longitude in degrees
    ///
    /// - Note: Marked as `@inlinable` for performance in hot paths such as
    ///         ground track generation loops.
    @inlinable
    public init(time: Date, latitudeDeg: Double, longitudeDeg: Double) {
        self.time = time
        self.latitudeDeg = latitudeDeg
        self.longitudeDeg = longitudeDeg
    }
}

// MARK: - Codable Conformance

extension GroundTrackPoint: Codable {}

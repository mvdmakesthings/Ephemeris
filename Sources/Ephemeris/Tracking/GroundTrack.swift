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

// MARK: - Orbit Ground Track Generation

extension Orbit {
    /// Generates a ground track (latitude/longitude trace) for the satellite over time.
    ///
    /// This method calculates the satellite's sub-satellite point (the point on Earth's
    /// surface directly below the satellite) at regular intervals across a specified
    /// time window. The resulting array of points can be used for visualization,
    /// coverage analysis, or debugging orbital propagation.
    ///
    /// - Parameters:
    ///   - start: Start time for the ground track
    ///   - end: End time for the ground track
    ///   - stepSeconds: Time step between points in seconds (default: 60)
    /// - Returns: Array of GroundTrackPoint objects representing the satellite's path
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Algorithm
    /// For each time step from start to end:
    /// 1. Calculate the satellite's position using orbital propagation
    /// 2. Extract latitude and longitude from the position
    /// 3. Store as a GroundTrackPoint
    ///
    /// ## Example
    /// ```swift
    /// let now = Date()
    /// let oneHourLater = now.addingTimeInterval(3600)
    /// let groundTrack = try orbit.groundTrack(
    ///     from: now,
    ///     to: oneHourLater,
    ///     stepSeconds: 60
    /// )
    ///
    /// // Visualize or export the ground track
    /// for point in groundTrack {
    ///     print("\(point.time): \(point.latitudeDeg)°, \(point.longitudeDeg)°")
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Visualizing satellite coverage on a map
    /// - Planning ground station contacts
    /// - Educational demonstrations of orbital mechanics
    /// - Validating orbital propagation accuracy
    ///
    /// - Note: For high-precision applications, use smaller step sizes (e.g., 10-30 seconds).
    ///         For overview visualizations, larger steps (60-120 seconds) may be sufficient.
    public func groundTrack(from start: Date, to end: Date, stepSeconds: Double = 60) throws -> [GroundTrackPoint] {
        var points: [GroundTrackPoint] = []
        var currentTime = start

        while currentTime <= end {
            let position = try calculatePosition(at: currentTime)
            let point = GroundTrackPoint(
                time: currentTime,
                latitudeDeg: position.latitude,
                longitudeDeg: position.longitude
            )
            points.append(point)
            currentTime = currentTime.addingTimeInterval(stepSeconds)
        }

        return points
    }
}

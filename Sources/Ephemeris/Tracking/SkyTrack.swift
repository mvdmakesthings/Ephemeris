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

// MARK: - Propagator Sky Track Generation

extension Propagator {
    /// Generates a sky track (azimuth/elevation trace) for the satellite as seen from an observer.
    ///
    /// This method calculates the satellite's position in the observer's local horizontal
    /// coordinate system (azimuth and elevation) at regular intervals across a specified
    /// time window. The resulting array of points can be used for visualization, pass
    /// planning, or antenna pointing.
    ///
    /// - Parameters:
    ///   - observer: The observer's location on Earth
    ///   - start: Start time for the sky track
    ///   - end: End time for the sky track
    ///   - stepSeconds: Time step between points in seconds (default: 60)
    /// - Returns: Array of SkyTrackPoint objects representing the satellite's path across the sky
    /// - Throws: Any error thrown by the propagator
    ///
    /// ## Algorithm
    /// For each time step from start to end:
    /// 1. Calculate topocentric coordinates for the satellite relative to the observer
    /// 2. Extract azimuth and elevation from the topocentric coordinates
    /// 3. Store as a SkyTrackPoint
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let now = Date()
    /// let oneHourLater = now.addingTimeInterval(3600)
    /// let skyTrack = try orbit.skyTrack(
    ///     for: observer,
    ///     from: now,
    ///     to: oneHourLater,
    ///     stepSeconds: 10
    /// )
    ///
    /// // Visualize or use for antenna pointing
    /// for point in skyTrack where point.elevationDeg > 0 {
    ///     print("\(point.time): Az \(point.azimuthDeg)°, El \(point.elevationDeg)°")
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Visualizing satellite passes on a polar plot
    /// - Generating antenna pointing commands
    /// - Planning photography or observation sessions
    /// - Validating pass prediction accuracy
    ///
    /// - Note: For smooth pass visualizations, use smaller step sizes (5-30 seconds).
    ///         Points with negative elevation indicate the satellite is below the horizon.
    public func skyTrack(for observer: Observer, from start: Date, to end: Date, stepSeconds: Double = 60) throws -> [SkyTrackPoint] {
        var points: [SkyTrackPoint] = []
        var currentTime = start

        while currentTime <= end {
            let topo = try topocentric(at: currentTime, for: observer, applyRefraction: false)
            let point = SkyTrackPoint(
                time: currentTime,
                azimuthDeg: topo.azimuthDeg,
                elevationDeg: topo.elevationDeg
            )
            points.append(point)
            currentTime = currentTime.addingTimeInterval(stepSeconds)
        }

        return points
    }
}

//
//  GroundTrack.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// A point on a satellite's ground track: the spot on Earth directly beneath it.
///
/// ## Example Usage
/// ```swift
/// let track = try sgp4.groundTrack(from: start, to: end, stepSeconds: 30)
/// let coordinates = track.map { CLLocationCoordinate2D(latitude: $0.position.latitudeDeg,
///                                                      longitude: $0.position.longitudeDeg) }
/// ```
public struct GroundTrackPoint: Hashable, Codable, Sendable {

    /// The time of this point
    public let time: Date

    /// The satellite's geodetic position (latitude, longitude, and altitude above the ellipsoid)
    public let position: GeodeticPosition

    /// Creates a ground track point.
    ///
    /// - Parameters:
    ///   - time: The time of this point
    ///   - position: The satellite's geodetic position
    public init(time: Date, position: GeodeticPosition) {
        self.time = time
        self.position = position
    }
}

// MARK: - Propagator Ground Track

extension Propagator {
    /// Samples the satellite's geodetic position at regular intervals.
    ///
    /// - Parameters:
    ///   - start: First sample time
    ///   - end: Last sample time (included even if it does not fall on a step)
    ///   - stepSeconds: Time between samples (default 60). Use 10-30 s for smooth map lines.
    /// - Returns: Points in time order
    /// - Throws: Any error thrown by the propagator
    ///
    /// - Note: Longitude wraps from +180° to −180°. Split the line where consecutive points
    ///         jump by more than 180° before drawing it on a map.
    public func groundTrack(from start: Date, to end: Date, stepSeconds: Double = 60) throws -> [GroundTrackPoint] {
        try sampleTimes(from: start, to: end, stepSeconds: stepSeconds).map { time in
            GroundTrackPoint(time: time, position: try calculatePosition(at: time))
        }
    }

    /// Evenly spaced times from `start` to `end`, always including `end`.
    func sampleTimes(from start: Date, to end: Date, stepSeconds: Double) -> [Date] {
        precondition(stepSeconds > 0, "stepSeconds must be positive")
        guard end >= start else { return [] }
        let duration = end.timeIntervalSince(start)
        let fullSteps = Int((duration / stepSeconds).rounded(.down))
        var times = (0...fullSteps).map { start.addingTimeInterval(Double($0) * stepSeconds) }
        if let last = times.last, last < end {
            times.append(end)
        }
        return times
    }
}

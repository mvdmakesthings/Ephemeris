//
//  SkyTrack.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// A point on a satellite's path across an observer's sky.
///
/// Carries the full look angles, including range and range rate, so the same samples can
/// drive a polar plot, an antenna rotator, and Doppler correction.
///
/// ## Example Usage
/// ```swift
/// let track = try sgp4.skyTrack(for: observer, from: pass.aos.time, to: pass.los.time, stepSeconds: 1)
/// for point in track {
///     rotator.point(azimuth: point.topocentric.azimuthDeg, elevation: point.topocentric.elevationDeg)
/// }
/// ```
public struct SkyTrackPoint: Hashable, Codable, Sendable {

    /// The time of this point
    public let time: Date

    /// Azimuth, elevation, range and range rate from the observer
    public let topocentric: Topocentric

    /// Creates a sky track point.
    ///
    /// - Parameters:
    ///   - time: The time of this point
    ///   - topocentric: Look angles from the observer
    public init(time: Date, topocentric: Topocentric) {
        self.time = time
        self.topocentric = topocentric
    }
}

// MARK: - Propagator Sky Track

extension Propagator {
    /// Samples where the satellite appears from an observer at regular intervals.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - start: First sample time
    ///   - end: Last sample time (included even if it does not fall on a step)
    ///   - stepSeconds: Time between samples (default 60). Use 1-5 s for antenna control.
    ///   - applyRefraction: Whether to report apparent (refracted) elevation (default `false`)
    /// - Returns: Points in time order. Negative elevations mean the satellite is below the horizon.
    /// - Throws: Any error thrown by the propagator
    public func skyTrack(for observer: Observer, from start: Date, to end: Date,
                         stepSeconds: Double = 60, applyRefraction: Bool = false) throws -> [SkyTrackPoint] {
        let frame = ObserverFrame(observer)
        return try sampleTimes(from: start, to: end, stepSeconds: stepSeconds).map { time in
            SkyTrackPoint(time: time, topocentric: try topocentric(at: time, from: frame, applyRefraction: applyRefraction))
        }
    }
}

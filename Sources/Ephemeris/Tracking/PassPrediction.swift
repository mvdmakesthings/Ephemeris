//
//  PassPrediction.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

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
    // MARK: - Nested Types

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

    // MARK: - Properties

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

    // MARK: - Initialization

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

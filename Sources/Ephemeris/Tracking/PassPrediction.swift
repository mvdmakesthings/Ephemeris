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
///
/// - Note: This type is frozen for ABI stability. New functionality will be added
///         through extension methods rather than new stored properties.
@frozen public struct PassWindow {
    // MARK: - Nested Types

    /// Represents a point during a satellite pass with time and azimuth.
    ///
    /// - Note: This type is frozen for ABI stability. New functionality will be added
    ///         through extension methods rather than new stored properties.
    @frozen public struct Point {
        /// The time of this point in the pass.
        public let time: Date

        /// The azimuth angle in degrees at this time (0-360).
        public let azimuthDeg: Double

        /// Creates a pass point.
        ///
        /// - Parameters:
        ///   - time: The time of this point
        ///   - azimuthDeg: The azimuth angle in degrees
        ///
        /// - Note: Marked as `@inlinable` for performance in hot paths such as
        ///         pass prediction algorithms.
        @inlinable
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
    ///
    /// - Note: Marked as `@inlinable` for performance in hot paths such as
    ///         pass prediction algorithms.
    @inlinable
    public init(aos: Point, max: (time: Date, elevationDeg: Double, azimuthDeg: Double), los: Point) {
        self.aos = aos
        self.max = max
        self.los = los
    }
}

// MARK: - Codable Conformance

extension PassWindow.Point: Codable {}

extension PassWindow: Codable {
    /// Coding keys for PassWindow
    private enum CodingKeys: String, CodingKey {
        case aos
        case maxTime
        case maxElevationDeg
        case maxAzimuthDeg
        case los
    }

    /// Encodes the PassWindow to an encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(aos, forKey: .aos)
        try container.encode(max.time, forKey: .maxTime)
        try container.encode(max.elevationDeg, forKey: .maxElevationDeg)
        try container.encode(max.azimuthDeg, forKey: .maxAzimuthDeg)
        try container.encode(los, forKey: .los)
    }

    /// Decodes a PassWindow from a decoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let aos = try container.decode(Point.self, forKey: .aos)
        let maxTime = try container.decode(Date.self, forKey: .maxTime)
        let maxElevationDeg = try container.decode(Double.self, forKey: .maxElevationDeg)
        let maxAzimuthDeg = try container.decode(Double.self, forKey: .maxAzimuthDeg)
        let los = try container.decode(Point.self, forKey: .los)

        self.init(
            aos: aos,
            max: (time: maxTime, elevationDeg: maxElevationDeg, azimuthDeg: maxAzimuthDeg),
            los: los
        )
    }
}

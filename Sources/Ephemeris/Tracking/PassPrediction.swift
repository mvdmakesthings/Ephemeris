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

// MARK: - Orbit Pass Prediction

extension Orbit {
    /// Predicts satellite passes over an observer's location within a time window.
    ///
    /// This method identifies all satellite passes (periods when the satellite is above
    /// the specified minimum elevation) within the given time range. For each pass, it
    /// determines the acquisition of signal (AOS), maximum elevation, and loss of signal (LOS).
    ///
    /// - Parameters:
    ///   - observer: The observer's location on Earth
    ///   - start: Start of the search window
    ///   - end: End of the search window
    ///   - minElevationDeg: Minimum elevation angle in degrees (default: 0°)
    ///   - stepSeconds: Time step for coarse search in seconds (default: 30s)
    /// - Returns: Array of PassWindow objects, one for each pass found
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Algorithm
    /// 1. Coarse search with specified time step to detect elevation sign changes
    /// 2. Bisection search to refine AOS and LOS times to ±1 second accuracy
    /// 3. Golden-section search to find precise maximum elevation within the pass
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let now = Date()
    /// let tomorrow = now.addingTimeInterval(24 * 3600)
    /// let passes = try orbit.predictPasses(for: observer, from: now, to: tomorrow, minElevationDeg: 10)
    ///
    /// for pass in passes {
    ///     print("AOS: \(pass.aos.time) at \(pass.aos.azimuthDeg)°")
    ///     print("MAX: \(pass.max.time) at \(pass.max.elevationDeg)° elevation")
    ///     print("LOS: \(pass.los.time) at \(pass.los.azimuthDeg)°")
    ///     print("Duration: \(pass.duration) seconds")
    /// }
    /// ```
    ///
    /// - Note: Algorithm based on Vallado, "Fundamentals of Astrodynamics and Applications"
    public func predictPasses(
        for observer: Observer,
        from start: Date,
        to end: Date,
        minElevationDeg: Double = 0,
        stepSeconds: Double = 30
    ) throws -> [PassWindow] {
        var passes: [PassWindow] = []

        var currentTime = start
        var previousElevation: Double?
        var passStartTime: Date?

        // Coarse search for passes
        while currentTime <= end {
            let topo = try topocentric(at: currentTime, for: observer, applyRefraction: false)
            let currentElevation = topo.elevationDeg

            if let prevElev = previousElevation {
                // Detect AOS: crossing from below to above minimum elevation
                if prevElev < minElevationDeg && currentElevation >= minElevationDeg {
                    passStartTime = currentTime.addingTimeInterval(-stepSeconds)
                }

                // Detect LOS: crossing from above to below minimum elevation
                if prevElev >= minElevationDeg && currentElevation < minElevationDeg {
                    if let startTime = passStartTime {
                        // We found a complete pass, now refine it
                        let passEndTime = currentTime

                        // Refine AOS time
                        let aosTime = try refineElevationCrossing(
                            observer: observer,
                            t1: startTime,
                            t2: startTime.addingTimeInterval(stepSeconds),
                            targetElevation: minElevationDeg,
                            risingEdge: true
                        )

                        // Refine LOS time
                        let losTime = try refineElevationCrossing(
                            observer: observer,
                            t1: passEndTime.addingTimeInterval(-stepSeconds),
                            t2: passEndTime,
                            targetElevation: minElevationDeg,
                            risingEdge: false
                        )

                        // Find maximum elevation within the pass
                        let maxResult = try findMaxElevation(
                            observer: observer,
                            t1: aosTime,
                            t2: losTime
                        )

                        // Get azimuth at AOS and LOS
                        let aosAzimuth = try topocentric(at: aosTime, for: observer).azimuthDeg
                        let losAzimuth = try topocentric(at: losTime, for: observer).azimuthDeg

                        let pass = PassWindow(
                            aos: PassWindow.Point(time: aosTime, azimuthDeg: aosAzimuth),
                            max: (time: maxResult.time, elevationDeg: maxResult.elevation, azimuthDeg: maxResult.azimuth),
                            los: PassWindow.Point(time: losTime, azimuthDeg: losAzimuth)
                        )

                        passes.append(pass)
                        passStartTime = nil
                    }
                }
            }

            previousElevation = currentElevation
            currentTime = currentTime.addingTimeInterval(stepSeconds)
        }

        return passes
    }
}

// MARK: - Pass Prediction Helpers

extension Orbit {
    /// Refines the time of an elevation crossing using bisection search.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - t1: Start of search interval
    ///   - t2: End of search interval
    ///   - targetElevation: The elevation angle to find
    ///   - risingEdge: True for AOS (rising), false for LOS (falling)
    /// - Returns: The refined time of the elevation crossing
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    private func refineElevationCrossing(
        observer: Observer,
        t1: Date,
        t2: Date,
        targetElevation: Double,
        risingEdge: Bool
    ) throws -> Date {
        var left = t1
        var right = t2
        let tolerance: TimeInterval = 1.0 // 1 second accuracy

        while right.timeIntervalSince(left) > tolerance {
            let mid = left.addingTimeInterval(right.timeIntervalSince(left) / 2.0)
            let topo = try topocentric(at: mid, for: observer, applyRefraction: false)
            let midElevation = topo.elevationDeg

            if risingEdge {
                // For AOS, we want the time when elevation crosses upward
                if midElevation < targetElevation {
                    left = mid
                } else {
                    right = mid
                }
            } else {
                // For LOS, we want the time when elevation crosses downward
                if midElevation > targetElevation {
                    left = mid
                } else {
                    right = mid
                }
            }
        }

        return left.addingTimeInterval(right.timeIntervalSince(left) / 2.0)
    }

    /// Finds the maximum elevation within a pass using golden-section search.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - t1: Start of search interval (AOS time)
    ///   - t2: End of search interval (LOS time)
    /// - Returns: Tuple of (time, elevation, azimuth) at maximum
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    private func findMaxElevation(
        observer: Observer,
        t1: Date,
        t2: Date
    ) throws -> (time: Date, elevation: Double, azimuth: Double) {
        let phi = (1.0 + sqrt(5.0)) / 2.0 // Golden ratio
        let resphi = 2.0 - phi

        var a = t1
        var b = t2
        let tolerance: TimeInterval = 1.0 // 1 second accuracy

        // Initial probe points
        var c = a.addingTimeInterval(b.timeIntervalSince(a) * resphi)
        var d = a.addingTimeInterval(b.timeIntervalSince(a) * (1.0 - resphi))

        var topoC = try topocentric(at: c, for: observer, applyRefraction: false)
        var topoD = try topocentric(at: d, for: observer, applyRefraction: false)
        var fc = topoC.elevationDeg
        var fd = topoD.elevationDeg

        while b.timeIntervalSince(a) > tolerance {
            if fc > fd {
                b = d
                d = c
                fd = fc
                topoD = topoC
                c = a.addingTimeInterval(b.timeIntervalSince(a) * resphi)
                topoC = try topocentric(at: c, for: observer, applyRefraction: false)
                fc = topoC.elevationDeg
            } else {
                a = c
                c = d
                fc = fd
                topoC = topoD
                d = a.addingTimeInterval(b.timeIntervalSince(a) * (1.0 - resphi))
                topoD = try topocentric(at: d, for: observer, applyRefraction: false)
                fd = topoD.elevationDeg
            }
        }

        // Return the point with higher elevation
        if fc > fd {
            return (time: c, elevation: topoC.elevationDeg, azimuth: topoC.azimuthDeg)
        } else {
            return (time: d, elevation: topoD.elevationDeg, azimuth: topoD.azimuthDeg)
        }
    }
}

//
//  PassPrediction.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// One pass of a satellite over an observer: rise (AOS), highest point, and set (LOS).
///
/// ## Example Usage
/// ```swift
/// let passes = try sgp4.predictPasses(for: observer, from: now, to: now.addingTimeInterval(86400),
///                                     minElevationDeg: 10)
/// for pass in passes {
///     print("Rise \(pass.aos.time) at \(pass.aos.azimuthDeg)°")
///     print("Max  \(pass.culmination.elevationDeg)° at \(pass.culmination.time)")
///     print("Set  \(pass.los.time) at \(pass.los.azimuthDeg)°")
/// }
/// ```
public struct PassWindow: Hashable, Codable, Sendable {

    // MARK: - Nested Types

    /// A moment in a pass and where the satellite is in the sky at that moment.
    public struct Event: Hashable, Codable, Sendable {
        /// When the event happens
        public let time: Date

        /// Azimuth in degrees clockwise from true north (0 to 360)
        public let azimuthDeg: Degrees

        /// Elevation in degrees above the horizon
        public let elevationDeg: Degrees

        /// Creates a pass event.
        ///
        /// - Parameters:
        ///   - time: When the event happens
        ///   - azimuthDeg: Azimuth in degrees clockwise from true north
        ///   - elevationDeg: Elevation in degrees above the horizon
        public init(time: Date, azimuthDeg: Degrees, elevationDeg: Degrees) {
            self.time = time
            self.azimuthDeg = azimuthDeg
            self.elevationDeg = elevationDeg
        }
    }

    // MARK: - Properties

    /// Acquisition of signal: the satellite rises above the minimum elevation.
    /// If `beginsBeforeSearch` is true, this is the start of the search window instead.
    public let aos: Event

    /// Culmination: the highest point of the pass
    public let culmination: Event

    /// Loss of signal: the satellite sets below the minimum elevation.
    /// If `endsAfterSearch` is true, this is the end of the search window instead.
    public let los: Event

    /// True when the satellite was already up at the start of the search window
    public let beginsBeforeSearch: Bool

    /// True when the satellite was still up at the end of the search window
    public let endsAfterSearch: Bool

    /// Time from AOS to LOS in seconds
    public var duration: TimeInterval {
        return los.time.timeIntervalSince(aos.time)
    }

    // MARK: - Initialization

    /// Creates a pass.
    ///
    /// - Parameters:
    ///   - aos: Rise above the minimum elevation (or the search start)
    ///   - culmination: Highest point of the pass
    ///   - los: Set below the minimum elevation (or the search end)
    ///   - beginsBeforeSearch: Whether the satellite was already up when the search began
    ///   - endsAfterSearch: Whether the satellite was still up when the search ended
    public init(aos: Event, culmination: Event, los: Event,
                beginsBeforeSearch: Bool = false, endsAfterSearch: Bool = false) {
        self.aos = aos
        self.culmination = culmination
        self.los = los
        self.beginsBeforeSearch = beginsBeforeSearch
        self.endsAfterSearch = endsAfterSearch
    }
}

// MARK: - Propagator Pass Prediction

extension Propagator {
    /// Finds every pass above a minimum elevation within a time window.
    ///
    /// - Parameters:
    ///   - observer: The observer's location
    ///   - start: Start of the search window
    ///   - end: End of the search window
    ///   - minElevationDeg: Elevation that counts as "up" (default 0°, the geometric horizon)
    ///   - stepSeconds: Coarse sampling interval (default 30 s)
    /// - Returns: Passes in time order. A pass in progress at either end of the window is
    ///            included and flagged with `beginsBeforeSearch` or `endsAfterSearch`.
    /// - Throws: Any error thrown by the propagator
    ///
    /// ## Algorithm
    /// 1. Sample elevation every `stepSeconds`.
    /// 2. Where consecutive samples straddle the minimum elevation, bisect to find AOS or
    ///    LOS to within 0.1 s.
    /// 3. Where a sample is a local peak but still below the minimum, search the
    ///    surrounding interval for the true peak. This catches passes that are shorter
    ///    than the sampling step.
    /// 4. Golden-section search between AOS and LOS for the culmination.
    ///
    /// - Note: Elevations are geometric (no refraction).
    public func predictPasses(
        for observer: Observer,
        from start: Date,
        to end: Date,
        minElevationDeg: Degrees = 0,
        stepSeconds: Double = 30
    ) throws -> [PassWindow] {
        // The observer's position and local axes never change, so compute them once
        let frame = ObserverFrame(observer)
        let times = sampleTimes(from: start, to: end, stepSeconds: stepSeconds)
        let elevations = try times.map { try elevation(at: $0, for: frame) }
        let isUp: (Int) -> Bool = { elevations[$0] >= minElevationDeg }

        var passes: [PassWindow] = []
        var riseTime: Date? = times.first.flatMap { isUp(0) ? $0 : nil }
        var risesBeforeSearch = riseTime != nil

        for index in times.indices.dropFirst() {
            let previous = index - 1

            if !isUp(previous) && isUp(index) {
                // Rising through the minimum elevation
                riseTime = try crossingTime(between: times[previous], and: times[index],
                                            for: frame, elevationDeg: minElevationDeg)
            } else if isUp(previous) && !isUp(index), let rise = riseTime {
                // Setting through the minimum elevation
                let set = try crossingTime(between: times[previous], and: times[index],
                                           for: frame, elevationDeg: minElevationDeg)
                passes.append(try makePass(from: rise, to: set, for: frame,
                                           beginsBeforeSearch: risesBeforeSearch, endsAfterSearch: false))
                riseTime = nil
                risesBeforeSearch = false
            } else if index >= 2, !isUp(index), !isUp(previous),
                      elevations[previous] >= elevations[previous - 1], elevations[previous] >= elevations[index] {
                // A sampled peak below the minimum: a short pass may hide between samples
                let peak = try culmination(between: times[previous - 1], and: times[index], for: frame)
                if peak.elevationDeg >= minElevationDeg {
                    let rise = try crossingTime(between: times[previous - 1], and: peak.time,
                                                for: frame, elevationDeg: minElevationDeg)
                    let set = try crossingTime(between: peak.time, and: times[index],
                                               for: frame, elevationDeg: minElevationDeg)
                    passes.append(try makePass(from: rise, to: set, for: frame,
                                               beginsBeforeSearch: false, endsAfterSearch: false))
                }
            }
        }

        // Still up when the window closes
        if let rise = riseTime, let last = times.last {
            passes.append(try makePass(from: rise, to: last, for: frame,
                                       beginsBeforeSearch: risesBeforeSearch, endsAfterSearch: true))
        }
        return passes
    }
}

// MARK: - Pass Prediction Helpers

extension Propagator {
    /// Geometric elevation of the satellite from the observer.
    private func elevation(at time: Date, for observer: ObserverFrame) throws -> Degrees {
        try topocentric(at: time, from: observer).elevationDeg
    }

    /// Builds a pass with its culmination and the look angles at each event.
    private func makePass(from rise: Date, to set: Date, for observer: ObserverFrame,
                          beginsBeforeSearch: Bool, endsAfterSearch: Bool) throws -> PassWindow {
        let aos = try topocentric(at: rise, from: observer)
        let los = try topocentric(at: set, from: observer)
        return PassWindow(
            aos: PassWindow.Event(time: rise, azimuthDeg: aos.azimuthDeg, elevationDeg: aos.elevationDeg),
            culmination: try culmination(between: rise, and: set, for: observer),
            los: PassWindow.Event(time: set, azimuthDeg: los.azimuthDeg, elevationDeg: los.elevationDeg),
            beginsBeforeSearch: beginsBeforeSearch,
            endsAfterSearch: endsAfterSearch
        )
    }

    /// Bisection for the time elevation crosses a value, given that it is on opposite
    /// sides of that value at the two ends of the interval. Accurate to 0.1 s.
    private func crossingTime(between start: Date, and end: Date, for observer: ObserverFrame,
                              elevationDeg target: Degrees) throws -> Date {
        let tolerance: TimeInterval = 0.1
        var low = start
        var high = end
        let startIsUp = try elevation(at: start, for: observer) >= target

        while high.timeIntervalSince(low) > tolerance {
            let mid = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
            if (try elevation(at: mid, for: observer) >= target) == startIsUp {
                low = mid
            } else {
                high = mid
            }
        }
        return low.addingTimeInterval(high.timeIntervalSince(low) / 2)
    }

    /// Golden-section search for the highest elevation in an interval, accurate to 0.1 s.
    ///
    /// Assumes a single peak in the interval, which holds within one pass.
    private func culmination(between start: Date, and end: Date, for observer: ObserverFrame) throws -> PassWindow.Event {
        let tolerance: TimeInterval = 0.1
        let invPhi = (sqrt(5.0) - 1) / 2   // 1/φ ≈ 0.618

        var low = start
        var high = end
        var left = high.addingTimeInterval(-invPhi * high.timeIntervalSince(low))
        var right = low.addingTimeInterval(invPhi * high.timeIntervalSince(low))
        var leftElevation = try elevation(at: left, for: observer)
        var rightElevation = try elevation(at: right, for: observer)

        while high.timeIntervalSince(low) > tolerance {
            if leftElevation > rightElevation {
                high = right
                right = left
                rightElevation = leftElevation
                left = high.addingTimeInterval(-invPhi * high.timeIntervalSince(low))
                leftElevation = try elevation(at: left, for: observer)
            } else {
                low = left
                left = right
                leftElevation = rightElevation
                right = low.addingTimeInterval(invPhi * high.timeIntervalSince(low))
                rightElevation = try elevation(at: right, for: observer)
            }
        }

        let peakTime = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
        let peak = try topocentric(at: peakTime, from: observer)
        return PassWindow.Event(time: peakTime, azimuthDeg: peak.azimuthDeg, elevationDeg: peak.elevationDeg)
    }
}

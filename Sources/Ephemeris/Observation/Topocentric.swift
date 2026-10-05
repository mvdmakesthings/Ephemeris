//
//  Topocentric.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Where a satellite appears from an observer's location: the values an antenna needs.
///
/// ## Coordinate System
/// - **Azimuth**: Clockwise from true north (0° = N, 90° = E, 180° = S, 270° = W)
/// - **Elevation**: Above the horizon (0° = horizon, 90° = zenith, negative = below)
/// - **Range**: Straight-line distance from observer to satellite
/// - **Range rate**: How fast the range is changing (positive = receding, negative =
///   approaching). Multiply by −f/c for the Doppler shift at frequency f.
///
/// ## Example Usage
/// ```swift
/// let topo = try sgp4.topocentric(at: Date(), for: observer)
/// print("Az: \(topo.azimuthDeg)°, El: \(topo.elevationDeg)°")
/// print("Range: \(topo.rangeKm) km, Rate: \(topo.rangeRateKmPerSec) km/s")
/// ```
public struct Topocentric: Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Azimuth in degrees clockwise from true north (0 to 360)
    public let azimuthDeg: Degrees

    /// Elevation in degrees above the horizon (-90 to 90)
    public let elevationDeg: Degrees

    /// Distance from observer to satellite in kilometers
    public let rangeKm: Double

    /// Rate of change of range in km/s (positive = moving away)
    public let rangeRateKmPerSec: Double

    // MARK: - Initialization

    /// Creates topocentric coordinates.
    ///
    /// - Parameters:
    ///   - azimuthDeg: Azimuth in degrees clockwise from true north (0 to 360)
    ///   - elevationDeg: Elevation in degrees above the horizon (-90 to 90)
    ///   - rangeKm: Distance from observer to satellite in kilometers
    ///   - rangeRateKmPerSec: Rate of change of range in km/s (positive = moving away)
    public init(azimuthDeg: Degrees, elevationDeg: Degrees, rangeKm: Double, rangeRateKmPerSec: Double) {
        self.azimuthDeg = azimuthDeg
        self.elevationDeg = elevationDeg
        self.rangeKm = rangeKm
        self.rangeRateKmPerSec = rangeRateKmPerSec
    }
}

// MARK: - Propagator Look Angles

extension Propagator {
    /// Calculates where the satellite appears from an observer's location.
    ///
    /// - Parameters:
    ///   - date: The time of interest
    ///   - observer: The observer's location
    ///   - applyRefraction: Whether to report apparent (refracted) elevation instead of
    ///     geometric elevation (default `false`)
    /// - Returns: Azimuth, elevation, range and range rate
    /// - Throws: Any error thrown by the propagator
    ///
    /// ## Algorithm
    /// 1. Propagate the inertial state vector and rotate it into ECEF using GMST
    /// 2. Express the satellite's position relative to the observer in East-North-Up
    /// 3. Convert ENU to azimuth, elevation and range
    /// 4. Project the Earth-relative velocity onto the line of sight for range rate
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let topo = try sgp4.topocentric(at: Date(), for: observer)
    /// print("Az: \(topo.azimuthDeg)°, El: \(topo.elevationDeg)°")
    /// ```
    ///
    /// - Note: Reference: Vallado, "Fundamentals of Astrodynamics and Applications", Section 4.4
    public func topocentric(at date: Date, for observer: Observer, applyRefraction: Bool = false) throws -> Topocentric {
        try topocentric(at: date, from: ObserverFrame(observer), applyRefraction: applyRefraction)
    }

    /// Look angles using an observer frame built once by the caller, for loops over time.
    func topocentric(at date: Date, from frame: ObserverFrame, applyRefraction: Bool = false) throws -> Topocentric {
        // Propagate, then rotate the inertial state into the Earth-fixed frame by GMST
        let satellite = CoordinateTransforms.eciToECEF(try stateVector(at: date), gmst: date.greenwichMeanSiderealTime)
        return frame.topocentric(of: satellite, applyRefraction: applyRefraction)
    }
}

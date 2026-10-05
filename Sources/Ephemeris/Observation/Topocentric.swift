//
//  Topocentric.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/21/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents topocentric (observer-relative) coordinates of a satellite.
///
/// `Topocentric` describes a satellite's position as seen from a specific observer
/// location on Earth. The coordinates use the horizontal coordinate system, which
/// is intuitive for tracking and pointing antennas or telescopes.
///
/// ## Coordinate System
/// - **Azimuth**: Horizontal angle measured clockwise from north (0° = North, 90° = East, 180° = South, 270° = West)
/// - **Elevation**: Vertical angle above the horizon (0° = horizon, 90° = zenith, negative = below horizon)
/// - **Range**: Straight-line distance from observer to satellite in kilometers
/// - **Range Rate**: Rate of change of range in km/s (positive = moving away, negative = approaching)
///
/// ## Example Usage
/// ```swift
/// let topo = try orbit.topocentric(at: Date(), for: observer)
/// print("Az: \(topo.azimuthDeg)°, El: \(topo.elevationDeg)°")
/// print("Range: \(topo.rangeKm) km, Rate: \(topo.rangeRateKmPerSec) km/s")
/// ```
///
/// - Note: This type is frozen for ABI stability. New functionality will be added
///         through extension methods rather than new stored properties.
@frozen public struct Topocentric {
    // MARK: - Properties

    /// Azimuth angle in degrees (0-360).
    /// Measured clockwise from true north: 0° = North, 90° = East, 180° = South, 270° = West.
    public let azimuthDeg: Double

    /// Elevation angle in degrees (-90 to 90).
    /// Angle above the horizon: 0° = horizon, 90° = zenith, negative = below horizon.
    public let elevationDeg: Double

    /// Slant range (distance) from observer to satellite in kilometers.
    public let rangeKm: Double

    /// Range rate (rate of change of distance) in kilometers per second.
    /// Positive values indicate the satellite is moving away from the observer,
    /// negative values indicate the satellite is approaching.
    public let rangeRateKmPerSec: Double

    // MARK: - Initialization

    /// Creates topocentric coordinates.
    ///
    /// - Parameters:
    ///   - azimuthDeg: Azimuth angle in degrees (0-360)
    ///   - elevationDeg: Elevation angle in degrees (-90 to 90)
    ///   - rangeKm: Distance in kilometers
    ///   - rangeRateKmPerSec: Range rate in km/s
    public init(azimuthDeg: Double, elevationDeg: Double, rangeKm: Double, rangeRateKmPerSec: Double) {
        self.azimuthDeg = azimuthDeg
        self.elevationDeg = elevationDeg
        self.rangeKm = rangeKm
        self.rangeRateKmPerSec = rangeRateKmPerSec
    }
}

// MARK: - Codable Conformance

extension Topocentric: Codable {}

// MARK: - Equatable Conformance

extension Topocentric: Equatable {}

// MARK: - Propagator Topocentric Calculation

extension Propagator {
    /// Calculates topocentric (observer-relative) coordinates for the satellite.
    ///
    /// This method computes the satellite's position as seen from a specific observer
    /// location on Earth, returning azimuth, elevation, range, and range rate.
    ///
    /// - Parameters:
    ///   - date: The date and time for the calculation
    ///   - observer: The observer's location on Earth
    ///   - applyRefraction: Whether to apply atmospheric refraction correction (default: false)
    /// - Returns: Topocentric coordinates (azimuth, elevation, range, range rate)
    /// - Throws: Any error thrown by the propagator
    ///
    /// ## Example
    /// ```swift
    /// let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
    /// let topo = try orbit.topocentric(at: Date(), for: observer)
    /// print("Az: \(topo.azimuthDeg)°, El: \(topo.elevationDeg)°")
    /// ```
    ///
    /// - Note: Coordinate transformations follow Vallado, "Fundamentals of Astrodynamics"
    public func topocentric(at date: Date, for observer: Observer, applyRefraction: Bool = false) throws -> Topocentric {
        // Get Julian date and GMST
        let julianDate = date.julianDate
        let gmst = Date.greenwichSideRealTime(from: julianDate)

        // Calculate satellite position and velocity in ECI frame
        let state = try stateVector(at: date)
        let eciPosition = state.position
        let eciVelocity = state.velocity

        // Transform satellite position and velocity to ECEF
        let satECEF = CoordinateTransforms.eciToECEF(eciPosition: eciPosition, gmst: gmst)
        let satVelECEF = CoordinateTransforms.eciVelocityToECEF(eciPosition: eciPosition, eciVelocity: eciVelocity, gmst: gmst)

        // Calculate observer position in ECEF
        let obsECEF = CoordinateTransforms.geodeticToECEF(
            latitudeDeg: observer.latitudeDeg,
            longitudeDeg: observer.longitudeDeg,
            altitudeMeters: observer.altitudeMeters
        )

        // Transform to ENU (local observer frame)
        let enu = CoordinateTransforms.ecefToENU(
            ecefPosition: satECEF,
            observerECEF: obsECEF,
            observerLatDeg: observer.latitudeDeg,
            observerLonDeg: observer.longitudeDeg
        )

        // Calculate azimuth, elevation, and range
        let (azimuth, elevation, range) = CoordinateTransforms.enuToAzEl(enu: enu)

        // Apply refraction correction if requested
        let correctedElevation = applyRefraction ? CoordinateTransforms.applyRefraction(elevationDeg: elevation) : elevation

        // Calculate range rate (rate of change of distance)
        // Project velocity onto the line-of-sight vector
        let relativePos = satECEF.subtract(obsECEF)
        let rangeRate = relativePos.dot(satVelECEF) / range

        return Topocentric(
            azimuthDeg: azimuth,
            elevationDeg: correctedElevation,
            rangeKm: range,
            rangeRateKmPerSec: rangeRate
        )
    }
}

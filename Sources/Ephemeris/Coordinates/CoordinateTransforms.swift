//
//  CoordinateTransforms.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// Conversions between the coordinate systems used in satellite tracking.
///
/// ## Coordinate Systems
/// - **ECI / TEME (Earth-Centered Inertial)**: Non-rotating, origin at Earth's center.
///   Propagators produce positions here.
/// - **ECEF (Earth-Centered, Earth-Fixed)**: Rotates with the Earth.
/// - **Geodetic**: Latitude, longitude and height on the WGS-84 ellipsoid.
/// - **ENU (East-North-Up)**: Local tangent plane at an observer, which gives azimuth
///   and elevation.
///
/// The pipeline from a propagator to an antenna is:
/// ```
/// ECI  ──(GMST)──▶  ECEF  ──(observer)──▶  ENU  ──▶  azimuth, elevation, range
///                     │
///                     └──▶  geodetic latitude, longitude, altitude
/// ```
///
/// ## References
/// - Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.)
/// - Montenbruck & Gill, "Satellite Orbits" (Springer, 2000)
public enum CoordinateTransforms {

    // MARK: - Geodetic ↔ ECEF

    /// Converts a geodetic position to ECEF coordinates.
    ///
    /// - Parameter position: Geodetic latitude, longitude and height on the WGS-84 ellipsoid
    /// - Returns: Position in the ECEF frame (km)
    ///
    /// ## Algorithm
    /// ```
    /// N = a / sqrt(1 - e²·sin²(lat))       radius of curvature in the prime vertical
    /// X = (N + h)·cos(lat)·cos(lon)
    /// Y = (N + h)·cos(lat)·sin(lon)
    /// Z = (N·(1 - e²) + h)·sin(lat)
    /// ```
    /// where `a` is the equatorial radius and `e²` the ellipsoid's eccentricity squared.
    ///
    /// - Note: Reference: Vallado, Section 3.5
    public static func geodeticToECEF(_ position: GeodeticPosition) -> Vector3D {
        let lat = position.latitudeDeg.inRadians()
        let lon = position.longitudeDeg.inRadians()
        let alt = position.altitudeKm

        let a = PhysicalConstants.Earth.semiMajorAxis
        let e2 = PhysicalConstants.Earth.eccentricitySquared

        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let primeVerticalRadius = a / sqrt(1.0 - e2 * sinLat * sinLat)

        return Vector3D(
            x: (primeVerticalRadius + alt) * cosLat * cos(lon),
            y: (primeVerticalRadius + alt) * cosLat * sin(lon),
            z: (primeVerticalRadius * (1.0 - e2) + alt) * sinLat
        )
    }

    /// Converts ECEF coordinates to a geodetic position.
    ///
    /// The inverse of `geodeticToECEF(_:)`. Geodetic latitude is measured to the ellipsoid
    /// normal, not to Earth's center, so it differs from geocentric latitude by up to about
    /// 0.19° at mid-latitudes.
    ///
    /// - Parameter ecef: Position in the ECEF frame (km)
    /// - Returns: Geodetic latitude, longitude and height on the WGS-84 ellipsoid
    ///
    /// ## Algorithm
    /// Fixed-point iteration on latitude, which reaches sub-millimeter precision in a few
    /// iterations for any point outside Earth's core:
    /// ```
    /// p = sqrt(X² + Y²)
    /// lon = atan2(Y, X)
    /// repeat:
    ///     N = a / sqrt(1 - e²·sin²(lat))
    ///     lat = atan2(Z + e²·N·sin(lat), p)
    /// h = p·cos(lat) + Z·sin(lat) - a·sqrt(1 - e²·sin²(lat))
    /// ```
    /// This height expression stays well conditioned at the poles, unlike `p / cos(lat) - N`.
    ///
    /// ## Example
    /// ```swift
    /// let position = CoordinateTransforms.ecefToGeodetic(Vector3D(x: 6524.834, y: 6862.875, z: 6448.296))
    /// // latitudeDeg ≈ 34.3525, longitudeDeg ≈ 46.4464, altitudeKm ≈ 5085.22
    /// ```
    ///
    /// - Note: Reference: Vallado, Section 3.4, Algorithm 12 and Example 3-3
    public static func ecefToGeodetic(_ ecef: Vector3D) -> GeodeticPosition {
        let a = PhysicalConstants.Earth.semiMajorAxis
        let e2 = PhysicalConstants.Earth.eccentricitySquared

        let p = sqrt(ecef.x * ecef.x + ecef.y * ecef.y)
        let longitude = atan2(ecef.y, ecef.x)

        // Initial guess: latitude for a point on the ellipsoid surface
        var latitude = atan2(ecef.z, p * (1.0 - e2))
        for _ in 0..<10 {
            let sinLat = sin(latitude)
            let primeVerticalRadius = a / sqrt(1.0 - e2 * sinLat * sinLat)
            let nextLatitude = atan2(ecef.z + e2 * primeVerticalRadius * sinLat, p)
            let change = abs(nextLatitude - latitude)
            latitude = nextLatitude
            if change < 1e-12 {
                break
            }
        }

        let sinLat = sin(latitude)
        let altitude = p * cos(latitude) + ecef.z * sinLat - a * sqrt(1.0 - e2 * sinLat * sinLat)

        return GeodeticPosition(latitudeDeg: latitude.inDegrees(), longitudeDeg: longitude.inDegrees(), altitudeKm: altitude)
    }

    // MARK: - ECI → ECEF

    /// Rotates an inertial position into the Earth-fixed frame.
    ///
    /// - Parameters:
    ///   - position: Position in the ECI/TEME frame (km)
    ///   - gmst: Greenwich Mean Sidereal Time (rad)
    /// - Returns: Position in the ECEF frame (km)
    ///
    /// ## Algorithm
    /// A rotation of −GMST about the Z axis:
    /// ```
    /// X_ecef =  cos(GMST)·X_eci + sin(GMST)·Y_eci
    /// Y_ecef = -sin(GMST)·X_eci + cos(GMST)·Y_eci
    /// Z_ecef =  Z_eci
    /// ```
    ///
    /// - Note: Reference: Vallado, Section 3.7. For TEME this is the TEME → PEF rotation;
    ///         polar motion (a few meters) is neglected.
    public static func eciToECEF(_ position: Vector3D, gmst: Radians) -> Vector3D {
        let cosGMST = cos(gmst)
        let sinGMST = sin(gmst)
        return Vector3D(
            x: cosGMST * position.x + sinGMST * position.y,
            y: -sinGMST * position.x + cosGMST * position.y,
            z: position.z
        )
    }

    /// Rotates an inertial state vector into the Earth-fixed frame.
    ///
    /// The velocity is relative to the rotating Earth, so it loses the part due to Earth's
    /// rotation. That is the velocity an observer on the ground sees, and the one range
    /// rate (Doppler) is computed from.
    ///
    /// - Parameters:
    ///   - state: Position (km) and velocity (km/s) in the ECI/TEME frame
    ///   - gmst: Greenwich Mean Sidereal Time (rad)
    /// - Returns: Position (km) and Earth-relative velocity (km/s) in the ECEF frame
    ///
    /// ## Algorithm
    /// ```
    /// r_ecef = R(GMST)·r_eci
    /// v_ecef = R(GMST)·v_eci − ω⊕ × r_ecef,   where ω⊕ × r = (−ω⊕·y, ω⊕·x, 0)
    /// ```
    ///
    /// - Note: Reference: Vallado, Section 3.7
    public static func eciToECEF(_ state: StateVector, gmst: Radians) -> StateVector {
        let omega = PhysicalConstants.Earth.rotationRate
        let position = eciToECEF(state.position, gmst: gmst)
        let rotatedVelocity = eciToECEF(state.velocity, gmst: gmst)
        let velocity = Vector3D(
            x: rotatedVelocity.x + omega * position.y,
            y: rotatedVelocity.y - omega * position.x,
            z: rotatedVelocity.z
        )
        return StateVector(position: position, velocity: velocity)
    }

    // MARK: - ECEF → ENU

    /// Expresses an ECEF position relative to an observer in the local East-North-Up frame.
    ///
    /// - Parameters:
    ///   - position: Position in the ECEF frame (km)
    ///   - observer: The observer's geodetic position
    /// - Returns: The position relative to the observer in ENU coordinates (km)
    ///
    /// ## Algorithm
    /// With `d` = target − observer in ECEF:
    /// ```
    /// E = -sin(lon)·dx + cos(lon)·dy
    /// N = -sin(lat)·cos(lon)·dx - sin(lat)·sin(lon)·dy + cos(lat)·dz
    /// U =  cos(lat)·cos(lon)·dx + cos(lat)·sin(lon)·dy + sin(lat)·dz
    /// ```
    ///
    /// - Note: Reference: Montenbruck & Gill, Section 5.4.1
    public static func ecefToENU(_ position: Vector3D, observer: GeodeticPosition) -> Vector3D {
        let d = position - geodeticToECEF(observer)

        let lat = observer.latitudeDeg.inRadians()
        let lon = observer.longitudeDeg.inRadians()
        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let sinLon = sin(lon)
        let cosLon = cos(lon)

        return Vector3D(
            x: -sinLon * d.x + cosLon * d.y,
            y: -sinLat * cosLon * d.x - sinLat * sinLon * d.y + cosLat * d.z,
            z: cosLat * cosLon * d.x + cosLat * sinLon * d.y + sinLat * d.z
        )
    }

    // MARK: - ENU → Look Angles

    /// Converts an ENU vector to azimuth, elevation and range.
    ///
    /// - Parameter enu: Position relative to the observer in ENU coordinates (km)
    /// - Returns: Azimuth (degrees clockwise from north, 0-360), elevation (degrees above
    ///            the horizon) and range (km)
    ///
    /// ## Algorithm
    /// ```
    /// azimuth   = atan2(E, N)
    /// elevation = atan2(U, sqrt(E² + N²))
    /// range     = sqrt(E² + N² + U²)
    /// ```
    public static func enuToAzEl(_ enu: Vector3D) -> (azimuthDeg: Degrees, elevationDeg: Degrees, rangeKm: Double) {
        let horizontalDistance = sqrt(enu.x * enu.x + enu.y * enu.y)
        let elevation = atan2(enu.z, horizontalDistance).inDegrees()
        var azimuth = atan2(enu.x, enu.y).inDegrees()
        if azimuth < 0 {
            azimuth += 360.0
        }
        return (azimuth, elevation, enu.magnitude)
    }

    // MARK: - Atmospheric Refraction

    /// Converts a geometric (true) elevation to the apparent elevation seen through the
    /// atmosphere.
    ///
    /// Refraction bends light downward, so objects near the horizon look higher than they
    /// are: about 0.5° at the horizon, falling to under 0.01° above 45°.
    ///
    /// ## Sæmundsson Formula
    /// ```
    /// R = 1.02 / tan(h + 10.3 / (h + 5.11))     arcminutes, h = true elevation in degrees
    /// ```
    /// This is the form for true elevation as input. (Bennett's formula is its inverse,
    /// taking apparent elevation.)
    ///
    /// - Parameter trueElevationDeg: Geometric elevation in degrees
    /// - Returns: Apparent elevation in degrees. Values below −1° are returned unchanged.
    ///
    /// - Note: Assumes 10 °C and 1010 mbar. This is an optical model; radio refraction
    ///         depends on humidity and is typically somewhat larger near the horizon.
    /// - Note: Reference: Meeus, "Astronomical Algorithms" (2nd ed.), Eq. 16.4
    public static func apparentElevation(fromTrueElevationDeg trueElevationDeg: Degrees) -> Degrees {
        // Refraction is unpredictable well below the horizon
        guard trueElevationDeg > -1.0 else {
            return trueElevationDeg
        }
        let h = trueElevationDeg + 10.3 / (trueElevationDeg + 5.11)
        // The formula dips slightly below zero right at the zenith; refraction cannot
        let refractionArcMinutes = max(0.0, 1.02 / tan(h.inRadians()))
        return trueElevationDeg + refractionArcMinutes / 60.0
    }
}

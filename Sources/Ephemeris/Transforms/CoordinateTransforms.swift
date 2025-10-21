//
//  CoordinateTransforms.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation

/// A three-dimensional vector representing position or velocity.
///
/// Used for coordinate transformations and calculations in various reference frames:
/// - ECI (Earth-Centered Inertial)
/// - ECEF (Earth-Centered, Earth-Fixed)
/// - ENU (East-North-Up, local tangent plane)
public struct Vector3D {
    /// X component
    public let x: Double
    
    /// Y component
    public let y: Double
    
    /// Z component
    public let z: Double
    
    /// Creates a 3D vector.
    ///
    /// - Parameters:
    ///   - x: X component
    ///   - y: Y component
    ///   - z: Z component
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Calculates the magnitude (length) of the vector.
    ///
    /// - Returns: The magnitude of the vector
    public var magnitude: Double {
        return sqrt(x * x + y * y + z * z)
    }
    
    /// Subtracts another vector from this vector.
    ///
    /// - Parameter other: The vector to subtract
    /// - Returns: The resulting vector
    public func subtract(_ other: Vector3D) -> Vector3D {
        return Vector3D(x: x - other.x, y: y - other.y, z: z - other.z)
    }
    
    /// Calculates the dot product with another vector.
    ///
    /// - Parameter other: The other vector
    /// - Returns: The dot product
    public func dot(_ other: Vector3D) -> Double {
        return x * other.x + y * other.y + z * other.z
    }
}

/// Utilities for coordinate system transformations used in satellite tracking.
///
/// This structure provides static methods for converting between different coordinate systems:
/// - Geodetic (latitude, longitude, altitude) → ECEF
/// - ECI → ECEF (using GMST rotation)
/// - ECEF → ENU (local East-North-Up frame)
///
/// ## Coordinate Systems
/// - **ECI (Earth-Centered Inertial)**: Non-rotating frame with origin at Earth's center
/// - **ECEF (Earth-Centered, Earth-Fixed)**: Rotating frame fixed to Earth's surface
/// - **Geodetic**: Latitude, longitude, altitude relative to WGS-84 ellipsoid
/// - **ENU (East-North-Up)**: Local tangent plane at observer's location
///
/// ## References
/// - Vallado, "Fundamentals of Astrodynamics and Applications" (4th ed.)
/// - Montenbruck & Gill, "Satellite Orbits" (Springer, 2000)
public struct CoordinateTransforms {
    private init() {}
    
    // MARK: - Geodetic to ECEF
    
    /// Converts geodetic coordinates (latitude, longitude, altitude) to ECEF coordinates.
    ///
    /// This conversion uses the WGS-84 ellipsoid model to transform from geodetic coordinates
    /// (commonly used for GPS and maps) to Cartesian ECEF coordinates.
    ///
    /// - Parameters:
    ///   - latitudeDeg: Geodetic latitude in degrees (-90 to 90)
    ///   - longitudeDeg: Geodetic longitude in degrees (-180 to 180)
    ///   - altitudeMeters: Height above the WGS-84 ellipsoid in meters
    /// - Returns: Position vector in ECEF frame (kilometers)
    ///
    /// ## Algorithm
    /// Uses the standard geodetic to ECEF conversion with WGS-84 ellipsoid parameters:
    /// ```
    /// N = a / sqrt(1 - e²·sin²(lat))
    /// X = (N + h)·cos(lat)·cos(lon)
    /// Y = (N + h)·cos(lat)·sin(lon)
    /// Z = (N·(1 - e²) + h)·sin(lat)
    /// ```
    /// where:
    /// - a = semi-major axis (equatorial radius)
    /// - e² = eccentricity squared
    /// - h = altitude
    ///
    /// ## Example
    /// ```swift
    /// let ecef = CoordinateTransforms.geodeticToECEF(
    ///     latitudeDeg: 38.2542,
    ///     longitudeDeg: -85.7594,
    ///     altitudeMeters: 140
    /// )
    /// ```
    ///
    /// - Note: Reference: Vallado, Section 3.5
    public static func geodeticToECEF(latitudeDeg: Double, longitudeDeg: Double, altitudeMeters: Double) -> Vector3D {
        let lat = latitudeDeg.inRadians()
        let lon = longitudeDeg.inRadians()
        let alt = altitudeMeters / 1000.0 // Convert to km
        
        let a = PhysicalConstants.Earth.semiMajorAxis // km
        let e2 = PhysicalConstants.Earth.eccentricitySquared
        
        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let sinLon = sin(lon)
        let cosLon = cos(lon)
        
        // Radius of curvature in the prime vertical
        let N = a / sqrt(1.0 - e2 * sinLat * sinLat)
        
        // ECEF coordinates
        let x = (N + alt) * cosLat * cosLon
        let y = (N + alt) * cosLat * sinLon
        let z = (N * (1.0 - e2) + alt) * sinLat
        
        return Vector3D(x: x, y: y, z: z)
    }
    
    // MARK: - ECI to ECEF
    
    /// Converts ECI (Earth-Centered Inertial) coordinates to ECEF (Earth-Centered, Earth-Fixed).
    ///
    /// This transformation accounts for Earth's rotation by using Greenwich Sidereal Time (GST).
    /// The rotation is about the Z-axis by the angle of GST.
    ///
    /// - Parameters:
    ///   - eciPosition: Position vector in ECI frame (kilometers)
    ///   - gmst: Greenwich Mean Sidereal Time in radians
    /// - Returns: Position vector in ECEF frame (kilometers)
    ///
    /// ## Algorithm
    /// Rotates the ECI coordinates by -GMST about the Z-axis:
    /// ```
    /// X_ecef =  cos(GMST)·X_eci + sin(GMST)·Y_eci
    /// Y_ecef = -sin(GMST)·X_eci + cos(GMST)·Y_eci
    /// Z_ecef = Z_eci
    /// ```
    ///
    /// ## Example
    /// ```swift
    /// let gmst = Date.greenwichSideRealTime(from: julianDay)
    /// let ecef = CoordinateTransforms.eciToECEF(eciPosition: eciPos, gmst: gmst)
    /// ```
    ///
    /// - Note: Reference: Vallado, Section 3.7
    public static func eciToECEF(eciPosition: Vector3D, gmst: Radians) -> Vector3D {
        let cosGMST = cos(gmst)
        let sinGMST = sin(gmst)
        
        // Rotation about Z-axis by -GMST (ECI to ECEF is opposite direction)
        let x = cosGMST * eciPosition.x + sinGMST * eciPosition.y
        let y = -sinGMST * eciPosition.x + cosGMST * eciPosition.y
        let z = eciPosition.z
        
        return Vector3D(x: x, y: y, z: z)
    }
    
    /// Converts ECI (Earth-Centered Inertial) velocity to ECEF (Earth-Centered, Earth-Fixed).
    ///
    /// Similar to position transformation, but also accounts for the cross product
    /// with Earth's rotation vector.
    ///
    /// - Parameters:
    ///   - eciPosition: Position vector in ECI frame (kilometers)
    ///   - eciVelocity: Velocity vector in ECI frame (km/s)
    ///   - gmst: Greenwich Mean Sidereal Time in radians
    /// - Returns: Velocity vector in ECEF frame (km/s)
    ///
    /// ## Algorithm
    /// Transforms velocity accounting for Earth's rotation:
    /// ```
    /// V_ecef = R(GMST)·V_eci - ω_earth × R(GMST)·R_eci
    /// ```
    /// where ω_earth is Earth's angular velocity vector
    ///
    /// - Note: Reference: Vallado, Section 3.7
    public static func eciVelocityToECEF(eciPosition: Vector3D, eciVelocity: Vector3D, gmst: Radians) -> Vector3D {
        let cosGMST = cos(gmst)
        let sinGMST = sin(gmst)
        
        // Rotate velocity vector
        let vx = cosGMST * eciVelocity.x + sinGMST * eciVelocity.y
        let vy = -sinGMST * eciVelocity.x + cosGMST * eciVelocity.y
        let vz = eciVelocity.z
        
        // Earth's rotation rate in rad/s
        let omegaEarth = PhysicalConstants.Earth.radsPerDay / PhysicalConstants.Time.secondsPerDay
        
        // Rotate position vector to ECEF
        let rx = cosGMST * eciPosition.x + sinGMST * eciPosition.y
        let ry = -sinGMST * eciPosition.x + cosGMST * eciPosition.y
        
        // Subtract the velocity component due to Earth's rotation: ω × r
        // For rotation about Z-axis: ω × r = [-ω·y, ω·x, 0]
        let vxCorrected = vx - (-omegaEarth * ry)
        let vyCorrected = vy - (omegaEarth * rx)
        let vzCorrected = vz
        
        return Vector3D(x: vxCorrected, y: vyCorrected, z: vzCorrected)
    }
    
    // MARK: - ECEF to ENU
    
    /// Converts ECEF coordinates to ENU (East-North-Up) local tangent plane coordinates.
    ///
    /// The ENU frame is a local coordinate system centered at the observer's location,
    /// with axes pointing East, North, and Up. This is the natural frame for expressing
    /// azimuth and elevation angles.
    ///
    /// - Parameters:
    ///   - ecefPosition: Position vector in ECEF frame (kilometers)
    ///   - observerECEF: Observer's position in ECEF frame (kilometers)
    ///   - observerLatDeg: Observer's geodetic latitude in degrees
    ///   - observerLonDeg: Observer's geodetic longitude in degrees
    /// - Returns: Position vector in ENU frame (kilometers)
    ///
    /// ## Algorithm
    /// 1. Compute the relative position vector (satellite - observer) in ECEF
    /// 2. Apply rotation matrix to transform to ENU frame:
    /// ```
    /// E = -sin(lon)·dx + cos(lon)·dy
    /// N = -sin(lat)·cos(lon)·dx - sin(lat)·sin(lon)·dy + cos(lat)·dz
    /// U =  cos(lat)·cos(lon)·dx + cos(lat)·sin(lon)·dy + sin(lat)·dz
    /// ```
    ///
    /// ## Example
    /// ```swift
    /// let enu = CoordinateTransforms.ecefToENU(
    ///     ecefPosition: satECEF,
    ///     observerECEF: obsECEF,
    ///     observerLatDeg: 38.2542,
    ///     observerLonDeg: -85.7594
    /// )
    /// ```
    ///
    /// - Note: Reference: Montenbruck & Gill, Section 5.4.1
    public static func ecefToENU(ecefPosition: Vector3D, observerECEF: Vector3D, observerLatDeg: Double, observerLonDeg: Double) -> Vector3D {
        // Relative position vector
        let dx = ecefPosition.x - observerECEF.x
        let dy = ecefPosition.y - observerECEF.y
        let dz = ecefPosition.z - observerECEF.z
        
        let lat = observerLatDeg.inRadians()
        let lon = observerLonDeg.inRadians()
        
        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let sinLon = sin(lon)
        let cosLon = cos(lon)
        
        // Transform to ENU frame
        let e = -sinLon * dx + cosLon * dy
        let n = -sinLat * cosLon * dx - sinLat * sinLon * dy + cosLat * dz
        let u = cosLat * cosLon * dx + cosLat * sinLon * dy + sinLat * dz
        
        return Vector3D(x: e, y: n, z: u)
    }
    
    // MARK: - ENU to Azimuth/Elevation
    
    /// Converts ENU coordinates to azimuth and elevation angles.
    ///
    /// - Parameter enu: Position vector in ENU frame (kilometers)
    /// - Returns: Tuple of (azimuth in degrees, elevation in degrees, range in kilometers)
    ///
    /// ## Algorithm
    /// - Azimuth: `atan2(East, North)` converted to 0-360° clockwise from north
    /// - Elevation: `atan2(Up, sqrt(East² + North²))`
    /// - Range: `sqrt(East² + North² + Up²)`
    ///
    /// ## Example
    /// ```swift
    /// let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enuVector)
    /// print("Azimuth: \(az)°, Elevation: \(el)°, Range: \(range) km")
    /// ```
    ///
    /// - Note: Azimuth is measured clockwise from north (0° = North, 90° = East, 180° = South, 270° = West)
    public static func enuToAzEl(enu: Vector3D) -> (azimuthDeg: Double, elevationDeg: Double, rangeKm: Double) {
        let range = enu.magnitude
        let horizontalDistance = sqrt(enu.x * enu.x + enu.y * enu.y)
        
        // Elevation angle
        let elevation = atan2(enu.z, horizontalDistance).inDegrees()
        
        // Azimuth angle (clockwise from north)
        var azimuth = atan2(enu.x, enu.y).inDegrees()
        
        // Normalize to 0-360°
        if azimuth < 0 {
            azimuth += 360.0
        }
        
        return (azimuth, elevation, range)
    }
    
    // MARK: - Atmospheric Refraction
    
    /// Applies atmospheric refraction correction to elevation angle.
    ///
    /// Uses the Bennett formula for atmospheric refraction, which is valid
    /// for elevation angles above -1°. Below this, refraction becomes highly
    /// variable and unpredictable.
    ///
    /// - Parameter elevationDeg: True elevation angle in degrees
    /// - Returns: Apparent elevation angle in degrees (after refraction)
    ///
    /// ## Bennett Formula
    /// For elevation angles above 15°:
    /// ```
    /// R ≈ cot(el + 7.31/(el + 4.4))
    /// ```
    /// where R is the refraction in arc minutes
    ///
    /// ## Example
    /// ```swift
    /// let apparentElevation = CoordinateTransforms.applyRefraction(elevationDeg: 10.0)
    /// ```
    ///
    /// - Note: This is a simplified model using standard atmospheric conditions
    ///         (temperature 10°C, pressure 1010 mbar). For precise work, use
    ///         actual weather data.
    /// - Note: Reference: Bennett, "The Calculation of Astronomical Refraction in Marine Navigation"
    public static func applyRefraction(elevationDeg: Double) -> Double {
        // Don't apply refraction if satellite is significantly below horizon
        guard elevationDeg > -1.0 else {
            return elevationDeg
        }
        
        // Bennett's formula (in arc minutes)
        let h = elevationDeg + 7.31 / (elevationDeg + 4.4)
        let R = 1.0 / tan(h.inRadians()) // Refraction in arc minutes
        
        // Convert to degrees and add to elevation
        return elevationDeg + R / 60.0
    }
}

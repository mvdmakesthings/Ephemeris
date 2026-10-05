//
//  Propagator.swift
//  Ephemeris
//
//  Common interface for orbit propagators and the Earth-fixed position built on it.
//

import Foundation

/// A satellite's position and velocity in an Earth-centered inertial frame.
///
/// For `SGP4` the frame is TEME (True Equator, Mean Equinox of date), which is the frame
/// TLEs are defined in. For the two-body `KeplerianOrbit` it is a generic ECI frame.
/// Either way, rotating by Greenwich Mean Sidereal Time gives Earth-fixed coordinates.
public struct StateVector: Hashable, Codable, Sendable {

    /// Position vector (km)
    public let position: Vector3D

    /// Velocity vector (km/s)
    public let velocity: Vector3D

    /// Creates a state vector.
    ///
    /// - Parameters:
    ///   - position: Position vector (km)
    ///   - velocity: Velocity vector (km/s)
    public init(position: Vector3D, velocity: Vector3D) {
        self.position = position
        self.velocity = velocity
    }
}

/// A type that can compute a satellite's inertial state at any time.
///
/// Conforming types get position, topocentric look angles, pass prediction, ground
/// tracks and sky tracks for free through protocol extensions, so every propagator
/// shares the same observer geometry code.
///
/// ## Conforming Types
/// - `SGP4`: The standard model for TLE data. Use this for real tracking.
/// - `KeplerianOrbit`: Two-body Keplerian motion. Simple and educational, but it ignores
///   Earth's oblateness and drag, so it drifts quickly from reality.
///
/// ## Example
/// ```swift
/// let propagator: Propagator = try SGP4(tle: tle)
/// let position = try propagator.calculatePosition(at: Date())
/// ```
public protocol Propagator {
    /// Computes the inertial position and velocity at a given time.
    ///
    /// - Parameter date: The time of interest
    /// - Returns: Position (km) and velocity (km/s) in an Earth-centered inertial frame
    /// - Throws: An error if the orbit cannot be propagated to that time
    func stateVector(at date: Date) throws -> StateVector
}

// MARK: - Geodetic Position

extension Propagator {
    /// Calculates the geographic position of the satellite at a specific time.
    ///
    /// The calculation involves:
    /// 1. Propagating the inertial state vector to the requested time
    /// 2. Rotating into the Earth-fixed (ECEF) frame using Greenwich Mean Sidereal Time
    /// 3. Converting ECEF to WGS-84 geodetic latitude, longitude, and ellipsoidal height
    ///
    /// - Parameter date: The date and time for which to calculate the position
    /// - Returns: A `GeodeticPosition` object containing latitude, longitude, and altitude
    /// - Throws: Any error thrown by the propagator
    ///
    /// ## Example
    /// ```swift
    /// let position = try propagator.calculatePosition(at: Date())
    /// print("Satellite is at \(position.latitudeDeg)°N, \(position.longitudeDeg)°E")
    /// print("Altitude: \(position.altitudeKm) km")
    /// ```
    ///
    /// - Note: Latitude is geodetic (measured to the ellipsoid normal) and altitude is the
    ///         height above the WGS-84 ellipsoid, matching what GPS and maps report.
    public func calculatePosition(at date: Date) throws -> GeodeticPosition {
        let inertial = try stateVector(at: date).position
        let earthFixed = CoordinateTransforms.eciToECEF(inertial, gmst: date.greenwichMeanSiderealTime)
        return CoordinateTransforms.ecefToGeodetic(earthFixed)
    }
}

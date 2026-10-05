//
//  Orbit.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// Represents an orbital path using Keplerian orbital elements.
///
/// `Orbit` encapsulates the six classical orbital elements that describe
/// the shape, size, and orientation of a satellite's orbit around Earth.
/// It conforms to the `Orbitable` protocol and provides methods to calculate
/// satellite positions at any given time.
///
/// ## Example Usage
/// ```swift
/// let tleString = """
/// ISS (ZARYA)
/// 1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
/// 2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
/// """
/// let tle = try TwoLineElement(from: tleString)
/// let orbit = Orbit(from: tle)
/// let position = try orbit.calculatePosition(at: Date())
/// print("Latitude: \(position.latitude)°")
/// ```
///
/// - Note: Orbital calculations are based on Keplerian orbital mechanics and use
///         WGS84 physical constants for accuracy.
public struct Orbit: Orbitable {

    // MARK: - Orbital Elements

    // MARK: Size of Orbit

    /// Describes half of the size of the orbit path from Perigee to Apogee.
    /// Denoted by ( a ) in (km)
    public let semimajorAxis: Double

    // MARK: Shape of Orbit

    /// Describes the shape of the orbital path.
    /// Denoted by ( e ) with a value between 0 and 1.
    public let eccentricity: Double

    // MARK: Orientation of Orbit

    /// The "tilt" in degrees from the vectors perpendicular to the orbital and equatorial planes
    /// Denoted by ( i ) and is in degrees 0–180°
    public let inclination: Degrees

    /// The "swivel" of the orbital plane in degrees in reference to the vernal equinox to the 'node' that corresponds
    /// with the object passing the equator in a northerly direction.
    /// Denoted by ( Ω ) in degrees
    public let rightAscensionOfAscendingNode: Degrees

    /// Describes the orientation of perigee on the orbital plane with reference to the right ascension of the ascending node
    /// Denoted by ( ω ) in degrees
    public let argumentOfPerigee: Degrees

    // MARK: Position of Craft

    /// The true angle between the position of the craft relative to perigee along the orbital path.
    /// Denoted as (ν or θ)
    /// Range between 0–360°
    ///
    /// - Note: This is a computed property that calculates the true anomaly from the mean anomaly
    /// using the eccentric anomaly as an intermediate step. If the calculation cannot be performed
    /// (e.g., due to singularities), it returns the mean anomaly as a fallback.
    public var trueAnomaly: Degrees {
        return calculateTrueAnomalyFromMean()
    }

    /// The position of the craft with respect to the mean motion.
    /// Denoted as (M)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     n = mean motion
    ///     t = time in motion
    ///     M = Current mean anomaly
    ///     M(Δt) = n(Δt) + M
    public let meanAnomaly: Degrees

    /// The average speed an object moves throughout an orbit.
    /// Denoted as (n)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     M = Gravitational Constant of Earth (3.986004418e^5 km^3/ s^2)
    ///     a = Semimajor axis
    ///     Mean Motion (n) = sqrt( M / a^3 )
    public let meanMotion: Double

    // MARK: - Computed Properties

    /// Apogee altitude in kilometers above Earth's surface.
    ///
    /// Apogee is the point in the orbit where the satellite is farthest from Earth's center.
    /// This property calculates the altitude at apogee above Earth's surface by subtracting
    /// Earth's mean radius from the apogee distance.
    ///
    /// - Returns: Altitude at apogee in kilometers
    ///
    /// ## Formula
    /// ```
    /// apogee_altitude = a(1 + e) - R_earth
    /// ```
    /// where:
    /// - `a` is the semimajor axis
    /// - `e` is the eccentricity
    /// - `R_earth` is Earth's mean radius (6371.0 km)
    ///
    /// ## Example
    /// ```swift
    /// let orbit = Orbit(from: tle)
    /// print("Apogee altitude: \(orbit.apogeeAltitude) km")
    /// ```
    ///
    /// - Note: Marked as `@inlinable` for performance in hot paths.
    @inlinable
    public var apogeeAltitude: Double {
        return semimajorAxis * (1 + eccentricity) - PhysicalConstants.Earth.radius
    }

    /// Perigee altitude in kilometers above Earth's surface.
    ///
    /// Perigee is the point in the orbit where the satellite is closest to Earth's center.
    /// This property calculates the altitude at perigee above Earth's surface by subtracting
    /// Earth's mean radius from the perigee distance.
    ///
    /// - Returns: Altitude at perigee in kilometers
    ///
    /// ## Formula
    /// ```
    /// perigee_altitude = a(1 - e) - R_earth
    /// ```
    /// where:
    /// - `a` is the semimajor axis
    /// - `e` is the eccentricity
    /// - `R_earth` is Earth's mean radius (6371.0 km)
    ///
    /// ## Example
    /// ```swift
    /// let orbit = Orbit(from: tle)
    /// print("Perigee altitude: \(orbit.perigeeAltitude) km")
    /// ```
    ///
    /// - Note: Marked as `@inlinable` for performance in hot paths.
    @inlinable
    public var perigeeAltitude: Double {
        return semimajorAxis * (1 - eccentricity) - PhysicalConstants.Earth.radius
    }

    /// Orbital period in seconds.
    ///
    /// The orbital period is the time it takes for the satellite to complete one full orbit
    /// around Earth. This is calculated using Kepler's third law.
    ///
    /// - Returns: Orbital period in seconds
    ///
    /// ## Formula
    /// ```
    /// T = 2π√(a³/μ)
    /// ```
    /// where:
    /// - `a` is the semimajor axis in km
    /// - `μ` is Earth's gravitational parameter (398600.4418 km³/s²)
    ///
    /// ## Example
    /// ```swift
    /// let orbit = Orbit(from: tle)
    /// let periodMinutes = orbit.orbitalPeriod / 60.0
    /// print("Orbital period: \(periodMinutes) minutes")
    /// ```
    ///
    /// - Note: For the ISS, this is approximately 92 minutes (5520 seconds)
    /// - Note: Marked as `@inlinable` for performance in hot paths.
    @inlinable
    public var orbitalPeriod: Double {
        return 2 * .pi * sqrt(pow(semimajorAxis, 3) / PhysicalConstants.Earth.µ)
    }

    // MARK: - Internal Properties

    internal let twoLineElement: TwoLineElement

    // MARK: - Initialization

    /// Creates an orbit from Two-Line Element (TLE) data.
    ///
    /// This initializer extracts orbital elements from a parsed TLE and calculates
    /// the semi-major axis from the mean motion value.
    ///
    /// - Parameter twoLineElement: A parsed Two-Line Element containing orbital data
    ///
    /// ## Example
    /// ```swift
    /// let tle = try TwoLineElement(from: tleString)
    /// let orbit = Orbit(from: tle)
    /// ```
    public init(from twoLineElement: TwoLineElement) {
        self.semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: twoLineElement.meanMotion)
        self.eccentricity = twoLineElement.eccentricity
        self.inclination = twoLineElement.inclination
        self.rightAscensionOfAscendingNode = twoLineElement.rightAscension
        self.argumentOfPerigee = twoLineElement.argumentOfPerigee
        self.meanMotion = twoLineElement.meanMotion
        self.meanAnomaly = twoLineElement.meanAnomaly
        self.twoLineElement = twoLineElement
    }

    // MARK: - Public Methods

    /// Calculates the ECI (Earth-Centered Inertial) position and velocity vectors.
    ///
    /// This internal method computes the satellite's state vector in the ECI frame,
    /// which is needed for topocentric calculations and other advanced operations.
    ///
    /// - Parameter date: The date and time for which to calculate the state vector
    /// - Returns: Tuple of (position vector in km, velocity vector in km/s) in ECI frame
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// - Note: Internal method used by calculatePosition and topocentric calculations
    func calculateECIStateVector(at date: Date) throws -> (position: Vector3D, velocity: Vector3D) {
        let julianDate = date.julianDate

        // Calculate 3 anomalies
        let currentMeanAnomaly = self.meanAnomalyForJulianDate(julianDate: julianDate)
        let currentEccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: self.eccentricity, meanAnomaly: currentMeanAnomaly)
        let currentTrueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: self.eccentricity, eccentricAnomaly: currentEccentricAnomaly)

        // Calculate the radius and position in the orbital plane
        let orbitalRadius = self.semimajorAxis * (1.0 - self.eccentricity * cos(currentEccentricAnomaly.inRadians()))

        // Position in orbital plane
        let xOrbital = orbitalRadius * cos(currentTrueAnomaly.inRadians())
        let yOrbital = orbitalRadius * sin(currentTrueAnomaly.inRadians())

        // Velocity in orbital plane (using vis-viva equation)
        let µ = PhysicalConstants.Earth.µ
        let h = sqrt(µ * self.semimajorAxis * (1.0 - self.eccentricity * self.eccentricity)) // Specific angular momentum
        let vxOrbital = -µ / h * sin(currentTrueAnomaly.inRadians())
        let vyOrbital = µ / h * (self.eccentricity + cos(currentTrueAnomaly.inRadians()))

        // Transform from orbital plane to ECI frame
        let argOfPerigeeRad = self.argumentOfPerigee.inRadians()
        let inclinationRad = self.inclination.inRadians()
        let raanRad = self.rightAscensionOfAscendingNode.inRadians()

        let cosω = cos(argOfPerigeeRad)
        let sinω = sin(argOfPerigeeRad)
        let cosΩ = cos(raanRad)
        let sinΩ = sin(raanRad)
        let cosi = cos(inclinationRad)
        let sini = sin(inclinationRad)

        // Position transformation to ECI
        let xECI = (cosΩ * cosω - sinΩ * sinω * cosi) * xOrbital + (-cosΩ * sinω - sinΩ * cosω * cosi) * yOrbital
        let yECI = (sinΩ * cosω + cosΩ * sinω * cosi) * xOrbital + (-sinΩ * sinω + cosΩ * cosω * cosi) * yOrbital
        let zECI = (sinω * sini) * xOrbital + (cosω * sini) * yOrbital

        // Velocity transformation to ECI
        let vxECI = (cosΩ * cosω - sinΩ * sinω * cosi) * vxOrbital + (-cosΩ * sinω - sinΩ * cosω * cosi) * vyOrbital
        let vyECI = (sinΩ * cosω + cosΩ * sinω * cosi) * vxOrbital + (-sinΩ * sinω + cosΩ * cosω * cosi) * vyOrbital
        let vzECI = (sinω * sini) * vxOrbital + (cosω * sini) * vyOrbital

        return (Vector3D(x: xECI, y: yECI, z: zECI), Vector3D(x: vxECI, y: vyECI, z: vzECI))
    }

    /// Calculates the geographic position of the satellite at a specific time.
    ///
    /// This method performs a complete orbital propagation from the epoch time to the
    /// specified date, calculating the satellite's position in Earth-centered, Earth-fixed
    /// (ECEF) coordinates and converting them to latitude, longitude, and altitude.
    ///
    /// The calculation involves:
    /// 1. Computing the current mean anomaly from the mean motion
    /// 2. Solving for eccentric anomaly using Newton-Raphson iteration
    /// 3. Calculating the true anomaly
    /// 4. Transforming from the orbital plane to the ECI frame
    /// 5. Rotating into the Earth-fixed (ECEF) frame using Greenwich Mean Sidereal Time
    /// 6. Converting ECEF to WGS-84 geodetic latitude, longitude, and ellipsoidal height
    ///
    /// - Parameter date: The date and time for which to calculate the position.
    ///                   If `nil`, uses the current date and time.
    /// - Returns: A `GeodeticPosition` object containing latitude, longitude, and altitude
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Example
    /// ```swift
    /// let position = try orbit.calculatePosition(at: Date())
    /// print("Satellite is at \(position.latitude)°N, \(position.longitude)°E")
    /// print("Altitude: \(position.altitude) km")
    /// ```
    ///
    /// - Note: Latitude is geodetic (measured to the ellipsoid normal) and altitude is the
    ///         height above the WGS-84 ellipsoid, matching what GPS and maps report.
    public func calculatePosition(at date: Date?) throws -> GeodeticPosition {
        let date = date ?? Date()

        // Satellite position in the inertial frame
        let (eciPosition, _) = try calculateECIStateVector(at: date)

        // Rotate into the Earth-fixed frame using sidereal time
        let julianDate = date.julianDate
        let gmst = Date.greenwichSideRealTime(from: julianDate)
        let ecefPosition = CoordinateTransforms.eciToECEF(eciPosition: eciPosition, gmst: gmst)

        // Convert to WGS-84 geodetic latitude, longitude, and height above the ellipsoid
        return CoordinateTransforms.ecefToGeodetic(ecef: ecefPosition)
    }
}

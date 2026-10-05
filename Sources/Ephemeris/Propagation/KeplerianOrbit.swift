//
//  KeplerianOrbit.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

/// An orbit described by the six classical Keplerian elements, propagated with two-body
/// motion.
///
/// Two-body motion treats the Earth as a point mass, so the orbit is a fixed ellipse and
/// the satellite simply moves around it. That makes this type ideal for learning what the
/// orbital elements mean and how Kepler's equation turns time into position.
///
/// It is **not** suitable for real tracking: it ignores Earth's oblateness (which turns a
/// low orbit's plane by several degrees per day) and drag. Use `SGP4` for TLE data.
///
/// ## Orbital Elements
/// - **Size**: semi-major axis `a`
/// - **Shape**: eccentricity `e`
/// - **Orientation**: inclination `i`, right ascension of the ascending node `Ω`,
///   argument of perigee `ω`
/// - **Position**: mean anomaly `M` at the epoch
///
/// ## Example Usage
/// ```swift
/// // From a TLE
/// let orbit = KeplerianOrbit(tle: try TwoLineElement(from: tleString))
/// print("Period: \(orbit.orbitalPeriod / 60) minutes")
///
/// // Or from elements you choose
/// let molniya = KeplerianOrbit(semimajorAxis: 26_600, eccentricity: 0.74, inclination: 63.4,
///                              rightAscensionOfAscendingNode: 0, argumentOfPerigee: 270,
///                              meanAnomaly: 0, epoch: Date())
/// let position = molniya.calculatePosition(at: Date().addingTimeInterval(3600))
/// ```
///
/// - Note: Reference: Vallado, "Fundamentals of Astrodynamics and Applications",
///         Chapter 2 (Kepler's equation) and Algorithm 10 (COE2RV).
public struct KeplerianOrbit: Propagator, Hashable, Codable, Sendable {

    // MARK: - Size and Shape

    /// Semi-major axis `a`: half the long axis of the ellipse (km)
    public let semimajorAxis: Double

    /// Eccentricity `e`: 0 is a circle, values toward 1 are increasingly elongated
    public let eccentricity: Double

    // MARK: - Orientation

    /// Inclination `i`: tilt of the orbital plane from the equator (degrees, 0-180)
    public let inclination: Degrees

    /// Right ascension of the ascending node `Ω`: where the orbit crosses the equator
    /// heading north, measured from the vernal equinox (degrees)
    public let rightAscensionOfAscendingNode: Degrees

    /// Argument of perigee `ω`: angle from the ascending node to perigee, in the orbital
    /// plane (degrees)
    public let argumentOfPerigee: Degrees

    // MARK: - Position at Epoch

    /// Mean anomaly `M` at the epoch (degrees). See `meanAnomaly(at:)` for other times.
    public let meanAnomaly: Degrees

    /// Mean motion `n`: average angular rate, in revolutions per day
    public let meanMotion: Double

    /// The instant the elements describe
    public let epoch: Date

    // MARK: - Derived Quantities

    /// Height of apogee (the farthest point) above the equatorial radius (km)
    ///
    /// ```
    /// apogee altitude = a(1 + e) − R⊕
    /// ```
    public var apogeeAltitude: Double {
        return semimajorAxis * (1 + eccentricity) - PhysicalConstants.Earth.semiMajorAxis
    }

    /// Height of perigee (the closest point) above the equatorial radius (km)
    ///
    /// ```
    /// perigee altitude = a(1 − e) − R⊕
    /// ```
    public var perigeeAltitude: Double {
        return semimajorAxis * (1 - eccentricity) - PhysicalConstants.Earth.semiMajorAxis
    }

    /// Time for one revolution, from Kepler's third law (seconds)
    ///
    /// ```
    /// T = 2π √(a³ / μ)
    /// ```
    /// About 92 minutes for the ISS.
    public var orbitalPeriod: Double {
        return 2 * .pi * sqrt(pow(semimajorAxis, 3) / PhysicalConstants.Earth.mu)
    }

    // MARK: - Initialization

    /// Creates an orbit from classical orbital elements.
    ///
    /// Mean motion is derived from the semi-major axis with Kepler's third law.
    ///
    /// - Parameters:
    ///   - semimajorAxis: Semi-major axis (km)
    ///   - eccentricity: Eccentricity, 0 ≤ e < 1
    ///   - inclination: Inclination (degrees)
    ///   - rightAscensionOfAscendingNode: Right ascension of the ascending node (degrees)
    ///   - argumentOfPerigee: Argument of perigee (degrees)
    ///   - meanAnomaly: Mean anomaly at the epoch (degrees)
    ///   - epoch: The instant the elements describe
    public init(semimajorAxis: Double, eccentricity: Double, inclination: Degrees,
                rightAscensionOfAscendingNode: Degrees, argumentOfPerigee: Degrees,
                meanAnomaly: Degrees, epoch: Date) {
        precondition((0..<1).contains(eccentricity), "Two-body elliptical orbits need 0 ≤ e < 1")
        self.semimajorAxis = semimajorAxis
        self.eccentricity = eccentricity
        self.inclination = inclination
        self.rightAscensionOfAscendingNode = rightAscensionOfAscendingNode
        self.argumentOfPerigee = argumentOfPerigee
        self.meanAnomaly = meanAnomaly
        self.meanMotion = Self.meanMotion(semimajorAxis: semimajorAxis)
        self.epoch = epoch
    }

    /// Creates an orbit from a TLE's elements, treating them as osculating Keplerian
    /// elements.
    ///
    /// The semi-major axis is derived from the TLE's mean motion with Kepler's third law.
    ///
    /// - Parameter tle: A parsed Two-Line Element set
    public init(tle: TwoLineElement) {
        self.semimajorAxis = Self.semimajorAxis(meanMotion: tle.meanMotion)
        self.eccentricity = tle.eccentricity
        self.inclination = tle.inclination
        self.rightAscensionOfAscendingNode = tle.rightAscensionOfAscendingNode
        self.argumentOfPerigee = tle.argumentOfPerigee
        self.meanAnomaly = tle.meanAnomaly
        self.meanMotion = tle.meanMotion
        self.epoch = tle.epoch
    }

    // MARK: - Anomalies Over Time

    /// The mean anomaly at a given time (degrees, 0-360).
    ///
    /// Mean anomaly grows at a constant rate, which is what makes it the "clock" of an orbit:
    /// ```
    /// M(t) = M₀ + n·(t − t₀)
    /// ```
    ///
    /// - Parameter date: The time of interest
    /// - Returns: Mean anomaly in degrees, normalized to 0-360
    public func meanAnomaly(at date: Date) -> Degrees {
        let days = date.timeIntervalSince(epoch) / PhysicalConstants.Time.secondsPerDay
        let anomaly = (meanAnomaly + meanMotion * days * 360.0).truncatingRemainder(dividingBy: 360.0)
        return anomaly < 0 ? anomaly + 360.0 : anomaly
    }

    /// The true anomaly at a given time: the actual angle from perigee to the satellite
    /// (degrees, 0-360).
    ///
    /// - Parameter date: The time of interest
    /// - Returns: True anomaly in degrees, normalized to 0-360
    public func trueAnomaly(at date: Date) -> Degrees {
        let eccentricAnomaly = Self.solveKeplersEquation(meanAnomaly: meanAnomaly(at: date), eccentricity: eccentricity)
        let anomaly = Self.trueAnomaly(eccentricAnomaly: eccentricAnomaly, eccentricity: eccentricity)
        return anomaly < 0 ? anomaly + 360.0 : anomaly
    }

    // MARK: - Propagator

    /// Calculates the inertial position and velocity with two-body motion.
    ///
    /// ## Algorithm
    /// 1. Advance the mean anomaly to the requested time
    /// 2. Solve Kepler's equation for the eccentric anomaly, then find the true anomaly
    /// 3. Position and velocity in the perifocal frame (x toward perigee, in the orbit plane):
    ///    ```
    ///    r = a(1 − e·cos E)
    ///    r_pqw = (r·cos ν, r·sin ν, 0)
    ///    v_pqw = (−μ/h·sin ν, μ/h·(e + cos ν), 0),   h = √(μ·a(1 − e²))
    ///    ```
    /// 4. Rotate to ECI by argument of perigee, inclination and node: R_z(Ω)·R_x(i)·R_z(ω)
    ///
    /// - Parameter date: The time of interest
    /// - Returns: Position (km) and velocity (km/s) in the ECI frame
    public func stateVector(at date: Date) -> StateVector {
        let mu = PhysicalConstants.Earth.mu
        let eccentricAnomaly = Self.solveKeplersEquation(meanAnomaly: meanAnomaly(at: date), eccentricity: eccentricity)
        let nu = Self.trueAnomaly(eccentricAnomaly: eccentricAnomaly, eccentricity: eccentricity).inRadians()

        // Perifocal (PQW) position and velocity
        let radius = semimajorAxis * (1.0 - eccentricity * cos(eccentricAnomaly.inRadians()))
        let angularMomentum = sqrt(mu * semimajorAxis * (1.0 - eccentricity * eccentricity))
        let positionPQW = Vector3D(x: radius * cos(nu), y: radius * sin(nu), z: 0)
        let velocityPQW = Vector3D(x: -mu / angularMomentum * sin(nu),
                                   y: mu / angularMomentum * (eccentricity + cos(nu)),
                                   z: 0)

        return StateVector(position: perifocalToECI(positionPQW), velocity: perifocalToECI(velocityPQW))
    }

    /// Rotates a perifocal (PQW) vector into the ECI frame: R_z(Ω)·R_x(i)·R_z(ω).
    private func perifocalToECI(_ vector: Vector3D) -> Vector3D {
        let cosO = cos(rightAscensionOfAscendingNode.inRadians())
        let sinO = sin(rightAscensionOfAscendingNode.inRadians())
        let cosW = cos(argumentOfPerigee.inRadians())
        let sinW = sin(argumentOfPerigee.inRadians())
        let cosI = cos(inclination.inRadians())
        let sinI = sin(inclination.inRadians())

        return Vector3D(
            x: (cosO * cosW - sinO * sinW * cosI) * vector.x + (-cosO * sinW - sinO * cosW * cosI) * vector.y,
            y: (sinO * cosW + cosO * sinW * cosI) * vector.x + (-sinO * sinW + cosO * cosW * cosI) * vector.y,
            z: (sinW * sinI) * vector.x + (cosW * sinI) * vector.y
        )
    }
}

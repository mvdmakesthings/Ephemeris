//
//  OrbitCalculations.swift
//  Ephemeris
//
//  Static calculation methods and helpers for orbital mechanics.
//  This file contains mathematical utilities used by the Orbit type.
//

import Foundation

// MARK: - Static Calculation Methods

extension Orbit {
    /// Calculates the semi-major axis from mean motion.
    ///
    /// Uses Kepler's Third Law to derive the semi-major axis (the "size" of the orbit)
    /// from the satellite's mean motion. The semi-major axis is half the distance between
    /// perigee (closest point) and apogee (farthest point).
    ///
    /// - Parameter meanMotion: Mean motion in revolutions per day
    /// - Returns: Semi-major axis in kilometers
    ///
    /// ## Formula
    /// Based on Kepler's Third Law: `a³ = µ/(n²)`
    /// - `a` = semi-major axis
    /// - `µ` = Earth's gravitational constant (398600.4418 km³/s²)
    /// - `n` = mean motion in radians/second
    ///
    /// ## Example
    /// ```swift
    /// let meanMotion = 15.5 // revolutions per day
    /// let semiMajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion)
    /// print("Semi-major axis: \(semiMajorAxis) km")
    /// ```
    ///
    /// - Note: Marked as `@inlinable` for performance in hot paths.
    @inlinable
    static func calculateSemimajorAxis(meanMotion: Double) -> Double {
        let earthsGravitationalConstant = PhysicalConstants.Earth.µ // km^3/s^2
        // Convert mean motion from revolutions/day to radians/second
        // revolutions/day * (2π radians/revolution) * (1 day/86400 seconds)
        let motionRadsPerSecond = meanMotion * 2.0 * .pi / PhysicalConstants.Time.secondsPerDay
        let semimajorAxis = pow(earthsGravitationalConstant / pow(motionRadsPerSecond, 2.0), 1.0 / 3.0)
        return semimajorAxis // km
    }

    /// Calculates the eccentric anomaly using Newton-Raphson iteration.
    ///
    /// The eccentric anomaly is an intermediate angular parameter that bridges the gap
    /// between mean anomaly (time-based position) and true anomaly (actual position).
    /// This method uses an iterative numerical method to solve Kepler's equation.
    ///
    /// - Parameters:
    ///   - eccentricity: Orbital eccentricity (0 for circular, approaching 1 for highly elliptical)
    ///   - meanAnomaly: Mean anomaly in degrees
    ///   - accuracy: Convergence accuracy (default: 0.00001). Iteration stops when change is less than this value
    ///   - maxIterations: Maximum number of iterations to prevent infinite loops (default: 500)
    /// - Returns: Eccentric anomaly in degrees
    ///
    /// ## Algorithm
    /// Solves Kepler's equation: `E - e·sin(E) = M` using Newton-Raphson method
    ///
    /// ## Example
    /// ```swift
    /// let E = Orbit.calculateEccentricAnomaly(eccentricity: 0.0167, meanAnomaly: 45.0)
    /// ```
    ///
    /// - Note: Reference: https://www.sciencedirect.com/topics/engineering/eccentric-anomaly
    /// - Note: Marked as `@inlinable` for performance in hot paths such as
    ///         position calculations and orbital propagation.
    @inlinable
    static func calculateEccentricAnomaly(eccentricity: Double, meanAnomaly: Degrees, accuracy: Double = PhysicalConstants.Calculation.defaultAccuracy, maxIterations: Int = PhysicalConstants.Calculation.maxIterations) -> Degrees {
        // Always convert degrees to radians before doing calculations
        let meanAnomaly: Radians = meanAnomaly.inRadians()
        var eccentricAnomaly: Radians = 0.0

        if meanAnomaly < .pi {
            eccentricAnomaly = meanAnomaly + eccentricity / 2
        } else {
            eccentricAnomaly = meanAnomaly - eccentricity / 2
        }

        var ratio = 1.0
        var iteration = 0

        repeat {
            let f = eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly
            let f2 = 1 - eccentricity * cos(eccentricAnomaly)
            ratio = f / f2
            eccentricAnomaly -= ratio
            iteration += 1
        } while (ratio > accuracy && iteration <= maxIterations)

        return eccentricAnomaly.inDegrees()
    }

    /// Calculates the true anomaly from the eccentric anomaly.
    ///
    /// The true anomaly is the actual angular position of the satellite in its orbit,
    /// measured from perigee (the closest point to Earth). This method converts from
    /// eccentric anomaly to true anomaly using the relationship between orbital geometry
    /// and eccentricity.
    ///
    /// - Parameters:
    ///   - eccentricity: Orbital eccentricity (must be < 1.0)
    ///   - eccentricAnomaly: Eccentric anomaly in degrees
    /// - Returns: True anomaly in degrees (0-360°)
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Example
    /// ```swift
    /// let trueAnomaly = try Orbit.calculateTrueAnomaly(
    ///     eccentricity: 0.0167,
    ///     eccentricAnomaly: 45.0
    /// )
    /// ```
    ///
    /// - Note: Formula uses `atan2` for proper quadrant handling
    /// - Note: Marked as `@inlinable` for performance in hot paths such as
    ///         position calculations and orbital propagation.
    @inlinable
    static func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Degrees) throws -> Degrees {
        if eccentricity >= 1 { throw CalculationError.reachedSingularity }
        let E = eccentricAnomaly.inRadians()
        let trueAnomaly = (2.0 * atan2(sqrt(1 + eccentricity) * sin(E), sqrt(1 - eccentricity) * cos(E))).inDegrees()
        return trueAnomaly
    }
}

// MARK: - Private Helper Methods

extension Orbit {
    /// Calculates the mean anomaly for a given Julian date.
    ///
    /// This method propagates the mean anomaly forward or backward in time from
    /// the TLE epoch using the mean motion.
    ///
    /// - Parameter julianDate: The Julian date for which to calculate mean anomaly
    /// - Returns: Mean anomaly in degrees (0-360°)
    func meanAnomalyForJulianDate(julianDate: Double) -> Double {
        let epochJulianDate = Date.julianDayFromEpoch(epochYear: twoLineElement.epochYear, epochDayFraction: twoLineElement.epochDay)
        let daysSinceEpoch = julianDate - epochJulianDate
        let revolutionsSinceEpoch = self.meanMotion * daysSinceEpoch
        let meanAnomalyForJulianDate = self.meanAnomaly + revolutionsSinceEpoch * PhysicalConstants.Angle.degreesPerCircle
        let fullRevolutions = floor(meanAnomalyForJulianDate / PhysicalConstants.Angle.degreesPerCircle)
        let adjustedMeanAnomalyForJulianDate = meanAnomalyForJulianDate - PhysicalConstants.Angle.degreesPerCircle * fullRevolutions

        return adjustedMeanAnomalyForJulianDate
    }

    /// Calculates the true anomaly from the mean anomaly.
    /// Uses eccentric anomaly as an intermediate calculation step.
    /// Returns the mean anomaly as a fallback if calculation fails (e.g., singularity).
    func calculateTrueAnomalyFromMean() -> Degrees {
        // Calculate eccentric anomaly from mean anomaly
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(
            eccentricity: self.eccentricity,
            meanAnomaly: self.meanAnomaly
        )

        // Try to calculate true anomaly from eccentric anomaly
        do {
            let trueAnomaly = try Orbit.calculateTrueAnomaly(
                eccentricity: self.eccentricity,
                eccentricAnomaly: eccentricAnomaly
            )
            return trueAnomaly
        } catch {
            // If calculation fails (e.g., singularity when e >= 1),
            // return mean anomaly as a safe fallback
            return self.meanAnomaly
        }
    }
}

// MARK: - Errors

/// Errors that can occur during orbital calculations.
public enum CalculationError: Int, Error {
    /// Indicates that a singularity was reached in the calculation, typically when eccentricity >= 1.0
    case reachedSingularity = 1
}

extension CalculationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reachedSingularity: return NSLocalizedString("Reached Singularity in calculation", comment: "reached singularity")
        }
    }
}

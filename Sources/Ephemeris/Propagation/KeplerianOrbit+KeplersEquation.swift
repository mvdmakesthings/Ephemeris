//
//  KeplerianOrbit+KeplersEquation.swift
//  Ephemeris
//
//  Kepler's third law and Kepler's equation: the math behind two-body propagation.
//

import Foundation

extension KeplerianOrbit {

    // MARK: - Kepler's Third Law

    /// Semi-major axis from mean motion, by Kepler's third law.
    ///
    /// ```
    /// a = (μ / n²)^(1/3),   n in rad/s
    /// ```
    ///
    /// - Parameter meanMotion: Mean motion (revolutions per day)
    /// - Returns: Semi-major axis (km). About 6,780 km for the ISS at 15.5 rev/day.
    static func semimajorAxis(meanMotion: Double) -> Double {
        let radiansPerSecond = meanMotion * 2.0 * .pi / PhysicalConstants.Time.secondsPerDay
        return pow(PhysicalConstants.Earth.mu / (radiansPerSecond * radiansPerSecond), 1.0 / 3.0)
    }

    /// Mean motion from semi-major axis, by Kepler's third law.
    ///
    /// ```
    /// n = √(μ / a³)   rad/s
    /// ```
    ///
    /// - Parameter semimajorAxis: Semi-major axis (km)
    /// - Returns: Mean motion (revolutions per day)
    static func meanMotion(semimajorAxis: Double) -> Double {
        let radiansPerSecond = sqrt(PhysicalConstants.Earth.mu / pow(semimajorAxis, 3))
        return radiansPerSecond * PhysicalConstants.Time.secondsPerDay / (2.0 * .pi)
    }

    // MARK: - Kepler's Equation

    /// Solves Kepler's equation for the eccentric anomaly with Newton-Raphson iteration.
    ///
    /// Kepler's equation links time (mean anomaly `M`) to geometry (eccentric anomaly `E`):
    /// ```
    /// M = E − e·sin(E)
    /// ```
    /// It has no closed-form solution for `E`, so each Newton step is
    /// ```
    /// E ← E − (E − e·sin E − M) / (1 − e·cos E)
    /// ```
    /// starting from `E = M ± e/2`. Convergence is quadratic: usually 3-5 steps.
    ///
    /// - Parameters:
    ///   - meanAnomaly: Mean anomaly (degrees)
    ///   - eccentricity: Eccentricity, 0 ≤ e < 1
    /// - Returns: Eccentric anomaly (degrees)
    ///
    /// - Note: Reference: Vallado, Algorithm 2 (KepEqtnE)
    static func solveKeplersEquation(meanAnomaly: Degrees, eccentricity: Double) -> Degrees {
        let tolerance = 1e-12   // radians
        let maxIterations = 50

        let meanAnomalyRadians = meanAnomaly.inRadians()
        var eccentricAnomaly = meanAnomalyRadians < .pi
            ? meanAnomalyRadians + eccentricity / 2
            : meanAnomalyRadians - eccentricity / 2

        for _ in 0..<maxIterations {
            let step = (eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomalyRadians)
                / (1 - eccentricity * cos(eccentricAnomaly))
            eccentricAnomaly -= step
            // The step can be negative, so compare its magnitude
            if abs(step) < tolerance {
                break
            }
        }
        return eccentricAnomaly.inDegrees()
    }

    /// True anomaly from eccentric anomaly.
    ///
    /// ```
    /// ν = 2·atan2(√(1 + e)·sin(E/2), √(1 − e)·cos(E/2))
    /// ```
    /// `atan2` keeps the result in the correct quadrant.
    ///
    /// - Parameters:
    ///   - eccentricAnomaly: Eccentric anomaly (degrees)
    ///   - eccentricity: Eccentricity, 0 ≤ e < 1
    /// - Returns: True anomaly (degrees, −180 to 180)
    static func trueAnomaly(eccentricAnomaly: Degrees, eccentricity: Double) -> Degrees {
        let halfE = eccentricAnomaly.inRadians() / 2
        return (2.0 * atan2(sqrt(1 + eccentricity) * sin(halfE), sqrt(1 - eccentricity) * cos(halfE))).inDegrees()
    }
}

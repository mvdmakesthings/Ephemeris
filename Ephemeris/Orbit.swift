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
    
    // MARK: - Size of Orbit
    
    /// Describes half of the size of the orbit path from Perigee to Apogee.
    /// Denoted by ( a ) in (km)
    public let semimajorAxis: Double
    
    // MARK: - Shape of Orbit
    
    /// Describes the shape of the orbital path.
    /// Denoted by ( e ) with a value between 0 and 1.
    public let eccentricity: Double
    
    // MARK: - Orientation of Orbit
    
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
    
    // MARK: - Position of Craft
    
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
    
    // MARK: - Private
    private let twoLineElement: TwoLineElement
    
    // MARK: - Initializers
    
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
    
    // MARK: - Functions
    
    /// Represents a geographic position with latitude, longitude, and altitude.
    ///
    /// This structure holds the calculated position of a satellite at a specific time,
    /// expressed in geographic coordinates relative to Earth's surface.
    public struct Position {
        /// Latitude in degrees (-90 to 90), where positive values indicate north
        public let latitude: Double
        /// Longitude in degrees (-180 to 180), where positive values indicate east
        public let longitude: Double
        /// Altitude in kilometers above Earth's surface
        public let altitude: Double
        
        /// Creates a position with the specified coordinates.
        ///
        /// - Parameters:
        ///   - latitude: Latitude in degrees (-90 to 90)
        ///   - longitude: Longitude in degrees (-180 to 180)
        ///   - altitude: Altitude in kilometers above Earth's surface
        public init(latitude: Double, longitude: Double, altitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
        }
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
    /// 4. Transforming from orbital plane to Earth-fixed coordinates
    /// 5. Accounting for Earth's rotation (sidereal time)
    ///
    /// - Parameter date: The date and time for which to calculate the position.
    ///                   If `nil`, uses the current date and time.
    /// - Returns: A `Position` object containing latitude, longitude, and altitude
    /// - Throws: `CalculationError.reachedSingularity` if eccentricity >= 1.0
    ///
    /// ## Example
    /// ```swift
    /// let position = try orbit.calculatePosition(at: Date())
    /// print("Satellite is at \(position.latitude)°N, \(position.longitude)°E")
    /// print("Altitude: \(position.altitude) km")
    /// ```
    ///
    /// - Note: Transform math based on https://www.csun.edu/~hcmth017/master/node20.html
    ///         Implementation inspired by ZeitSatTrack (Apache 2.0)
    public func calculatePosition(at date: Date?) throws -> Position {
        
        // Current parameters at this specific time.
        let julianDate = Date.julianDay(from: date ?? Date())!

        // Calculate 3 anomalies
        let currentMeanAnomaly = self.meanAnomalyForJulianDate(julianDate: julianDate)
        let currentEccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: self.eccentricity, meanAnomaly: currentMeanAnomaly)
        let currentTrueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: self.eccentricity, eccentricAnomaly: currentEccentricAnomaly)
        
        // Calculate the XYZ coordinates on the orbital plane
        let orbitalRadius = self.semimajorAxis - (self.semimajorAxis * self.eccentricity) * cos(currentEccentricAnomaly.inRadians())
        let x = orbitalRadius * cos(currentTrueAnomaly.inRadians())
        let y = orbitalRadius * sin(currentTrueAnomaly.inRadians())
        let z = 0.0
        
        // Rotate about z''' by the argument of perigee.
        let argOfPerigeeRads = self.argumentOfPerigee.inRadians()
        let xByPerigee = cos(argOfPerigeeRads) * x - sin(argOfPerigeeRads) * y
        let yByPerigee = sin(argOfPerigeeRads) * x + cos(argOfPerigeeRads) * y
        let zByPerigee = z
        
        // Rotate about x'' axis by inclination.
        let inclinationRads = self.inclination.inRadians()
        let xInclination = xByPerigee
        let yInclination = cos(inclinationRads) * yByPerigee - sin(inclinationRads) * zByPerigee
        let zInclination = sin(inclinationRads) * yByPerigee + cos(inclinationRads) * zByPerigee
        
        // Rotate about z' axis by right ascension of the ascending node.
        let raanRads = self.rightAscensionOfAscendingNode.inRadians()
        let xRaan = cos(raanRads) * xInclination - sin(raanRads) * yInclination
        let yRaan = sin(raanRads) * xInclination + cos(raanRads) * yInclination
        let zRaan = zInclination
        
        // Rotate about z axis by the rotation of the earth.
        let rotationFromGeocentric = Date.greenwichSideRealTime(from: julianDate)
        let rotationFromGeocentricRad = -rotationFromGeocentric
        let xFinal = cos(rotationFromGeocentricRad) * xRaan - sin(rotationFromGeocentricRad) * yRaan
        let yFinal = sin(rotationFromGeocentricRad) * xRaan + cos(rotationFromGeocentricRad) * yRaan
        let zFinal = zRaan
        
        // Geocoordinates
        let earthsRadius = PhysicalConstants.Earth.radius
        let latitude = 90.0 - acos(zFinal / sqrt(xFinal * xFinal + yFinal * yFinal + zFinal * zFinal)).inDegrees()
        let longitude = atan2(yFinal, xFinal).inDegrees()
        let altitude = orbitalRadius - earthsRadius

        return Position(latitude: latitude, longitude: longitude, altitude: altitude)
    }
}

// MARK: - Private Functions

extension Orbit {
    private func meanAnomalyForJulianDate(julianDate: Double) -> Double {
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
    private func calculateTrueAnomalyFromMean() -> Degrees {
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

// MARK: - Static Functions

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
    static func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Degrees) throws -> Degrees {
        if eccentricity >= 1 { throw CalculationError.reachedSingularity }
        let E = eccentricAnomaly.inRadians()
        let trueAnomaly = (2.0 * atan2(sqrt(1 + eccentricity) * sin(E), sqrt(1 - eccentricity) * cos(E))).inDegrees()
        return trueAnomaly
    }
}

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

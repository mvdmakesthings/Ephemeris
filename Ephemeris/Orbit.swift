//
//  Orbit.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

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

    /// Calculates the position of the orbiting object relative to earth.
    ///
    /// - Note:
    ///     Transform math used from https://www.csun.edu/~hcmth017/master/node20.html
    ///     Heavily inspired by ZeitSatTrack https://github.com/dhmspector/ZeitSatTrack Apache 2.0
    public func calculatePosition(at date: Date?) throws -> (x: Double, y: Double, z: Double) {
        
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
        let xInclination = xByPerigee;
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

        return (latitude, longitude, altitude)
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
            print("OE | Warning: Failed to calculate true anomaly, using mean anomaly as fallback")
            return self.meanAnomaly
        }
    }
}

// MARK: - Static Functions

extension Orbit {
    /// Used to describe the "size" of the orbit path which is half the distance between the perigee and apogee in km
    static func calculateSemimajorAxis(meanMotion: Double) -> Double {
        let earthsGravitationalConstant = PhysicalConstants.Earth.µ
        let motionRadsPerSecond = meanMotion / PhysicalConstants.Time.secondsPerDay
        let semimajorAxis = pow(earthsGravitationalConstant / (4.0 * pow(.pi, 2.0) * pow(motionRadsPerSecond, 2.0)), 1.0 / 3.0)
        return semimajorAxis // km
    }
    
    /// A helper variable that bridges the gap between the true anomaly (or the true position of an object from perigee)
    /// to the mean anomaly.
    ///
    /// https://www.sciencedirect.com/topics/engineering/eccentric-anomaly
    ///
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
            eccentricAnomaly = eccentricAnomaly - ratio
            iteration += 1
        } while (ratio > accuracy && iteration <= maxIterations)
        
        return eccentricAnomaly.inDegrees()
    }
    
    /// The true angle relative to perigee and the position of the object along its orbit path
    /// 
    static func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Degrees) throws -> Degrees {
        if eccentricity >= 1 { throw CalculationError.reachedSingularity }
        let E = eccentricAnomaly.inRadians()
        let trueAnomaly = (2.0 * atan2(sqrt(1 + eccentricity) * sin(E), sqrt(1 - eccentricity) * cos(E))).inDegrees()
        return trueAnomaly
    }
}

public enum CalculationError: Int, Error {
    case reachedSingularity = 1
}

extension CalculationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reachedSingularity: return NSLocalizedString("Reached Singularity in calculation", comment: "reached singularity")
        }
    }
}

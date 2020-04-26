//
//  Orbit.swift
//  SwiftSatTrack
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

public struct Orbit {
    
    // MARK: - Size of Orbit
    
    /// Describes half of the size of the orbit path from Perigee to Apogee.
    /// Denoted by ( a ) in (km)
    public let semimajorAxis: Double
    
    // MARK: - Shape of Orbit
    
    /// Describes the shape of the orbital path.
    /// Denoted by ( e ) with a value between 0 and 1.
    public let eccentricity: Double
    
    // MARK: - Orientation of Orbit
    
    /// The "tilt" in degrees from the vectors perpandicular to the orbital and equatorial planes
    /// Denoted by ( i ) and is in degrees 0–180°
    public let inclination: Degree
    
    /// The "swivel" of the orbital plane in degrees in reference to the vernal equinox to the 'node' that cooresponds
    /// with the object passing the equator in a northernly direction.
    /// Denoted by ( Ω ) in degrees
    public let rightAscensionOfAscendingNode: Degree
    
    /// Describes the orientation of perigee on the orbital plane with reference to the right ascension of the ascending node
    /// Denoted by ( ω ) in degrees
    public let argumentOfPerigee: Degree
    
    // MARK: - Position of Craft
    
    /// The true angle between the position of the craft relative to perigee along the orbital path.
    /// Denoted as (ν or θ)
    /// Range between 0–360°
    public let trueAnomaly: Degree
    
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
    public let meanAnomaly: Degree
    
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
        self.semimajorAxis = Orbit.calculateSemimajorAxis(from: twoLineElement.meanMotion)
        self.eccentricity = twoLineElement.eccentricity
        self.inclination = twoLineElement.inclination
        self.rightAscensionOfAscendingNode = twoLineElement.rightAscension
        self.argumentOfPerigee = twoLineElement.argumentOfPerigee
        self.trueAnomaly = Orbit.calculateTrueAnomaly(eccentricity: twoLineElement.eccentricity, eccentricAnomaly: Orbit.calculateEccentricAnomaly(eccentricity: twoLineElement.eccentricity, meanAnomaly: twoLineElement.meanAnomaly))
        self.meanMotion = twoLineElement.meanMotion
        self.meanAnomaly = twoLineElement.meanAnomaly
        self.twoLineElement = twoLineElement
    }
    
    // MARK: - Functions
    
    public func meanAnomalyForJulianDate(julianDate: Double) -> Double {
        let epochJulianDate = Date.julianDayFromEpoch(epochYear: twoLineElement.epochYear, epochDayFraction: twoLineElement.epochDay)
        let daysSinceEpoch = julianDate - epochJulianDate
        let revolutionsSinceEpoch = meanMotion * daysSinceEpoch
        let meanAnomalyForJulianDate = meanAnomaly + revolutionsSinceEpoch * 360.0
        let fullRevolutions = floor(meanAnomalyForJulianDate / 360.0)
        let adjustedMeanAnomalyForJulianDate = meanAnomalyForJulianDate - 360.0 * fullRevolutions
        
        return adjustedMeanAnomalyForJulianDate
    }
    
    /// A helper variable that bridges the gap between the true anomaly (or the true position of an object from perigee)
    /// to the mean anomaly.
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    public static func calculateEccentricAnomaly(eccentricity: Double, meanAnomaly: Degree, accuracy: Double = 0.0001, maxIterations: Int = 500) -> Degree {
        let meanAnomaly: Radian = meanAnomaly.toRadians()
        let eccentricity: Double = eccentricity
        
        // For small eccentricities the mean anomaly M can be used as an initial value E0 for the iteration. In case of e>0.8 the initial value E0=π is taken.
        var eccentricAnomaly: Double = meanAnomaly
        if eccentricity > 0.8 {
            eccentricAnomaly = .pi
        }
        
        var delta: Double = eccentricAnomaly - (eccentricity * sin(meanAnomaly)) - meanAnomaly
        var iteration = 0
        
        repeat {
            eccentricAnomaly = eccentricAnomaly - delta / (1.0 - eccentricity * cos(eccentricAnomaly))
            delta = eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly
            print("OE | Iteration: \(iteration + 1) | Accuracy: \(delta.round(to: 5)) | Eccentric Anomaly: \(eccentricAnomaly.toDegrees())")
            iteration += 1
        } while (delta > accuracy && iteration <= maxIterations)
        
        return eccentricAnomaly.toDegrees()
    }
    

    /// The true angle relative to parigee and the position of the object along it's orbit path
    /// - Notes: Calculated from https://en.wikipedia.org/wiki/True_anomaly
    public static func calculateTrueAnomaly(eccentricity: Double, eccentricAnomaly: Degree) -> Degree {
        let E = eccentricAnomaly.toRadians()
        let phi = 2.0 * atan(sqrt(1 + eccentricity / 1 - eccentricity) * tan(E/2))
        print("OE | True Anomaly: \(phi.toDegrees()) degrees")
        return phi.toDegrees()
    }
    
    /// Calculating the semimajor axis from mean motion.
    /// - Returns: Size of Orbit (km)
    private static func calculateSemimajorAxis(from meanMotion: Double) -> Double {
        let earthsGravitationalConstant = 398613.52
        let motionRadsPerSecond = meanMotion / 86400
        let semimajorAxis = pow(earthsGravitationalConstant / (4.0 * pow(.pi, 2.0) * pow(motionRadsPerSecond, 2.0)), 1.0 / 3.0)
        print("OE | Semimajor Axis: \(semimajorAxis) km")
        return semimajorAxis
    }
    
    /// Calculates the position of the orbiting object relative to earth.
    ///
    /// - Note:
    ///     Transform math used from https://www.csun.edu/~hcmth017/master/node20.html
    ///     Heavily inspired by ZeitSatTrack https://github.com/dhmspector/ZeitSatTrack Apache 2.0
    public static func calculatePosition(semimajorAxis: Double, eccentricity: Double, eccentricAnomaly: Degree, trueAnomaly: Degree, argumentOfPerigee: Degree, inclination: Degree, rightAscensionOfAscendingNode: Degree) -> (x: Double, y: Double, z: Double) {
        
        // Calculate the XYZ coordinates on the orbital plane
        let orbitalRadius = semimajorAxis - (semimajorAxis * eccentricity) * cos(eccentricAnomaly.toRadians())
        let x = orbitalRadius * cos(trueAnomaly.toRadians())
        let y = orbitalRadius * sin(trueAnomaly.toRadians())
        let z = 0.0
        
        // Rotate about z''' by the argument of perigee.
        let argOfPerigeeRads = argumentOfPerigee.toRadians()
        let xByPerigee = cos(argOfPerigeeRads) * x - sin(argOfPerigeeRads) * y
        let yByPerigee = sin(argOfPerigeeRads) * x + cos(argOfPerigeeRads) * y
        let zByPerigee = z
        
        // Rotate about x'' axis by inclination.
        let inclinationRads = inclination.toRadians()
        let xInclination = xByPerigee;
        let yInclination = cos(inclinationRads) * yByPerigee - sin(inclinationRads) * zByPerigee
        let zInclination = sin(inclinationRads) * yByPerigee + cos(inclinationRads) * zByPerigee
        
        // Rotate about z' axis by right ascension of the ascending node.
        let raanRads = rightAscensionOfAscendingNode.toRadians()
        let xRaan = cos(raanRads) * xInclination - sin(raanRads) * yInclination
        let yRaan = sin(raanRads) * xInclination + cos(raanRads) * yInclination
        let zRaan = zInclination
        
        // Rotate about z axis by the rotation of the earth.
        let rotationFromGeocentric = 0.0 // TODO: Calculate this
        let rotationFromGeocentricRad = -rotationFromGeocentric.toRadians()
        let xFinal = cos(rotationFromGeocentricRad) * xRaan - sin(rotationFromGeocentricRad) * yRaan
        let yFinal = sin(rotationFromGeocentricRad) * xRaan + cos(rotationFromGeocentricRad) * yRaan
        let zFinal = zRaan
        
        // Geocoordinates
        let earthsRadius = 6370.0 //km
        let latitude = 90.0 - acos(zFinal / sqrt(xFinal * xFinal + yFinal * yFinal + zFinal * zFinal)).toDegrees()
        let longitude = atan2(yFinal, xFinal).toDegrees()
        let altitude = orbitalRadius - earthsRadius

        print("OE | Latitude: \(latitude) degrees | Longitude: \(longitude) degrees | Altitude: \(altitude)km")

        return (latitude, longitude, altitude)
    }
}

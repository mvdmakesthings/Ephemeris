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
    let semimajorAxis: Double
    
    // MARK: - Shape of Orbit
    
    /// Describes the shape of the orbital path.
    /// Denoted by ( e ) with a value between 0 and 1.
    let eccentricity: Double
    
    // MARK: - Orientation of Orbit
    
    /// The "tilt" in degrees from the vectors perpandicular to the orbital and equatorial planes
    /// Denoted by ( i ) and is in degrees 0–180°
    let inclination: Degree
    
    /// The "swivel" of the orbital plane in degrees in reference to the vernal equinox to the 'node' that cooresponds
    /// with the object passing the equator in a northernly direction.
    /// Denoted by ( Ω ) in degrees
    let rightAscensionOfAscendingNode: Degree
    
    /// Describes the orientation of perigee on the orbital plane with reference to the right ascension of the ascending node
    /// Denoted by ( ω ) in degrees
    let argumentOfPerigee: Degree
    
    // MARK: - Position of Craft
    
    /// The true angle between the position of the craft relative to perigee along the orbital path.
    /// Denoted as (ν or θ)
    /// Range between 0–360°
    let trueAnomaly: Degree
    
    // MARK: - Private

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
    let meanAnomaly: Degree
    
    /// The average speed an object moves throughout an orbit.
    /// Denoted as (n)
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    /// - Note: Calculated as
    ///     M = Gravitational Constant of Earth (3.986004418e^5 km^3/ s^2)
    ///     a = Semimajor axis
    ///     Mean Motion (n) = sqrt( M / a^3 )
    let meanMotion: Double
    
    // MARK: - Initializers
    init(from twoLineElement: TwoLineElement) {
        self.semimajorAxis = Orbit.calculateSemimajorAxis(from: twoLineElement.meanMotion)
        self.eccentricity = twoLineElement.eccentricity
        self.inclination = twoLineElement.inclination
        self.rightAscensionOfAscendingNode = twoLineElement.rightAscension
        self.argumentOfPerigee = twoLineElement.argumentOfPerigee
        self.trueAnomaly = Orbit.calculateTrueAnomaly(from: twoLineElement.eccentricity, with: Orbit.calculateEccentricAnomaly(eccentricity: twoLineElement.eccentricity, meanAnomaly: twoLineElement.meanAnomaly))
        self.meanMotion = twoLineElement.meanMotion
        self.meanAnomaly = twoLineElement.meanAnomaly
    }
    
    // MARK: - Functions
    
    /// A helper variable that bridges the gap between the true anomaly (or the true position of an object from perigee)
    /// to the mean anomaly.
    ///
    /// https://www.youtube.com/watch?v=cf9Jh44kL20
    ///
    static func calculateEccentricAnomaly(eccentricity: Double, meanAnomaly: Degree, accuracy: Double = 0.0001, maxIterations: Int = 500) -> Degree {
        let meanAnomaly: Radian = meanAnomaly.toRadians()
        let eccentricity: Double = eccentricity
        
        // For small eccentricities the mean anomaly M can be used as an initial value E0 for the iteration. In case of e>0.8 the initial value E0=π is taken.
        var eccentricAnomaly: Radian = .pi
        if eccentricity <= 0.8 {
            eccentricAnomaly = meanAnomaly
        }
        
        var delta: Double = eccentricAnomaly - (eccentricity * sin(meanAnomaly)) - meanAnomaly
        var iteration = 0
        
        repeat {
            eccentricAnomaly = eccentricAnomaly - delta / (1.0 - eccentricity * cos(eccentricAnomaly))
            delta = eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly
            print("Orbital Elements | Iteration: \(iteration + 1) | Accuracy: \(delta.round(to: 5)) | Eccentric Anomaly: \(eccentricAnomaly.toDegrees())")
            iteration += 1
        } while (delta > accuracy && iteration <= maxIterations)
        
        return eccentricAnomaly.toDegrees()
    }
    
    
    
    /// The true angle relative to parigee and the position of the object along it's orbit path
    private static func calculateTrueAnomaly(from eccentricity: Double, with eccentricAnomaly: Degree) -> Degree {
        // all angles in calculus should be normalized to radians
        let E = eccentricAnomaly.toRadians()
        let fak = sqrt(1.0 - eccentricity * eccentricity)
        let phi = atan2(fak*sin(E), cos(E)-eccentricity)
        print("Orbital Elements | True Anomaly: \(phi.toDegrees()) degrees")
        return phi.toDegrees()
    }
    
    /// Calculating the semimajor axis from mean motion.
    /// - Returns: Size of Orbit (km)
    private static func calculateSemimajorAxis(from meanMotion: Double) -> Double {
        let earthsGravitationalConstant = 398600.4418
        let motionRadsPerSecond = (meanMotion * 2.0 * .pi) / 86400
        let semimajorAxis = (pow(earthsGravitationalConstant, 1/3) / pow(motionRadsPerSecond, 2/3))
        print("Orbital Elements | Semimajor Axis: \(semimajorAxis) km")
        return semimajorAxis
    }
    
    /// Calculates the position of the orbiting object relative to earth
    static func calculatePosition(semimajorAxis: Double, eccentricity: Double, eccentricAnomaly: Degree, trueAnomaly: Degree, argumentOfPerigee: Degree, inclination: Degree, rightAscensionOfAscendingNode: Degree) -> (x: Double, y: Double, z: Double) {
        
        // Calculate the XYZ coordinates on the orbital plane
        let orbitalRadius = semimajorAxis - (semimajorAxis * eccentricity) * cos(eccentricAnomaly.toRadians())
        print("Orbital Elements | Orbital Radius: \(orbitalRadius) km")
        var x = orbitalRadius * cos(trueAnomaly.toRadians())
        var y = orbitalRadius * cos(trueAnomaly.toRadians())
        var z = 0.0
        print("Orbital Elements | Orbital Base | X: \(x) km | Y: \(y) km | Z: \(z)")
        
        // Rotate about z''' by the argument of perigee.
        let argOfPerigee = argumentOfPerigee.toRadians()
        x = cos(argOfPerigee) * x - sin(argOfPerigee) * y
        y = sin(argOfPerigee) * x + cos(argOfPerigee) * y
        print("Orbital Elements | Rotation on Z by Argument of Perigee | X: \(x) km | Y: \(y) km | Z: \(z)")
    
        // Rotate about x'' axis by inclination.
        let inclination = inclination.toRadians()
        y = cos(inclination) * y - sin(inclination) * z
        z = sin(inclination) * y + cos(inclination) * z
        print("Orbital Elements | Rotation on X by Inclination | X: \(x) km | Y: \(y) km | Z: \(z)")
        
        // Rotate about z' axis by right ascension of the ascending node.
        let rightAscensionOfAscendingNode = rightAscensionOfAscendingNode.toRadians()
        x = cos(rightAscensionOfAscendingNode) * x - sin(rightAscensionOfAscendingNode) * y
        y = sin(rightAscensionOfAscendingNode) * x + cos(rightAscensionOfAscendingNode) * y
        print("Orbital Elements | Rotation on Z by Right Ascension | X: \(x) km | Y: \(y) km | Z: \(z)")
        
        // Rotate about z axis by the rotation of the earth.
        let earthsRotationAtGivenTime: Radian = 0.00 // TODO: Figure out how to calculate this.
        let earthsEquitorialRadius = 6378.137 // km
        x = cos(earthsRotationAtGivenTime) * x - sin(earthsRotationAtGivenTime) * y
        y = sin(earthsRotationAtGivenTime) * x + cos(earthsRotationAtGivenTime) * y
        print("Orbital Elements | Rotation on Z by Earth's rotation | X: \(x) km | Y: \(y) km | Z: \(z)")
        
        // Finally, Latitude, Longitude, and Altitude
        let latitude = 90.0 - acos(z / sqrt(x*x + y*y + z*z)).toDegrees()
        let longitude = atan2(y, x).toDegrees()
        let altitude = orbitalRadius - earthsEquitorialRadius

        print("Orbital Elements | Latitude: \(latitude) degrees | Longitude: \(longitude) degrees | Altitude: \(altitude)km")

        return (latitude, longitude, altitude)
    }
}

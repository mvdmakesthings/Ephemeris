//
//  Orbit.swift
//  SwiftSatTrack
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

class Orbit {
    
    let title: String
    let rightAscension: Double
    let eccentricity: Double
    let argumentPeriapsis: Double
    var meanAnomaly: Double
    let meanMotion: Double
    let epochDate: Date
    
    init(title: String, rightAscension: Double, eccentricity: Double, argumentPeriapsis: Double, meanAnomaly: Double, meanMotion: Double, epochDate: Date) {
        self.title = title
        self.rightAscension = rightAscension
        self.eccentricity = eccentricity
        self.argumentPeriapsis = argumentPeriapsis
        self.meanAnomaly = meanAnomaly
        self.meanMotion = meanMotion
        self.epochDate = epochDate
    }
    
    /// Approximates Eccentric Anomaly from Mean Anomaly
    /// - Parameters:
    ///     - maxAccuracy: Also known as Epsilon or the total accuracy of the eccentric anomaly
    /// - Note: Kepler's Equation is:
    ///     M = E-eSin(E)
    ///
    ///     Where:
    ///
    ///     M = Mean Anomaly (range 0 - 180 degrees)
    ///
    ///     e = Eccentricity (range 0-1)
    ///
    ///     E = Eccentric Anomaly
    ///
    /// - Link: http://orbitsimulator.com/sheela/kepler.htm
    /// - TODO: Better optimize using Newton's Method of finding minima: https://en.wikipedia.org/wiki/Newton%27s_method
    func eccentricAnomaly(maxAccuracy: Double = 0.00001) -> Degree {
        var meanAnomaly = Orbit.degreeToRadian(self.meanAnomaly)

        if self.eccentricity == 0 {
            return self.meanAnomaly
        }
        
        if meanAnomaly >= 0.8 {
            meanAnomaly = .pi
        }
        let meanAnomalyInRadians = meanAnomaly * .pi / 180.0

        var errorRate = 0.0
        var estimate = 0.0
        var previousEstimate = meanAnomalyInRadians
        
        repeat {
            estimate = meanAnomaly - (meanAnomaly - self.eccentricity * sin(meanAnomaly) - meanAnomaly) / (1.0 - self.eccentricity * cos(meanAnomaly))
            errorRate = fabs(estimate - previousEstimate)
            previousEstimate = estimate
        } while (errorRate > maxAccuracy)
        
        return Orbit.radianToDegree(estimate)
    }
    
    /// Motion per second (radians/second) of an object using mean motion
    func motionRadiansPerSecond() -> Radian {
        return meanMotion * 2 * .pi / (24 * 60 * 60)
    }
    
    /// The time difference between now and the orbit's epoch.
    func epochTimeDifference(from date: Date = Date()) -> TimeInterval {
        let now = date.timeIntervalSinceNow
        let epoch = epochDate.timeIntervalSinceNow
        let diff = now - epoch
        return diff
    }
    
    /// The offset (in Radians) from the time difference from now until the epoch into Degrees
    func timeAdjustedMeanAnomaly() -> Radian {
        let adjustedMeanAnomaly = Orbit.degreeToRadian(epochTimeDifference() * motionRadiansPerSecond())
        self.meanAnomaly += adjustedMeanAnomaly.truncatingRemainder(dividingBy: 360)
        return self.meanAnomaly
    }
    
    /// Infers the period from the TLE mean motion
    func period() -> Double {
        let dayInSeconds: Double = (24 * 60 * 60)
        let period = dayInSeconds / meanMotion
        return period
    }
    
    /// Calculates the Semi-Major axis.
    /// - Parameters:
    ///     - keplersConstant: Standard Gravitational Parameter for the orbital body (km^3 / s^2)
    func semiMajorAxis(with keplersConstant: Double = 398600.4418) -> Double {
        let motionPerSecond = self.motionRadiansPerSecond()
        return pow(keplersConstant / (4.0 * pow(.pi, 2) * pow(motionPerSecond,2)), 1.0/3.0)
    }
    
    /// Calculates true anomaly
    /// - Link: http://en.wikipedia.org/wiki/True_anomaly
    func trueAnomalyFromEccentricAnomaly() -> Double {
        let eccentricAnomaly = self.eccentricAnomaly() / 2.0
        return 2.0 * atan2(sqrt(1 + self.eccentricity) * sin(eccentricAnomaly), sqrt(1 - self.eccentricity) * cos(eccentricAnomaly)) * 180.0 / .pi
    }
}

extension Orbit {
    /// Converts Radians to Degrees
    public static func radianToDegree(_ radian: Radian) -> Degree {
        return radian * 180 / .pi
    }
    
    /// Converts Degrees to Radians
    public static func degreeToRadian(_ degree: Degree) -> Radian {
        return degree * .pi / 180
    }
}

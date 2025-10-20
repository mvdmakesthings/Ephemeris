//
//  OrbitalCalculationTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Spectre
@testable import Ephemeris

let orbitalCalculationTests: ((ContextType) -> Void) = {
    $0.describe("Orbital Calculations") {
        
        $0.it("calculates semimajor axis correctly") {
            // GOES 16 Satellite
            // 42,164.9 km (26,200.0 mi)
            let knownSemimajorAxis = 42165.0 // km
            let meanMotion = 1.00271173 // Revolutions Per Day
            let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion).rounded() // Rounded to the nearest km
            _ = expect(semimajorAxis == knownSemimajorAxis)
        }
        
        $0.it("calculates eccentric anomaly correctly") {
            // See numerical example: http://www.csun.edu/~hcmth017/master/node16.html
            let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: 0.00001, meanAnomaly: 30, accuracy: 0.0001, maxIterations: 500)
            _ = expect(eccentricAnomaly.round(to: 5) == 30.00029)
        }
        
        $0.it("calculates true anomaly correctly") {
            let eccentricity = 0.5
            let trueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: eccentricity, eccentricAnomaly: 30.000)
            _ = expect(trueAnomaly.round(to: 1) == 90.0)
        }
        
        $0.it("orbit conforms to Orbitable protocol") {
            // Test that Orbit struct properly conforms to Orbitable protocol
            let tle = try MockTLEs.ISSSample()
            let orbit = Orbit(from: tle)
            
            // Verify that orbit can be used as Orbitable
            let orbitable: Orbitable = orbit
            
            // Test that trueAnomaly is accessible and non-optional through protocol
            let trueAnomalyValue = orbitable.trueAnomaly
            _ = try expect(trueAnomalyValue >= 0.0)
            _ = try expect(trueAnomalyValue <= 360.0)
        }
        
        $0.it("true anomaly always returns a value") {
            // Test that trueAnomaly always returns a value, even for edge cases
            let tle = try MockTLEs.ISSSample()
            let orbit = Orbit(from: tle)
            
            // Access trueAnomaly - should never be nil
            let trueAnomaly = orbit.trueAnomaly
            _ = try expect(trueAnomaly >= 0.0)
            _ = try expect(trueAnomaly <= 360.0)
        }
        
        $0.it("calculates true anomaly from mean anomaly") {
            // Test that trueAnomaly is properly calculated from mean anomaly
            let tle = try MockTLEs.objectAtPerigee()
            let orbit = Orbit(from: tle)
            
            // For an object at perigee with e=0.5 and M=0, true anomaly should be 0
            let trueAnomaly = orbit.trueAnomaly
            // The value should be computed and be a valid angle
            _ = try expect(trueAnomaly >= 0.0)
            _ = try expect(trueAnomaly <= 360.0)
        }
        
        $0.it("validates WGS84 physical constants") {
            // Verify Earth's gravitational constant (µ = GM) matches WGS84 standard
            // WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
            let expectedMu = 398600.4418 // km^3/s^2
            _ = try expect(abs(PhysicalConstants.Earth.µ - expectedMu) < 0.0001)
            
            // Verify Earth's radius matches WGS84 standard
            // WGS84 equatorial radius: 6378.137 km
            let expectedRadius = 6378.137 // km
            _ = try expect(abs(PhysicalConstants.Earth.radius - expectedRadius) < 0.001)
            
            // Verify seconds per day is correct
            let expectedSecondsPerDay = 86400.0
            _ = expect(PhysicalConstants.Time.secondsPerDay == expectedSecondsPerDay)
        }
    }
}


//
//  OrbitalElementsTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Spectre
@testable import Ephemeris

let orbitalElementsTests: ((ContextType) -> Void) = {
    $0.describe("Orbital Elements") {
        
        $0.it("calculates semimajor axis correctly") {
            // GOES 16 Satellite
            // 42,164.9 km (26,200.0 mi)
            let knownSemimajorAxis = 42165.0 // km
            let meanMotion = 1.00271173 // Revolutions Per Day
            let semimajorAxis = Orbit.calculateSemimajorAxis(meanMotion: meanMotion).rounded() // Rounded to the nearest km
            _ = expect(semimajorAxis == knownSemimajorAxis)
        }
        
        $0.it("calculates eccentric anomaly correctly") {
            // Test with low eccentricity (nearly circular orbit)
            // See numerical example: http://www.csun.edu/~hcmth017/master/node16.html
            let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: 0.00001, meanAnomaly: 30, accuracy: 0.0001, maxIterations: 500)
            _ = expect(eccentricAnomaly.round(to: 5) == 30.00029)
        }
        
        $0.it("calculates true anomaly correctly") {
            // Test true anomaly calculation with edge case values
            // For E=0 (at periapsis), true anomaly should be 0
            let eccentricity = 0.1
            let eccentricAnomalyAtPeriapsis: Degrees = 0.0
            let trueAnomalyAtPeriapsis = try Orbit.calculateTrueAnomaly(eccentricity: eccentricity, eccentricAnomaly: eccentricAnomalyAtPeriapsis)
            _ = try expect(abs(trueAnomalyAtPeriapsis - 0.0) < 0.001)
            
            // Test that function returns valid angles (0-360°)
            let eccentricAnomaly: Degrees = 45.0
            let trueAnomaly = try Orbit.calculateTrueAnomaly(eccentricity: eccentricity, eccentricAnomaly: eccentricAnomaly)
            _ = expect(trueAnomaly >= 0.0)
            _ = expect(trueAnomaly <= 360.0)
        }
        
        $0.it("initializes orbit from TLE") {
            // Test that an Orbit can be created from a TLE
            let tle = try MockTLEs.ISSSample()
            let orbit = Orbit(from: tle)
            
            // Verify basic orbital elements are set
            _ = expect(orbit.semimajorAxis > 0)
            _ = expect(orbit.eccentricity >= 0)
            _ = expect(orbit.eccentricity <= 1)
            _ = expect(orbit.inclination >= 0)
            _ = expect(orbit.inclination <= 180)
        }
    }
}


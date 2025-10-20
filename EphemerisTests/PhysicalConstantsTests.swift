//
//  PhysicalConstantsTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/19/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Spectre
@testable import Ephemeris

let physicalConstantsTests: ((ContextType) -> Void) = {
    $0.describe("Physical Constants") {
        
        // MARK: - Earth Constants Tests
        
        $0.context("Earth constants") {
            $0.it("has correct gravitational constant") {
                // Verify Earth's gravitational constant (µ = GM) matches WGS84 standard
                // WGS84 value: 3.986004418 × 10^14 m^3/s^2 = 398600.4418 km^3/s^2
                let expectedMu = 398600.4418 // km^3/s^2
                try expect(abs(PhysicalConstants.Earth.µ - expectedMu) < 0.0001)
            }
            
            $0.it("has correct radius") {
                // Verify Earth's radius matches WGS84 standard
                // WGS84 equatorial radius: 6378.137 km
                let expectedRadius = 6378.137 // km
                try expect(abs(PhysicalConstants.Earth.radius - expectedRadius) < 0.001)
            }
            
            $0.it("has correct mean radius") {
                // Mean radius should be approximately 6371 km
                try expect(PhysicalConstants.Earth.meanRadius == 6371.0)
            }
            
            $0.it("has correct radians per day") {
                // Earth rotates approximately 2π radians per sidereal day
                // Expected value from Vallado: 6.3003809866574
                try expect(abs(PhysicalConstants.Earth.radsPerDay - 6.3003809866574) < 0.0000001)
                
                // Should be slightly more than 2π (difference between solar and sidereal day)
                try expect(PhysicalConstants.Earth.radsPerDay > 2.0 * .pi)
                try expect(abs(PhysicalConstants.Earth.radsPerDay - 2.0 * .pi) < 0.02 == true)
            }
        }
        
        // MARK: - Time Constants Tests
        
        $0.context("Time constants") {
            $0.it("has correct seconds per day") {
                try expect(PhysicalConstants.Time.secondsPerDay == 86400.0)
                try expect(PhysicalConstants.Time.secondsPerDay == 24.0 * 60.0 * 60.0)
            }
            
            $0.it("has correct days per Julian century") {
                try expect(PhysicalConstants.Time.daysPerJulianCentury == 36525.0)
            }
            
            $0.it("has correct seconds per hour") {
                try expect(PhysicalConstants.Time.secondsPerHour == 3600.0)
                try expect(PhysicalConstants.Time.secondsPerHour == 60.0 * 60.0)
            }
            
            $0.it("has correct seconds per minute") {
                try expect(PhysicalConstants.Time.secondsPerMinute == 60.0)
            }
        }
        
        // MARK: - Julian Date Constants Tests
        
        $0.context("Julian date constants") {
            $0.it("has correct Unix epoch") {
                // Unix epoch (Jan 1, 1970 00:00:00 UTC) should be JD 2440587.5
                try expect(PhysicalConstants.Julian.unixEpoch == 2440587.5)
            }
            
            $0.it("has correct J2000 epoch") {
                // J2000.0 epoch (Jan 1, 2000 12:00:00 TT) should be JD 2451545.0
                try expect(PhysicalConstants.Julian.j2000Epoch == 2451545.0)
            }
        }
        
        // MARK: - Calculation Constants Tests
        
        $0.context("Calculation constants") {
            $0.it("has correct default accuracy") {
                try expect(PhysicalConstants.Calculation.defaultAccuracy == 0.00001)
            }
            
            $0.it("has correct max iterations") {
                try expect(PhysicalConstants.Calculation.maxIterations == 500)
                try expect(PhysicalConstants.Calculation.maxIterations > 0)
            }
        }
        
        // MARK: - Angle Constants Tests
        
        $0.context("Angle constants") {
            $0.it("has correct degrees per circle") {
                try expect(PhysicalConstants.Angle.degreesPerCircle == 360.0)
            }
            
            $0.it("has correct radians per circle") {
                try expect(abs(PhysicalConstants.Angle.radiansPerCircle - 2.0 * .pi) < 0.0000001)
            }
        }
    }
}


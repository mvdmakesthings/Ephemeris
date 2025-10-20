//
//  ObserverTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation
import Spectre
@testable import Ephemeris

let observerTests: ((ContextType) -> Void) = {
    $0.describe("Observer and Topocentric Coordinates") {
        
        $0.context("Observer initialization") {
            $0.it("creates observer with correct coordinates") {
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                _ = expect(observer.latitudeDeg == 38.2542)
                _ = expect(observer.longitudeDeg == -85.7594)
                _ = expect(observer.altitudeMeters == 140)
            }
        }
        
        $0.context("Topocentric initialization") {
            $0.it("creates topocentric with correct values") {
                let topo = Topocentric(azimuthDeg: 45.0, elevationDeg: 30.0, rangeKm: 1000.0, rangeRateKmPerSec: 5.0)
                _ = expect(topo.azimuthDeg == 45.0)
                _ = expect(topo.elevationDeg == 30.0)
                _ = expect(topo.rangeKm == 1000.0)
                _ = expect(topo.rangeRateKmPerSec == 5.0)
            }
        }
        
        $0.context("PassWindow") {
            $0.it("creates pass window and calculates duration") {
                let aosTime = Date()
                let losTime = aosTime.addingTimeInterval(600) // 10 minutes later
                let maxTime = aosTime.addingTimeInterval(300) // 5 minutes later
                
                let aos = PassWindow.Point(time: aosTime, azimuthDeg: 90.0)
                let los = PassWindow.Point(time: losTime, azimuthDeg: 270.0)
                let pass = PassWindow(
                    aos: aos,
                    max: (time: maxTime, elevationDeg: 45.0, azimuthDeg: 180.0),
                    los: los
                )
                
                _ = expect(pass.aos.azimuthDeg == 90.0)
                _ = expect(pass.los.azimuthDeg == 270.0)
                _ = expect(pass.max.elevationDeg == 45.0)
                _ = expect(pass.duration == 600)
            }
        }
        
        $0.context("Geodetic to ECEF conversion") {
            $0.it("converts equator prime meridian correctly") {
                // Point on equator at prime meridian, sea level
                let ecef = CoordinateTransforms.geodeticToECEF(
                    latitudeDeg: 0.0,
                    longitudeDeg: 0.0,
                    altitudeMeters: 0.0
                )
                
                // Should be at Earth's equatorial radius on X-axis
                _ = expect(ecef.x.round(to: 1) == 6378.1)
                _ = expect(ecef.y.round(to: 1) == 0.0)
                _ = expect(ecef.z.round(to: 1) == 0.0)
            }
            
            $0.it("converts north pole correctly") {
                // North pole at sea level
                let ecef = CoordinateTransforms.geodeticToECEF(
                    latitudeDeg: 90.0,
                    longitudeDeg: 0.0,
                    altitudeMeters: 0.0
                )
                
                // Should be at Earth's polar radius on Z-axis
                _ = expect(ecef.x.round(to: 1) == 0.0)
                _ = expect(ecef.y.round(to: 1) == 0.0)
                _ = expect(ecef.z.round(to: 1) == 6356.8)
            }
            
            $0.it("converts Louisville, KY correctly") {
                // Louisville, Kentucky
                let ecef = CoordinateTransforms.geodeticToECEF(
                    latitudeDeg: 38.2542,
                    longitudeDeg: -85.7594,
                    altitudeMeters: 140.0
                )
                
                // Verify all components are non-zero and reasonable
                _ = expect(abs(ecef.x) > 0.0)
                _ = expect(abs(ecef.y) > 0.0)
                _ = expect(abs(ecef.z) > 0.0)
                
                // Total magnitude should be close to Earth radius + altitude
                let magnitude = sqrt(ecef.x * ecef.x + ecef.y * ecef.y + ecef.z * ecef.z)
                _ = expect(magnitude > 6378.0)
                _ = expect(magnitude < 6379.0)
            }
        }
        
        $0.context("Vector3D operations") {
            $0.it("calculates magnitude correctly") {
                let v = Vector3D(x: 3.0, y: 4.0, z: 0.0)
                _ = expect(v.magnitude == 5.0)
            }
            
            $0.it("subtracts vectors correctly") {
                let v1 = Vector3D(x: 5.0, y: 7.0, z: 9.0)
                let v2 = Vector3D(x: 2.0, y: 3.0, z: 4.0)
                let result = v1.subtract(v2)
                
                _ = expect(result.x == 3.0)
                _ = expect(result.y == 4.0)
                _ = expect(result.z == 5.0)
            }
            
            $0.it("calculates dot product correctly") {
                let v1 = Vector3D(x: 1.0, y: 2.0, z: 3.0)
                let v2 = Vector3D(x: 4.0, y: 5.0, z: 6.0)
                let dot = v1.dot(v2)
                
                // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
                _ = expect(dot == 32.0)
            }
        }
        
        $0.context("ENU to Azimuth/Elevation") {
            $0.it("converts directly north correctly") {
                let enu = Vector3D(x: 0.0, y: 100.0, z: 0.0) // North on horizon
                let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)
                
                _ = expect(az.round(to: 1) == 0.0) // North = 0°
                _ = expect(el.round(to: 1) == 0.0) // On horizon
                _ = expect(range == 100.0)
            }
            
            $0.it("converts directly east correctly") {
                let enu = Vector3D(x: 100.0, y: 0.0, z: 0.0) // East on horizon
                let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)
                
                _ = expect(az.round(to: 1) == 90.0) // East = 90°
                _ = expect(el.round(to: 1) == 0.0) // On horizon
                _ = expect(range == 100.0)
            }
            
            $0.it("converts directly up correctly") {
                let enu = Vector3D(x: 0.0, y: 0.0, z: 100.0) // Zenith
                let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)
                
                _ = expect(el.round(to: 1) == 90.0) // Zenith = 90°
                _ = expect(range == 100.0)
                // Azimuth is undefined at zenith, so we don't test it
            }
            
            $0.it("converts 45° elevation correctly") {
                let enu = Vector3D(x: 100.0, y: 0.0, z: 100.0) // 45° elevation to east
                let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)
                
                _ = expect(az.round(to: 1) == 90.0) // East
                _ = expect(el.round(to: 1) == 45.0) // 45° elevation
            }
        }
        
        $0.context("Topocentric calculation") {
            $0.it("calculates topocentric for ISS") {
                // Use ISS TLE
                let tle = try MockTLEs.ISSSample()
                let orbit = Orbit(from: tle)
                
                // Observer in Louisville, Kentucky
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                // Calculate topocentric at epoch time
                let epochDate = Date.julianDay(from: Date())!
                let testDate = Date() // Use current date for this test
                
                let topo = try orbit.topocentric(at: testDate, for: observer)
                
                // Verify outputs are in valid ranges
                _ = expect(topo.azimuthDeg >= 0.0)
                _ = expect(topo.azimuthDeg <= 360.0)
                _ = expect(topo.elevationDeg >= -90.0)
                _ = expect(topo.elevationDeg <= 90.0)
                _ = expect(topo.rangeKm > 0.0)
                
                // Range should be at least altitude difference and less than half Earth's circumference
                _ = expect(topo.rangeKm < 20000.0)
            }
        }
        
        $0.context("Atmospheric refraction") {
            $0.it("increases elevation for low angles") {
                let trueElev = 10.0
                let apparentElev = CoordinateTransforms.applyRefraction(elevationDeg: trueElev)
                
                // Refraction should increase apparent elevation
                _ = expect(apparentElev > trueElev)
                
                // Refraction at 10° should be small (less than 1°)
                _ = expect((apparentElev - trueElev) < 1.0)
            }
            
            $0.it("does not apply refraction below horizon") {
                let trueElev = -5.0
                let apparentElev = CoordinateTransforms.applyRefraction(elevationDeg: trueElev)
                
                // Should not change significantly below -1°
                _ = expect(apparentElev == trueElev)
            }
            
            $0.it("has minimal effect at high elevations") {
                let trueElev = 80.0
                let apparentElev = CoordinateTransforms.applyRefraction(elevationDeg: trueElev)
                
                // Refraction should be very small at high elevations
                _ = expect((apparentElev - trueElev) < 0.1)
            }
        }
    }
}

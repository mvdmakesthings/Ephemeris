//
//  GroundTrackSkyTrackTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation
import Spectre
@testable import Ephemeris

// Helper function to create UTC dates for testing
fileprivate func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date? {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    return calendar.date(from: components)
}

let groundTrackSkyTrackTests: ((ContextType) -> Void) = {
    $0.describe("Ground Track and Sky Track Plotters") {
        
        // MARK: - Ground Track Tests
        
        $0.context("Ground Track Generation") {
            $0.it("generates ground track points for ISS") {
                // ISS example from 2020
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                // Generate ground track for 10 minutes
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(600) // 10 minutes
                
                let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)
                
                // Should have 11 points (0, 60, 120, ..., 600 seconds)
                _ = try expect(groundTrack.count == 11)
                
                // First point should be at start time
                _ = expect(groundTrack.first!.time == start)
                
                // Last point should be at end time
                _ = expect(groundTrack.last!.time == end)
                
                // All latitude values should be within valid range
                for point in groundTrack {
                    _ = expect(point.latitudeDeg >= -90.0)
                    _ = expect(point.latitudeDeg <= 90.0)
                }
                
                // All longitude values should be within valid range
                for point in groundTrack {
                    _ = expect(point.longitudeDeg >= -180.0)
                    _ = expect(point.longitudeDeg <= 180.0)
                }
                
                // ISS inclination is ~51.6°, so latitude should stay within that range
                for point in groundTrack {
                    _ = expect(abs(point.latitudeDeg) <= 52.0)
                }
            }
            
            $0.it("generates ground track for equatorial orbit") {
                // Create a nearly equatorial orbit (low inclination)
                let tleString = """
                TEST EQUATORIAL
                1 99999U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
                2 99999   0.1000   0.0000 0001000   0.0000   0.0000 15.00000000000016
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 12, minute: 0, second: 0) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(3600) // 1 hour
                
                let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)
                
                _ = try expect(groundTrack.count == 61)
                
                // For equatorial orbit, latitude should stay very close to 0
                for point in groundTrack {
                    _ = expect(abs(point.latitudeDeg) < 1.0)
                }
            }
            
            $0.it("generates ground track for polar orbit") {
                // Create a polar orbit (high inclination ~90°)
                let tleString = """
                TEST POLAR
                1 88888U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9996
                2 88888  90.0000   0.0000 0001000   0.0000   0.0000 14.00000000000018
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 12, minute: 0, second: 0) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(3600) // 1 hour
                
                let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)
                
                _ = try expect(groundTrack.count == 61)
                
                // For polar orbit, latitude can reach near ±90°
                var hasHighLatitude = false
                for point in groundTrack {
                    if abs(point.latitudeDeg) > 80.0 {
                        hasHighLatitude = true
                    }
                }
                _ = expect(hasHighLatitude) // Should pass over high latitudes
            }
            
            $0.it("generates ground track for GEO orbit") {
                // Create a geostationary orbit (period ~24 hours, altitude ~35,786 km)
                // Mean motion for GEO is approximately 1.0027379 revs/day
                let tleString = """
                TEST GEO
                1 77777U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
                2 77777   0.0500   0.0000 0000100   0.0000   0.0000  1.00273790000013
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 12, minute: 0, second: 0) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(3600) // 1 hour
                
                let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 300) // 5 min steps
                
                _ = try expect(groundTrack.count == 13)
                
                // GEO orbits stay near equator
                for point in groundTrack {
                    _ = expect(abs(point.latitudeDeg) < 2.0)
                }
            }
            
            $0.it("respects custom step size") {
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(600) // 10 minutes
                
                // Test with 30 second steps
                let groundTrack30 = try orbit.groundTrack(from: start, to: end, stepSeconds: 30)
                _ = try expect(groundTrack30.count == 21) // 0, 30, 60, ..., 600
                
                // Test with 120 second steps
                let groundTrack120 = try orbit.groundTrack(from: start, to: end, stepSeconds: 120)
                _ = try expect(groundTrack120.count == 6) // 0, 120, 240, 360, 480, 600
            }
            
            $0.it("handles single time point") {
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                
                let groundTrack = try orbit.groundTrack(from: epoch, to: epoch, stepSeconds: 60)
                
                // Should have exactly 1 point when start == end
                _ = try expect(groundTrack.count == 1)
                _ = expect(groundTrack.first!.time == epoch)
            }
        }
        
        // MARK: - Sky Track Tests
        
        $0.context("Sky Track Generation") {
            $0.it("generates sky track points for ISS pass") {
                // ISS example
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                // Observer in Louisville, KY
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(600) // 10 minutes
                
                let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 30)
                
                // Should have 21 points (0, 30, 60, ..., 600 seconds)
                _ = try expect(skyTrack.count == 21)
                
                // First point should be at start time
                _ = expect(skyTrack.first!.time == start)
                
                // Last point should be at end time
                _ = expect(skyTrack.last!.time == end)
                
                // All azimuth values should be within valid range
                for point in skyTrack {
                    _ = expect(point.azimuthDeg >= 0.0)
                    _ = expect(point.azimuthDeg <= 360.0)
                }
                
                // All elevation values should be within valid range
                for point in skyTrack {
                    _ = expect(point.elevationDeg >= -90.0)
                    _ = expect(point.elevationDeg <= 90.0)
                }
            }
            
            $0.it("detects satellite below horizon") {
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                // Observer in Louisville, KY
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(7200) // 2 hours
                
                let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 60)
                
                // Check that we have both positive and negative elevations
                var hasPositive = false
                var hasNegative = false
                
                for point in skyTrack {
                    if point.elevationDeg > 0 {
                        hasPositive = true
                    }
                    if point.elevationDeg < 0 {
                        hasNegative = true
                    }
                }
                
                // Over 2 hours, ISS should both rise above and drop below horizon
                _ = expect(hasPositive)
                _ = expect(hasNegative)
            }
            
            $0.it("tracks azimuth changes during pass") {
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                // Observer in Louisville, KY
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(600) // 10 minutes
                
                let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 10)
                
                _ = try expect(skyTrack.count == 61)
                
                // During a pass, azimuth should change
                let firstAzimuth = skyTrack.first!.azimuthDeg
                let lastAzimuth = skyTrack.last!.azimuthDeg
                
                // Azimuth should change over 10 minutes
                _ = expect(abs(firstAzimuth - lastAzimuth) > 1.0)
            }
            
            $0.it("respects custom step size for sky track") {
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let start = epoch
                let end = start.addingTimeInterval(300) // 5 minutes
                
                // Test with 10 second steps
                let skyTrack10 = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 10)
                _ = try expect(skyTrack10.count == 31) // 0, 10, 20, ..., 300
                
                // Test with 60 second steps
                let skyTrack60 = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 60)
                _ = try expect(skyTrack60.count == 6) // 0, 60, 120, 180, 240, 300
            }
            
            $0.it("handles single time point for sky track") {
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                
                let skyTrack = try orbit.skyTrack(for: observer, from: epoch, to: epoch, stepSeconds: 30)
                
                // Should have exactly 1 point when start == end
                _ = try expect(skyTrack.count == 1)
                _ = expect(skyTrack.first!.time == epoch)
            }
            
            $0.it("generates consistent results with topocentric calculations") {
                // Verify that skyTrack points match individual topocentric calculations
                let tleString = """
                ISS (ZARYA)
                1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
                2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
                """
                let tle = try TwoLineElement(from: tleString)
                let orbit = Orbit(from: tle)
                
                let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
                
                guard let epoch = makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20) else {
                    throw failure("Failed to create date")
                }
                let testTime = epoch.addingTimeInterval(300) // 5 minutes after epoch
                
                // Get sky track point
                let skyTrack = try orbit.skyTrack(for: observer, from: testTime, to: testTime, stepSeconds: 60)
                let skyPoint = skyTrack.first!
                
                // Get direct topocentric calculation
                let topo = try orbit.topocentric(at: testTime, for: observer, applyRefraction: false)
                
                // Should match
                _ = try expect(abs(skyPoint.azimuthDeg - topo.azimuthDeg) < 0.001)
                _ = try expect(abs(skyPoint.elevationDeg - topo.elevationDeg) < 0.001)
            }
        }
        
        // MARK: - Data Structure Tests
        
        $0.context("GroundTrackPoint structure") {
            $0.it("stores correct values") {
                let time = Date()
                let point = Orbit.GroundTrackPoint(time: time, latitudeDeg: 38.2542, longitudeDeg: -85.7594)
                
                _ = expect(point.time == time)
                _ = expect(point.latitudeDeg == 38.2542)
                _ = expect(point.longitudeDeg == -85.7594)
            }
        }
        
        $0.context("SkyTrackPoint structure") {
            $0.it("stores correct values") {
                let time = Date()
                let point = Orbit.SkyTrackPoint(time: time, azimuthDeg: 180.0, elevationDeg: 45.0)
                
                _ = expect(point.time == time)
                _ = expect(point.azimuthDeg == 180.0)
                _ = expect(point.elevationDeg == 45.0)
            }
        }
    }
}

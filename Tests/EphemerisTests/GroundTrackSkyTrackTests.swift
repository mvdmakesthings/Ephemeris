//
//  GroundTrackSkyTrackTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation
import XCTest
@testable import Ephemeris

final class GroundTrackSkyTrackTests: XCTestCase {

    // MARK: - Helper Methods

    /// Helper function to create UTC dates for testing
    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date? {
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

    // MARK: - Ground Track Tests

    func testGroundTrack_forISS_shouldGenerateValidPoints() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let start = epoch
        let end = start.addingTimeInterval(600) // 10 minutes

        // When
        let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)

        // Then
        // Should have 11 points (0, 60, 120, ..., 600 seconds)
        XCTAssertEqual(groundTrack.count, 11)

        // First and last points should match start/end times
        XCTAssertEqual(groundTrack.first!.time, start)
        XCTAssertEqual(groundTrack.last!.time, end)

        // All values should be within valid ranges
        for point in groundTrack {
            XCTAssertGreaterThanOrEqual(point.latitudeDeg, -90.0)
            XCTAssertLessThanOrEqual(point.latitudeDeg, 90.0)
            XCTAssertGreaterThanOrEqual(point.longitudeDeg, -180.0)
            XCTAssertLessThanOrEqual(point.longitudeDeg, 180.0)
        }

        // ISS inclination is ~51.6°, so latitude should stay within that range
        for point in groundTrack {
            XCTAssertLessThanOrEqual(abs(point.latitudeDeg), 52.0)
        }
    }

    func testGroundTrack_forEquatorialOrbit_shouldStayNearEquator() throws {
        // Given - Create a nearly equatorial orbit (low inclination)
        let tleString = """
            TEST EQUATORIAL
            1 99999U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
            2 99999   0.1000   0.0000 0001000   0.0000   0.0000 15.00000000000016
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 12, minute: 0, second: 0))
        let start = epoch
        let end = start.addingTimeInterval(3600) // 1 hour

        // When
        let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)

        // Then
        XCTAssertEqual(groundTrack.count, 61)

        // For equatorial orbit, latitude should stay very close to 0
        for point in groundTrack {
            XCTAssertLessThan(abs(point.latitudeDeg), 1.0)
        }
    }

    func testGroundTrack_forPolarOrbit_shouldReachHighLatitudes() throws {
        // Given - Create a polar orbit (high inclination ~90°)
        let tleString = """
            TEST POLAR
            1 88888U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9996
            2 88888  90.0000   0.0000 0001000   0.0000   0.0000 14.00000000000018
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 12, minute: 0, second: 0))
        let start = epoch
        let end = start.addingTimeInterval(3600) // 1 hour

        // When
        let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 60)

        // Then
        XCTAssertEqual(groundTrack.count, 61)

        // For polar orbit, latitude can reach near ±90°
        var hasHighLatitude = false
        for point in groundTrack {
            if abs(point.latitudeDeg) > 80.0 {
                hasHighLatitude = true
            }
        }
        XCTAssertTrue(hasHighLatitude, "Polar orbit should pass over high latitudes")
    }

    func testGroundTrack_forGEOOrbit_shouldStayNearEquator() throws {
        // Given - Create a geostationary orbit
        let tleString = """
            TEST GEO
            1 77777U 20001A   20097.50000000  .00000000  00000-0  00000-0 0  9991
            2 77777   0.0500   0.0000 0000100   0.0000   0.0000  1.00273790000013
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 12, minute: 0, second: 0))
        let start = epoch
        let end = start.addingTimeInterval(3600) // 1 hour

        // When
        let groundTrack = try orbit.groundTrack(from: start, to: end, stepSeconds: 300) // 5 min steps

        // Then
        XCTAssertEqual(groundTrack.count, 13)

        // GEO orbits stay near equator
        for point in groundTrack {
            XCTAssertLessThan(abs(point.latitudeDeg), 2.0)
        }
    }

    func testGroundTrack_withCustomStepSize_shouldRespectStepSize() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let start = epoch
        let end = start.addingTimeInterval(600) // 10 minutes

        // When
        // Test with 30 second steps
        let groundTrack30 = try orbit.groundTrack(from: start, to: end, stepSeconds: 30)

        // Test with 120 second steps
        let groundTrack120 = try orbit.groundTrack(from: start, to: end, stepSeconds: 120)

        // Then
        XCTAssertEqual(groundTrack30.count, 21) // 0, 30, 60, ..., 600
        XCTAssertEqual(groundTrack120.count, 6) // 0, 120, 240, 360, 480, 600
    }

    func testGroundTrack_withSingleTimePoint_shouldReturnSinglePoint() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))

        // When
        let groundTrack = try orbit.groundTrack(from: epoch, to: epoch, stepSeconds: 60)

        // Then
        // Should have exactly 1 point when start == end
        XCTAssertEqual(groundTrack.count, 1)
        XCTAssertEqual(groundTrack.first!.time, epoch)
    }

    // MARK: - Sky Track Tests

    func testSkyTrack_forISSPass_shouldGenerateValidPoints() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let start = epoch
        let end = start.addingTimeInterval(600) // 10 minutes

        // When
        let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 30)

        // Then
        // Should have 21 points (0, 30, 60, ..., 600 seconds)
        XCTAssertEqual(skyTrack.count, 21)

        // First and last points should match start/end times
        XCTAssertEqual(skyTrack.first!.time, start)
        XCTAssertEqual(skyTrack.last!.time, end)

        // All values should be within valid ranges
        for point in skyTrack {
            XCTAssertGreaterThanOrEqual(point.azimuthDeg, 0.0)
            XCTAssertLessThanOrEqual(point.azimuthDeg, 360.0)
            XCTAssertGreaterThanOrEqual(point.elevationDeg, -90.0)
            XCTAssertLessThanOrEqual(point.elevationDeg, 90.0)
        }
    }

    func testSkyTrack_overExtendedPeriod_shouldDetectBothAboveAndBelowHorizon() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let start = epoch
        let end = start.addingTimeInterval(7200) // 2 hours

        // When
        let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 60)

        // Then
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
        XCTAssertTrue(hasPositive)
        XCTAssertTrue(hasNegative)
    }

    func testSkyTrack_duringPass_shouldShowAzimuthChanges() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let start = epoch
        let end = start.addingTimeInterval(600) // 10 minutes

        // When
        let skyTrack = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 10)

        // Then
        XCTAssertEqual(skyTrack.count, 61)

        // During a pass, azimuth should change
        let firstAzimuth = skyTrack.first!.azimuthDeg
        let lastAzimuth = skyTrack.last!.azimuthDeg

        // Azimuth should change over 10 minutes
        XCTAssertGreaterThan(abs(firstAzimuth - lastAzimuth), 1.0)
    }

    func testSkyTrack_withCustomStepSize_shouldRespectStepSize() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let start = epoch
        let end = start.addingTimeInterval(300) // 5 minutes

        // When
        // Test with 10 second steps
        let skyTrack10 = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 10)

        // Test with 60 second steps
        let skyTrack60 = try orbit.skyTrack(for: observer, from: start, to: end, stepSeconds: 60)

        // Then
        XCTAssertEqual(skyTrack10.count, 31) // 0, 10, 20, ..., 300
        XCTAssertEqual(skyTrack60.count, 6) // 0, 60, 120, 180, 240, 300
    }

    func testSkyTrack_withSingleTimePoint_shouldReturnSinglePoint() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))

        // When
        let skyTrack = try orbit.skyTrack(for: observer, from: epoch, to: epoch, stepSeconds: 30)

        // Then
        // Should have exactly 1 point when start == end
        XCTAssertEqual(skyTrack.count, 1)
        XCTAssertEqual(skyTrack.first!.time, epoch)
    }

    func testSkyTrack_consistencyWithTopocentricCalculations_shouldMatch() throws {
        // Given
        let tleString = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        let tle = try TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)

        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let epoch = try XCTUnwrap(makeDate(year: 2020, month: 4, day: 6, hour: 19, minute: 53, second: 20))
        let testTime = epoch.addingTimeInterval(300) // 5 minutes after epoch

        // When
        // Get sky track point
        let skyTrack = try orbit.skyTrack(for: observer, from: testTime, to: testTime, stepSeconds: 60)
        let skyPoint = skyTrack.first!

        // Get direct topocentric calculation
        let topo = try orbit.topocentric(at: testTime, for: observer, applyRefraction: false)

        // Then
        // Should match
        XCTAssertEqual(skyPoint.azimuthDeg, topo.azimuthDeg, accuracy: 0.001)
        XCTAssertEqual(skyPoint.elevationDeg, topo.elevationDeg, accuracy: 0.001)
    }

    // MARK: - Data Structure Tests

    func testGroundTrackPoint_initialization_shouldStoreCorrectValues() {
        // Given
        let time = Date()
        let latitude = 38.2542
        let longitude = -85.7594

        // When
        let point = Orbit.GroundTrackPoint(time: time, latitudeDeg: latitude, longitudeDeg: longitude)

        // Then
        XCTAssertEqual(point.time, time)
        XCTAssertEqual(point.latitudeDeg, latitude)
        XCTAssertEqual(point.longitudeDeg, longitude)
    }

    func testSkyTrackPoint_initialization_shouldStoreCorrectValues() {
        // Given
        let time = Date()
        let azimuth = 180.0
        let elevation = 45.0

        // When
        let point = Orbit.SkyTrackPoint(time: time, azimuthDeg: azimuth, elevationDeg: elevation)

        // Then
        XCTAssertEqual(point.time, time)
        XCTAssertEqual(point.azimuthDeg, azimuth)
        XCTAssertEqual(point.elevationDeg, elevation)
    }
}

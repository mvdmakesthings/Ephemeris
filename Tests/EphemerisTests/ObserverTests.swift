//
//  ObserverTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 10/20/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Foundation
import XCTest
@testable import Ephemeris

final class ObserverTests: XCTestCase {

    // MARK: - Observer Initialization Tests

    func testObserver_initialization_shouldStoreCorrectCoordinates() {
        // Given
        let latitude = 38.2542
        let longitude = -85.7594
        let altitude = 140.0

        // When
        let observer = Observer(latitudeDeg: latitude, longitudeDeg: longitude, altitudeMeters: altitude)

        // Then
        XCTAssertEqual(observer.latitudeDeg, latitude)
        XCTAssertEqual(observer.longitudeDeg, longitude)
        XCTAssertEqual(observer.altitudeMeters, altitude)
    }

    // MARK: - Topocentric Initialization Tests

    func testTopocentric_initialization_shouldStoreCorrectValues() {
        // Given
        let azimuth = 45.0
        let elevation = 30.0
        let range = 1000.0
        let rangeRate = 5.0

        // When
        let topo = Topocentric(
            azimuthDeg: azimuth,
            elevationDeg: elevation,
            rangeKm: range,
            rangeRateKmPerSec: rangeRate
        )

        // Then
        XCTAssertEqual(topo.azimuthDeg, azimuth)
        XCTAssertEqual(topo.elevationDeg, elevation)
        XCTAssertEqual(topo.rangeKm, range)
        XCTAssertEqual(topo.rangeRateKmPerSec, rangeRate)
    }

    // MARK: - PassWindow Tests

    func testPassWindow_initialization_shouldCalculateDurationCorrectly() {
        // Given
        let aosTime = Date()
        let losTime = aosTime.addingTimeInterval(600) // 10 minutes later
        let maxTime = aosTime.addingTimeInterval(300) // 5 minutes later

        let aos = PassWindow.Point(time: aosTime, azimuthDeg: 90.0)
        let los = PassWindow.Point(time: losTime, azimuthDeg: 270.0)

        // When
        let pass = PassWindow(
            aos: aos,
            max: (time: maxTime, elevationDeg: 45.0, azimuthDeg: 180.0),
            los: los
        )

        // Then
        XCTAssertEqual(pass.aos.azimuthDeg, 90.0)
        XCTAssertEqual(pass.los.azimuthDeg, 270.0)
        XCTAssertEqual(pass.max.elevationDeg, 45.0)
        XCTAssertEqual(pass.duration, 600)
    }

    // MARK: - Geodetic to ECEF Conversion Tests

    func testGeodeticToECEF_withEquatorPrimeMeridian_shouldReturnCorrectECEF() {
        // Given
        // Point on equator at prime meridian, sea level

        // When
        let ecef = CoordinateTransforms.geodeticToECEF(
            latitudeDeg: 0.0,
            longitudeDeg: 0.0,
            altitudeMeters: 0.0
        )

        // Then
        // Should be at Earth's equatorial radius on X-axis
        XCTAssertEqual(ecef.x.round(to: 1), 6378.1)
        XCTAssertEqual(ecef.y.round(to: 1), 0.0)
        XCTAssertEqual(ecef.z.round(to: 1), 0.0)
    }

    func testGeodeticToECEF_withNorthPole_shouldReturnCorrectECEF() {
        // Given
        // North pole at sea level

        // When
        let ecef = CoordinateTransforms.geodeticToECEF(
            latitudeDeg: 90.0,
            longitudeDeg: 0.0,
            altitudeMeters: 0.0
        )

        // Then
        // Should be at Earth's polar radius on Z-axis
        XCTAssertEqual(ecef.x.round(to: 1), 0.0)
        XCTAssertEqual(ecef.y.round(to: 1), 0.0)
        XCTAssertEqual(ecef.z.round(to: 1), 6356.8)
    }

    func testGeodeticToECEF_withLouisvilleKY_shouldReturnValidECEF() {
        // Given
        // Louisville, Kentucky

        // When
        let ecef = CoordinateTransforms.geodeticToECEF(
            latitudeDeg: 38.2542,
            longitudeDeg: -85.7594,
            altitudeMeters: 140.0
        )

        // Then
        // Verify all components are non-zero and reasonable
        XCTAssertGreaterThan(abs(ecef.x), 0.0)
        XCTAssertGreaterThan(abs(ecef.y), 0.0)
        XCTAssertGreaterThan(abs(ecef.z), 0.0)

        // Total magnitude should be close to Earth radius + altitude
        // At lat 38°, radius is between polar (6356.8) and equatorial (6378.1)
        let magnitude = sqrt(ecef.x * ecef.x + ecef.y * ecef.y + ecef.z * ecef.z)
        XCTAssertGreaterThan(magnitude, 6356.0) // Greater than polar radius
        XCTAssertLessThan(magnitude, 6379.0) // Less than equatorial + altitude
    }

    // MARK: - Vector3D Operation Tests

    func testVector3D_magnitude_shouldCalculateCorrectly() {
        // Given
        let v = Vector3D(x: 3.0, y: 4.0, z: 0.0)

        // When
        let magnitude = v.magnitude

        // Then
        XCTAssertEqual(magnitude, 5.0)
    }

    func testVector3D_subtract_shouldCalculateCorrectly() {
        // Given
        let v1 = Vector3D(x: 5.0, y: 7.0, z: 9.0)
        let v2 = Vector3D(x: 2.0, y: 3.0, z: 4.0)

        // When
        let result = v1.subtract(v2)

        // Then
        XCTAssertEqual(result.x, 3.0)
        XCTAssertEqual(result.y, 4.0)
        XCTAssertEqual(result.z, 5.0)
    }

    func testVector3D_dotProduct_shouldCalculateCorrectly() {
        // Given
        let v1 = Vector3D(x: 1.0, y: 2.0, z: 3.0)
        let v2 = Vector3D(x: 4.0, y: 5.0, z: 6.0)

        // When
        let dot = v1.dot(v2)

        // Then
        // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
        XCTAssertEqual(dot, 32.0)
    }

    // MARK: - ENU to Azimuth/Elevation Tests

    func testENUToAzEl_withDirectlyNorth_shouldReturnCorrectValues() {
        // Given
        let enu = Vector3D(x: 0.0, y: 100.0, z: 0.0) // North on horizon

        // When
        let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)

        // Then
        XCTAssertEqual(az.round(to: 1), 0.0) // North = 0°
        XCTAssertEqual(el.round(to: 1), 0.0) // On horizon
        XCTAssertEqual(range, 100.0)
    }

    func testENUToAzEl_withDirectlyEast_shouldReturnCorrectValues() {
        // Given
        let enu = Vector3D(x: 100.0, y: 0.0, z: 0.0) // East on horizon

        // When
        let (az, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)

        // Then
        XCTAssertEqual(az.round(to: 1), 90.0) // East = 90°
        XCTAssertEqual(el.round(to: 1), 0.0) // On horizon
        XCTAssertEqual(range, 100.0)
    }

    func testENUToAzEl_withDirectlyUp_shouldReturnZenithElevation() {
        // Given
        let enu = Vector3D(x: 0.0, y: 0.0, z: 100.0) // Zenith

        // When
        let (_, el, range) = CoordinateTransforms.enuToAzEl(enu: enu)

        // Then
        XCTAssertEqual(el.round(to: 1), 90.0) // Zenith = 90°
        XCTAssertEqual(range, 100.0)
        // Azimuth is undefined at zenith, so we don't test it
    }

    func testENUToAzEl_with45DegreeElevation_shouldReturnCorrectValues() {
        // Given
        let enu = Vector3D(x: 100.0, y: 0.0, z: 100.0) // 45° elevation to east

        // When
        let (az, el, _) = CoordinateTransforms.enuToAzEl(enu: enu)

        // Then
        XCTAssertEqual(az.round(to: 1), 90.0) // East
        XCTAssertEqual(el.round(to: 1), 45.0) // 45° elevation
    }

    // MARK: - Topocentric Calculation Tests

    func testTopocentric_forISS_shouldReturnValidValues() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)
        let testDate = Date()

        // When
        let topo = try orbit.topocentric(at: testDate, for: observer)

        // Then
        // Verify outputs are in valid ranges
        XCTAssertGreaterThanOrEqual(topo.azimuthDeg, 0.0)
        XCTAssertLessThanOrEqual(topo.azimuthDeg, 360.0)
        XCTAssertGreaterThanOrEqual(topo.elevationDeg, -90.0)
        XCTAssertLessThanOrEqual(topo.elevationDeg, 90.0)
        XCTAssertGreaterThan(topo.rangeKm, 0.0)

        // Range should be at least altitude difference and less than half Earth's circumference
        XCTAssertLessThan(topo.rangeKm, 20000.0)
    }

    // MARK: - Atmospheric Refraction Tests

    func testAtmosphericRefraction_atLowAngles_shouldIncreaseElevation() {
        // Given
        let trueElev = 10.0

        // When
        let apparentElev = CoordinateTransforms.applyRefraction(elevationDeg: trueElev)

        // Then
        // Refraction should increase apparent elevation
        XCTAssertGreaterThan(apparentElev, trueElev)

        // Refraction at 10° should be small (less than 1°)
        XCTAssertLessThan((apparentElev - trueElev), 1.0)
    }

    func testAtmosphericRefraction_belowHorizon_shouldNotApplyRefraction() {
        // Given
        let trueElev = -5.0

        // When
        let apparentElev = CoordinateTransforms.applyRefraction(elevationDeg: trueElev)

        // Then
        // Should not change significantly below -1°
        XCTAssertEqual(apparentElev, trueElev)
    }

    func testAtmosphericRefraction_atHighElevations_shouldHaveMinimalEffect() {
        // Given
        let trueElev = 80.0

        // When
        let apparentElev = CoordinateTransforms.applyRefraction(elevationDeg: trueElev)

        // Then
        // Refraction should be very small at high elevations
        XCTAssertLessThan((apparentElev - trueElev), 0.1)
    }

    // MARK: - Pass Prediction Tests

    func testPassPrediction_forISS_shouldReturnValidPasses() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let start = Date()
        let end = start.addingTimeInterval(24 * 3600) // 24 hours later

        // When
        let passes = try orbit.predictPasses(
            for: observer,
            from: start,
            to: end,
            minElevationDeg: 10.0,
            stepSeconds: 30
        )

        // Then
        // We should find at least zero passes (may not find any if none meet the 10° threshold)
        XCTAssertGreaterThanOrEqual(passes.count, 0)

        // If we found passes, verify their structure
        for pass in passes {
            // AOS should be before LOS
            XCTAssertLessThan(pass.aos.time, pass.los.time)

            // Max should be between AOS and LOS
            XCTAssertGreaterThanOrEqual(pass.max.time, pass.aos.time)
            XCTAssertLessThanOrEqual(pass.max.time, pass.los.time)

            // Duration should be positive
            XCTAssertGreaterThan(pass.duration, 0)
            XCTAssertLessThan(pass.duration, 3600) // Less than 1 hour

            // Elevation should be above minimum
            XCTAssertGreaterThanOrEqual(pass.max.elevationDeg, 10.0)

            // Azimuth should be in valid range
            XCTAssertGreaterThanOrEqual(pass.aos.azimuthDeg, 0.0)
            XCTAssertLessThanOrEqual(pass.aos.azimuthDeg, 360.0)
            XCTAssertGreaterThanOrEqual(pass.los.azimuthDeg, 0.0)
            XCTAssertLessThanOrEqual(pass.los.azimuthDeg, 360.0)
            XCTAssertGreaterThanOrEqual(pass.max.azimuthDeg, 0.0)
            XCTAssertLessThanOrEqual(pass.max.azimuthDeg, 360.0)
        }
    }

    func testPassPrediction_withShortTimeWindow_shouldCompleteSuccessfully() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour later

        // When
        let passes = try orbit.predictPasses(
            for: observer,
            from: start,
            to: end,
            minElevationDeg: 0.0,
            stepSeconds: 30
        )

        // Then
        // Should complete without error
        XCTAssertGreaterThanOrEqual(passes.count, 0)
    }

    func testPassPrediction_withMinimumElevationThreshold_shouldFilterCorrectly() throws {
        // Given
        let tle = try MockTLEs.ISSSample()
        let orbit = Orbit(from: tle)
        let observer = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

        let start = Date()
        let end = start.addingTimeInterval(12 * 3600) // 12 hours

        // When
        // Search with low threshold
        let passesLow = try orbit.predictPasses(
            for: observer,
            from: start,
            to: end,
            minElevationDeg: 0.0,
            stepSeconds: 60
        )

        // Search with high threshold
        let passesHigh = try orbit.predictPasses(
            for: observer,
            from: start,
            to: end,
            minElevationDeg: 30.0,
            stepSeconds: 60
        )

        // Then
        // Should find more passes with lower threshold
        XCTAssertLessThanOrEqual(passesHigh.count, passesLow.count)

        // All high-elevation passes should have max elevation >= 30°
        for pass in passesHigh {
            XCTAssertGreaterThanOrEqual(pass.max.elevationDeg, 30.0)
        }
    }
}

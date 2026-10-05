//
//  CoordinateTransformsTests.swift
//  EphemerisTests
//
//  Geodetic ↔ ECEF, ECI → ECEF, ECEF → ENU → look angles, refraction, and Vector3D.
//

import Foundation
import XCTest
@testable import Ephemeris

final class CoordinateTransformsTests: XCTestCase {

    // MARK: - Geodetic ↔ ECEF

    func testGeodeticToECEF_atEquatorAndPrimeMeridian_shouldLieOnXAxis() {
        // Given/When
        let ecef = CoordinateTransforms.geodeticToECEF(GeodeticPosition(latitudeDeg: 0, longitudeDeg: 0, altitudeKm: 0))

        // Then
        XCTAssertEqual(ecef.x, PhysicalConstants.Earth.semiMajorAxis, accuracy: 1e-9)
        XCTAssertEqual(ecef.y, 0, accuracy: 1e-9)
        XCTAssertEqual(ecef.z, 0, accuracy: 1e-9)
    }

    func testGeodeticToECEF_atNorthPole_shouldBeAtPolarRadius() {
        // Given/When
        let ecef = CoordinateTransforms.geodeticToECEF(GeodeticPosition(latitudeDeg: 90, longitudeDeg: 0, altitudeKm: 0))

        // Then
        // WGS-84 semi-minor axis b = a·√(1 − e²) = 6356.7523142 km
        XCTAssertEqual(ecef.z, 6356.7523142, accuracy: 1e-6)
        XCTAssertEqual(hypot(ecef.x, ecef.y), 0, accuracy: 1e-9)
    }

    func testECEFToGeodetic_withValladoExample3_3_shouldMatchPublishedValues() {
        // Given
        // Vallado, "Fundamentals of Astrodynamics and Applications", Example 3-3:
        // r = (6524.834, 6862.875, 6448.296) km → φgd = 34.352496°, λ = 46.4464°, h = 5085.22 km
        let ecef = Vector3D(x: 6524.834, y: 6862.875, z: 6448.296)

        // When
        let position = CoordinateTransforms.ecefToGeodetic(ecef)

        // Then
        XCTAssertEqual(position.latitudeDeg, 34.352496, accuracy: 1e-5)
        XCTAssertEqual(position.longitudeDeg, 46.4464, accuracy: 1e-4)
        XCTAssertEqual(position.altitudeKm, 5085.22, accuracy: 0.01)
    }

    func testECEFToGeodetic_roundTripWithGeodeticToECEF_shouldRecoverInputs() {
        // Given
        let latitudes: [Double] = [-90, -89.9, -60, -34.5, 0, 12.3, 45, 77.7, 89.9, 90]
        let longitudes: [Double] = [-179.9, -85.7594, 0, 46.4464, 179.9]
        let altitudes: [Double] = [0, 0.14, 420, 20200, 35786]

        for lat in latitudes {
            for lon in longitudes {
                for alt in altitudes {
                    // When
                    let original = GeodeticPosition(latitudeDeg: lat, longitudeDeg: lon, altitudeKm: alt)
                    let recovered = CoordinateTransforms.ecefToGeodetic(CoordinateTransforms.geodeticToECEF(original))

                    // Then
                    XCTAssertEqual(recovered.latitudeDeg, lat, accuracy: 1e-9)
                    XCTAssertEqual(recovered.altitudeKm, alt, accuracy: 1e-6)
                    // Longitude is undefined at the poles
                    if abs(lat) < 90 {
                        XCTAssertEqual(recovered.longitudeDeg, lon, accuracy: 1e-9)
                    }
                }
            }
        }
    }

    // MARK: - ECI → ECEF

    func testECIToECEF_withQuarterTurn_shouldRotateBackward() {
        // Given
        // When Greenwich has turned 90° past the vernal equinox, a point on the inertial
        // +x axis sits 90° west of Greenwich, on the Earth-fixed −y axis
        let eci = Vector3D(x: 7000, y: 0, z: 1000)

        // When
        let ecef = CoordinateTransforms.eciToECEF(eci, gmst: .pi / 2)

        // Then
        XCTAssertEqual(ecef.x, 0, accuracy: 1e-9)
        XCTAssertEqual(ecef.y, -7000, accuracy: 1e-9)
        XCTAssertEqual(ecef.z, 1000, accuracy: 1e-12)
    }

    func testECIToECEF_forGeostationaryState_shouldBeNearlyStationary() {
        // Given
        // A geostationary satellite moves with the Earth, so its Earth-relative velocity is ~0
        let radius = 42164.0
        let speed = PhysicalConstants.Earth.rotationRate * radius
        let state = StateVector(position: Vector3D(x: radius, y: 0, z: 0), velocity: Vector3D(x: 0, y: speed, z: 0))

        // When
        let ecef = CoordinateTransforms.eciToECEF(state, gmst: 1.234)

        // Then
        XCTAssertEqual(ecef.velocity.magnitude, 0, accuracy: 1e-12)
        XCTAssertEqual(ecef.position.magnitude, radius, accuracy: 1e-9)
    }

    // MARK: - ECEF → ENU → Look Angles

    func testECEFToENU_forPointDirectlyAbove_shouldBePureUp() {
        // Given
        let observer = GeodeticPosition(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeKm: 0.14)
        let above = CoordinateTransforms.geodeticToECEF(
            GeodeticPosition(latitudeDeg: observer.latitudeDeg, longitudeDeg: observer.longitudeDeg, altitudeKm: 500.14)
        )

        // When
        let enu = CoordinateTransforms.ecefToENU(above, observer: observer)

        // Then
        XCTAssertEqual(enu.x, 0, accuracy: 1e-6)
        XCTAssertEqual(enu.y, 0, accuracy: 1e-6)
        XCTAssertEqual(enu.z, 500, accuracy: 1e-6)
    }

    func testENUToAzEl_forCardinalDirections_shouldMeasureClockwiseFromNorth() {
        // Given/When/Then
        let north = CoordinateTransforms.enuToAzEl(Vector3D(x: 0, y: 100, z: 0))
        XCTAssertEqual(north.azimuthDeg, 0, accuracy: 1e-12)
        XCTAssertEqual(north.elevationDeg, 0, accuracy: 1e-12)
        XCTAssertEqual(north.rangeKm, 100, accuracy: 1e-12)

        XCTAssertEqual(CoordinateTransforms.enuToAzEl(Vector3D(x: 100, y: 0, z: 0)).azimuthDeg, 90, accuracy: 1e-12)
        XCTAssertEqual(CoordinateTransforms.enuToAzEl(Vector3D(x: 0, y: -100, z: 0)).azimuthDeg, 180, accuracy: 1e-12)
        XCTAssertEqual(CoordinateTransforms.enuToAzEl(Vector3D(x: -100, y: 0, z: 0)).azimuthDeg, 270, accuracy: 1e-12)
    }

    func testENUToAzEl_forElevatedPoints_shouldMeasureAngleAboveHorizon() {
        // Given/When/Then
        XCTAssertEqual(CoordinateTransforms.enuToAzEl(Vector3D(x: 0, y: 0, z: 100)).elevationDeg, 90, accuracy: 1e-12)
        let diagonal = CoordinateTransforms.enuToAzEl(Vector3D(x: 0, y: 100, z: 100))
        XCTAssertEqual(diagonal.elevationDeg, 45, accuracy: 1e-12)
        XCTAssertEqual(diagonal.rangeKm, 100 * sqrt(2), accuracy: 1e-12)
    }

    // MARK: - Refraction

    func testApparentElevation_shouldMatchSaemundssonValues() {
        // Given/When/Then
        // R = 1.02 / tan(h + 10.3/(h + 5.11)) arcminutes: 28.98′ at the horizon, 5.41′ at 10°
        XCTAssertEqual(CoordinateTransforms.apparentElevation(fromTrueElevationDeg: 0), 28.98 / 60, accuracy: 0.001)
        XCTAssertEqual(CoordinateTransforms.apparentElevation(fromTrueElevationDeg: 10), 10 + 5.408 / 60, accuracy: 0.001)
    }

    func testApparentElevation_shouldShrinkWithElevationAndNeverBeNegative() {
        // Given/When/Then
        var previousRefraction = Double.infinity
        for elevation in stride(from: 0.0, through: 90.0, by: 5.0) {
            let refraction = CoordinateTransforms.apparentElevation(fromTrueElevationDeg: elevation) - elevation
            XCTAssertGreaterThanOrEqual(refraction, 0, "\(elevation)°")
            XCTAssertLessThanOrEqual(refraction, previousRefraction, "\(elevation)°")
            previousRefraction = refraction
        }
    }

    func testApparentElevation_wellBelowHorizon_shouldBeUnchanged() {
        // Given/When/Then
        XCTAssertEqual(CoordinateTransforms.apparentElevation(fromTrueElevationDeg: -5), -5)
    }

    // MARK: - Vector3D

    func testVector3D_operations_shouldFollowVectorAlgebra() {
        // Given
        let a = Vector3D(x: 1, y: 2, z: 2)
        let b = Vector3D(x: 4, y: -1, z: 0.5)

        // When/Then
        XCTAssertEqual(a.magnitude, 3)
        XCTAssertEqual(a + b, Vector3D(x: 5, y: 1, z: 2.5))
        XCTAssertEqual(a - b, Vector3D(x: -3, y: 3, z: 1.5))
        XCTAssertEqual(a * 2, Vector3D(x: 2, y: 4, z: 4))
        XCTAssertEqual(a.dot(b), 3)
    }
}

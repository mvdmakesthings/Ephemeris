//
//  KeplerianOrbitTests.swift
//  EphemerisTests
//
//  Two-body propagation: Kepler's third law, Kepler's equation, the anomalies, and
//  physical invariants of the resulting state vectors.
//

import Foundation
import XCTest
@testable import Ephemeris

final class KeplerianOrbitTests: XCTestCase {

    // MARK: - Helpers

    private let mu = PhysicalConstants.Earth.mu

    private func molniya(epoch: Date = Date(timeIntervalSince1970: 0)) -> KeplerianOrbit {
        KeplerianOrbit(semimajorAxis: 26_600, eccentricity: 0.74, inclination: 63.4,
                       rightAscensionOfAscendingNode: 40, argumentOfPerigee: 270,
                       meanAnomaly: 0, epoch: epoch)
    }

    // MARK: - Kepler's Third Law

    func testSemimajorAxis_forGeostationaryMeanMotion_shouldBeGeostationaryRadius() {
        // Given
        // GOES-16 mean motion; geostationary radius is 42,164 km
        let meanMotion = 1.00271173

        // When
        let semimajorAxis = KeplerianOrbit.semimajorAxis(meanMotion: meanMotion)

        // Then
        XCTAssertEqual(semimajorAxis, 42164.9035, accuracy: 1e-3)
    }

    func testMeanMotion_andSemimajorAxis_shouldBeInverses() {
        // Given/When/Then
        for semimajorAxis in [6_700.0, 7_000.0, 26_560.0, 42_164.0] {
            let meanMotion = KeplerianOrbit.meanMotion(semimajorAxis: semimajorAxis)
            XCTAssertEqual(KeplerianOrbit.semimajorAxis(meanMotion: meanMotion), semimajorAxis, accuracy: 1e-8)
        }
    }

    // MARK: - Kepler's Equation

    func testSolveKeplersEquation_withValladoExample2_1_shouldMatchPublishedValue() {
        // Given
        // Vallado, "Fundamentals of Astrodynamics and Applications", Example 2-1:
        // M = 235.4°, e = 0.4 → E = 220.512074767522°
        // When
        let eccentricAnomaly = KeplerianOrbit.solveKeplersEquation(meanAnomaly: 235.4, eccentricity: 0.4)

        // Then
        XCTAssertEqual(eccentricAnomaly, 220.512074767522, accuracy: 1e-9)
    }

    func testSolveKeplersEquation_withHighEccentricity_shouldSatisfyKeplersEquationEverywhere() {
        // Given
        // Molniya-type eccentricity. The Newton step can be negative; a convergence check
        // without abs() would stop after one step and leave errors of several degrees.
        let eccentricity = 0.7

        for meanAnomaly in stride(from: 0.0, to: 360.0, by: 1.0) {
            // When
            let eccentricAnomaly = KeplerianOrbit.solveKeplersEquation(meanAnomaly: meanAnomaly, eccentricity: eccentricity)
                .inRadians()

            // Then
            // M = E − e·sin(E)
            XCTAssertEqual(eccentricAnomaly - eccentricity * sin(eccentricAnomaly), meanAnomaly.inRadians(),
                           accuracy: 1e-11, "M = \(meanAnomaly)°")
        }
    }

    // MARK: - True Anomaly

    func testTrueAnomaly_shouldMatchValladoEquation2_9() {
        // Given
        // Independent form: ν = atan2(√(1 − e²)·sin E, cos E − e)
        let cases: [(eccentricAnomaly: Double, eccentricity: Double)] = [(30, 0.5), (150, 0.3), (270, 0.7), (10, 0.01)]

        for (eccentricAnomaly, eccentricity) in cases {
            // When
            let trueAnomaly = KeplerianOrbit.trueAnomaly(eccentricAnomaly: eccentricAnomaly, eccentricity: eccentricity)

            // Then
            let e = eccentricAnomaly.inRadians()
            let expected = atan2(sqrt(1 - eccentricity * eccentricity) * sin(e), cos(e) - eccentricity).inDegrees()
            // Compare as angles: 225.57° and −134.43° are the same direction
            let difference = (trueAnomaly - expected + 540).truncatingRemainder(dividingBy: 360) - 180
            XCTAssertEqual(difference, 0, accuracy: 1e-9, "E = \(eccentricAnomaly)°, e = \(eccentricity)")
        }
    }

    func testTrueAnomaly_forCircularOrbit_shouldEqualEccentricAnomaly() {
        // Given/When/Then
        // With e = 0 all three anomalies coincide
        XCTAssertEqual(KeplerianOrbit.trueAnomaly(eccentricAnomaly: 30, eccentricity: 0), 30, accuracy: 1e-12)
    }

    func testTrueAnomaly_atPerigeeAndApogee_shouldBeZeroAndOneEighty() {
        // Given/When/Then
        XCTAssertEqual(KeplerianOrbit.trueAnomaly(eccentricAnomaly: 0, eccentricity: 0.6), 0, accuracy: 1e-12)
        XCTAssertEqual(abs(KeplerianOrbit.trueAnomaly(eccentricAnomaly: 180, eccentricity: 0.6)), 180, accuracy: 1e-9)
    }

    // MARK: - Initialization

    func testInit_fromTLE_shouldCopyElementsAndDeriveSemimajorAxis() throws {
        // Given
        let tle = try MockTLEs.ISSSample()

        // When
        let orbit = KeplerianOrbit(tle: tle)

        // Then
        XCTAssertEqual(orbit.inclination, 51.6465)
        XCTAssertEqual(orbit.rightAscensionOfAscendingNode, 341.5807)
        XCTAssertEqual(orbit.eccentricity, 0.000388, accuracy: 1e-12)
        XCTAssertEqual(orbit.argumentOfPerigee, 94.4223)
        XCTAssertEqual(orbit.meanAnomaly, 26.1197)
        XCTAssertEqual(orbit.meanMotion, 15.48685836)
        XCTAssertEqual(orbit.epoch, tle.epoch)
        // a = (μ/n²)^(1/3) for 15.48685836 rev/day
        XCTAssertEqual(orbit.semimajorAxis, 6798.7065, accuracy: 1e-3)
        XCTAssertEqual(orbit.orbitalPeriod / 60, 92.982, accuracy: 1e-3)
    }

    func testInit_fromElements_shouldDeriveMeanMotionAndAltitudes() {
        // Given/When
        let orbit = molniya()

        // Then
        XCTAssertEqual(orbit.meanMotion, KeplerianOrbit.meanMotion(semimajorAxis: 26_600), accuracy: 1e-12)
        XCTAssertEqual(orbit.perigeeAltitude, 26_600 * 0.26 - 6378.137, accuracy: 1e-9)
        XCTAssertEqual(orbit.apogeeAltitude, 26_600 * 1.74 - 6378.137, accuracy: 1e-9)
    }

    // MARK: - Propagation Over Time

    func testMeanAnomaly_afterOnePeriod_shouldReturnToEpochValue() {
        // Given
        let orbit = molniya()

        // When
        let later = orbit.meanAnomaly(at: orbit.epoch.addingTimeInterval(orbit.orbitalPeriod))

        // Then
        // Compare as angles: 359.9999999° and 0° are the same point
        let difference = (later - orbit.meanAnomaly + 540).truncatingRemainder(dividingBy: 360) - 180
        XCTAssertEqual(difference, 0, accuracy: 1e-6)
    }

    func testStateVector_atEpochWithZeroMeanAnomaly_shouldBeAtPerigee() {
        // Given
        let orbit = molniya()

        // When
        let state = orbit.stateVector(at: orbit.epoch)

        // Then
        XCTAssertEqual(state.position.magnitude, orbit.semimajorAxis * (1 - orbit.eccentricity), accuracy: 1e-6)
        // At perigee, velocity is perpendicular to the radius vector
        XCTAssertEqual(state.position.dot(state.velocity), 0, accuracy: 1e-6)
    }

    func testStateVector_overOneOrbit_shouldConserveEnergyAndAngularMomentum() {
        // Given
        // Two-body motion conserves specific energy (vis-viva: v²/2 − μ/r = −μ/2a)
        // and the magnitude of specific angular momentum (h = √(μ·a(1 − e²)))
        let orbit = molniya()
        let expectedEnergy = -mu / (2 * orbit.semimajorAxis)
        let expectedMomentum = sqrt(mu * orbit.semimajorAxis * (1 - orbit.eccentricity * orbit.eccentricity))

        for fraction in stride(from: 0.0, to: 1.0, by: 0.05) {
            // When
            let state = orbit.stateVector(at: orbit.epoch.addingTimeInterval(fraction * orbit.orbitalPeriod))
            let r = state.position
            let v = state.velocity

            // Then
            let energy = v.dot(v) / 2 - mu / r.magnitude
            let momentum = Vector3D(x: r.y * v.z - r.z * v.y, y: r.z * v.x - r.x * v.z, z: r.x * v.y - r.y * v.x).magnitude
            XCTAssertEqual(energy, expectedEnergy, accuracy: 1e-9, "fraction \(fraction)")
            XCTAssertEqual(momentum, expectedMomentum, accuracy: 1e-6, "fraction \(fraction)")
        }
    }

    func testStateVector_shouldStayInOrbitalPlane() {
        // Given
        // The orbit normal makes angle i with the z axis
        let orbit = molniya()
        let first = orbit.stateVector(at: orbit.epoch)
        let r = first.position
        let v = first.velocity
        let normal = Vector3D(x: r.y * v.z - r.z * v.y, y: r.z * v.x - r.x * v.z, z: r.x * v.y - r.y * v.x)

        // When/Then
        XCTAssertEqual(acos(normal.z / normal.magnitude).inDegrees(), orbit.inclination, accuracy: 1e-9)
        for hours in [1.0, 3.0, 7.0] {
            let position = orbit.stateVector(at: orbit.epoch.addingTimeInterval(hours * 3600)).position
            XCTAssertEqual(position.dot(normal) / normal.magnitude, 0, accuracy: 1e-6)
        }
    }
}

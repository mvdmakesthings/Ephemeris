//
//  TopocentricTests.swift
//  EphemerisTests
//
//  Look angles from an observer: geometry consistency and range rate (Doppler).
//

import Foundation
import XCTest
@testable import Ephemeris

final class TopocentricTests: XCTestCase {

    // MARK: - Helpers

    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

    // MARK: - Geometry

    func testTopocentric_fromSubSatellitePoint_shouldSeeSatelliteAtZenith() throws {
        // Given
        // Standing at the reported sub-satellite point, the satellite is straight overhead.
        // This only holds if calculatePosition returns geodetic latitude (measured along
        // the ellipsoid normal), consistent with the observer frame.
        let propagators: [Propagator] = [try SGP4(tle: try MockTLEs.ISSSample()),
                                         KeplerianOrbit(tle: try MockTLEs.ISSSample())]
        let epoch = try MockTLEs.ISSSample().epoch

        for propagator in propagators {
            for minutes in stride(from: 0.0, through: 90.0, by: 7.5) {
                let date = epoch.addingTimeInterval(minutes * 60)

                // When
                let position = try propagator.calculatePosition(at: date)
                let observer = Observer(latitudeDeg: position.latitudeDeg, longitudeDeg: position.longitudeDeg,
                                        altitudeMeters: 0)
                let topo = try propagator.topocentric(at: date, for: observer)

                // Then
                XCTAssertEqual(topo.elevationDeg, 90.0, accuracy: 1e-6)
                XCTAssertEqual(topo.rangeKm, position.altitudeKm, accuracy: 1e-6)
            }
        }
    }

    func testTopocentric_withRefraction_shouldRaiseElevationOnly() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2020-04-07T00:31:00Z"))

        // When
        let geometric = try sgp4.topocentric(at: date, for: louisville)
        let apparent = try sgp4.topocentric(at: date, for: louisville, applyRefraction: true)

        // Then
        XCTAssertGreaterThan(apparent.elevationDeg, geometric.elevationDeg)
        XCTAssertEqual(apparent.azimuthDeg, geometric.azimuthDeg)
        XCTAssertEqual(apparent.rangeKm, geometric.rangeKm)
    }

    // MARK: - Range Rate

    /// Largest gap between reported range rate and the numerical slope of range,
    /// (range(t + h) − range(t − h)) / 2h, over a day of samples.
    private func worstRangeRateError(_ propagator: Propagator, from start: Date) throws -> Double {
        let h = 0.25
        var worst = 0.0
        for minutes in stride(from: 0.0, through: 1440.0, by: 37.0) {
            let date = start.addingTimeInterval(minutes * 60)
            let topo = try propagator.topocentric(at: date, for: louisville)
            let before = try propagator.topocentric(at: date.addingTimeInterval(-h), for: louisville).rangeKm
            let after = try propagator.topocentric(at: date.addingTimeInterval(h), for: louisville).rangeKm
            worst = max(worst, abs(topo.rangeRateKmPerSec - (after - before) / (2 * h)))
        }
        return worst
    }

    func testRangeRate_withTwoBodyOrbit_shouldEqualNumericalDerivativeOfRange() throws {
        // Given
        // Range rate drives Doppler correction, so check the math against the slope of range
        // itself. Two-body velocity is the exact derivative of two-body position, so this
        // isolates the Earth-rotation and line-of-sight math. The central difference has its
        // own truncation error of about h²/6 · d³(range)/dt³, ~1.6e-6 km/s for h = 0.25 s.
        let orbit = KeplerianOrbit(tle: try MockTLEs.ISSSample())

        // When
        let worst = try worstRangeRateError(orbit, from: orbit.epoch)

        // Then
        XCTAssertLessThan(worst, 5e-6)
    }

    func testRangeRate_withSGP4_shouldMatchSlopeOfRangeWithinSGP4VelocityConsistency() throws {
        // Given
        // SGP4's velocity comes from its own analytic formulas rather than by differentiating
        // its position, and the two agree to about 2 cm/s. That is the floor here: 3e-5 km/s
        // is about 0.04 Hz of Doppler at 437 MHz.
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())

        // When
        let worst = try worstRangeRateError(sgp4, from: sgp4.epoch)

        // Then
        XCTAssertLessThan(worst, 3e-5)
    }

    func testRangeRate_forGeostationarySatellite_shouldBeNearlyZero() throws {
        // Given
        let geo = try SGP4(tle: try MockTLEs.geostationarySample())

        // When
        let topo = try geo.topocentric(at: geo.epoch.addingTimeInterval(3600), for: louisville)

        // Then
        // Fixed in the sky, so almost no Doppler (residual from slight eccentricity/inclination)
        XCTAssertLessThan(abs(topo.rangeRateKmPerSec), 0.01)
    }
}

//
//  DopplerTests.swift
//  EphemerisTests
//
//  Doppler shift and Doppler rate, checked against Skyfield 1.x for the same ISS pass used
//  in EndToEndCrossCheckTests. Skyfield values: range rate from
//  (sat - observer).at(t).frame_latlon_and_rates(observer), turned into frequency with
//  f · (1 − ṙ/c), and the rate from a central difference of Skyfield's range rate at ±0.5 s.
//
//  Skyfield applies UT1 − UTC (−0.23 s here); Ephemeris uses UTC. Range rate agrees to about
//  2 m/s (1 Hz at 145.8 MHz); the measured difference is at most 0.51 Hz, so frequencies are
//  compared to 1 Hz and rates (measured within 0.003 Hz/s) to 0.02 Hz/s.
//

import Foundation
import XCTest
@testable import Ephemeris

final class DopplerTests: XCTestCase {

    /// ISS FM voice downlink
    private let nominal = 145_800_000.0
    private let louisville = Observer(latitudeDeg: 38.2542, longitudeDeg: -85.7594, altitudeMeters: 140)

    private func date(_ iso8601: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return try XCTUnwrap(formatter.date(from: iso8601) ?? ISO8601DateFormatter().date(from: iso8601))
    }

    // MARK: - Formulas

    func testDownlinkFrequency_withZeroRangeRate_shouldEqualNominal() {
        XCTAssertEqual(Doppler.downlinkFrequency(nominalHz: nominal, rangeRateKmPerSec: 0), nominal)
        XCTAssertEqual(Doppler.downlinkShift(nominalHz: nominal, rangeRateKmPerSec: 0), 0)
    }

    func testDownlinkFrequency_whenApproaching_shouldBeHigher() {
        // Given: closing at 7 km/s. Expected shift = f · 7 / 299,792.458 = 3404.36 Hz
        let rangeRate = -7.0

        // When
        let received = Doppler.downlinkFrequency(nominalHz: nominal, rangeRateKmPerSec: rangeRate)
        let shift = Doppler.downlinkShift(nominalHz: nominal, rangeRateKmPerSec: rangeRate)

        // Then
        XCTAssertEqual(shift, 3404.36, accuracy: 0.01)
        XCTAssertEqual(received - nominal, shift, accuracy: 1e-6)
    }

    func testUplinkFrequency_shouldUndoTheDopplerShiftAtTheSatellite() {
        // Given: the satellite hears f_tx · (1 − ṙ/c)
        for rangeRate in [-7.5, -3.2, 0, 2.1, 7.5] {
            // When
            let transmit = Doppler.uplinkFrequency(nominalHz: 435_000_000, rangeRateKmPerSec: rangeRate)
            let heardBySatellite = Doppler.downlinkFrequency(nominalHz: transmit, rangeRateKmPerSec: rangeRate)

            // Then
            XCTAssertEqual(heardBySatellite, 435_000_000, accuracy: 1e-6, "ṙ = \(rangeRate)")
        }
    }

    // MARK: - Against Skyfield

    func testDoppler_duringISSPass_shouldMatchSkyfield() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let reference: [(time: String, shift: Double, rate: Double)] = [
            ("2020-04-07T00:31:00Z", 3138.350, -3.568),
            ("2020-04-07T00:33:25Z", 25.135, -52.202),
            ("2020-04-07T00:35:30Z", -3048.673, -5.300)
        ]

        for expected in reference {
            // When
            let point = try sgp4.doppler(at: try date(expected.time), for: louisville, nominalFrequencyHz: nominal)

            // Then
            XCTAssertEqual(point.shiftHz, expected.shift, accuracy: 1.0, expected.time)
            XCTAssertEqual(point.frequencyHz, nominal + expected.shift, accuracy: 1.0, expected.time)
            XCTAssertEqual(point.rateHzPerSec, expected.rate, accuracy: 0.02, expected.time)
        }
    }

    func testDopplerCurve_duringISSPass_shouldCrossZeroAtSkyfieldClosestApproach() throws {
        // Given: Skyfield's range rate crosses zero at 00:33:25.48 UTC
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let closestApproach = try date("2020-04-07T00:33:25.48Z")

        // When
        let curve = try sgp4.dopplerCurve(for: louisville, nominalFrequencyHz: nominal,
                                          from: try date("2020-04-07T00:32:00Z"),
                                          to: try date("2020-04-07T00:35:00Z"), stepSeconds: 1)

        // Then: exactly one sign change, found by linear interpolation between samples
        let crossings = zip(curve, curve.dropFirst()).filter { $0.shiftHz > 0 && $1.shiftHz <= 0 }
        XCTAssertEqual(crossings.count, 1)
        let (before, after) = try XCTUnwrap(crossings.first)
        let fraction = before.shiftHz / (before.shiftHz - after.shiftHz)
        let zeroTime = before.time.addingTimeInterval(fraction * after.time.timeIntervalSince(before.time))
        // UT1 − UTC (0.23 s) and the 2 m/s range-rate difference allow a few tenths of a second
        XCTAssertEqual(zeroTime.timeIntervalSince(closestApproach), 0, accuracy: 0.5)
    }

    // MARK: - Internal Consistency

    func testDopplerRate_shouldMatchSlopeOfTheCurve() throws {
        // Given: a curve sampled every second, so its slope is an independent rate estimate
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let curve = try sgp4.dopplerCurve(for: louisville, nominalFrequencyHz: 437_800_000,
                                          from: try date("2020-04-07T00:31:00Z"),
                                          to: try date("2020-04-07T00:36:00Z"), stepSeconds: 1)

        // When / Then: (f(t+1) − f(t−1)) / 2 s against the reported rate at t
        for index in 1..<(curve.count - 1) {
            let slope = (curve[index + 1].frequencyHz - curve[index - 1].frequencyHz) / 2
            // A 2 s secant differs from the instantaneous rate by at most 0.013 Hz/s here
            XCTAssertEqual(curve[index].rateHzPerSec, slope, accuracy: 0.05, "\(curve[index].time)")
        }
    }

    func testDopplerCurve_shouldIncludeBothEndsAndStayWithinOrbitalSpeed() throws {
        // Given
        let sgp4 = try SGP4(tle: try MockTLEs.ISSSample())
        let start = try date("2020-04-07T00:00:00Z")
        let end = start.addingTimeInterval(95)

        // When
        let curve = try sgp4.dopplerCurve(for: louisville, nominalFrequencyHz: nominal, from: start, to: end)

        // Then: samples at 0, 10, ..., 90 and the end at 95
        XCTAssertEqual(curve.count, 11)
        XCTAssertEqual(curve.first?.time, start)
        XCTAssertEqual(curve.last?.time, end)
        // The line-of-sight speed can never exceed the ISS's orbital speed (about 7.7 km/s)
        let limit = nominal * 7.8 / PhysicalConstants.speedOfLight
        XCTAssertTrue(curve.allSatisfy { abs($0.shiftHz) < limit })
    }
}

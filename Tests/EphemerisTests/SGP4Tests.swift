//
//  SGP4Tests.swift
//  EphemerisTests
//
//  Tests for the SGP4 public API, options not covered by the Vallado verification
//  vectors (WGS-84 gravity, AFSPC mode), and integration with the Propagator features.
//
//  Reference values marked "python-sgp4" come from python-sgp4 2.27 (pure-Python
//  propagation module), an independent port of the same reference implementation.
//

import Foundation
import XCTest
@testable import Ephemeris

final class SGP4Tests: XCTestCase {

    // MARK: - Helpers

    private func makeSGP4(_ line1: String, _ line2: String,
                          gravity: GravityModel = .wgs72,
                          mode: SGP4.OperationMode = .improved) throws -> SGP4 {
        let tle = try TwoLineElement(from: "\(line1)\n\(line2)")
        return try SGP4(tle: tle, gravity: gravity, operationMode: mode)
    }

    private func assertState(_ state: StateVector, position: [Double], velocity: [Double],
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(state.position.x, position[0], accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(state.position.y, position[1], accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(state.position.z, position[2], accuracy: 1e-6, file: file, line: line)
        XCTAssertEqual(state.velocity.x, velocity[0], accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(state.velocity.y, velocity[1], accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(state.velocity.z, velocity[2], accuracy: 1e-9, file: file, line: line)
    }

    private let issLine1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
    private let issLine2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"

    // MARK: - Epoch

    func testEpoch_forISS_shouldMatchTLEEpoch() throws {
        // Given
        // 20097.82871450 → 2020, day 97 (April 6) + 0.82871450 day = 19:53:20.9328 UTC
        let expected = try XCTUnwrap(ISO8601DateFormatter().date(from: "2020-04-06T19:53:20Z"))
            .addingTimeInterval(0.9328)

        // When
        let sgp4 = try makeSGP4(issLine1, issLine2)

        // Then
        XCTAssertEqual(sgp4.epoch.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1e-3)
    }

    func testStateVectorAtDate_atEpoch_shouldEqualPropagateAtZero() throws {
        // Given
        let sgp4 = try makeSGP4(issLine1, issLine2)

        // When
        let byDate = try sgp4.stateVector(at: sgp4.epoch)
        let byMinutes = try sgp4.propagate(minutesSinceEpoch: 0)

        // Then
        XCTAssertEqual(byDate, byMinutes)
    }

    func testStateVectorAtDate_ninetyMinutesLater_shouldEqualPropagateAtNinety() throws {
        // Given
        let sgp4 = try makeSGP4(issLine1, issLine2)

        // When
        let byDate = try sgp4.stateVector(at: sgp4.epoch.addingTimeInterval(90 * 60))
        let byMinutes = try sgp4.propagate(minutesSinceEpoch: 90)

        // Then
        XCTAssertEqual(byDate.position.x, byMinutes.position.x, accuracy: 1e-9)
        XCTAssertEqual(byDate.position.y, byMinutes.position.y, accuracy: 1e-9)
        XCTAssertEqual(byDate.position.z, byMinutes.position.z, accuracy: 1e-9)
    }

    // MARK: - Gravity Models

    func testPropagate_forISSWithWGS72_shouldMatchPythonSGP4() throws {
        // Given
        let sgp4 = try makeSGP4(issLine1, issLine2, gravity: .wgs72)

        // When/Then (python-sgp4, wgs72, opsmode 'i')
        assertState(try sgp4.propagate(minutesSinceEpoch: 0),
                    position: [-2134.010675574867, 4534.723208527425, 4581.922251763638],
                    velocity: [-7.0258017304960685, -0.20773250178355035, -3.056803647588281])
        assertState(try sgp4.propagate(minutesSinceEpoch: 90),
                    position: [-844.2673421592251, 4487.47484989307, 5024.768829086699],
                    velocity: [-7.3566741335103405, 0.8404004100014544, -1.9807674591711324])
        assertState(try sgp4.propagate(minutesSinceEpoch: 1440),
                    position: [1610.0399703206724, -4703.97386303228, -4647.062230137177],
                    velocity: [7.038627512361637, -0.5007119204437865, 2.9489989225784736])
    }

    func testPropagate_forISSWithWGS84_shouldMatchPythonSGP4() throws {
        // Given
        let sgp4 = try makeSGP4(issLine1, issLine2, gravity: .wgs84)

        // When/Then (python-sgp4, wgs84, opsmode 'i')
        assertState(try sgp4.propagate(minutesSinceEpoch: 0),
                    position: [-2133.999892724715, 4534.731400601943, 4581.936324205182],
                    velocity: [-7.025789001351691, -0.2077260864975101, -3.0567908854511137])
        assertState(try sgp4.propagate(minutesSinceEpoch: 1440),
                    position: [1610.0832381634948, -4703.970253609216, -4647.02866618429],
                    velocity: [7.03862479823748, -0.5006847577564097, 2.9490444186792795])
    }

    func testGravityModel_wgs72_shouldDeriveXkeFromMuAndRadius() {
        // Given/When
        let model = GravityModel.wgs72

        // Then
        // xke = 60 / sqrt(R³/μ) for R = 6378.135 km, μ = 398600.8 km³/s²
        XCTAssertEqual(model.xke, 0.07436691613317342, accuracy: 1e-15)
        XCTAssertEqual(model.tumin, 1.0 / model.xke, accuracy: 1e-15)
        XCTAssertEqual(model.j3oj2, model.j3 / model.j2, accuracy: 1e-15)
    }

    // MARK: - Operation Mode

    func testOperationMode_afspc_shouldUseLegacySiderealTimeAtEpoch() throws {
        // Given
        // AFSPC mode computes sidereal time at epoch with the 1970-based formula from the
        // original operational code. It differs from IAU-82 by ~1e-11 rad, too little to
        // show in positions, so the value itself is checked (python-sgp4, opsmode 'a').
        let cases: [(String, String, Double)] = [
            ("1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753",
             "2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667",
             3.4691723423920777),
            ("1 22674U 93035D   06176.55909107  .00002121  00000-0  29868-3 0  6569",
             "2 22674  63.5035 354.4452 7541712 253.3264  18.7754  1.96679808 93877",
             2.003968969638045)
        ]

        for (line1, line2, expectedGsto) in cases {
            // When
            let afspc = try makeSGP4(line1, line2, mode: .afspc)
            let improved = try makeSGP4(line1, line2, mode: .improved)

            // Then
            XCTAssertEqual(afspc.elements.gsto, expectedGsto, accuracy: 1e-13)
            XCTAssertNotEqual(afspc.elements.gsto, improved.elements.gsto)
        }
    }

    // MARK: - Deep Space Selection

    func testIsDeepSpace_shouldSwitchAt225MinutePeriod() throws {
        // Given/When
        // ISS: ~93 minute period; 00005: ~133 minutes; 22674: ~732 minutes (Molniya-like)
        let iss = try makeSGP4(issLine1, issLine2)
        let vanguard = try makeSGP4("1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753",
                                    "2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667")
        let molniya = try makeSGP4("1 22674U 93035D   06176.55909107  .00002121  00000-0  29868-3 0  6569",
                                   "2 22674  63.5035 354.4452 7541712 253.3264  18.7754  1.96679808 93877")

        // Then
        XCTAssertFalse(iss.isDeepSpace)
        XCTAssertFalse(vanguard.isDeepSpace)
        XCTAssertTrue(molniya.isDeepSpace)
        XCTAssertEqual(molniya.elements.resonance.irez, 2, "Half-day resonance expected")
    }

    // MARK: - Errors

    func testSGP4Error_codes_shouldMatchReferenceImplementation() {
        // Given/When/Then
        XCTAssertEqual(SGP4Error.meanEccentricityOutOfRange(1.1).code, 1)
        XCTAssertEqual(SGP4Error.meanMotionNotPositive(-1).code, 2)
        XCTAssertEqual(SGP4Error.perturbedEccentricityOutOfRange(1.1).code, 3)
        XCTAssertEqual(SGP4Error.semiLatusRectumNegative(-1).code, 4)
        XCTAssertEqual(SGP4Error.decayed(radiusEarthRadii: 0.99).code, 6)
        XCTAssertNotNil(SGP4Error.decayed(radiusEarthRadii: 0.99).errorDescription)
    }

    // MARK: - Propagator Integration

    func testCalculatePosition_forISSOverOneDay_shouldStayAtISSAltitude() throws {
        // Given
        let sgp4 = try makeSGP4(issLine1, issLine2)

        for minutes in stride(from: 0.0, through: 1440.0, by: 10.0) {
            // When
            let position = try sgp4.calculatePosition(at: sgp4.epoch.addingTimeInterval(minutes * 60))

            // Then
            // The ISS orbit is nearly circular about Earth's center, but the ellipsoid
            // surface is ~21 km lower near the poles, so height above the ellipsoid ranges
            // from ~408 km near the equator to ~441 km near its maximum latitude.
            XCTAssertGreaterThan(position.altitudeKm, 400, "t = \(minutes) min")
            XCTAssertLessThan(position.altitudeKm, 445, "t = \(minutes) min")
            // Inclination (51.6465°) bounds geocentric latitude. Geodetic latitude runs
            // up to ~0.15° higher at this latitude.
            XCTAssertLessThanOrEqual(abs(position.latitudeDeg), 51.6465 + 0.2, "t = \(minutes) min")
        }
    }

    func testTwoBodyOrbit_versusSGP4_shouldDriftApartWithinADay() throws {
        // Given
        // Two-body motion ignores J2. For the ISS, J2 turns the orbital plane by about
        // 5° per day, so the simple model ends up hundreds of kilometers off.
        let tle = try TwoLineElement(from: "\(issLine1)\n\(issLine2)")
        let sgp4 = try SGP4(tle: tle)
        let twoBody = KeplerianOrbit(tle: tle)
        let oneDayLater = sgp4.epoch.addingTimeInterval(86400)

        // When
        let sgp4Position = try sgp4.stateVector(at: oneDayLater).position
        let twoBodyPosition = twoBody.stateVector(at: oneDayLater).position
        let separation = (sgp4Position - twoBodyPosition).magnitude

        // Then
        XCTAssertGreaterThan(separation, 100)
    }
}

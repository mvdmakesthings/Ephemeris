//
//  AstronomicalTimeTests.swift
//  EphemerisTests
//
//  Julian dates and Greenwich Mean Sidereal Time.
//

import Foundation
import XCTest
@testable import Ephemeris

final class AstronomicalTimeTests: XCTestCase {

    // MARK: - Helpers

    private func date(_ iso8601: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: iso8601))
    }

    /// Independent Julian date from calendar fields (Meeus, "Astronomical Algorithms", Ch. 7).
    private func meeusJulianDate(year: Int, month: Int, day: Double) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = y / 100
        let b = 2 - a + a / 4
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + day + Double(b) - 1524.5
    }

    // MARK: - Julian Date

    func testJulianDate_atUnixEpoch_shouldBe2440587Point5() throws {
        // Given/When
        let jd = try date("1970-01-01T00:00:00Z").julianDate

        // Then
        XCTAssertEqual(jd, 2440587.5, accuracy: 1e-9)
    }

    func testJulianDate_atJ2000Noon_shouldBe2451545() throws {
        // Given/When
        // J2000.0 is defined in TT; at the 1e-3 day level UTC and TT agree
        let jd = try date("2000-01-01T12:00:00Z").julianDate

        // Then
        XCTAssertEqual(jd, 2451545.0, accuracy: 1e-9)
    }

    func testJulianDate_at2100_shouldMatchPublishedValue() throws {
        // Given/When
        let jd = try date("2100-01-01T00:00:00Z").julianDate

        // Then
        XCTAssertEqual(jd, 2488069.5, accuracy: 1e-9)
    }

    func testJulianDate_acrossTLEYearRange_shouldMatchMeeusCalendarAlgorithm() throws {
        // Given
        // 1957-2056 is the full range of two-digit TLE years
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        for year in stride(from: 1957, through: 2056, by: 7) {
            for month in [1, 2, 3, 7, 12] {
                let components = DateComponents(year: year, month: month, day: 15, hour: 18, minute: 30)
                let date = try XCTUnwrap(calendar.date(from: components))

                // When
                let jd = date.julianDate

                // Then
                let dayFraction = 15.0 + (18.0 + 30.0 / 60.0) / 24.0
                XCTAssertEqual(jd, meeusJulianDate(year: year, month: month, day: dayFraction), accuracy: 1e-8,
                               "\(year)-\(month)")
            }
        }
    }

    func testJulianCenturiesSinceJ2000_shouldBeZeroAtEpochAndOneAfterACentury() {
        // Given/When/Then
        XCTAssertEqual(Date.julianCenturiesSinceJ2000(julianDate: 2451545.0), 0.0, accuracy: 1e-15)
        XCTAssertEqual(Date.julianCenturiesSinceJ2000(julianDate: 2451545.0 + 36525.0), 1.0, accuracy: 1e-15)
    }

    // MARK: - Greenwich Mean Sidereal Time

    func testGMST_atJ2000Noon_shouldMatchIAU82Constant() {
        // Given/When
        // At J2000.0 (noon) GMST is 280.46061837° (Vallado, Eq. 3-47).
        // 100.46° would be the value at 0h UT that day, not at noon.
        let gmst = Date.greenwichMeanSiderealTime(julianDate: 2451545.0)

        // Then
        XCTAssertEqual(gmst.inDegrees(), 280.46061837, accuracy: 1e-7)
    }

    func testGMST_withValladoExample3_5_shouldMatchPublishedValue() throws {
        // Given
        // Vallado, "Fundamentals of Astrodynamics and Applications", Example 3-5:
        // 1992 August 20, 12:14:00 UT1 → GMST = 152.578787810°
        let instant = try date("1992-08-20T12:14:00Z")

        // When
        let gmst = instant.greenwichMeanSiderealTime

        // Then
        XCTAssertEqual(gmst.inDegrees(), 152.578787810, accuracy: 1e-6)
    }

    func testGMST_acrossOneDay_shouldAdvanceBySiderealRate() throws {
        // Given
        // Earth turns about 360.9856° relative to the stars per solar day, so GMST must
        // advance by about 90.2464° every 6 hours. A model that ignores time of day would not.
        let midnight = try date("2026-10-05T00:00:00Z")

        // When
        let start = midnight.greenwichMeanSiderealTime
        let later = midnight.addingTimeInterval(6 * 3600).greenwichMeanSiderealTime
        var advance = (later - start).inDegrees()
        if advance < 0 { advance += 360.0 }

        // Then
        XCTAssertEqual(advance, 90.2464, accuracy: 0.001)
    }

    func testGMST_overManyDates_shouldStayWithinZeroToTwoPi() {
        // Given/When/Then
        for offset in stride(from: -40_000.0, through: 40_000.0, by: 123.4567) {
            let gmst = Date.greenwichMeanSiderealTime(julianDate: 2451545.0 + offset)
            XCTAssertGreaterThanOrEqual(gmst, 0)
            XCTAssertLessThan(gmst, 2 * .pi)
        }
    }

    // MARK: - Angles

    func testAngleConversion_shouldConvertAndRoundTrip() {
        // Given/When/Then
        XCTAssertEqual(180.0.inRadians(), .pi, accuracy: 1e-15)
        XCTAssertEqual((Double.pi / 2).inDegrees(), 90.0, accuracy: 1e-12)
        XCTAssertEqual((-45.0).inRadians(), -.pi / 4, accuracy: 1e-15)
        for degrees in stride(from: -720.0, through: 720.0, by: 17.5) {
            XCTAssertEqual(degrees.inRadians().inDegrees(), degrees, accuracy: 1e-12)
        }
    }
}

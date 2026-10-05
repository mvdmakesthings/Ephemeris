//
//  DateTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 11/26/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
import XCTest
@testable import Ephemeris

final class DateTests: XCTestCase {

    // MARK: - Julian Day Conversion Tests

    func testJulianDay_withUnixEpoch_shouldReturn2440587Point5() throws {
        // Given
        let date = Date(timeIntervalSince1970: 0) // Jan 1, 1970 00:00:00 UTC
        let knownJulianDay = 2440587.5

        // When
        let julianDay = try XCTUnwrap(Date.julianDay(from: date))

        // Then
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }

    func testJulianDay_withUnixEpochAtNoon_shouldReturn2440588() throws {
        // Given
        // Test with a specific time: Jan 1, 1970 12:00:00 UTC (noon)
        let date = Date(timeIntervalSince1970: 43200) // 12 hours = 43200 seconds
        // At noon, JD should be exactly 2440588.0 (since JD starts at noon)
        let knownJulianDay = 2440588.0

        // When
        let julianDay = try XCTUnwrap(Date.julianDay(from: date))

        // Then
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }

    func testJulianDate_property_shouldMatchCalendarBasedConversion() throws {
        // Given
        // The timestamp-based property must agree with the calendar algorithm.
        // Dates span 1957 to 2056 (the NORAD TLE year range) at odd times of day.
        let start = Date(timeIntervalSince1970: -386_380_800) // 1957-10-04 00:00 UTC
        let step: TimeInterval = 86_400 * 365.25 * 3 + 12_345.678

        for index in 0..<34 {
            let date = start.addingTimeInterval(Double(index) * step)

            // When
            let calendarBased = try XCTUnwrap(Date.julianDay(from: date))

            // Then
            // 1e-8 days ≈ 1 ms
            XCTAssertEqual(date.julianDate, calendarBased, accuracy: 1e-8)
        }
    }

    func testJulianDayFromEpoch_withYear2000Day1_shouldReturn2451544Point5() {
        // Given
        // Test epoch conversion for year 2000, day 1.0 (Jan 1, 2000 at midnight)
        let epochYear = 2000
        let epochDayFraction = 1.0
        // Expected JD for Jan 1, 2000 00:00:00 UTC
        let knownJulianDay = 2451544.5

        // When
        let julianDay = Date.julianDayFromEpoch(epochYear: epochYear, epochDayFraction: epochDayFraction)

        // Then
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }

    func testJulianDayFromEpoch_withYear2000Day1Point5_shouldReturn2451545() {
        // Given
        // Test epoch conversion with fractional day
        // Year 2000, day 1.5 (Jan 1, 2000 at noon)
        let epochYear = 2000
        let epochDayFraction = 1.5
        // Expected JD for Jan 1, 2000 12:00:00 UTC
        let knownJulianDay = 2451545.0

        // When
        let julianDay = Date.julianDayFromEpoch(epochYear: epochYear, epochDayFraction: epochDayFraction)

        // Then
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }

    func testJulianDay_withHistoricalDate1582_shouldReturnCorrectJD() throws {
        // Given
        // Test a historical date: Oct 15, 1582 (Gregorian calendar adoption)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        var components = DateComponents()
        components.year = 1582
        components.month = 10
        components.day = 15
        components.hour = 0
        components.minute = 0
        components.second = 0

        let date = try XCTUnwrap(calendar.date(from: components))

        // When
        let julianDay = try XCTUnwrap(Date.julianDay(from: date))

        // Then
        // Known JD for Oct 15, 1582 00:00:00 UTC
        let knownJulianDay = 2299160.5
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.5) // Allow small tolerance for historical dates
    }

    func testJulianDay_withFutureDate2100_shouldReturnCorrectJD() throws {
        // Given
        // Test a future date: Jan 1, 2100 00:00:00 UTC
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        var components = DateComponents()
        components.year = 2100
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        let date = try XCTUnwrap(calendar.date(from: components))

        // When
        let julianDay = try XCTUnwrap(Date.julianDay(from: date))

        // Then
        // Known JD for Jan 1, 2100 00:00:00 UTC
        let knownJulianDay = 2488069.5
        XCTAssertEqual(julianDay, knownJulianDay, accuracy: 0.000001)
    }

    // MARK: - Greenwich Sidereal Time Tests

    func testGreenwichSiderealTime_withEpoch1970_shouldMatchKnownValue() {
        // Given
        let jd = 2440587.5 // Jan 1, 1970 00:00:00 UTC
        let knownGSTrads = 1.7493372337513193

        // When
        let gst = Date.greenwichSideRealTime(from: jd)

        // Then
        XCTAssertEqual(gst, knownGSTrads, accuracy: 0.000001)
    }

    func testGreenwichSiderealTime_withJ2000Epoch_shouldMatchKnownValue() {
        // Given
        let jd = 2451545.0 // Jan 1, 2000 12:00:00 TT (J2000.0 epoch)

        // When
        let gst = Date.greenwichSideRealTime(from: jd)

        // Then
        // GMST at J2000.0 (noon) is 280.46061837° (Vallado, Eq. 3-47).
        // 1.753368559 rad (100.46°) is the value at 0h UT that day, not at noon.
        XCTAssertEqual(gst, 280.46061837.inRadians(), accuracy: 1e-9)
    }

    func testGreenwichSiderealTime_withValladoExample3_5_shouldMatchPublishedValue() throws {
        // Given
        // Vallado, "Fundamentals of Astrodynamics and Applications", Example 3-5:
        // 1992 August 20, 12:14:00 UT1 → GMST = 152.578787810°
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 1992, month: 8, day: 20, hour: 12, minute: 14)))
        let jd = try XCTUnwrap(Date.julianDay(from: date))

        // When
        let gst = Date.greenwichSideRealTime(from: jd)

        // Then
        XCTAssertEqual(gst.inDegrees(), 152.578787810, accuracy: 1e-6)
    }

    func testGreenwichSiderealTime_acrossOneDay_shouldAdvanceBySiderealRate() {
        // Given
        // Earth turns about 360.9856° relative to the stars per solar day, so GMST must
        // advance by about 90.2464° every 6 hours. A model that ignores time of day would not.
        let midnight = 2461318.5 // 2026-10-05 00:00 UTC
        let quarterDay = 0.25

        // When
        let gstStart = Date.greenwichSideRealTime(from: midnight)
        let gstLater = Date.greenwichSideRealTime(from: midnight + quarterDay)
        var advance = (gstLater - gstStart).inDegrees()
        if advance < 0 { advance += 360.0 }

        // Then
        XCTAssertEqual(advance, 90.2464, accuracy: 0.001)
    }

    // MARK: - J2000 Conversion Tests

    func testToJ2000_atJ2000Epoch_shouldReturnZero() {
        // Given
        // Test conversion at J2000.0 epoch
        let jd = 2451545.0

        // When
        let j2000 = Date.toJ2000(from: jd)

        // Then
        XCTAssertEqual(j2000, 0.0, accuracy: 0.000001)
    }

    func testToJ2000_oneHundredYearsAfterEpoch_shouldReturnOne() {
        // Given
        // Test conversion 100 years (1 century) after J2000.0
        let jd = 2451545.0 + 36525.0 // One Julian century

        // When
        let j2000 = Date.toJ2000(from: jd)

        // Then
        XCTAssertEqual(j2000, 1.0, accuracy: 0.000001)
    }
}

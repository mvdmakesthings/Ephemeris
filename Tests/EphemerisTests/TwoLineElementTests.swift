//
//  TwoLineElementTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
import XCTest
@testable import Ephemeris

final class TwoLineElementTests: XCTestCase {

    // MARK: - Basic Parsing Tests

    func testTLEParsing_withISSSample_shouldExtractAllFieldsCorrectly() throws {
        // Given
        let ISSTLE = try MockTLEs.ISSSample()

        // Then - Line 0
        XCTAssertEqual(ISSTLE.name, "ISS (ZARYA)")

        // Then - Line 1
        XCTAssertEqual(ISSTLE.catalogNumber, 25544)
        XCTAssertEqual(ISSTLE.internationalDesignator, "98067A")
        XCTAssertEqual(ISSTLE.epochYear, 2020)
        XCTAssertEqual(ISSTLE.epochDay, 97.82871450)
        XCTAssertEqual(ISSTLE.elementSetEpochUTC, "20097.82871450")

        // Then - Line 2
        XCTAssertEqual(ISSTLE.inclination, 51.6465)
        XCTAssertEqual(ISSTLE.rightAscension, 341.5807)
        XCTAssertEqual(ISSTLE.eccentricity, 0.0003880)
        XCTAssertEqual(ISSTLE.meanAnomaly, 26.1197)
        XCTAssertEqual(ISSTLE.meanMotion, 15.48685836)
        XCTAssertEqual(ISSTLE.revolutionsAtEpoch, 22095)
    }

    // MARK: - Year Parsing Tests

    func testYearParsing_withCurrentCenturyYears_shouldParseCorrectly() throws {
        // Given - Test year 2020 (parsed from "20")
        let tleString2020 = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When
        let tle2020 = try TwoLineElement(from: tleString2020)

        // Then
        XCTAssertEqual(tle2020.epochYear, 2020)

        // Given - Test year 2000 (parsed from "00")
        let tleString2000 = """
            NOAA 16 [-]
            1 26536U 00055A   00116.52380576 -.00000007  00000-0  19116-4 0  9996
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """

        // When
        let tle2000 = try TwoLineElement(from: tleString2000)

        // Then
        XCTAssertEqual(tle2000.epochYear, 2000)
    }

    func testYearParsing_withPreviousCenturyYears_shouldParseCorrectly() throws {
        // Given - Test year 1999 (parsed from "99")
        let tleString1999 = """
            Historical Satellite
            1 26536U 99055A   99116.52380576 -.00000007  00000-0  19116-4 0  9992
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """

        // When
        let tle1999 = try TwoLineElement(from: tleString1999)

        // Then
        XCTAssertEqual(tle1999.epochYear, 1999)

        // Given - Test year 80 with context
        let tleString1980 = """
            Satellite from 1980
            1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999
            2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005
            """

        // When
        let tle1980 = try TwoLineElement(from: tleString1980)

        // Then
        XCTAssertEqual(tle1980.epochYear, 1980)
    }

    func testYearParsing_withBoundaryConditionYears_shouldParseCorrectly() throws {
        // Given
        let line1 = "1 99999U 56001A   56001.00000000  .00000000  00000-0  00000-0 0  9999"
        let line2 = "2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001"
        let tleString56 = """
            Future Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle56 = try TwoLineElement(from: tleString56)

        // Then
        // 56 is the last year of the NORAD 2000s range
        XCTAssertEqual(tle56.epochYear, 2056)
    }

    func testYearParsing_withRecentYears_shouldParseCorrectly() throws {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastTwoDigits = currentYear % 100

        let line1 = "1 99999U 24001A   \(String(format: "%02d", lastTwoDigits))001.00000000  .00000000  00000-0  00000-0 0  9999"
        let line2 = "2 99999  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000001"
        let tleString = """
            Recent Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.epochYear, currentYear)
    }

    func testYearParsing_with57_shouldMapTo1957PerNORADConvention() throws {
        // Given
        // NORAD convention: 57-99 → 1957-1999, 00-56 → 2000-2056.
        // Sputnik 1 launched in 1957, so no valid TLE has an epoch before then.
        let tleString57 = """
            Test Satellite
            1 00001U 57001A   57275.00000000  .00000000  00000-0  00000-0 0  9990
            2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005
            """

        // When
        let tle57 = try TwoLineElement(from: tleString57)

        // Then
        XCTAssertEqual(tle57.epochYear, 1957)
    }

    func testYearParsing_withAllTwoDigitYears_shouldNotDependOnCurrentDate() {
        // Given/When/Then
        // The mapping is fixed, so the same TLE always yields the same epoch
        for twoDigitYear in 0...99 {
            let expected = twoDigitYear < 57 ? 2000 + twoDigitYear : 1900 + twoDigitYear
            XCTAssertEqual(TwoLineElement.parse2DigitYear(twoDigitYear), expected)
        }
    }

    // MARK: - Error Handling Tests

    func testErrorHandling_withInvalidTLEString_shouldThrowMissingLineError() {
        // Given
        let invalidTLE = "Invalid TLE String"

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: invalidTLE)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .missingLine(let expected, let actual) = tleError else {
                XCTFail("Expected TLEParsingError.missingLine")
                return
            }
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 1)
        }
    }

    func testErrorHandling_withMissingLines_shouldThrowMissingLineError() {
        // Given
        let tleWithTwoLines = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithTwoLines)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .missingLine(let expected, let actual) = tleError else {
                XCTFail("Expected TLEParsingError.missingLine")
                return
            }
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 2)
        }
    }

    func testErrorHandling_withInvalidCatalogNumber_shouldThrowInvalidNumberError() {
        // Given
        let tleWithInvalidCatalogNumber = """
            ISS (ZARYA)
            1 ABCDEU 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidCatalogNumber)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .invalidNumber(let field, _) = tleError else {
                XCTFail("Expected TLEParsingError.invalidNumber")
                return
            }
            XCTAssertEqual(field, "catalogNumber")
        }
    }

    func testErrorHandling_withInvalidInclination_shouldThrowInvalidNumberError() {
        // Given
        let line2 = "2 25544  INVALID 341.5807 0003880  94.4223  26.1197 15.48685836220958"
        let tleWithInvalidInclination = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidInclination)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .invalidNumber(let field, _) = tleError else {
                XCTFail("Expected TLEParsingError.invalidNumber")
                return
            }
            XCTAssertEqual(field, "inclination")
        }
    }

    func testErrorHandling_withShortLine0_shouldAccept() throws {
        // Given - Line 0 (satellite name) can be any length according to TLE spec
        let tleWithShortLine0 = """
            ISS
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When
        let tle = try TwoLineElement(from: tleWithShortLine0)

        // Then
        XCTAssertEqual(tle.name, "ISS")
    }

    func testErrorHandling_withShortLine1_shouldThrowInvalidFormatError() {
        // Given
        let tleWithShortLine1 = """
            ISS (ZARYA)
            1 25544U
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine1)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .invalidFormat(let message) = tleError else {
                XCTFail("Expected TLEParsingError.invalidFormat")
                return
            }
            XCTAssertTrue(message.contains("Line 1"))
        }
    }

    func testErrorHandling_withShortLine2_shouldThrowInvalidFormatError() {
        // Given
        let tleWithShortLine2 = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine2)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .invalidFormat(let message) = tleError else {
                XCTFail("Expected TLEParsingError.invalidFormat")
                return
            }
            XCTAssertTrue(message.contains("Line 2"))
        }
    }

    // MARK: - Checksum Validation Tests

    func testChecksumValidation_withCorrectChecksums_shouldSucceed() throws {
        // Given/When
        let tle = try MockTLEs.ISSSample()

        // Then
        XCTAssertEqual(tle.catalogNumber, 25544)
    }

    func testChecksumValidation_withInvalidLine1Checksum_shouldThrowError() {
        // Given - Line 1 with incorrect checksum (last digit changed from 2 to 0)
        let tleWithInvalidChecksum = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9990
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidChecksum)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .invalidChecksum(let line, let expected, let actual) = tleError else {
                XCTFail("Expected TLEParsingError.invalidChecksum")
                return
            }
            XCTAssertEqual(line, 1)
            XCTAssertEqual(expected, 0)
            XCTAssertEqual(actual, 2)
        }
    }

    func testChecksumValidation_withInvalidLine2Checksum_shouldThrowError() {
        // Given - Line 2 with incorrect checksum (last digit changed from 8 to 0)
        let tleWithInvalidChecksum = """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220950
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidChecksum)) { error in
            guard let tleError = error as? TLEParsingError,
                  case .invalidChecksum(let line, let expected, let actual) = tleError else {
                XCTFail("Expected TLEParsingError.invalidChecksum")
                return
            }
            XCTAssertEqual(line, 2)
            XCTAssertEqual(expected, 0) // checksum in TLE file (wrong)
            XCTAssertEqual(actual, 8) // computed checksum (correct)
        }
    }

    // MARK: - Eccentricity Validation Tests

    func testEccentricity_withNormalValues_shouldBeLessThanOne() throws {
        // Given
        let tle = try MockTLEs.ISSSample()

        // When/Then
        XCTAssertLessThan(tle.eccentricity, 1.0)
        XCTAssertEqual(tle.eccentricity, 0.0003880, accuracy: 1e-7)
    }

    func testEccentricity_withHighValues_shouldBeLessThanOne() throws {
        // Given - High but valid eccentricity (e.g., 0.9 for highly elliptical orbit)
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
        let line2 = "2 25544  51.6465 341.5807 9000000  94.4223  26.1197 15.48685836220959"
        let tleString = """
            Test Satellite
            \(line1)
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.eccentricity, 0.9000000, accuracy: 1e-7)
        XCTAssertLessThan(tle.eccentricity, 1.0)
    }

    func testEccentricity_withMaximumValue_shouldHandleCorrectly() throws {
        // Given - 9999999 would be parsed as 0.9999999
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
        let line2 = "2 25544  51.6465 341.5807 9999999  94.4223  26.1197 15.48685836220950"
        let tleString = """
            Test Satellite
            \(line1)
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try? TwoLineElement(from: tleString)

        // Then
        XCTAssertNotNil(tle)
        XCTAssertLessThan(try XCTUnwrap(tle).eccentricity, 1.0)
    }

    // MARK: - Fixed-Width Format Edge Cases

    func testFixedWidthFormat_withLeadingSpaces_shouldParseCorrectly() throws {
        // Given
        let line1 = "1  5544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9999"
        let line2 = "2  5544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220959"
        let tleString = """
            Test Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.catalogNumber, 5544)
    }

    func testFixedWidthFormat_withTrailingSpaces_shouldParseCorrectly() throws {
        // Given
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992  "
        let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958  "
        let tleString = """
            Test Satellite
            \(line1)
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.catalogNumber, 25544)
    }

    func testFixedWidthFormat_withSmallCatalogNumber_shouldParseCorrectly() throws {
        // Given
        let line1 = "1 00001U 57001A   57275.00000000  .00000000  00000-0  00000-0 0  9990"
        let line2 = "2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005"
        let tleString = """
            Sputnik 1
            \(line1)
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.catalogNumber, 1)
    }

    func testFixedWidthFormat_withZeroEccentricity_shouldParseCircularOrbit() throws {
        // Given
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992"
        let line2 = "2 25544  51.6465 341.5807 0000000  94.4223  26.1197 15.48685836220954"
        let tleString = """
            Test Satellite
            \(line1)
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.eccentricity, 0.0, accuracy: 1e-12)
    }

    func testFixedWidthFormat_withAllZeroFields_shouldParseCorrectly() throws {
        // Given
        let line1 = "1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999"
        let line2 = "2 00001  00.0000 000.0000 0000000 000.0000 000.0000 15.00000000000000"
        let tleString = """
            Test Zero Fields
            \(line1)
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.catalogNumber, 1)
        XCTAssertEqual(tle.inclination, 0.0)
        XCTAssertEqual(tle.rightAscension, 0.0)
        XCTAssertEqual(tle.eccentricity, 0.0)
        XCTAssertEqual(tle.argumentOfPerigee, 0.0)
        XCTAssertEqual(tle.meanAnomaly, 0.0)
        XCTAssertEqual(tle.bstarDragTerm, 0.0)
        XCTAssertEqual(tle.meanMotionSecondDerivative, 0.0)
    }
}

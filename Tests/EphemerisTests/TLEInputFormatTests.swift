//
//  TLEInputFormatTests.swift
//  EphemerisTests
//
//  Tests for TLE input normalization (line endings, two-line form, 3LE prefix)
//  and catalog number handling (Alpha-5, line 1/line 2 consistency).
//

import Foundation
import XCTest
@testable import Ephemeris

final class TLEInputFormatTests: XCTestCase {

    // MARK: - Input Normalization Tests

    func testInputNormalization_withCRLFLineEndings_shouldParse() throws {
        // Given
        let tleString = "ISS (ZARYA)\r\n"
            + "1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992\r\n"
            + "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958\r\n"

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.name, "ISS (ZARYA)")
        XCTAssertEqual(tle.catalogNumber, 25544)
        XCTAssertEqual(tle.meanMotion, 15.48685836, accuracy: 1e-8)
    }

    func testInputNormalization_withTrailingNewlineAndBlankLines_shouldParse() throws {
        // Given
        // CelesTrak downloads end with a newline; pasted text often has blank lines
        let tleString = """

            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958


            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.name, "ISS (ZARYA)")
        XCTAssertEqual(tle.catalogNumber, 25544)
    }

    func testInputNormalization_withTwoLineFormat_shouldParseWithEmptyName() throws {
        // Given
        let tleString = """
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.name, "")
        XCTAssertEqual(tle.catalogNumber, 25544)
        XCTAssertEqual(tle.inclination, 51.6465, accuracy: 1e-6)
    }

    func testInputNormalization_withSpaceTrack3LEZeroPrefix_shouldStripPrefix() throws {
        // Given
        // Space-Track's 3LE format prefixes the name line with "0 "
        let tleString = """
            0 ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.name, "ISS (ZARYA)")
    }

    // MARK: - Catalog Number Tests

    func testCatalogNumber_withAlpha5Format_shouldDecodeToSixDigitNumber() throws {
        // Given
        let line1 = "1 A0001U 24001A   24001.00000000  .00000000  00000-0  00000-0 0  9990"
        let line2 = "2 A0001  65.0000 180.0000 0100000 180.0000 180.0000 15.00000000000000"
        let tleString = """
            Alpha-5 Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(MockTLEs.fixChecksum(for: line2))
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.catalogNumber, 100001)
    }

    func testCatalogNumber_withAlpha5Letters_shouldSkipIAndO() {
        // Given/When/Then
        // Letters I and O are not used, to avoid confusion with 1 and 0
        XCTAssertEqual(TwoLineElement.parseCatalogNumber("A0000"), 100000)
        XCTAssertEqual(TwoLineElement.parseCatalogNumber("H9999"), 179999)
        XCTAssertEqual(TwoLineElement.parseCatalogNumber("J0000"), 180000)
        XCTAssertEqual(TwoLineElement.parseCatalogNumber("P0000"), 230000)
        XCTAssertEqual(TwoLineElement.parseCatalogNumber("Z9999"), 339999)
        XCTAssertNil(TwoLineElement.parseCatalogNumber("I0000"))
        XCTAssertNil(TwoLineElement.parseCatalogNumber("O0000"))
        XCTAssertNil(TwoLineElement.parseCatalogNumber("ABCDE"))
        XCTAssertNil(TwoLineElement.parseCatalogNumber("-1234"))
        XCTAssertEqual(TwoLineElement.parseCatalogNumber("00005"), 5)
    }

    func testCatalogNumber_withMismatchedLines_shouldThrowInvalidFormatError() {
        // Given
        // Line 2 belongs to a different object (NOAA 16) than line 1 (ISS)
        let tleString = """
            Mismatched
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 26536  98.7361 186.8634 0009660 233.4374 126.5910 14.13250159306768
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleString)) { error in
            guard case TLEParsingError.invalidFormat = error else {
                XCTFail("Expected TLEParsingError.invalidFormat, got \(error)")
                return
            }
        }
    }

    func testErrorHandling_withSwappedDataLines_shouldThrowInvalidFormatError() {
        // Given
        let tleString = """
            ISS (ZARYA)
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            """

        // When/Then
        XCTAssertThrowsError(try TwoLineElement(from: tleString)) { error in
            guard case TLEParsingError.invalidFormat = error else {
                XCTFail("Expected TLEParsingError.invalidFormat, got \(error)")
                return
            }
        }
    }
}

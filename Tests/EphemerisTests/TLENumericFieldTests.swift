//
//  TLENumericFieldTests.swift
//  EphemerisTests
//
//  Tests for TLE numeric field parsing: the assumed-decimal scientific notation
//  used by BSTAR and the mean motion derivatives, and signed values.
//

import Foundation
import XCTest
@testable import Ephemeris

final class TLENumericFieldTests: XCTestCase {

    // MARK: - Scientific Notation Parsing Tests

    func testScientificNotation_withBSTARDragTerm_shouldParseCorrectly() throws {
        // Given
        // Format: 24271-4 means 0.24271 × 10⁻⁴ = 0.000024271
        let tle = try MockTLEs.ISSSample()

        // When/Then
        XCTAssertEqual(tle.bstarDragTerm, 0.000024271, accuracy: 1e-9)
    }

    func testScientificNotation_withPositiveExponent_shouldParseCorrectly() throws {
        // Given - BSTAR with positive exponent: 12345+2 means 0.12345 × 10² = 12.345
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0  12345+2 0  9998"
        let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
        let tleString = """
            Test Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.bstarDragTerm, 12.345, accuracy: 1e-9)
    }

    func testScientificNotation_withZeroValue_shouldParseAsZero() throws {
        // Given
        let line1 = "1 00001U 80001A   80001.00000000  .00000000  00000-0  00000-0 0  9999"
        let line2 = "2 00001  65.1000 180.0000 0520000 180.0000 180.0000 15.00000000000005"
        let tleString = """
            Test Satellite
            \(line1)
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.bstarDragTerm, 0.0, accuracy: 1e-12)
    }

    func testScientificNotation_withMeanMotionSecondDerivative_shouldParseCorrectly() throws {
        // Given
        let tle = try MockTLEs.ISSSample()

        // When/Then
        XCTAssertEqual(tle.meanMotionSecondDerivative, 0.0, accuracy: 1e-12)
    }

    func testScientificNotation_withNonZeroSecondDerivative_shouldParseCorrectly() throws {
        // Given - 12345-5 means 0.12345 × 10⁻⁵
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  12345-5  24271-4 0  9999"
        let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
        let tleString = """
            Test Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.meanMotionSecondDerivative, 0.0000012345, accuracy: 1e-12)
    }

    // MARK: - Negative Value Handling Tests

    func testNegativeValues_withNegativeFirstDerivative_shouldParseCorrectly() throws {
        // Given - Test negative first derivative (orbital decay)
        let tle = try MockTLEs.NOAASample()

        // When/Then
        XCTAssertEqual(tle.meanMotionFirstDerivative, -0.00000007, accuracy: 1e-12)
    }

    func testNegativeValues_withPositiveFirstDerivative_shouldParseCorrectly() throws {
        // Given
        let tle = try MockTLEs.ISSSample()

        // When/Then
        XCTAssertEqual(tle.meanMotionFirstDerivative, 0.00000874, accuracy: 1e-12)
    }

    func testNegativeValues_withNegativeSecondDerivative_shouldParseCorrectly() throws {
        // Given
        let line1 = "1 25544U 98067A   20097.82871450  .00000874 -12345-5  24271-4 0  9993"
        let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
        let tleString = """
            Test Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.meanMotionSecondDerivative, -0.0000012345, accuracy: 1e-12)
    }

    func testNegativeValues_withNegativeBSTARDragTerm_shouldParseCorrectly() throws {
        // Given
        let line1 = "1 25544U 98067A   20097.82871450  .00000874  00000-0 -12345-3 0  9997"
        let line2 = "2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958"
        let tleString = """
            Test Satellite
            \(MockTLEs.fixChecksum(for: line1))
            \(line2)
            """

        // When
        let tle = try TwoLineElement(from: tleString)

        // Then
        XCTAssertEqual(tle.bstarDragTerm, -0.00012345, accuracy: 1e-12)
    }
}

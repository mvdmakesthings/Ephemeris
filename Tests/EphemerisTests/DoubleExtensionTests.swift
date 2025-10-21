//
//  DoubleExtensionTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/19/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

final class DoubleExtensionTests: XCTestCase {

    // MARK: - Rounding Tests

    func testRounding_withZeroPlaces_shouldRoundToInteger() {
        // Given
        let value = 3.14159

        // When
        let result = value.round(to: 0)

        // Then
        XCTAssertEqual(result, 3.0, accuracy: 0.000001)
    }

    func testRounding_withTwoPlaces_shouldRoundToTwoDecimals() {
        // Given
        let value = 3.14159

        // When
        let result = value.round(to: 2)

        // Then
        XCTAssertEqual(result, 3.14, accuracy: 0.000001)
    }

    func testRounding_withFivePlaces_shouldRoundToFiveDecimals() {
        // Given
        let value = 3.14159265359

        // When
        let result = value.round(to: 5)

        // Then
        XCTAssertEqual(result, 3.14159, accuracy: 0.000001)
    }

    func testRounding_withNegativeNumber_shouldRoundCorrectly() {
        // Given
        let value = -3.14159

        // When
        let result = value.round(to: 2)

        // Then
        XCTAssertEqual(result, -3.14, accuracy: 0.000001)
    }

    func testRounding_withZero_shouldReturnZero() {
        // Given
        let value = 0.0

        // When
        let result = value.round(to: 5)

        // Then
        XCTAssertEqual(result, 0.0, accuracy: 0.000001)
    }

    // MARK: - Angle Conversion Tests

    func testDegreesToRadians_with0Degrees_shouldReturn0Radians() {
        // Given
        let degrees = 0.0

        // When
        let result = degrees.inRadians()

        // Then
        XCTAssertEqual(result, 0.0, accuracy: 0.000001)
    }

    func testDegreesToRadians_with90Degrees_shouldReturnPiOver2() {
        // Given
        let degrees = 90.0

        // When
        let result = degrees.inRadians()

        // Then
        XCTAssertEqual(result, .pi / 2, accuracy: 0.000001)
    }

    func testDegreesToRadians_with180Degrees_shouldReturnPi() {
        // Given
        let degrees = 180.0

        // When
        let result = degrees.inRadians()

        // Then
        XCTAssertEqual(result, .pi, accuracy: 0.000001)
    }

    func testDegreesToRadians_with360Degrees_shouldReturn2Pi() {
        // Given
        let degrees = 360.0

        // When
        let result = degrees.inRadians()

        // Then
        XCTAssertEqual(result, 2.0 * .pi, accuracy: 0.000001)
    }

    func testDegreesToRadians_with45Degrees_shouldReturnPiOver4() {
        // Given
        let degrees = 45.0

        // When
        let result = degrees.inRadians()

        // Then
        XCTAssertEqual(result, .pi / 4, accuracy: 0.000001)
    }

    func testRadiansToDegrees_with0Radians_shouldReturn0Degrees() {
        // Given
        let radians = 0.0

        // When
        let result = radians.inDegrees()

        // Then
        XCTAssertEqual(result, 0.0, accuracy: 0.000001)
    }

    func testRadiansToDegrees_withPiOver2_shouldReturn90Degrees() {
        // Given
        let radians = Double.pi / 2

        // When
        let result = radians.inDegrees()

        // Then
        XCTAssertEqual(result, 90.0, accuracy: 0.000001)
    }

    func testRadiansToDegrees_withPi_shouldReturn180Degrees() {
        // Given
        let radians = Double.pi

        // When
        let result = radians.inDegrees()

        // Then
        XCTAssertEqual(result, 180.0, accuracy: 0.000001)
    }

    func testRadiansToDegrees_with2Pi_shouldReturn360Degrees() {
        // Given
        let radians = 2.0 * Double.pi

        // When
        let result = radians.inDegrees()

        // Then
        XCTAssertEqual(result, 360.0, accuracy: 0.000001)
    }

    func testRadiansToDegrees_withPiOver4_shouldReturn45Degrees() {
        // Given
        let radians = Double.pi / 4

        // When
        let result = radians.inDegrees()

        // Then
        XCTAssertEqual(result, 45.0, accuracy: 0.000001)
    }

    func testAngleConversion_degreesToRadiansToDegrees_shouldPreserveValue() {
        // Given
        let degrees = 123.456

        // When
        let convertedBack = degrees.inRadians().inDegrees()

        // Then
        XCTAssertEqual(degrees, convertedBack, accuracy: 0.000001)
    }

    func testAngleConversion_radiansToDegreesToRadians_shouldPreserveValue() {
        // Given
        let radians = 2.15

        // When
        let convertedBack = radians.inDegrees().inRadians()

        // Then
        XCTAssertEqual(radians, convertedBack, accuracy: 0.000001)
    }

    func testDegreesToRadians_withNegativeDegrees_shouldReturnNegativeRadians() {
        // Given
        let degrees = -90.0

        // When
        let result = degrees.inRadians()

        // Then
        XCTAssertEqual(result, -.pi / 2, accuracy: 0.000001)
    }

    func testRadiansToDegrees_withNegativeRadians_shouldReturnNegativeDegrees() {
        // Given
        let radians = -Double.pi

        // When
        let result = radians.inDegrees()

        // Then
        XCTAssertEqual(result, -180.0, accuracy: 0.000001)
    }
}

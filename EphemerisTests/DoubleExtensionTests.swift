//
//  DoubleExtensionTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/19/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class DoubleExtensionTests: XCTestCase {
    
    // MARK: - Rounding Tests
    
    func testRoundToZeroPlaces() throws {
        let value = 3.14159
        XCTAssertEqual(value.round(to: 0), 3.0)
    }
    
    func testRoundToTwoPlaces() throws {
        let value = 3.14159
        XCTAssertEqual(value.round(to: 2), 3.14)
    }
    
    func testRoundToFivePlaces() throws {
        let value = 3.14159265359
        XCTAssertEqual(value.round(to: 5), 3.14159)
    }
    
    func testRoundNegativeNumber() throws {
        let value = -3.14159
        XCTAssertEqual(value.round(to: 2), -3.14)
    }
    
    func testRoundZero() throws {
        let value = 0.0
        XCTAssertEqual(value.round(to: 5), 0.0)
    }
    
    // MARK: - Angle Conversion Tests
    
    func testDegreesToRadians() throws {
        // Test 0 degrees
        XCTAssertEqual(0.0.inRadians(), 0.0, accuracy: 0.000001)
        
        // Test 90 degrees = π/2 radians
        XCTAssertEqual(90.0.inRadians(), .pi / 2, accuracy: 0.000001)
        
        // Test 180 degrees = π radians
        XCTAssertEqual(180.0.inRadians(), .pi, accuracy: 0.000001)
        
        // Test 360 degrees = 2π radians
        XCTAssertEqual(360.0.inRadians(), 2.0 * .pi, accuracy: 0.000001)
        
        // Test 45 degrees = π/4 radians
        XCTAssertEqual(45.0.inRadians(), .pi / 4, accuracy: 0.000001)
    }
    
    func testRadiansToDegrees() throws {
        // Test 0 radians
        XCTAssertEqual(0.0.inDegrees(), 0.0, accuracy: 0.000001)
        
        // Test π/2 radians = 90 degrees
        XCTAssertEqual((.pi / 2).inDegrees(), 90.0, accuracy: 0.000001)
        
        // Test π radians = 180 degrees
        XCTAssertEqual(Double.pi.inDegrees(), 180.0, accuracy: 0.000001)
        
        // Test 2π radians = 360 degrees
        XCTAssertEqual((2.0 * .pi).inDegrees(), 360.0, accuracy: 0.000001)
        
        // Test π/4 radians = 45 degrees
        XCTAssertEqual((.pi / 4).inDegrees(), 45.0, accuracy: 0.000001)
    }
    
    func testAngleConversionRoundTrip() throws {
        // Test that converting degrees to radians and back gives the same value
        let degrees = 123.456
        let convertedBack = degrees.inRadians().inDegrees()
        XCTAssertEqual(degrees, convertedBack, accuracy: 0.000001)
        
        // Test that converting radians to degrees and back gives the same value
        let radians = 2.15
        let convertedBackRad = radians.inDegrees().inRadians()
        XCTAssertEqual(radians, convertedBackRad, accuracy: 0.000001)
    }
    
    func testNegativeAngleConversions() throws {
        // Test negative degrees to radians
        XCTAssertEqual((-90.0).inRadians(), -.pi / 2, accuracy: 0.000001)
        
        // Test negative radians to degrees
        XCTAssertEqual((-.pi).inDegrees(), -180.0, accuracy: 0.000001)
    }
}

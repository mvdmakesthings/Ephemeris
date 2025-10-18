//
//  TwoLineElementTests.swift
//  EphemerisTests
//
//  Created by Michael VanDyke on 4/6/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import Ephemeris

class TwoLineElementTests: XCTestCase {
    
    override func setUpWithError() throws {
    
    }

    override func tearDownWithError() throws {
    
    }

    func testTLEParses() throws {
        let ISSTLE = try MockTLEs.ISSSample()
        // Line 0
        XCTAssertEqual(ISSTLE.name, "ISS (ZARYA)")
        
        // Line 1
        XCTAssertEqual(ISSTLE.catalogNumber, 25544)
        XCTAssertEqual(ISSTLE.internationalDesignator, "98067A")
        XCTAssertEqual(ISSTLE.epochYear, 2020)
        XCTAssertEqual(ISSTLE.epochDay, 97.82871450)
        XCTAssertEqual(ISSTLE.elementSetEpochUTC, "20097.82871450")
        
        // Line 2
        XCTAssertEqual(ISSTLE.inclination, 51.6465)
        XCTAssertEqual(ISSTLE.rightAscension, 341.5807)
        XCTAssertEqual(ISSTLE.eccentricity, 0.0003880)
        XCTAssertEqual(ISSTLE.meanAnomaly, 26.1197)
        XCTAssertEqual(ISSTLE.meanMotion, 15.48685836)
        XCTAssertEqual(ISSTLE.revolutionsAtEpoch, 22095)
    }
    
    func testTLEParsingThrowsOnInvalidString() {
        let invalidTLE = "Invalid TLE String"
        XCTAssertThrowsError(try TwoLineElement(from: invalidTLE)) { error in
            guard case TLEParsingError.missingLine(let expected, let actual) = error else {
                XCTFail("Expected TLEParsingError.missingLine but got \(error)")
                return
            }
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 1)
        }
    }
    
    func testTLEParsingThrowsOnMissingLines() {
        let tleWithTwoLines =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithTwoLines)) { error in
            guard case TLEParsingError.missingLine(let expected, let actual) = error else {
                XCTFail("Expected TLEParsingError.missingLine but got \(error)")
                return
            }
            XCTAssertEqual(expected, 3)
            XCTAssertEqual(actual, 2)
        }
    }
    
    func testTLEParsingThrowsOnInvalidCatalogNumber() {
        let tleWithInvalidCatalogNumber =
            """
            ISS (ZARYA)
            1 ABCDEU 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidCatalogNumber)) { error in
            guard case TLEParsingError.invalidNumber(let field, _) = error else {
                XCTFail("Expected TLEParsingError.invalidNumber but got \(error)")
                return
            }
            XCTAssertEqual(field, "catalogNumber")
        }
    }
    
    func testTLEParsingThrowsOnInvalidInclination() {
        let tleWithInvalidInclination =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  INVALID 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithInvalidInclination)) { error in
            guard case TLEParsingError.invalidNumber(let field, _) = error else {
                XCTFail("Expected TLEParsingError.invalidNumber but got \(error)")
                return
            }
            XCTAssertEqual(field, "inclination")
        }
    }
    
    func testTLEParsingThrowsOnShortLine0() {
        let tleWithShortLine0 =
            """
            ISS
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine0)) { error in
            guard case TLEParsingError.invalidFormat(let message) = error else {
                XCTFail("Expected TLEParsingError.invalidFormat but got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Line 0"))
        }
    }
    
    func testTLEParsingThrowsOnShortLine1() {
        let tleWithShortLine1 =
            """
            ISS (ZARYA)
            1 25544U
            2 25544  51.6465 341.5807 0003880  94.4223  26.1197 15.48685836220958
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine1)) { error in
            guard case TLEParsingError.invalidFormat(let message) = error else {
                XCTFail("Expected TLEParsingError.invalidFormat but got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Line 1"))
        }
    }
    
    func testTLEParsingThrowsOnShortLine2() {
        let tleWithShortLine2 =
            """
            ISS (ZARYA)
            1 25544U 98067A   20097.82871450  .00000874  00000-0  24271-4 0  9992
            2 25544
            """
        XCTAssertThrowsError(try TwoLineElement(from: tleWithShortLine2)) { error in
            guard case TLEParsingError.invalidFormat(let message) = error else {
                XCTFail("Expected TLEParsingError.invalidFormat but got \(error)")
                return
            }
            XCTAssertTrue(message.contains("Line 2"))
        }
    }
}

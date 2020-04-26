//
//  OrbitalElementsTests.swift
//  SwiftSatTrackTests
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import SwiftSatTrack

class OrbitalElementsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOrbitalElementCalulations() throws {
        let objectAtPerigee = MockTLEs.objectAtPerigee()
        let oe = Orbit(from: objectAtPerigee)
        XCTAssertEqual(oe.semimajorAxis, 6945.033345653489)
        XCTAssertEqual(oe.trueAnomaly, 0)
        XCTAssertEqual(oe.argumentOfPerigee, 0)
        XCTAssertEqual(oe.eccentricity, 0.5)
    }
    
    func testOrbitalPositionCalculation() throws {
        let issTLE = MockTLEs.ISSSample()
        let oe = Orbit(from: issTLE)
        _ = Orbit.calculatePosition(semimajorAxis: oe.semimajorAxis, eccentricity: oe.eccentricity, eccentricAnomaly: Orbit.calculateEccentricAnomaly(eccentricity: oe.eccentricity, meanAnomaly: oe.meanAnomaly), trueAnomaly: oe.trueAnomaly, argumentOfPerigee: oe.argumentOfPerigee, inclination: oe.inclination, rightAscensionOfAscendingNode: oe.rightAscensionOfAscendingNode)
    }
    

}

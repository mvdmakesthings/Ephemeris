//
//  OrbitalElementsTests.swift
//  SwiftSatTrackTests
//
//  Created by Michael VanDyke on 4/23/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import XCTest
@testable import SwiftSatTrack

class OrbitalElementsTests: XCTestCase {
    func testM50DateInterval() throws {
        let date = Date()
        let m50date = date.asM50TimeInterval()
        XCTAssertEqual(m50date, 0)
    }
}

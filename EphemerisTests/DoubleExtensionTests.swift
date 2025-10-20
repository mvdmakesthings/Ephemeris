//
//  DoubleExtensionTests.swift
//  EphemerisTests
//
//  Created by Copilot on 10/19/25.
//  Copyright © 2025 Michael VanDyke. All rights reserved.
//

import Spectre
@testable import Ephemeris

let doubleExtensionTests: ((ContextType) -> Void) = {
    $0.describe("Double Extension") {
        
        // MARK: - Rounding Tests
        
        $0.context("rounding") {
            $0.it("rounds to zero places") {
                let value = 3.14159
                try expect(value.round(to: 0)) == 3.0
            }
            
            $0.it("rounds to two places") {
                let value = 3.14159
                try expect(value.round(to: 2)) == 3.14
            }
            
            $0.it("rounds to five places") {
                let value = 3.14159265359
                try expect(value.round(to: 5)) == 3.14159
            }
            
            $0.it("rounds negative numbers") {
                let value = -3.14159
                try expect(value.round(to: 2)) == -3.14
            }
            
            $0.it("rounds zero") {
                let value = 0.0
                try expect(value.round(to: 5)) == 0.0
            }
        }
        
        // MARK: - Angle Conversion Tests
        
        $0.context("angle conversions") {
            $0.it("converts 0 degrees to radians") {
                let result = 0.0.inRadians()
                try expect(abs(result - 0.0) < 0.000001)
            }
            
            $0.it("converts 90 degrees to π/2 radians") {
                let result = 90.0.inRadians()
                try expect(abs(result - .pi / 2) < 0.000001)
            }
            
            $0.it("converts 180 degrees to π radians") {
                let result = 180.0.inRadians()
                try expect(abs(result - .pi) < 0.000001)
            }
            
            $0.it("converts 360 degrees to 2π radians") {
                let result = 360.0.inRadians()
                try expect(abs(result - 2.0 * .pi) < 0.000001)
            }
            
            $0.it("converts 45 degrees to π/4 radians") {
                let result = 45.0.inRadians()
                try expect(abs(result - .pi / 4) < 0.000001)
            }
            
            $0.it("converts 0 radians to degrees") {
                let result = 0.0.inDegrees()
                try expect(abs(result - 0.0) < 0.000001)
            }
            
            $0.it("converts π/2 radians to 90 degrees") {
                let result = (.pi / 2).inDegrees()
                try expect(abs(result - 90.0) < 0.000001)
            }
            
            $0.it("converts π radians to 180 degrees") {
                let result = Double.pi.inDegrees()
                try expect(abs(result - 180.0) < 0.000001)
            }
            
            $0.it("converts 2π radians to 360 degrees") {
                let result = (2.0 * .pi).inDegrees()
                try expect(abs(result - 360.0) < 0.000001)
            }
            
            $0.it("converts π/4 radians to 45 degrees") {
                let result = (.pi / 4).inDegrees()
                try expect(abs(result - 45.0) < 0.000001)
            }
            
            $0.it("performs round trip degrees to radians conversion") {
                let degrees = 123.456
                let convertedBack = degrees.inRadians().inDegrees()
                try expect(abs(degrees - convertedBack) < 0.000001)
            }
            
            $0.it("performs round trip radians to degrees conversion") {
                let radians = 2.15
                let convertedBackRad = radians.inDegrees().inRadians()
                try expect(abs(radians - convertedBackRad) < 0.000001)
            }
            
            $0.it("converts negative degrees to radians") {
                let result = (-90.0).inRadians()
                try expect(abs(result - (-.pi / 2)) < 0.000001)
            }
            
            $0.it("converts negative radians to degrees") {
                let result = (-.pi).inDegrees()
                try expect(abs(result - (-180.0)) < 0.000001)
            }
        }
    }
}


//
//  Double.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

extension Double {
    /// Rounds doubles up to specified places
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Converts degrees to radians
    func toRadians() -> Radian {
        return self * .pi / 180
    }
    
    /// Converts radians to degrees
    func toDegrees() -> Degree {
        return self * 180 / .pi
    }
}

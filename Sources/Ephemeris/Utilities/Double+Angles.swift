//
//  Double+Angles.swift
//  Ephemeris
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation

extension Double {
    /// Converts an angle in degrees to radians.
    ///
    /// ```swift
    /// let radians = 180.0.inRadians()  // π
    /// ```
    func inRadians() -> Radians {
        return self * .pi / 180
    }

    /// Converts an angle in radians to degrees.
    ///
    /// ```swift
    /// let degrees = Double.pi.inDegrees()  // 180.0
    /// ```
    func inDegrees() -> Degrees {
        return self * 180 / .pi
    }
}

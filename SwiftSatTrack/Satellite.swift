//
//  Satellite.swift
//  SwiftSatTrack
//
//  Created by Michael VanDyke on 4/22/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
import CoreLocation

struct Coordinates {
    let longitude: CLLocationDegrees
    let latitude: CLLocationDegrees
    let altitude: Double
}

class Satellite {
    
    var tle: TwoLineElement?
    var orbit: Orbit?
    
    convenience init(tle: TwoLineElement, orbit: Orbit) {
        self.init()

        self.tle = tle
        self.orbit = orbit
    }
    
    func position(at date: Date) -> Coordinates? {
        return nil
    }
}

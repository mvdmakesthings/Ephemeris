//
//  Satellite.swift
//  SwiftSatTrackDemo
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
import MapKit
import SwiftSatTrack

class Satellite: NSObject, MKAnnotation {
    let name: String
    let tle: TwoLineElement
    let orbit: Orbit
    var altitude: Double
    var coordinate: CLLocationCoordinate2D
    
    init(name: String) {
        let tleString =
        """
        GOES 16
        1 41866U 16071A   20116.77920108 -.00000243 +00000-0 +00000-0 0  9994
        2 41866 000.0176 285.7071 0000894 150.8911 342.9988 01.00271976012613
        """
        let tle = TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: orbit.eccentricity, meanAnomaly: orbit.meanAnomaly)
        let position = Orbit.calculatePosition(semimajorAxis: orbit.semimajorAxis, eccentricity: orbit.eccentricity, eccentricAnomaly: eccentricAnomaly, trueAnomaly: orbit.trueAnomaly, argumentOfPerigee: orbit.argumentOfPerigee, inclination: orbit.inclination, rightAscensionOfAscendingNode: orbit.rightAscensionOfAscendingNode)
        
        let lat = CLLocationDegrees(position.x)
        let long = CLLocationDegrees(position.y)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let altitude = position.z
        
        self.tle = tle
        self.orbit = orbit
        
        self.name = name
        self.coordinate = location
        self.altitude = altitude
    }
    
    var subtitle: String? {
        return nil
    }
    
    var title: String? {
        return self.name
    }
}

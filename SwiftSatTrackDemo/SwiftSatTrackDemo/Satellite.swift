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
    var name: String
    let tle: TwoLineElement?
    let orbit: Orbit?
    var altitude: Double
    var coordinate: CLLocationCoordinate2D
    
    convenience init(name: String, coordinate: CLLocationCoordinate2D) {
        self.init()

        self.name = name
        self.coordinate = coordinate
    }
    
    override init() {
        let tleString =
        """
        GOES 16 [+]
        1 41866U 16071A   20116.77920108 -.00000243  00000-0  00000-0 0  9994
        2 41866   0.0176 285.7071 0000894 150.8911 342.9988  1.00271976 12613
        """
        let tle = TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)
        let julianDate = Date().advanced(by: 86400 * 10).julianDayFromDate()
        let currentMeanAnomaly = orbit.meanAnomalyForJulianDate(julianDate: julianDate)
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: orbit.eccentricity, meanAnomaly: currentMeanAnomaly)
        let position = Orbit.calculatePosition(semimajorAxis: orbit.semimajorAxis, eccentricity: orbit.eccentricity, eccentricAnomaly: eccentricAnomaly, trueAnomaly: orbit.trueAnomaly, argumentOfPerigee: orbit.argumentOfPerigee, inclination: orbit.inclination, rightAscensionOfAscendingNode: orbit.rightAscensionOfAscendingNode)
        
        let lat = CLLocationDegrees(-position.x)
        let long = CLLocationDegrees(-position.y)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let altitude = position.z
        
        self.tle = tle
        self.orbit = orbit
        
        self.name = tle.name
        self.coordinate = location
        self.altitude = altitude
    }
    
    var subtitle: String? {
        return "Lat: \(coordinate.latitude.rounded()) | Long: \(coordinate.longitude.rounded())"
    }
    
    var title: String? {
        return self.name
    }
}

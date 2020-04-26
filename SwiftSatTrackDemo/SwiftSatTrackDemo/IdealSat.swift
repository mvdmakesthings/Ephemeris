//
//  IdealSat.swift
//  SwiftSatTrackDemo
//
//  Created by Michael VanDyke on 4/26/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import Foundation
import MapKit

class IdealSat: NSObject, MKAnnotation {
    var name: String
    var coordinate: CLLocationCoordinate2D
    
    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
    }
    
    var subtitle: String? {
        return "Lat: \(coordinate.latitude.rounded()) | Long: \(coordinate.longitude.rounded())"
    }
    
    var title: String? {
        return self.name
    }
}

//
//  ViewController.swift
//  SwiftSatTrackDemo
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import UIKit
import SwiftSatTrack
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let sat = Satellite()
        let ideal = IdealSat(name: "Ideal", coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(-0.0), longitude: CLLocationDegrees(-75.2)))
        mapView.addAnnotation(ideal)
        mapView.addAnnotation(sat)
    }
}


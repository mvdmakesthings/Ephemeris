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
        
        let sat = Satellite(name: "ZARYA")
        mapView.addAnnotation(sat)
    }
}


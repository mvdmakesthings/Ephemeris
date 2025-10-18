//
//  ViewController.swift
//  EphemerisDemo
//
//  Created by Michael VanDyke on 4/25/20.
//  Copyright © 2020 Michael VanDyke. All rights reserved.
//

import UIKit
import Ephemeris
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    private var orbit: Orbit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        // Do any additional setup after loading the view.

        let tleString =
        """
        NOAA 15 [B]
        1 25338U 98030A   20118.84334876  .00000037  00000-0  34099-4 0  9995
        2 25338  98.7217 144.1403 0011283  54.5983 305.6249 14.25960903141760
        """
        let tle = TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)
        self.orbit = orbit
        
        // Create PolyLines
        var coordinatePoints = [CLLocationCoordinate2D]()
        let timeIntervalOffset: TimeInterval = 5 * PhysicalConstants.Time.secondsPerMinute
        let timeIntervalMax: TimeInterval = PhysicalConstants.Time.secondsPerHour
        var offset: TimeInterval = 0
        let firstOffset = try! calculatePosition(by: offset)
        
        repeat {
            let coordinate = try! calculatePosition(by: offset)
            coordinatePoints.append(coordinate)
            print("OE Plot | Plotting Points \(offset) seconds into the future. | Lat: \(coordinate.latitude) | Long: \(coordinate.longitude)")
            offset += timeIntervalOffset
        } while (offset <= timeIntervalMax)
        
        print("OE Plot | \(coordinatePoints.count) total plotted points.")
        let polyLine = MKPolyline(coordinates: coordinatePoints, count: coordinatePoints.count)
        mapView.addOverlay(polyLine)

        let ideal = Satellite(name: "NOAA 16", coordinate: firstOffset)
        mapView.addAnnotation(ideal)

    }
    
    private func calculatePosition(by timeinterval: TimeInterval) throws -> CLLocationCoordinate2D {
        guard var orbit = self.orbit else { fatalError() }
        let position = try! orbit.calculatePosition(at: Date().addingTimeInterval(timeinterval))
        
        let lat = CLLocationDegrees(position.x)
        let long = CLLocationDegrees(position.y)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        return location
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = .green
            return lineView
        }
        return MKOverlayRenderer()
    }
}

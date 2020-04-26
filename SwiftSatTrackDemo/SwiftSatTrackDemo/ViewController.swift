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

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    private var orbit: Orbit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        // Do any additional setup after loading the view.

        let tleString =
        """
        NOAA 16 [-]
        1 26536U 00055A   20117.37338810 -.00000002  00000-0  21830-4 0  9997
        2 26536  98.7360 187.6930 0009700 230.8055 129.2257 14.13250298306888
        """
        let tle = TwoLineElement(from: tleString)
        let orbit = Orbit(from: tle)
        self.orbit = orbit
        
        // Create PolyLines
        var coordinatePoints = [CLLocationCoordinate2D]()
        let timeIntervalOffset: TimeInterval = 15 // 5 minutes
        let timeIntervalMax: TimeInterval = (4 * 60 * 60) // 1 full day
        var offset: TimeInterval = 0
        let firstOffset = calculatePosition(by: offset)
        
        repeat {
            let coordinate = calculatePosition(by: offset)
            coordinatePoints.append(coordinate)
            print("OE Plot | Plotting Points \(offset) seconds into the future. | Lat: \(coordinate.latitude) | Long: \(coordinate.longitude)")
            offset += timeIntervalOffset
        } while (offset <= timeIntervalMax)
        
        print("OE Plot | \(coordinatePoints.count) total plotted points.")
        let polyLine = MKPolyline(coordinates: coordinatePoints, count: coordinatePoints.count)
        mapView.addOverlay(polyLine)

        let ideal = IdealSat(name: "NOAA 16", coordinate: firstOffset)
        mapView.addAnnotation(ideal)

    }
    
    private func calculatePosition(by timeinterval: TimeInterval) -> CLLocationCoordinate2D {
        guard let orbit = self.orbit else { fatalError() }
        let julianDate = Date().advanced(by: timeinterval).julianDayFromDate()
        let currentMeanAnomaly = orbit.meanAnomalyForJulianDate(julianDate: julianDate)
        print("OE Plot | Mean Anomaly: \(currentMeanAnomaly)")
        let eccentricAnomaly = Orbit.calculateEccentricAnomaly(eccentricity: orbit.eccentricity, meanAnomaly: currentMeanAnomaly)
        print("OE Plot | Eccentric Anomaly: \(eccentricAnomaly)")
        let trueAnomaly = Orbit.calculateTrueAnomaly(eccentricity: orbit.eccentricity, eccentricAnomaly: eccentricAnomaly)
        print("OE Plot | True Anomaly: \(trueAnomaly)")
        let position = Orbit.calculatePosition(semimajorAxis: orbit.semimajorAxis, eccentricity: orbit.eccentricity, eccentricAnomaly: eccentricAnomaly, trueAnomaly: trueAnomaly, argumentOfPerigee: orbit.argumentOfPerigee, inclination: orbit.inclination, rightAscensionOfAscendingNode: orbit.rightAscensionOfAscendingNode)
        
        let lat = CLLocationDegrees(position.x)
        let long = CLLocationDegrees(position.y)
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
//        let altitude = position.z
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


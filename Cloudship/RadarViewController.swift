//
//  RadarViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 9/28/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RadarViewController: UIViewController {
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    let radarAPIKey = "17e182c3ab5751f199d94e19c685ca11"
    let radarBaseURL = "https://tile.openweathermap.org/map/precipitation/10/"

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.startUpdatingLocation()
//        locationManager.requestLocation()
        
        buildRadarURL(radarBaseURL: radarBaseURL, radarAPIKey: radarAPIKey, userLocation: userLocation)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self as? MKMapViewDelegate
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
        
        view.addSubview(mapView)
        
        let safeArea = view.safeAreaLayoutGuide
        
        mapView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
    }
    
    func buildRadarURL(radarBaseURL: String,radarAPIKey: String,userLocation: CLLocation) -> String {
        var radarURLString: String = ""
        let userLat = userLocation.coordinate.latitude
        let userLong = userLocation.coordinate.longitude
        let userCoords = ("\(userLat)/\(userLong)")
        
        radarURLString.append(radarBaseURL)
        radarURLString.append(userCoords)
        radarURLString.append(".png")
        radarURLString.append("?appid=")
        radarURLString.append(radarAPIKey)
        print(radarURLString)
        return radarURLString
    }

}

extension RadarViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.showsUserLocation = true
        
        for location in locations {
            print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
            userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

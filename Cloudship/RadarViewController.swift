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
    let radarAPIKey = "028172b81ffd68d6beb18b4ccf434ad4"
    let radarBaseURL = "https://tile.openweathermap.org/map/precipitation_new/3/"
    var tileConvertX = 0
    var tileConvertY = 0

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
        
        transformCoordinate(userLat, userLong, withZoom: 3)
        let userCoords = ("\(tileConvertX)/\(tileConvertY)")
        
        radarURLString.append(radarBaseURL)
        radarURLString.append(userCoords)
        radarURLString.append(".png")
        radarURLString.append("?appid=")
        radarURLString.append(radarAPIKey)
        print(radarURLString)
        
        let imageV = UIImageView(frame: CGRect(x: 90, y: 200, width: 200, height: 200))
        imageV.layer.borderWidth = 5
        imageV.layer.borderColor = UIColor.red.cgColor
        imageV.dowloadFromServer(link: radarURLString, contentMode: .scaleAspectFill)
        self.view.addSubview(imageV)
        
        return radarURLString
    }
    
    func transformCoordinate(_ latitude: Double, _ longitude: Double, withZoom zoom: Int) -> (x: Int, y: Int) {
        let tileX = Int(floor((longitude + 180) / 360.0 * pow(2.0, Double(zoom))))
        let tileY = Int(floor((1 - log( tan( latitude * Double.pi / 180.0 ) + 1 / cos( latitude * Double.pi / 180.0 )) / Double.pi ) / 2 * pow(2.0, Double(zoom))))
        
        tileConvertX = tileX
        tileConvertY = tileY
        
        return (tileX, tileY)
    }

}

extension UIImageView {
    func dowloadFromServer(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func dowloadFromServer(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        dowloadFromServer(url: url, contentMode: mode)
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

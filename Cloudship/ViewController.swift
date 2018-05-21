//
//  ViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var userLocationLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataFetched) , name: WeatherController.weatherDataParseComplete, object: nil)
        WeatherController.shared.fetchWeatherInfo()
        
    }
    
    @objc func weatherDataFetched () {
        //do something amazing
        print("We should be getting the weather array back here, please!!!!!!")
        print(WeatherController.shared.weatherArray)
        
        if let currentTemp = WeatherController.shared.weather?.currently?.temperature {
            DispatchQueue.main.async {
                self.currentTempLabel.text = String(currentTemp)
            }
        }
        
        if let dailyHighTemp = WeatherController.shared.weather?.daily?.data?[0].temperatureMax {
            DispatchQueue.main.async {
                self.highTempLabel.text = String(dailyHighTemp)
            }
        }
    }
    
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthStatus = status
        if status == .authorizedWhenInUse {
            print("We can get your location, muahahahaha")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        
        //        var userLocation:[CLLocation] = locations
        //
        //        let geocoder = CLGeocoder()
        //        geocoder.reverseGeocodeLocation(userLocation) { (placemarks:[CLPlacemark]?, error: Error?) in
        //            if let error = error {
        //                print(error)
        //                return
        //            }
        //            if let placemarks = placemarks {
        //                for placemark in placemarks {
        //                    var addressString = placemark.subThoroughfare ?? ""
        //                    addressString.append(" ")
        //                    addressString.append(placemark.thoroughfare ?? "")
        //                    addressString.append("\n")
        //                    addressString.append(placemark.locality ?? "")
        //                    addressString.append(", ")
        //                    addressString.append(placemark.administrativeArea ?? "")
        //                    addressString.append(" ")
        //                    addressString.append(placemark.postalCode ?? "")
        //
        //                    cell.catAddressLabel.text = addressString
        //                }
        //            }
        //        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}


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
    
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var currentSummaryLabel: UILabel!
    
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
        
        let dataPoint = WeatherController.shared.weather
        
        if let currentTemp = dataPoint?.currently?.temperature, let currentCondition = dataPoint?.currently?.summary {
            let newCurrentTemp = String(format: "%.0f", currentTemp)
            DispatchQueue.main.async {
                self.currentTempLabel.text = newCurrentTemp + "\u{00B0} - " + currentCondition
            }
        }
        
        if let highTemp = dataPoint?.daily?.data?[0].temperatureMax, let lowTemp = dataPoint?.daily?.data?[0].temperatureLow {
            let newHighTemp = String(format: "%.0f", highTemp)
            let newLowTemp = String(format: "%.0f", lowTemp)
            DispatchQueue.main.async {
                self.highTempLabel.text = newHighTemp + "\u{00B0}/" + newLowTemp + "\u{00B0}"
            }
        }
        
        if let currentSummary = dataPoint?.daily?.data?[0].summary {
            DispatchQueue.main.async {
                self.currentSummaryLabel.text = String(currentSummary)
            }
        }
        
//        if let currentSummary = WeatherController.shared.weather?.daily?.data?[0]. {
//            DispatchQueue.main.async {
//                self.currentSummaryLabel.text = String(currentSummary)
//            }
//        }
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
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks:[CLPlacemark]?, error: Error?) in
                if let error = error {
                    print(error)
                    return
                }
                if let placemarks = placemarks {
                    for placemark in placemarks {
                        var addressString = placemark.subThoroughfare ?? ""
                        addressString.append(" ")
                        addressString.append(placemark.thoroughfare ?? "")
                        addressString.append(" ")
                        addressString.append(placemark.locality ?? "")
                        addressString.append(", ")
                        addressString.append(placemark.administrativeArea ?? "")
//                        addressString.append(" ")
//                        addressString.append(placemark.postalCode ?? "")
                        
                        self.navigationItem.title = addressString
                    }
                }
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}


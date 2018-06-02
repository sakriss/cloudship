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
 
    @IBOutlet weak var alertViewContainer: UIView!
    @IBAction func alertActiveButton(_ sender: Any) {
        print("Alert button pressed")
    }
    
    @IBOutlet weak var backgroundAnimatedImage: UIImageView!
    @IBOutlet weak var currentAddressLabel: UILabel!
    @IBOutlet weak var currentConditionLabel: UILabel!
    @IBOutlet weak var lowTempLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var currentSummaryLabel: UILabel!
    @IBOutlet weak var minutelyLookingAheadLabel: UILabel!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    let locationManager = CLLocationManager()
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(activityIndicator)
        // Set up its size (the super view bounds usually)
        activityIndicator.frame = view.bounds
        // Start the loading animation
        activityIndicator.startAnimating()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataFetched) , name: WeatherController.weatherDataParseComplete, object: nil)
        alertViewContainer.isHidden = true
    }
    
    @objc func weatherDataFetched () {
        //now that data is parsed, we can display it
        DispatchQueue.main.async {
            self.activityIndicator.removeFromSuperview()
        }
        
        let dataPoint = WeatherController.shared.weather
        
        if let currentTemp = dataPoint?.currently?.temperature {
            let newCurrentTemp = String(format: "%.0f", currentTemp)
            DispatchQueue.main.async {
                self.currentTempLabel.text = newCurrentTemp
            }
        }
        
        if let currentCondition = dataPoint?.currently?.summary {
            DispatchQueue.main.async {
                self.currentConditionLabel.text = currentCondition
            }
        }
        
        if let highTemp = dataPoint?.daily?.data?[0].temperatureMax {
            let newHighTemp = String(format: "%.0f", highTemp)
            DispatchQueue.main.async {
                self.highTempLabel.text = newHighTemp + "\u{00B0}"
            }
        }
        
        if let lowTemp = dataPoint?.daily?.data?[0].temperatureLow {
            let newLowTemp = String(format: "%.0f", lowTemp)
            DispatchQueue.main.async {
                self.lowTempLabel.text = newLowTemp + "\u{00B0}"
            }
        }
        
        if let currentSummary = dataPoint?.daily?.data?[0].summary {
            DispatchQueue.main.async {
                self.currentSummaryLabel.text = String(currentSummary)
            }
        }
        
        if let lookingAhead = dataPoint?.minutely?.summary {
            DispatchQueue.main.async {
                self.minutelyLookingAheadLabel.text = lookingAhead
            }
        }
        
        if let alertsActive = dataPoint?.alerts?[0] {
            print(alertsActive)
            
            DispatchQueue.main.async {
                self.alertViewContainer.isHidden = false
            }
        }
        

        //attempting to load animated gif
            DispatchQueue.main.async {
                self.backgroundAnimatedImage.loadGif(asset: "weather")
        }
        
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthStatus = status
        if status == .authorizedWhenInUse {
            print("We can now get your location")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            WeatherController.shared.fetchWeatherInfo(latitude: location.coordinate.latitude, longitude:location.coordinate.longitude)
            
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


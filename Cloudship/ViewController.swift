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
 
    @IBOutlet weak var currentlyTableView: UITableView!
    
    var lastLocation: CLLocation? = nil
    
//    @IBOutlet weak var alertViewContainer: UIView!
//    @IBAction func alertActiveButton(_ sender: Any) {
//        print("Alert button pressed")
//    }
    
//    @IBOutlet weak var backgroundAnimatedImage: UIImageView!
//    @IBOutlet weak var currentConditionLabel: UILabel!
//    @IBOutlet weak var lowTempLabel: UILabel!
//    @IBOutlet weak var currentTempLabel: UILabel!
//    @IBOutlet weak var highTempLabel: UILabel!
//    @IBOutlet weak var currentSummaryLabel: UILabel!
//    @IBOutlet weak var minutelyLookingAheadLabel: UILabel!
    
    private let refreshControl = UIRefreshControl()
    
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
//        alertViewContainer.isHidden = true
        
        refreshControl.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching New Weather Data...")
        refreshControl.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
        self.currentlyTableView.addSubview(refreshControl)
    }
    
    @objc func refreshData(sender:AnyObject) {
        WeatherController.shared.fetchWeatherInfo(latitude: (lastLocation?.coordinate.latitude)!, longitude: (lastLocation?.coordinate.longitude)!)
        weatherDataFetched()
        DispatchQueue.main.async {
            self.currentlyTableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc func weatherDataFetched () {
        
        //now that data is parsed, we can display it
        DispatchQueue.main.async {
            self.activityIndicator.removeFromSuperview()
        }
        
        DispatchQueue.main.async {
            self.currentlyTableView.reloadData()
            self.refreshControl.endRefreshing()
        }
        
        
        
//        let dataPoint = WeatherController.shared.weather
//
//        if let currentTemp = dataPoint?.currently?.temperature {
//            let newCurrentTemp = String(format: "%.0f", currentTemp)
//            DispatchQueue.main.async {
//                self.currentTempLabel.text = newCurrentTemp
//            }
//        }
//
//        if let currentCondition = dataPoint?.currently?.summary {
//            DispatchQueue.main.async {
//                self.currentConditionLabel.text = currentCondition
//            }
//        }
//
//        if let highTemp = dataPoint?.daily?.data?[0].temperatureMax {
//            let newHighTemp = String(format: "%.0f", highTemp)
//            DispatchQueue.main.async {
//                self.highTempLabel.text = newHighTemp + "\u{00B0}"
//            }
//        }
//
//        if let lowTemp = dataPoint?.daily?.data?[0].temperatureLow {
//            let newLowTemp = String(format: "%.0f", lowTemp)
//            DispatchQueue.main.async {
//                self.lowTempLabel.text = newLowTemp + "\u{00B0}"
//            }
//        }
//
//        if let currentSummary = dataPoint?.daily?.data?[0].summary {
//            DispatchQueue.main.async {
//                self.currentSummaryLabel.text = String(currentSummary)
//            }
//        }
//
//        if let lookingAhead = dataPoint?.minutely?.summary {
//            DispatchQueue.main.async {
//                cell.minutelyLookingAheadLabel.text = lookingAhead
//            }
//        }
//
//        if let alertsActive = dataPoint?.alerts?[0] {
//            print(alertsActive)
//
//            DispatchQueue.main.async {
//                alertViewContainer.isHidden = false
//            }
//        }
//
//
//        //attempting to load animated gif
//            DispatchQueue.main.async {
//                self.backgroundAnimatedImage.loadGif(asset: "weather")
//        }
        
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
            
            lastLocation = location
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

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentlyTableViewCell", for: indexPath) as? CurrentlyTableViewCell else {
            return UITableViewCell()
        }
        
        let dataPoint = WeatherController.shared.weather
        
        if let currentTemp = dataPoint?.currently?.temperature {
            let newCurrentTemp = String(format: "%.0f", currentTemp)
            DispatchQueue.main.async {
                cell.currentTempLabel.text = newCurrentTemp
            }
        }
        
        if let currentCondition = dataPoint?.currently?.summary {
            DispatchQueue.main.async {
                cell.currentConditionLabel.text = currentCondition
            }
        }
        
        if let highTemp = dataPoint?.daily?.data?[0].temperatureMax {
            let newHighTemp = String(format: "%.0f", highTemp)
            DispatchQueue.main.async {
                cell.highTempLabel.text = newHighTemp + "\u{00B0}"
            }
        }
        
        if let lowTemp = dataPoint?.daily?.data?[0].temperatureLow {
            let newLowTemp = String(format: "%.0f", lowTemp)
            DispatchQueue.main.async {
                cell.lowTempLabel.text = newLowTemp + "\u{00B0}"
            }
        }
        
        if let currentSummary = dataPoint?.daily?.data?[0].summary {
            DispatchQueue.main.async {
                cell.currentSummaryLabel.text = String(currentSummary)
            }
        }
        
        if let lookingAhead = dataPoint?.minutely?.summary {
            DispatchQueue.main.async {
                cell.minutelyLookingAheadLabel.text = lookingAhead
            }
        }

        if let alertsActive = dataPoint?.alerts?[0] {
            print(alertsActive)

            DispatchQueue.main.async {
                cell.alertViewContainer.isHidden = false
            }
        }
        
        //attempting to load animated gif
        DispatchQueue.main.async {
            cell.backgroundAnimatedImage.loadGif(asset: "weather")
        }

        
        return cell
    }
}

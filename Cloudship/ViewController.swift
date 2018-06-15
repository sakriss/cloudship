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
        
        refreshControl.tintColor = UIColor.black
        refreshControl.backgroundColor = UIColor.lightGray
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching New Weather Data...")
        refreshControl.addTarget(self, action: #selector(refreshData), for: UIControlEvents.valueChanged)
        self.currentlyTableView.addSubview(refreshControl)
    }
    
    @objc func refreshData(sender:AnyObject) {
        DispatchQueue.main.async {
            self.refreshControl.beginRefreshing()
        }
        locationManager.requestLocation()

    }
    
    @objc func weatherDataFetched () {
        
        //now that data is parsed, we can display it
        DispatchQueue.main.async {
            self.activityIndicator.removeFromSuperview()
            self.currentlyTableView.reloadData()

            self.refreshControl.endRefreshing()
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

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return currentlyTableView.bounds.size.height
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
                cell.currentTempLabel.text = newCurrentTemp
            
        }
        
        if let currentCondition = dataPoint?.currently?.summary {
                cell.currentConditionLabel.text = currentCondition
            
        }
        
        if let highTemp = dataPoint?.daily?.data?[0].temperatureMax {
            let newHighTemp = String(format: "%.0f", highTemp)
                cell.highTempLabel.text = newHighTemp + "\u{00B0}"
            
        }
        
        if let lowTemp = dataPoint?.daily?.data?[0].temperatureLow {
            let newLowTemp = String(format: "%.0f", lowTemp)
                cell.lowTempLabel.text = newLowTemp + "\u{00B0}"
            
        }
        
        if let currentSummary = dataPoint?.daily?.data?[0].summary {
                cell.currentSummaryLabel.text = String(currentSummary)
            
        }
        
        if let lookingAhead = dataPoint?.minutely?.summary {
                cell.minutelyLookingAheadLabel.text = lookingAhead
            
        }

        if let alertsActive = dataPoint?.alerts?[0] {
            print(alertsActive)

                cell.alertViewContainer.isHidden = false
            
        }
        
        //load animated gif
        //TODO: load animation based on current weather conditions
            cell.backgroundAnimatedImage.loadGif(asset: "weather")
    
        return cell
    }
    

}

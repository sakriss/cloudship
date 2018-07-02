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
 
//    @IBOutlet weak var lookingAheadCollectionView: UICollectionView!
    @IBOutlet weak var currentlyTableView: UITableView!
    
    var lastLocation: CLLocation? = nil
    var nearestStorm = 0.0
    
    private let refreshControl = UIRefreshControl()
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    let locationManager = CLLocationManager()
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        view.addSubview(activityIndicator)
        // Set up its size (the super view bounds usually)
        activityIndicator.frame = view.bounds
        
        // Start the loading animation
        activityIndicator.startAnimating()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataFetched) , name: WeatherController.weatherDataParseComplete, object: nil)
        
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
        if let nearestStormDistance = WeatherController.shared.weather?.currently?.nearestStormDistance {
            nearestStorm = nearestStormDistance
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
        return currentlyTableView.bounds.size.height - 60
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
                cell.minutelyLookingAheadLabel.text = String(currentSummary)
        }
        
        if let lookingAhead = dataPoint?.minutely?.summary {
                cell.currentSummaryLabel.text = lookingAhead
        }

        if let alertsActive = dataPoint?.alerts?[0] {
            print(alertsActive)
                cell.alertViewContainer.isHidden = false
        }
        
        //load animated gif
        //TODO: load animation based on current weather conditions
        //cell.backgroundAnimatedImage.loadGif(asset: "cloudygif")
        let conditionIcon = dataPoint?.hourly?.data?[indexPath.item].icon
        switch conditionIcon {
        case "cloudy":
            cell.backgroundAnimatedImage.image = UIImage(named: "mostlycloudybackground")
        case "partly-cloudy-day":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudybackground")
        case "partly-cloudy-night":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
        case "clear-day":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainierbackground")
        case "clear-night":
            cell.backgroundAnimatedImage.image = UIImage(named: "clearnightbackground")
        case "rain":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "snow":
            cell.backgroundAnimatedImage.image = UIImage(named: "snowbackground")
        case "sleet":
            cell.backgroundAnimatedImage.image = UIImage(named: "sleetbackground")
        case "wind":
            cell.backgroundAnimatedImage.image = UIImage(named: "windybackground")
        case "fog":
            cell.backgroundAnimatedImage.image = UIImage(named: "fogbackground")
        default:
            cell.backgroundAnimatedImage.image = UIImage(named: "rainierbackground")
        }
    
        cell.lookingAheadCollectionView.reloadData()
        
        return cell
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LookingAheadCollectionViewCell", for: indexPath) as? LookingAheadCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.cornerRadius = 5.0
        cell.layer.borderWidth = 0.5
        
        let dataPoint = WeatherController.shared.weather
        
        if let hourTime = dataPoint?.hourly?.data?[indexPath.item].time {
            let hourlyTime = NSDate(timeIntervalSince1970: (hourTime))
            
            let dailyHourString = "\(hourlyTime)" // the date string to be parsed
            let df3 = DateFormatter()
            df3.locale = Locale(identifier: "en_US")
            df3.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
            if let hour = df3.date(from: dailyHourString) {
                let format = "ha"
                let df4 = DateFormatter()
                df4.dateFormat = format
                df4.amSymbol = "AM"
                df4.pmSymbol = "PM"
                let string = df4.string(from: hour)
                cell.lookingAheadHourLabel.text = string
            } else {
                print("Unable to parse date string")
            }
        }
        
        if let hourlyTemp = dataPoint?.hourly?.data?[indexPath.item].temperature {
            let newHighTemp = String(format: "%.0f", hourlyTemp)
            cell.lookingAheadTempLabel.text = newHighTemp + "\u{00B0}"
        }
        
        let conditionIcon = dataPoint?.hourly?.data?[indexPath.item].icon
        switch conditionIcon {
        case "partly-cloudy-day":
            cell.lookingAheadConditionImage.image = UIImage(named: "mostlycloudy.png")
            
        case "partly-cloudy-night":
            cell.lookingAheadConditionImage.image = UIImage(named: "cloudynight.png")
            
        case "cloudy":
            cell.lookingAheadConditionImage.image = UIImage(named: "cloudy.png")
            
        case "clear-day":
            cell.lookingAheadConditionImage.image = UIImage(named: "sunny.png")
            
        case "clear-night":
            cell.lookingAheadConditionImage.image = UIImage(named: "clearnight.png")
            
        case "rain":
            cell.lookingAheadConditionImage.image = UIImage(named: "rain.png")
            
        case "snow":
            cell.lookingAheadConditionImage.image = UIImage(named: "snow.png")
            
        case "sleet":
            cell.lookingAheadConditionImage.image = UIImage(named: "sleet.png")
            
        case "wind":
            cell.lookingAheadConditionImage.image = UIImage(named: "wind.png")
            
        case "fog":
            cell.lookingAheadConditionImage.image = UIImage(named: "fog.png")
            
        default:
            cell.lookingAheadConditionImage.image = UIImage(named: "default.png")
            
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        
        if let precipChance = dataPoint?.hourly?.data?[indexPath.item].precipProbability {
            cell.lookingAheadPrecipLabel.text = percentFormatter.string(from: precipChance as NSNumber)
        }
        
        return cell
    }
    
    
}

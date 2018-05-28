//
//  WeatherController.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class WeatherController: Codable {
    
    static let shared = WeatherController()
    
    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
    
    var weather: Weather?
    
    var weatherArray: [Weather] {
        if let theArray = weather {
            return [theArray]
        }
        return []
    }
    
    func fetchWeatherInfo() {
        
        URLSession.shared.dataTask(with: URL(string: "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/47.197882,-122.170778")!) { (data:Data?, response:URLResponse?, error:Error?) in
        //URLSession.shared.dataTask(with: URL(string: API.AuthenticatedBaseURL.appendPathComponent("\(latitude),\(longitude)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
        if let data = data {
                self.weather = ( try? JSONDecoder().decode(Weather.self, from: data)) 
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }
        }.resume()
    }
    
}


class LocationService: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthStatus = status
        if status == .authorizedWhenInUse {
            print("We can now get your location, in WeatherController")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
            //TODO get coords and give them back to fetch weather
            
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}



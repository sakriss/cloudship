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
    
    func fetchWeatherInfo(latitude: Double, longitude: Double) {
        let baseURL = "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/"
        
        //URLSession.shared.dataTask(with: URL(string: "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/47.197882,-122.170778")!) { (data:Data?, response:URLResponse?, error:Error?) in
        URLSession.shared.dataTask(with: URL(string: baseURL + ("\(latitude),\(longitude)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseURL + ("\(latitude),\(longitude)"))
            if let data = data {
                self.weather = ( try? JSONDecoder().decode(Weather.self, from: data)) 
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }
        }.resume()
    }
    
}



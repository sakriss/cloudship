//
//  WeatherController.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherController: Codable {
    
    static let shared = WeatherController()
    
    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
    
    private var weatherInfo: WeatherInfo?
    
    var weatherArray:[Weather] {
        if let theArray = self.weatherInfo?.weather {
            return theArray
        }
        return []
    }
    
    func fetchWeatherInfo() {
        URLSession.shared.dataTask(with: URL(string: "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/47.197882,-122.170778")!) { (data:Data?, response:URLResponse?, error:Error?) in
            if let data = data {
                self.weatherInfo = ( try? JSONDecoder().decode(WeatherInfo.self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }
        }.resume()
    }
}

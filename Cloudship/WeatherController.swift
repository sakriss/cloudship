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
    static let weatherDataParseFailed = Notification.Name("weatherDataParseFailed")
    
    var weather: Weather?
    var weatherbitWeatherCurrent: WeatherbitCurrent?
    var weatherbitWeatherDaily: WeatherbitDaily?
    var weatherbitWeatherHourly: WeatherbitHourly?
    var weatherbitWeatherAlerts: WeatherbitAlert?
    
    func fetchWeatherInfo(latitude: Double, longitude: Double, units: String) {
        //let units = "units=us"
        //        let baseURL = "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/"
        //        let key = "https://api.weatherbit.io/v2.0/current?lat=47.1980208&lon=-122.1630685&key=fce7e60991d64234bfc549f55b96de21"
        //
        //        //URLSession.shared.dataTask(with: URL(string: "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/47.197882,-122.170778")!) { (data:Data?, response:URLResponse?, error:Error?) in
        //        URLSession.shared.dataTask(with: URL(string: baseURL + ("\(latitude),\(longitude)?\(units)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
        //            print(baseURL + ("\(latitude),\(longitude)"))
        //            if let data = data {
        //                self.weather = ( try? JSONDecoder().decode(Weather.self, from: data))
        //                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
        //            }else {
        //                print("ERROR: \(error!)")
        //                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
        //            }
        //        }.resume()
        
        //MARK: Current
        let baseURL = "https://api.weatherbit.io/v2.0/current?"
        let key = "key=fce7e60991d64234bfc549f55b96de21"
        
        //        "https://api.weatherbit.io/v2.0/current?lat=47.1980208&lon=-122.1630685&units=I&key=fce7e60991d64234bfc549f55b96de21"
        let tempUnits = "units=I"
        URLSession.shared.dataTask(with: URL(string: baseURL + ("lat=\(latitude)&lon=\(longitude)&\(units)&\(key)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseURL + ("\(latitude),\(longitude)&\(units)&\(key)"))
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "")
                self.weatherbitWeatherCurrent = ( try! JSONDecoder().decode(WeatherbitCurrent.self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }else {
                print("ERROR: \(error!)")
                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            }
        }.resume()
        
        //MARK: Daily
        let baseURLDaily = "https://api.weatherbit.io/v2.0/forecast/daily?"
        //                let key = "key=fce7e60991d64234bfc549f55b96de21"
        
        //        "https://api.weatherbit.io/v2.0/current?lat=47.1980208&lon=-122.1630685&units=I&key=fce7e60991d64234bfc549f55b96de21"
        let tempDailyUnits = "units=I"
        URLSession.shared.dataTask(with: URL(string: baseURLDaily + ("lat=\(latitude)&lon=\(longitude)&\(units)&\(key)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseURLDaily + ("\(latitude),\(longitude)&\(units)&\(key)"))
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "")
                self.weatherbitWeatherDaily = ( try! JSONDecoder().decode(WeatherbitDaily.self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }else {
                print("ERROR: \(error!)")
                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            }
        }.resume()
        
        //MARK: Hourly
        let baseURLHourly = "https://api.weatherbit.io/v2.0/forecast/hourly?"
        //                let key = "key=fce7e60991d64234bfc549f55b96de21"
        
        //        "https://api.weatherbit.io/v2.0/current?lat=47.1980208&lon=-122.1630685&units=I&key=fce7e60991d64234bfc549f55b96de21"
        let tempHourlyUnits = "units=I"
        let hoursToReturn = "&hours=24"
        URLSession.shared.dataTask(with: URL(string: baseURLHourly + ("lat=\(latitude)&lon=\(longitude)&\(units)&\(key)\(hoursToReturn)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseURLHourly + ("lat=\(latitude)&lon=\(longitude)&\(tempHourlyUnits)&\(key)\(hoursToReturn)"))
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "")
                self.weatherbitWeatherHourly = ( try! JSONDecoder().decode(WeatherbitHourly.self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }else {
                print("ERROR: \(error!)")
                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            }
        }.resume()
        
        //MARK: Alerts
        let baseURLAlerts = "https://api.weatherbit.io/v2.0/alerts?"
        
        // https://api.weatherbit.io/v2.0/alerts?lat=33.2280&lon=-88.3085&key=fce7e60991d64234bfc549f55b96de21
        
        URLSession.shared.dataTask(with: URL(string: baseURLAlerts + ("lat=\(latitude)&lon=\(longitude)&\(key)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseURLAlerts + ("\(latitude),\(longitude)&\(units)&\(key)"))
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "")
                self.weatherbitWeatherAlerts = ( try? JSONDecoder().decode(WeatherbitAlert.self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }else {
                print("ERROR: \(error!)")
                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            }
        }.resume()
    }
    
}



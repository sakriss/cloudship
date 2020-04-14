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
    //    var climacellDailyWeather: [ClimaWeatherDailyElement]?
    var climacellDailyWeather: [ClimaDaily]?
    var climacellHourlyWeather: [ClimaHourly]?
    
    //    func fetchWeatherInfo(latitude: Double, longitude: Double, units: String) {
    //        //let units = "units=us"
    //        let baseURL = "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/"
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
    //    }
    
    //    func fetchWeatherInfo(lat: Double, lon: Double, units: String) {
    //        //let units = "units=us"
    //        var baseURL = "https://api.climacell.co/v3/weather/realtime?"
    //        let session = URLSession.shared
    //        baseURL.append("lat=\(lat)")
    //        baseURL.append("&lon=\(lon)")
    //        baseURL.append("&unit_system=us")
    //        baseURL.append("&fields=temp")
    ////        baseURL.append("\(lat),\(lon)?\(units)")
    //        let url = URL(string: baseURL)!
    //        var request = URLRequest(url: url)
    //        request.addValue("tahOlvrTehJfjz8fwsY0BJ0O9dOuKxzn", forHTTPHeaderField: "apikey")
    //        request.addValue("application/json", forHTTPHeaderField: "Accept")
    //        print("REQUEST : \(request)")
    //
    //        session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
    //            print(baseURL + ("\(lat),\(lon)"))
    //            print(request)
    //            if let data = data {
    //                let dataString = String(data: data, encoding: .utf8)
    //                print(dataString ?? "")
    //                self.climacellWeather = ( try? JSONDecoder().decode(ClimaWeather.self, from: data))
    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
    //            }else {
    //                print("ERROR: \(error!)")
    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
    //            }
    //        }).resume()
    //    }
    
    func fetchWeatherInfo(lat: Double, lon: Double, units: String) {
        //let units = "units=us"
        // MARK: Hourly Call
        var baseHourlyURL = "https://api.climacell.co/v3/weather/forecast/hourly?"
        let sessionHourly = URLSession.shared
        baseHourlyURL.append("lat=\(lat)")
        baseHourlyURL.append("&lon=\(lon)")
        baseHourlyURL.append("&unit_system=us")
        baseHourlyURL.append("&fields=")
        baseHourlyURL.append("precipitation_probability")
        baseHourlyURL.append(",temp")
        baseHourlyURL.append(",wind_speed")
        baseHourlyURL.append(",wind_direction")
        baseHourlyURL.append(",weather_code")
        baseHourlyURL.append("&start_time=now")
        
        let urlHourly = URL(string: baseHourlyURL)!
        var requestHourly = URLRequest(url: urlHourly)
        let headers = [
            "apikey": "tahOlvrTehJfjz8fwsY0BJ0O9dOuKxzn"
        ]
        requestHourly.allHTTPHeaderFields = headers
        print("REQUEST : \(requestHourly)")
        
        // Hourly
        sessionHourly.dataTask(with: requestHourly, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseHourlyURL + ("\(lat),\(lon)"))
            print(requestHourly)
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "")
                self.climacellHourlyWeather = ( try! JSONDecoder().decode([ClimaHourly].self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }else {
                print("ERROR: \(error!)")
                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            }
        }).resume()
        
        // MARK: Daily Call
        var baseDailyURL = "https://api.climacell.co/v3/weather/forecast/daily?"
        let session = URLSession.shared
        baseDailyURL.append("lat=\(lat)")
        baseDailyURL.append("&lon=\(lon)")
        baseDailyURL.append("&start_time=now")
        baseDailyURL.append("&unit_system=us")
        baseDailyURL.append("&fields=temp%3AF")
        
        baseDailyURL.append(",wind_speed")
        baseDailyURL.append(",wind_direction")
        baseDailyURL.append(",precipitation_probability")
        baseDailyURL.append(",humidity")
        baseDailyURL.append(",sunrise")
        baseDailyURL.append(",sunset")
        baseDailyURL.append(",weather_code")
        //        baseURL.append("\(lat),\(lon)?\(units)")
        let urlDaily = URL(string: baseDailyURL)!
        var requestDaily = URLRequest(url: urlDaily)
        
        requestDaily.allHTTPHeaderFields = headers
        print("REQUEST : \(requestDaily)")
        
        // Hourly
        session.dataTask(with: requestDaily, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            print(baseDailyURL + ("\(lat),\(lon)"))
            print(requestDaily)
            if let data = data {
                let dataString = String(data: data, encoding: .utf8)
                print(dataString ?? "")
                self.climacellDailyWeather = ( try! JSONDecoder().decode([ClimaDaily].self, from: data))
                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
            }else {
                print("ERROR: \(error!)")
                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            }
        }).resume()
    }
    
}



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
//
//class WeatherController: Codable {
//
//    static let shared = WeatherController()
//
//    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
//    static let weatherDataParseFailed = Notification.Name("weatherDataParseFailed")
//
//    var weather: Weather?
//    //    var climacellDailyWeather: [ClimaWeatherDailyElement]?
//    var climacellDailyWeather: [ClimaDaily]?
//    var climacellHourlyWeather: [ClimaHourly]?
//    var climacellV4Weather: ClimacellV4?
//
//    //    func fetchWeatherInfo(latitude: Double, longitude: Double, units: String) {
//    //        //let units = "units=us"
//    //        let baseURL = "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/"
//    //
//    //        //URLSession.shared.dataTask(with: URL(string: "https://api.darksky.net/forecast/f7bc7a2bca5a3df8d3492ec37f730f60/47.197882,-122.170778")!) { (data:Data?, response:URLResponse?, error:Error?) in
//    //        URLSession.shared.dataTask(with: URL(string: baseURL + ("\(latitude),\(longitude)?\(units)"))!) { (data:Data?, response:URLResponse?, error:Error?) in
//    //            print(baseURL + ("\(latitude),\(longitude)"))
//    //            if let data = data {
//    //                self.weather = ( try? JSONDecoder().decode(Weather.self, from: data))
//    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
//    //            }else {
//    //                print("ERROR: \(error!)")
//    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
//    //            }
//    //        }.resume()
//    //    }
//
//    //    func fetchWeatherInfo(lat: Double, lon: Double, units: String) {
//    //        //let units = "units=us"
//    //        var baseURL = "https://api.climacell.co/v3/weather/realtime?"
//    //        let session = URLSession.shared
//    //        baseURL.append("lat=\(lat)")
//    //        baseURL.append("&lon=\(lon)")
//    //        baseURL.append("&unit_system=us")
//    //        baseURL.append("&fields=temp")
//    ////        baseURL.append("\(lat),\(lon)?\(units)")
//    //        let url = URL(string: baseURL)!
//    //        var request = URLRequest(url: url)
//    //        request.addValue("tahOlvrTehJfjz8fwsY0BJ0O9dOuKxzn", forHTTPHeaderField: "apikey")
//    //        request.addValue("application/json", forHTTPHeaderField: "Accept")
//    //        print("REQUEST : \(request)")
//    //
//    //        session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
//    //            print(baseURL + ("\(lat),\(lon)"))
//    //            print(request)
//    //            if let data = data {
//    //                let dataString = String(data: data, encoding: .utf8)
//    //                print(dataString ?? "")
//    //                self.climacellWeather = ( try? JSONDecoder().decode(ClimaWeather.self, from: data))
//    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
//    //            }else {
//    //                print("ERROR: \(error!)")
//    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
//    //            }
//    //        }).resume()
//    //    }
//
//    func fetchWeatherInfo(lat: Double, lon: Double, units: String) {
//        //let units = "units=us"
//        // MARK: Hourly Call
////        var baseHourlyURL = "https://api.climacell.co/v3/weather/forecast/hourly?"
////        let sessionHourly = URLSession.shared
////        baseHourlyURL.append("lat=\(lat)")
////        baseHourlyURL.append("&lon=\(lon)")
////        baseHourlyURL.append("&unit_system=us")
////        baseHourlyURL.append("&fields=")
////        baseHourlyURL.append("precipitation_probability")
////        baseHourlyURL.append(",temp")
////        baseHourlyURL.append(",wind_speed")
////        baseHourlyURL.append(",wind_direction")
////        baseHourlyURL.append(",weather_code")
////        baseHourlyURL.append(",cloud_cover")
////        baseHourlyURL.append("&start_time=now")
////
////        let urlHourly = URL(string: baseHourlyURL)!
////        var requestHourly = URLRequest(url: urlHourly)
////        let headers = [
////            "apikey": "tahOlvrTehJfjz8fwsY0BJ0O9dOuKxzn"
////        ]
////        requestHourly.allHTTPHeaderFields = headers
////        print("REQUEST : \(requestHourly)")
////
////        // Hourly
////        sessionHourly.dataTask(with: requestHourly, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
////            print(baseHourlyURL + ("\(lat),\(lon)"))
////            print(requestHourly)
////            if let data = data {
////                let dataString = String(data: data, encoding: .utf8)
////                print(dataString ?? "")
////                self.climacellHourlyWeather = ( try! JSONDecoder().decode([ClimaHourly].self, from: data))
////                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
////            }else {
////                print("ERROR: \(error!)")
////                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
////            }
////        }).resume()
////
////        // MARK: Daily Call
////        var baseDailyURL = "https://api.climacell.co/v3/weather/forecast/daily?"
////        let session = URLSession.shared
////        baseDailyURL.append("lat=\(lat)")
////        baseDailyURL.append("&lon=\(lon)")
////        baseDailyURL.append("&start_time=now")
////        baseDailyURL.append("&unit_system=us")
////        baseDailyURL.append("&fields=temp%3AF")
////
////        baseDailyURL.append(",wind_speed")
////        baseDailyURL.append(",wind_direction")
////        baseDailyURL.append(",precipitation_probability")
////        baseDailyURL.append(",humidity")
////        baseDailyURL.append(",sunrise")
////        baseDailyURL.append(",sunset")
////        baseDailyURL.append(",weather_code")
////        //        baseURL.append("\(lat),\(lon)?\(units)")
////        let urlDaily = URL(string: baseDailyURL)!
////        var requestDaily = URLRequest(url: urlDaily)
////
////        requestDaily.allHTTPHeaderFields = headers
////        print("REQUEST : \(requestDaily)")
////
////        // Hourly
////        session.dataTask(with: requestDaily, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
////            print(baseDailyURL + ("\(lat),\(lon)"))
////            print(requestDaily)
////            if let data = data {
////                let dataString = String(data: data, encoding: .utf8)
////                print(dataString ?? "")
////                self.climacellDailyWeather = ( try! JSONDecoder().decode([ClimaDaily].self, from: data))
////                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
////            }else {
////                print("ERROR: \(error!)")
////                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
////            }
////        }).resume()
//
//        // MARK: Tomorrow V4 Call
////        let timeNow: Date = Date()
//        let date = Date()
//        let modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
//        let formatter = DateFormatter()
//        formatter.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
//        formatter.string(from: date)
//        let dateFormatted = formatter.string(from: date)
//        let tomorrowFormatted = formatter.string(from: modifiedDate)
//
////        let timeString = String(timeNow)
//        var tomorrowURL = "https://api.tomorrow.io/v4/timelines?"
//        let sessionTomorrow = URLSession.shared
//        tomorrowURL.append("location=\(lat)")
//        tomorrowURL.append(",\(lon)")
//        tomorrowURL.append("&fields=")
//        tomorrowURL.append("precipitationIntensity")
//        tomorrowURL.append(",temperature")
//        tomorrowURL.append(",windSpeed")
//        tomorrowURL.append(",windDirection")
//        tomorrowURL.append(",precipitationProbability")
//        tomorrowURL.append(",precipitationType")
//        tomorrowURL.append(",humidity")
//        tomorrowURL.append(",sunsetTime")
//        tomorrowURL.append(",sunriseTime")
//        tomorrowURL.append(",weatherCode")
//        tomorrowURL.append(",cloudCover")
//        tomorrowURL.append("&startTime=")
//        tomorrowURL.append(dateFormatted)
//        tomorrowURL.append("&endTime=")
//        tomorrowURL.append(tomorrowFormatted)
//        tomorrowURL.append("&timesteps=1d")
//        tomorrowURL.append("&units=imperial")
//        tomorrowURL.append("&timezone=UTC")
//        tomorrowURL.append("&apikey=KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM")
//
//        let urlTomorrow = URL(string: tomorrowURL)!
//        var requestTomorrow = URLRequest(url: urlTomorrow)
////        let headers = [
////            "apikey": "tahOlvrTehJfjz8fwsY0BJ0O9dOuKxzn"
////        ]
//        //requestTomorrow.allHTTPHeaderFields = headers
//        requestTomorrow.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        print("REQUEST : \(requestTomorrow)")
//
//        // Hourly
//        sessionTomorrow.dataTask(with: requestTomorrow, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
//            //print(baseHourlyURL + ("\(lat),\(lon)"))
//            print(requestTomorrow)
//            if let data = data {
//                let dataString = String(data: data, encoding: .utf8)
//                print(dataString ?? "")
//                self.climacellV4Weather = ( try! JSONDecoder().decode(ClimacellV4.self, from: data))
//                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
//            }else {
//                print("ERROR: \(error!)")
//                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
//            }
//        }).resume()
//
//        // current
//        let headers = ["accept": "application/json"]
//
//        let request = NSMutableURLRequest(url: NSURL(string: "https://api.tomorrow.io/v4/weather/forecast?location=new%20york&apikey=KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM")! as URL,
//                                                cachePolicy: .useProtocolCachePolicy,
//                                            timeoutInterval: 10.0)
//        request.httpMethod = "GET"
//        request.allHTTPHeaderFields = headers
//
//        let session = URLSession.shared
//        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
//          if (error != nil) {
//            print(error as Any)
//          } else {
//            let httpResponse = response as? HTTPURLResponse
//            print(httpResponse)
//          }
//        })
//
//        dataTask.resume()
//    }
//
//}
//
//

class WeatherController {
    
    static let shared = WeatherController()
    
    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
    static let weatherDataParseFailed = Notification.Name("weatherDataParseFailed")
    
    var weather: Weather?
    var climacellDailyWeather: [ClimaDaily]?
    var climacellHourlyWeather: [ClimaHourly]?
    var climacellV4Weather: ClimacellV4?
    
    func fetchWeatherInfo(lat: Double, lon: Double, units: String) async {
        do {
            // Fetch current weather
            try await fetchCurrentWeather(lat: lat, lon: lon, units: units)
            
            // Fetch forecast data
            try await fetchForecast(lat: lat, lon: lon, units: units)
        } catch {
            // Handle the error, such as showing an error message
            print("Error fetching weather information: \(error)")
        }
    }
    
    func fetchCurrentWeather(lat: Double, lon: Double, units: String) async throws {
        let url = URL(string: "https://api.tomorrow.io/v4/weather/realtime")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "location", value: "\(lat),\(lon)"),
            URLQueryItem(name: "apikey", value: "KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM"),
        ]
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = ["accept": "application/json"]

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("****REALTIME:****")
            print(String(decoding: data, as: UTF8.self))
            
//            let decodedResponse = try JSONDecoder().decode(ClimacellV4.self, from: data)
            let decodedResponse = try JSONDecoder().decode(ClimacellV4.self, from: data)
                WeatherController.shared.climacellV4Weather = decodedResponse
                
                // Debug: print the entire decoded response
                print("Decoded Response: \(decodedResponse)")
                
                // Debug: Check if realtime data exists
                if let realtime = decodedResponse.realtime {
                    print("Realtime Data Exists")
                    // Check if temperature data exists in realtime values
                    if let temperature = realtime.values.temperature {
                        print("Temperature: \(temperature)°C")
                    } else {
                        print("Temperature data not available in realtime.values.")
                    }
                } else {
                    print("Realtime data not available in the response.")
                }
            WeatherController.shared.climacellV4Weather = decodedResponse
            NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
        } catch {
            print("Error fetching weather data: \(error)")
            NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            throw error
        }
    }
    
    func fetchForecast(lat: Double, lon: Double, units: String) async throws {
        let url = URL(string: "https://api.tomorrow.io/v4/weather/forecast")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        // Add query items directly
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "location", value: "\(lat),\(lon)"),
            URLQueryItem(name: "apikey", value: "KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM"),
            URLQueryItem(name: "units", value: "imperial") // Pass units as well
        ]
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = ["accept": "application/json"]

        do {
            // Make the request and await the data
            let (data, _) = try await URLSession.shared.data(for: request)
            print("****FORECAST:****")
            print(String(decoding: data, as: UTF8.self))
            // Decode the response into the updated model
            let decoder = JSONDecoder()
//            let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
            let climacell = try decoder.decode(ClimacellV4.self, from: data)
//            WeatherController.shared.forecastData = forecastResponse
            
            // Handle the response data
//            print("Minutely forecast data: \(climacell.timelines?.minutely ?? [])")
//            print("Hourly forecast data: \(forecastResponse.timelines?.hourly ?? [])")
//            print("Daily forecast data: \(forecastResponse.timelines?.daily ?? [])")

            // Post notification or update UI as needed
            NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
        } catch {
            // Handle any errors
            print("Error fetching forecast data: \(error)")
            NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
            throw error
        }
    }
    
    //        let currentWeatherURL = "https://api.tomorrow.io/v4/weather/realtime?location=\(lat),\(lon)&apikey=KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM"
    //        print(currentWeatherURL)
    //        guard let url = URL(string: currentWeatherURL) else { return }
    //        var request = URLRequest(url: url)
    //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    //
    //        URLSession.shared.dataTask(with: request) { (data, response, error) in
    //            if let error = error {
    //                print("ERROR: \(error)")
    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
    //                return
    //            }
    //
    //            guard let data = data else { return }
    //            do {
    //                let decodedResponse = try JSONDecoder().decode(ClimacellV4.self, from: data)
    //                self.climacellV4Weather = decodedResponse
    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
    //            } catch {
    //                print("Decoding Error: \(error)")
    //                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
    //            }
    //        }.resume()
}

//    private func fetchForecast(lat: Double, lon: Double, units: String) {
//        let forecastURL = "https://api.tomorrow.io/v4/weather/forecast?location=\(lat),\( lon)&apikey=KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM"
//        print(forecastURL)
//        guard let url = URL(string: forecastURL) else { return }
//        var request = URLRequest(url: url)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        URLSession.shared.dataTask(with: request) { (data, response, error) in
//            if let error = error {
//                print("ERROR: \(error)")
//                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
//                return
//            }
//
//            guard let data = data else { return }
//            do {
//                let decodedResponse = try JSONDecoder().decode(ClimacellV4.self, from: data)
//                self.climacellV4Weather = decodedResponse
//                NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
//            } catch {
//                print("Decoding Error: \(error)")
//                NotificationCenter.default.post(name: WeatherController.weatherDataParseFailed, object: nil)
//            }
//        }.resume()
//    }


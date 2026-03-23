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

class WeatherController {
    
    static let shared = WeatherController()
    
    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
    static let weatherDataParseFailed = Notification.Name("weatherDataParseFailed")
    
    var climacellV4Weather: ClimacellV4?
    var forecastWeather: ClimacellV4.ForecastResponse?
    
    func fetchWeatherInfo(lat: Double, lon: Double, units: String) async {
        do {
            // Realtime is required — failure shows the error alert
            try await fetchCurrentWeather(lat: lat, lon: lon, units: units)
        } catch {
            print("Error fetching current weather: \(error)")
            return
        }

        do {
            // Forecast is supplementary — failure just logs, doesn't show alert
            try await fetchForecast(lat: lat, lon: lon, units: units)
        } catch {
            print("Error fetching forecast (non-fatal): \(error)")
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

            let forecastResponse = try JSONDecoder().decode(ClimacellV4.ForecastResponse.self, from: data)
            // Merge forecast into the existing climacellV4Weather object via a wrapper
            WeatherController.shared.forecastWeather = forecastResponse
            print("Forecast timelines - hourly count: \(forecastResponse.timelines?.hourly?.count ?? 0), daily count: \(forecastResponse.timelines?.daily?.count ?? 0)")

            NotificationCenter.default.post(name: WeatherController.weatherDataParseComplete, object: nil)
        } catch {
            // Forecast failure is non-fatal — just log and rethrow so caller can handle quietly
            print("Error fetching forecast data: \(error)")
            throw error
        }
    }
    
}

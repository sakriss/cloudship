//
//  WeatherDataSource.swift
//  Cloudship
//
//  Protocol that all weather data sources must conform to.
//  Allows swapping between Tomorrow.io, NOAA, etc. at runtime.
//

import Foundation

protocol WeatherDataSource {
    /// Human-readable name shown in Settings (e.g. "Tomorrow.io", "NOAA")
    var name: String { get }

    /// Fetch complete weather for a location.
    /// - Parameters:
    ///   - lat: Latitude
    ///   - lon: Longitude
    ///   - units: "imperial" or "metric"
    /// - Returns: Unified weather data consumed by all UI cards
    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData
}

// MARK: - Known source identifiers for UserDefaults persistence

enum WeatherSourceID: String {
    case tomorrowIO    = "tomorrowIO"
    case noaa          = "noaa"
    case openMeteo     = "openMeteo"
    case pirateWeather = "pirateWeather"
    case appleWeather  = "appleWeather"
}

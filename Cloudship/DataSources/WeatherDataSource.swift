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

enum WeatherSourceID: String, Codable {
    case tomorrowIO    = "tomorrowIO"
    case noaa          = "noaa"
    case openMeteo     = "openMeteo"
    case pirateWeather = "pirateWeather"
    case appleWeather  = "appleWeather"
    case accuWeather   = "accuWeather"
}

extension WeatherSourceID {
    static let forecastQuickSwitchOrder: [WeatherSourceID] = [
        .noaa, .openMeteo, .pirateWeather, .appleWeather, .tomorrowIO, .accuWeather
    ]

    var requiresPremium: Bool {
        switch self {
        case .tomorrowIO, .accuWeather:
            return true
        case .noaa, .openMeteo, .pirateWeather, .appleWeather:
            return false
        }
    }

    var forecastMenuTitle: String {
        switch self {
        case .tomorrowIO:    return "Tomorrow.io"
        case .noaa:          return "NOAA"
        case .openMeteo:     return "Open-Meteo"
        case .pirateWeather: return "Pirate Weather"
        case .appleWeather:  return "Apple Weather"
        case .accuWeather:   return "AccuWeather"
        }
    }

    func makeWeatherDataSource() -> WeatherDataSource {
        switch self {
        case .tomorrowIO:    return TomorrowIODataSource()
        case .noaa:          return NOAADataSource()
        case .openMeteo:     return OpenMeteoDataSource()
        case .pirateWeather: return PirateWeatherDataSource()
        case .appleWeather:  return AppleWeatherDataSource()
        case .accuWeather:   return AccuWeatherDataSource()
        }
    }
}

//
//  UnifiedWeatherModels.swift
//  Cloudship
//
//  Source-agnostic weather data models consumed by all UI cards.
//  Both Tomorrow.io and NOAA sources map into these structs.
//

import Foundation

// MARK: - Root data structure

struct UnifiedWeatherData: Codable {
    var locationName: String?
    var current: CurrentConditions
    var hourly: [HourlyEntry]       // up to 24 entries
    var daily: [DailyEntry]         // up to 7 entries
    var minutely: [MinutelyEntry]   // up to 60 entries (empty for NOAA)
    var alerts: [WeatherAlert]      // active weather alerts (may be empty)
    var airQuality: AirQualityData? // nil when unavailable (e.g. NOAA source)
    var pollen: PollenData?         // nil when unavailable
}

// MARK: - Air Quality

struct AirQualityData: Codable {
    var index: Int              // EPA AQI 0–500
    var category: AQICategory

    enum AQICategory: String, Codable {
        case good                    = "Good"
        case moderate                = "Moderate"
        case unhealthySensitive      = "Unhealthy for Sensitive Groups"
        case unhealthy               = "Unhealthy"
        case veryUnhealthy           = "Very Unhealthy"
        case hazardous               = "Hazardous"

        static func from(index: Int) -> AQICategory {
            switch index {
            case 0...50:   return .good
            case 51...100: return .moderate
            case 101...150: return .unhealthySensitive
            case 151...200: return .unhealthy
            case 201...300: return .veryUnhealthy
            default:        return .hazardous
            }
        }

        var description: String {
            switch self {
            case .good:               return "Air quality is satisfactory, and air pollution poses little or no risk."
            case .moderate:           return "Air quality is acceptable. Some pollutants may be a concern for a small number of people."
            case .unhealthySensitive: return "Members of sensitive groups may experience health effects."
            case .unhealthy:          return "Everyone may begin to experience health effects."
            case .veryUnhealthy:      return "Health alert: everyone may experience more serious health effects."
            case .hazardous:          return "Health warning of emergency conditions."
            }
        }
    }
}

// MARK: - Pollen

struct PollenData: Codable {
    var tree:  PollenLevel
    var grass: PollenLevel
    var weed:  PollenLevel
    var mold:  PollenLevel?
}

enum PollenLevel: Int, CaseIterable, Codable {
    case none    = 0
    case veryLow = 1
    case low     = 2
    case medium  = 3
    case high    = 4
    case veryHigh = 5

    var label: String {
        switch self {
        case .none:     return "None"
        case .veryLow:  return "Very Low"
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .veryHigh: return "Very High"
        }
    }
}

// MARK: - Weather alerts

struct WeatherAlert: Codable {
    var event: String           // e.g. "Winter Storm Warning"
    var headline: String        // short NWS headline
    var description: String     // full alert body text
    var instruction: String?    // what to do
    var severity: AlertSeverity
    var onset: Date?
    var expires: Date?
    var areaDesc: String?       // affected area description
    var source: String          // "NWS" / "Tomorrow.io"
}

enum AlertSeverity: String, Comparable, Codable {
    case extreme  = "Extreme"
    case severe   = "Severe"
    case moderate = "Moderate"
    case minor    = "Minor"
    case unknown  = "Unknown"

    /// Ordering: extreme > severe > moderate > minor > unknown
    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        let order: [AlertSeverity] = [.unknown, .minor, .moderate, .severe, .extreme]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }

    /// Emoji prefix shown in the banner
    var emoji: String {
        switch self {
        case .extreme:  return "🚨"
        case .severe:   return "⚠️"
        case .moderate: return "⚠️"
        case .minor:    return "ℹ️"
        case .unknown:  return "⚠️"
        }
    }
}

// MARK: - Current conditions

struct CurrentConditions: Codable {
    var temperature: Double?
    var feelsLike: Double?
    var humidity: Double?
    var windSpeed: Double?
    var windGust: Double?
    var windDirection: Double?
    var condition: WeatherCondition
    var uvIndex: Double?
    var visibility: Double?
    var pressure: Double?
    var dewPoint: Double?
    var cloudCover: Double?
}

// MARK: - Forecast entries

struct HourlyEntry: Codable {
    var time: Date
    var temp: Double?
    var condition: WeatherCondition
    var precipChance: Double?
    var windGust: Double?
}

struct DailyEntry: Codable {
    var time: Date
    var tempMin: Double?
    var tempMax: Double?
    var feelsLikeMin: Double?
    var feelsLikeMax: Double?
    var condition: WeatherCondition
    var conditionNight: WeatherCondition
    var precipChance: Double?
    var precipAmount: Double?       // inches or mm depending on units
    var sunrise: Date?
    var sunset: Date?
    var moonPhase: Double?          // 0–1: 0=new, 0.25=first quarter, 0.5=full, 0.75=last quarter
    var dayDescription: String?     // e.g. "Partly sunny"
    var nightDescription: String?   // e.g. "Partly cloudy and cold"
}

struct MinutelyEntry: Codable {
    var time: Date
    var precipIntensity: Double?
}

// MARK: - Moon phase helper

extension DailyEntry {
    var moonPhaseName: String {
        guard let phase = moonPhase else { return "" }
        switch phase {
        case 0..<0.0625, 0.9375...1.0: return "New Moon"
        case 0.0625..<0.1875:          return "Waxing Crescent"
        case 0.1875..<0.3125:          return "First Quarter"
        case 0.3125..<0.4375:          return "Waxing Gibbous"
        case 0.4375..<0.5625:          return "Full Moon"
        case 0.5625..<0.6875:          return "Waning Gibbous"
        case 0.6875..<0.8125:          return "Last Quarter"
        default:                        return "Waning Crescent"
        }
    }

    var moonPhaseEmoji: String {
        guard let phase = moonPhase else { return "🌑" }
        switch phase {
        case 0..<0.0625, 0.9375...1.0: return "🌑"
        case 0.0625..<0.1875:          return "🌒"
        case 0.1875..<0.3125:          return "🌓"
        case 0.3125..<0.4375:          return "🌔"
        case 0.4375..<0.5625:          return "🌕"
        case 0.5625..<0.6875:          return "🌖"
        case 0.6875..<0.8125:          return "🌗"
        default:                        return "🌘"
        }
    }
}

// MARK: - Weather condition enum

enum WeatherCondition: String, Codable {
    case clear
    case mostlyClear
    case partlyCloudy
    case mostlyCloudy
    case cloudy
    case fog
    case lightFog
    case drizzle
    case rain
    case heavyRain
    case lightSnow
    case snow
    case heavySnow
    case sleet
    case thunderstorm
    case windy
    case unknown

    /// Human-readable description
    var description: String {
        switch self {
        case .clear:         return "Clear"
        case .mostlyClear:   return "Mostly Clear"
        case .partlyCloudy:  return "Partly Cloudy"
        case .mostlyCloudy:  return "Mostly Cloudy"
        case .cloudy:        return "Cloudy"
        case .fog:           return "Fog"
        case .lightFog:      return "Light Fog"
        case .drizzle:       return "Drizzle"
        case .rain:          return "Rain"
        case .heavyRain:     return "Heavy Rain"
        case .lightSnow:     return "Light Snow"
        case .snow:          return "Snow"
        case .heavySnow:     return "Heavy Snow"
        case .sleet:         return "Sleet"
        case .thunderstorm:  return "Thunderstorm"
        case .windy:         return "Windy"
        case .unknown:       return "—"
        }
    }
}

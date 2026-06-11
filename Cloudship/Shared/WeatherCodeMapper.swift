//
//  WeatherCodeMapper.swift
//  Cloudship
//
//  Maps Tomorrow.io integer codes and NOAA text descriptions to WeatherCondition enum.
//  Also provides asset names for icons from Assets.xcassets.
//

import Foundation

enum WeatherCodeMapper {

    private static func firstKnownCondition(from codes: [Int?]) -> WeatherCondition {
        for code in codes {
            let condition = condition(fromTomorrowCode: code)
            if condition != .unknown {
                return condition
            }
        }
        return .unknown
    }

    // MARK: - Tomorrow.io integer → WeatherCondition

    static func condition(fromTomorrowCode code: Int?) -> WeatherCondition {
        guard let code = code else { return .unknown }
        switch code {
        case 1000:           return .clear
        case 1100:           return .mostlyClear
        case 1101:           return .partlyCloudy
        case 1102:           return .mostlyCloudy
        case 1001:           return .cloudy
        case 2000:           return .fog
        case 2100:           return .lightFog
        case 4000:           return .drizzle
        case 4200:           return .rain
        case 4001:           return .rain
        case 4201:           return .heavyRain
        case 5100:           return .lightSnow
        case 5000:           return .snow
        case 5001:           return .snow       // flurries → snow
        case 5101:           return .heavySnow
        case 6000, 6200:     return .sleet      // freezing drizzle / light freezing rain
        case 6001, 6201:     return .sleet      // freezing rain / heavy freezing rain
        case 7000, 7101, 7102: return .sleet    // ice pellets
        case 8000:           return .thunderstorm
        default:             return .unknown
        }
    }

    /// Daily timelines can emit mixed-condition codes that are not covered by the
    /// basic weatherCode mapping. Prefer the richer day/full-day codes when present,
    /// then fall back to avg/max/min until we find a known icon-safe condition.
    static func condition(fromTomorrowDailyValues values: ClimacellV4.ForecastValues?) -> WeatherCondition {
        firstKnownCondition(from: [
            values?.weatherCodeFullDay,
            values?.weatherCodeDay,
            values?.weatherCodeAvg,
            values?.weatherCodeMax,
            values?.weatherCodeMin
        ])
    }

    static func nightCondition(fromTomorrowDailyValues values: ClimacellV4.ForecastValues?) -> WeatherCondition {
        firstKnownCondition(from: [
            values?.weatherCodeNight,
            values?.weatherCodeMax,
            values?.weatherCodeFullDay,
            values?.weatherCodeAvg,
            values?.weatherCodeMin
        ])
    }

    // MARK: - NOAA text description → WeatherCondition

    static func condition(fromNOAADescription text: String?) -> WeatherCondition {
        guard let text = text?.lowercased() else { return .unknown }

        if text.contains("thunder")                         { return .thunderstorm }
        if text.contains("blizzard") || text.contains("heavy snow") { return .heavySnow }
        if text.contains("snow") || text.contains("flurr") { return .snow }
        if text.contains("sleet") || text.contains("ice") || text.contains("freezing") { return .sleet }
        if text.contains("heavy rain") || text.contains("heavy shower") { return .heavyRain }
        if text.contains("shower") || text.contains("rain") || text.contains("drizzle") { return .rain }
        if text.contains("fog")                             { return .fog }
        if text.contains("mostly cloudy") || text.contains("mostly overcast") { return .mostlyCloudy }
        if text.contains("partly cloudy") || text.contains("partly sunny") { return .partlyCloudy }
        if text.contains("overcast") || text.contains("cloudy") { return .cloudy }
        if text.contains("mostly clear") || text.contains("mostly sunny") { return .mostlyClear }
        if text.contains("clear") || text.contains("sunny") || text.contains("fair") { return .clear }
        if text.contains("wind") || text.contains("breezy") { return .windy }
        return .unknown
    }

    // MARK: - WeatherCondition → asset name

    static func iconName(for condition: WeatherCondition, isNight: Bool = false) -> String {
        switch condition {
        case .clear, .mostlyClear:
            return isNight ? "clearnight" : "sunny"
        case .partlyCloudy:
            return isNight ? "cloudynight" : "mostlycloudy"
        case .mostlyCloudy:
            return "mostlycloudy"
        case .cloudy:
            return "cloudy"
        case .fog, .lightFog:
            return "fog"
        case .drizzle:
            return "drizzle"
        case .rain, .heavyRain:
            return "rain"
        case .lightSnow, .snow, .heavySnow:
            return "snow"
        case .sleet:
            return "sleet"
        case .thunderstorm:
            return "thunderstorm"
        case .windy:
            return "wind"
        case .unknown:
            return "cloudy"
        }
    }

    // MARK: - Convenience: description from condition

    static func description(for condition: WeatherCondition) -> String {
        condition.description
    }

    // MARK: - Night detection helper

    /// Uses solar times when they describe the requested date, then falls back
    /// to a predictable clock-based boundary for sources without sun data.
    static func isNight(
        at date: Date = Date(),
        sunrise: Date? = nil,
        sunset: Date? = nil,
        calendar: Calendar = .current
    ) -> Bool {
        if let sunrise, let sunset,
           calendar.isDate(date, inSameDayAs: sunrise),
           calendar.isDate(date, inSameDayAs: sunset) {
            return date < sunrise || date >= sunset
        }

        let hour = calendar.component(.hour, from: date)
        return hour >= 20 || hour < 6
    }

    static func isNighttime() -> Bool {
        isNight()
    }

    // MARK: - Dark Sky / Pirate Weather icon string → WeatherCondition

    static func condition(fromDarkSkyIcon icon: String?) -> WeatherCondition {
        guard let icon = icon else { return .unknown }
        switch icon {
        case "clear-day", "clear-night":                     return .clear
        case "rain", "possible-rain-day", "possible-rain-night": return .rain
        case "light-rain":                                   return .drizzle
        case "heavy-rain":                                   return .heavyRain
        case "drizzle":                                      return .drizzle
        case "snow", "possible-snow-day", "possible-snow-night": return .snow
        case "light-snow", "flurries":                       return .lightSnow
        case "heavy-snow":                                   return .heavySnow
        case "sleet", "possible-sleet-day", "possible-sleet-night": return .sleet
        case "light-sleet", "heavy-sleet":                   return .sleet
        case "wind", "breezy", "dangerous-wind":             return .windy
        case "fog", "mist", "haze":                          return .fog
        case "cloudy":                                       return .cloudy
        case "partly-cloudy-day", "partly-cloudy-night":     return .partlyCloudy
        case "thunderstorm":                                 return .thunderstorm
        case "smoke":                                        return .fog
        case "mixed":                                        return .sleet
        default:                                             return .unknown
        }
    }

    // MARK: - AccuWeather icon number → WeatherCondition

    /// Maps AccuWeather icon numbers (1-44) to WeatherCondition.
    /// Reference: https://developer.accuweather.com/weather-icons
    static func condition(fromAccuWeatherIcon icon: Int?) -> WeatherCondition {
        guard let icon = icon else { return .unknown }
        switch icon {
        case 1, 2:            return .clear          // Sunny, Mostly Sunny
        case 33, 34:          return .clear          // Clear (night), Mostly Clear (night)
        case 3, 4:            return .partlyCloudy   // Partly Sunny, Intermittent Clouds
        case 35, 36:          return .partlyCloudy   // Partly Cloudy (night), Intermittent Clouds (night)
        case 5:               return .lightFog       // Hazy Sunshine
        case 6:               return .mostlyCloudy   // Mostly Cloudy
        case 38:              return .mostlyCloudy   // Mostly Cloudy (night)
        case 7:               return .cloudy         // Cloudy
        case 8:               return .cloudy         // Dreary (Overcast)
        case 37:              return .lightFog       // Hazy Moonlight (night)
        case 11:              return .fog            // Fog
        case 12:              return .rain           // Showers
        case 13:              return .rain           // Mostly Cloudy w/ Showers
        case 14:              return .rain           // Partly Sunny w/ Showers
        case 39:              return .rain           // Partly Cloudy w/ Showers (night)
        case 40:              return .rain           // Mostly Cloudy w/ Showers (night)
        case 15:              return .thunderstorm   // T-Storms
        case 16:              return .thunderstorm   // Mostly Cloudy w/ T-Storms
        case 17:              return .thunderstorm   // Partly Sunny w/ T-Storms
        case 41:              return .thunderstorm   // Partly Cloudy w/ T-Storms (night)
        case 42:              return .thunderstorm   // Mostly Cloudy w/ T-Storms (night)
        case 18:              return .heavyRain      // Rain
        case 19:              return .lightSnow      // Flurries
        case 20:              return .lightSnow      // Mostly Cloudy w/ Flurries
        case 21:              return .lightSnow      // Partly Sunny w/ Flurries
        case 43:              return .lightSnow      // Mostly Cloudy w/ Flurries (night)
        case 22:              return .snow           // Snow
        case 23:              return .snow           // Mostly Cloudy w/ Snow
        case 44:              return .snow           // Mostly Cloudy w/ Snow (night)
        case 24:              return .sleet          // Ice
        case 25:              return .sleet          // Sleet
        case 26:              return .sleet          // Freezing Rain
        case 29:              return .sleet          // Rain and Snow
        case 30:              return .clear          // Hot
        case 31:              return .clear          // Cold
        case 32:              return .windy          // Windy
        default:              return .unknown
        }
    }

    // MARK: - WMO code (Open-Meteo) → WeatherCondition

    static func condition(fromWMOCode code: Int?) -> WeatherCondition {
        guard let code = code else { return .unknown }
        switch code {
        case 0:           return .clear
        case 1:           return .mostlyClear
        case 2:           return .partlyCloudy
        case 3:           return .cloudy
        case 45, 48:      return .fog
        case 51, 53:      return .drizzle
        case 55:          return .drizzle
        case 56, 57:      return .sleet
        case 61:          return .rain
        case 63:          return .rain
        case 65:          return .heavyRain
        case 66, 67:      return .sleet
        case 71:          return .lightSnow
        case 73:          return .snow
        case 75:          return .heavySnow
        case 77:          return .snow
        case 80:          return .rain
        case 81:          return .rain
        case 82:          return .heavyRain
        case 85:          return .lightSnow
        case 86:          return .heavySnow
        case 95:          return .thunderstorm
        case 96, 99:      return .thunderstorm
        default:          return .unknown
        }
    }
}

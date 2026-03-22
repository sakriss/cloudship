//
//  WeatherCodeMapper.swift
//  Cloudship
//
//  Maps Tomorrow.io integer codes and NOAA text descriptions to WeatherCondition enum.
//  Also provides asset names for icons from Assets.xcassets.
//

import Foundation

enum WeatherCodeMapper {

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
        case .drizzle, .rain, .heavyRain:
            return "rain"
        case .lightSnow, .snow, .heavySnow:
            return "snow"
        case .sleet:
            return "sleet"
        case .thunderstorm:
            return "rain"       // fallback; add thunder asset later
        case .windy:
            return "wind"
        case .unknown:
            return "sunny"
        }
    }

    // MARK: - Convenience: description from condition

    static func description(for condition: WeatherCondition) -> String {
        condition.description
    }

    // MARK: - Night detection helper

    /// Returns true if the current local hour is between 8 PM and 6 AM.
    static func isNighttime() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 20 || hour < 6
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

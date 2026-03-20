//
//  WidgetConditionIcon.swift
//  CloudshipWidget
//
//  Maps condition raw strings to SF Symbol names for widget display.
//

import SwiftUI

enum WidgetConditionIcon {

    /// SF Symbol name for a weather condition string.
    static func symbolName(for conditionRaw: String) -> String {
        switch conditionRaw {
        case "clear":         return "sun.max.fill"
        case "mostlyClear":   return "sun.min.fill"
        case "partlyCloudy":  return "cloud.sun.fill"
        case "mostlyCloudy":  return "cloud.fill"
        case "cloudy":        return "smoke.fill"
        case "fog", "lightFog": return "cloud.fog.fill"
        case "drizzle":       return "cloud.drizzle.fill"
        case "rain":          return "cloud.rain.fill"
        case "heavyRain":     return "cloud.heavyrain.fill"
        case "lightSnow":     return "cloud.snow.fill"
        case "snow":          return "cloud.snow.fill"
        case "heavySnow":     return "snowflake"
        case "sleet":         return "cloud.sleet.fill"
        case "thunderstorm":  return "cloud.bolt.rain.fill"
        case "windy":         return "wind"
        default:              return "cloud.fill"
        }
    }

    /// Color tint for a weather condition.
    static func color(for conditionRaw: String) -> Color {
        switch conditionRaw {
        case "clear", "mostlyClear":
            return .yellow
        case "rain", "heavyRain", "drizzle":
            return Color(red: 0.27, green: 0.65, blue: 0.89)
        case "snow", "lightSnow", "heavySnow", "sleet":
            return Color(red: 0.7, green: 0.85, blue: 1.0)
        case "thunderstorm":
            return .purple
        case "fog", "lightFog":
            return .gray
        default:
            return .white
        }
    }
}

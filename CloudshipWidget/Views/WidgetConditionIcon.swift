//
//  WidgetConditionIcon.swift
//  CloudshipWidget
//
//  Maps condition raw strings to Cloudship weather artwork.
//

import SwiftUI

enum WidgetConditionIcon {

    static func assetName(for conditionRaw: String, isNight: Bool = false) -> String {
        switch conditionRaw {
        case "clear", "mostlyClear":       return isNight ? "clearnight" : "sunny"
        case "partlyCloudy":               return isNight ? "cloudynight" : "mostlycloudy"
        case "mostlyCloudy":               return "mostlycloudy"
        case "cloudy":                     return "cloudy"
        case "fog", "lightFog":            return "fog"
        case "drizzle":                    return "drizzle"
        case "rain", "heavyRain":          return "rain"
        case "lightSnow", "snow", "heavySnow": return "snow"
        case "sleet":                      return "sleet"
        case "thunderstorm":               return "thunderstorm"
        case "windy":                      return "wind"
        default:                           return "cloudy"
        }
    }

    static func isNight(
        at date: Date,
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
}

//
//  PrecipitationActivityAttributes.swift
//  Cloudship
//
//  ActivityKit attributes for the Precipitation Live Activity.
//  Compiled into both the main app (to start/update/end) and the
//  widget extension (to render Dynamic Island + Lock Screen views).
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct PrecipitationActivityAttributes: ActivityAttributes {

    // MARK: - Dynamic state (updated with each weather refresh)

    public struct ContentState: Codable, Hashable {
        /// Short human-readable summary, e.g. "Rain ending in 12 min"
        var summary: String
        /// Precipitation intensity in mm/hr (0 = none)
        var precipIntensity: Double
        /// "rain", "snow", "sleet", or "" for none
        var precipType: String
        /// 0–100 precipitation probability from the next hourly entry
        var precipChance: Int
        /// Formatted temperature string including unit, e.g. "72°F"
        var temperatureString: String
        /// SF Symbol name for the current weather condition
        var conditionSymbol: String
        /// Minutes until precipitation starts or stops (nil if unknown / beyond minutely range)
        var transitionMinutes: Int?
        /// Whether it is currently precipitating
        var isPrecipitating: Bool
    }

    // MARK: - Static attributes (fixed at activity start)

    var locationName: String
}

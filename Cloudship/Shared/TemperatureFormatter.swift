//
//  TemperatureFormatter.swift
//  Cloudship
//

import Foundation

enum TemperatureFormatter {

    /// Formats a temperature value with degree symbol and unit letter.
    /// - Parameters:
    ///   - value: The temperature value (in the units implied by UserDefaults "Units")
    ///   - showUnit: Whether to append °F or °C (default true)
    /// - Returns: Formatted string e.g. "72°F" or "72°"
    static func format(_ value: Double?, showUnit: Bool = false) -> String {
        guard let value = value else { return "—" }
        let rounded = Int(value.rounded())
        if showUnit {
            let unit = isMetric ? "C" : "F"
            return "\(rounded)°\(unit)"
        }
        return "\(rounded)°"
    }

    /// Returns the current unit preference from UserDefaults.
    static var isMetric: Bool {
        let units = UserDefaults.standard.string(forKey: "Units") ?? "imperial"
        return units == "metric"
    }

    /// The Tomorrow.io / NOAA units string for API calls.
    static var apiUnits: String {
        isMetric ? "metric" : "imperial"
    }
}

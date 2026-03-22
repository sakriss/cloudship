//
//  PrecipitationAnalyzer.swift
//  Cloudship
//
//  Deterministic precipitation one-liner — no API call, pure logic.
//  Reused by MinutelyCardView (Feature 4), PrecipitationNotificationService (Feature 1),
//  and saved-location notifications (Feature 5).
//

import Foundation

struct PrecipitationAnalyzer {

    // MARK: - Public

    /// Returns a short, human-readable summary of upcoming precipitation.
    /// Priority: minutely transitions → hourly transitions → current condition fallback.
    static func oneLiner(minutely: [MinutelyEntry],
                         hourly: [HourlyEntry],
                         current: CurrentConditions) -> String {

        // 1. Try minutely data first (most precise)
        if !minutely.isEmpty, let result = analyzeMinutely(minutely, current: current) {
            return result
        }

        // 2. Fall back to hourly data
        if !hourly.isEmpty, let result = analyzeHourly(hourly, current: current) {
            return result
        }

        // 3. Ultimate fallback: current condition + temperature
        return conditionFallback(current)
    }

    // MARK: - Minutely analysis

    private static func analyzeMinutely(_ entries: [MinutelyEntry],
                                        current: CurrentConditions) -> String? {
        let now = Date()
        // Filter to future entries only
        let future = entries.filter { $0.time >= now.addingTimeInterval(-60) }
        guard future.count >= 2 else { return nil }

        let isCurrentlyRaining = isPrecipitating(current.condition)
        let threshold: Double = 0.1  // mm/hr — anything above this counts as precipitation

        if isCurrentlyRaining {
            // Look for when it stops
            if let stopIndex = future.firstIndex(where: { ($0.precipIntensity ?? 0) < threshold }) {
                let minutesUntilStop = minutesBetween(now, and: future[stopIndex].time)
                if minutesUntilStop <= 5 {
                    return "\(precipNoun(current.condition)) ending soon"
                }
                return "\(precipNoun(current.condition)) ending in \(minutesUntilStop) min"
            }
            // No stop found — rain for the duration
            let totalMinutes = minutesBetween(now, and: future.last!.time)
            if totalMinutes <= 65 {
                return "\(precipNoun(current.condition)) for the next hour"
            }
            return "\(precipNoun(current.condition)) for the next \(totalMinutes) min"
        } else {
            // Look for when it starts
            if let startIndex = future.firstIndex(where: { ($0.precipIntensity ?? 0) >= threshold }) {
                let minutesUntilStart = minutesBetween(now, and: future[startIndex].time)
                // Determine what kind of precip based on intensity
                let intensity = future[startIndex].precipIntensity ?? 0
                let noun = intensityNoun(intensity, condition: current.condition)
                if minutesUntilStart <= 5 {
                    return "\(noun) starting soon"
                }
                return "\(noun) starting in \(minutesUntilStart) min"
            }
            // No precipitation in minutely range
            let totalMinutes = minutesBetween(now, and: future.last!.time)
            if totalMinutes >= 55 {
                return "No precipitation in the next hour"
            }
            return "No precipitation in the next \(totalMinutes) min"
        }
    }

    // MARK: - Hourly analysis

    private static func analyzeHourly(_ entries: [HourlyEntry],
                                      current: CurrentConditions) -> String? {
        let now = Date()
        // Only look at entries from now through the next 12 hours
        let upcoming = entries.filter {
            $0.time >= now.addingTimeInterval(-1800) &&
            $0.time <= now.addingTimeInterval(12 * 3600)
        }
        guard upcoming.count >= 2 else { return nil }

        let isCurrentlyRaining = isPrecipitating(current.condition)
        let precipThreshold: Double = 30  // % chance — above this we consider it "likely"

        if isCurrentlyRaining {
            // Look for when it stops
            if let stopEntry = upcoming.first(where: { (($0.precipChance ?? 0) < precipThreshold) && !isPrecipitating($0.condition) }) {
                let label = hourLabel(for: stopEntry.time)
                return "\(precipNoun(current.condition)) ending around \(label)"
            }
            return "\(precipNoun(current.condition)) for the rest of the day"
        } else {
            // Look for when precipitation starts
            if let startEntry = upcoming.first(where: { ($0.precipChance ?? 0) >= precipThreshold && isPrecipitating($0.condition) }) {
                let label = hourLabel(for: startEntry.time)
                let noun = precipNoun(startEntry.condition)
                return "\(noun) starting around \(label)"
            }
            // Dry for foreseeable future
            return "Clear for the rest of the day"
        }
    }

    // MARK: - Helpers

    private static func conditionFallback(_ current: CurrentConditions) -> String {
        let condition = current.condition.description
        if let temp = current.temperature {
            let isMetric = UserDefaults.standard.string(forKey: "Units") == "metric"
            let unit = isMetric ? "°C" : "°F"
            return "\(condition), \(Int(temp.rounded()))\(unit)"
        }
        return condition
    }

    private static func isPrecipitating(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .drizzle, .rain, .heavyRain,
             .lightSnow, .snow, .heavySnow,
             .sleet, .thunderstorm:
            return true
        default:
            return false
        }
    }

    private static func precipNoun(_ condition: WeatherCondition) -> String {
        switch condition {
        case .drizzle:                       return "Drizzle"
        case .rain:                          return "Rain"
        case .heavyRain:                     return "Heavy rain"
        case .lightSnow:                     return "Light snow"
        case .snow:                          return "Snow"
        case .heavySnow:                     return "Heavy snow"
        case .sleet:                         return "Sleet"
        case .thunderstorm:                  return "Thunderstorms"
        default:                             return "Rain"
        }
    }

    private static func intensityNoun(_ mmPerHour: Double, condition: WeatherCondition) -> String {
        // If the current condition gives us a hint about snow/sleet, use that
        switch condition {
        case .lightSnow, .snow, .heavySnow: return "Snow"
        case .sleet:                        return "Sleet"
        default: break
        }
        // Otherwise classify by intensity
        if mmPerHour < 0.5 { return "Light rain" }
        if mmPerHour < 2.0 { return "Rain" }
        return "Heavy rain"
    }

    private static func minutesBetween(_ from: Date, and to: Date) -> Int {
        max(1, Int((to.timeIntervalSince(from) / 60).rounded()))
    }

    private static func hourLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"   // "3 PM", "10 AM"
        return formatter.string(from: date)
    }
}

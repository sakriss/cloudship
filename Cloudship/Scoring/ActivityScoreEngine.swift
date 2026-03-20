//
//  ActivityScoreEngine.swift
//  Cloudship
//
//  Computes outdoor activity suitability scores (0-100) from live weather data.
//  Pure logic — no UI dependency.
//

import Foundation

// MARK: - Models

enum Activity: String, CaseIterable {
    case running
    case cycling
    case dogWalking
    case outdoorDining

    var emoji: String {
        switch self {
        case .running:       return "\u{1F3C3}"  // 🏃
        case .cycling:       return "\u{1F6B4}"  // 🚴
        case .dogWalking:    return "\u{1F415}"  // 🐕
        case .outdoorDining: return "\u{1F356}"  // 🍖
        }
    }

    var displayName: String {
        switch self {
        case .running:       return "Running"
        case .cycling:       return "Cycling"
        case .dogWalking:    return "Dog Walking"
        case .outdoorDining: return "BBQ / Dining"
        }
    }
}

struct ActivityScore {
    let activity: Activity
    let score: Int            // 0-100
    let rating: Rating
    let limitingFactor: String?

    enum Rating: String {
        case great, good, fair, poor, bad

        var displayName: String { rawValue.capitalized }
    }
}

// MARK: - Engine

final class ActivityScoreEngine {

    /// Compute scores for all activities from the current weather data.
    static func scores(from data: UnifiedWeatherData) -> [ActivityScore] {
        let isMetric = TemperatureFormatter.isMetric
        return Activity.allCases.map { score(for: $0, data: data, isMetric: isMetric) }
    }

    // MARK: - Per-activity scoring

    private static func score(for activity: Activity, data: UnifiedWeatherData, isMetric: Bool) -> ActivityScore {
        switch activity {
        case .running:       return runningScore(data: data, isMetric: isMetric)
        case .cycling:       return cyclingScore(data: data, isMetric: isMetric)
        case .dogWalking:    return dogWalkingScore(data: data, isMetric: isMetric)
        case .outdoorDining: return outdoorDiningScore(data: data, isMetric: isMetric)
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Running: temp (ideal 45-65°F), humidity, wind, AQI, precip
    // ──────────────────────────────────────────────────────────────────────

    private static func runningScore(data: UnifiedWeatherData, isMetric: Bool) -> ActivityScore {
        let c = data.current
        var factors: [(String, Double)] = []  // (factor name, sub-score 0-100)

        // Temperature (ideal 45-65°F / 7-18°C)
        let idealLo = isMetric ? 7.0 : 45.0
        let idealHi = isMetric ? 18.0 : 65.0
        let hardLo  = isMetric ? -7.0 : 20.0
        let hardHi  = isMetric ? 35.0 : 95.0
        let tempScore = rangeScore(value: c.temperature, idealLo: idealLo, idealHi: idealHi, hardLo: hardLo, hardHi: hardHi)
        factors.append(("Temperature", tempScore))

        // Humidity (ideal <60%, bad >95%)
        let humScore = invertedScore(value: c.humidity, goodBelow: 60, badAbove: 95)
        factors.append(("High humidity", humScore))

        // Wind (ideal <10mph/16kmh, bad >30mph/48kmh)
        let windGood = isMetric ? 16.0 : 10.0
        let windBad  = isMetric ? 48.0 : 30.0
        let windScore = invertedScore(value: c.windSpeed, goodBelow: windGood, badAbove: windBad)
        factors.append(("Too windy", windScore))

        // AQI (ideal <50, bad >200)
        let aqiScore = invertedScore(value: Double(data.airQuality?.index ?? 0), goodBelow: 50, badAbove: 200)
        factors.append(("Poor air quality", aqiScore))

        // Precipitation
        let precipScore = precipitationScore(condition: c.condition, hourly: data.hourly, hoursAhead: 2)
        factors.append(("Rain expected", precipScore))

        let weights: [Double] = [0.30, 0.20, 0.20, 0.15, 0.15]
        return buildScore(activity: .running, factors: factors, weights: weights)
    }

    // ──────────────────────────────────────────────────────────────────────
    // Cycling: wind (most important), visibility, rain, temp, AQI
    // ──────────────────────────────────────────────────────────────────────

    private static func cyclingScore(data: UnifiedWeatherData, isMetric: Bool) -> ActivityScore {
        let c = data.current
        var factors: [(String, Double)] = []

        // Wind (ideal <12mph/19kmh, bad >25mph/40kmh)
        let windGood = isMetric ? 19.0 : 12.0
        let windBad  = isMetric ? 40.0 : 25.0
        let windScore = invertedScore(value: c.windSpeed, goodBelow: windGood, badAbove: windBad)
        factors.append(("Too windy", windScore))

        // Temperature (ideal 50-75°F / 10-24°C)
        let idealLo = isMetric ? 10.0 : 50.0
        let idealHi = isMetric ? 24.0 : 75.0
        let hardLo  = isMetric ? -1.0 : 30.0
        let hardHi  = isMetric ? 37.0 : 98.0
        let tempScore = rangeScore(value: c.temperature, idealLo: idealLo, idealHi: idealHi, hardLo: hardLo, hardHi: hardHi)
        factors.append(("Temperature", tempScore))

        // Rain — hard penalty for active rain
        let precipScore = precipitationScore(condition: c.condition, hourly: data.hourly, hoursAhead: 2)
        factors.append(("Rain", precipScore))

        // Visibility (ideal >5mi/8km, bad <0.5mi/0.8km)
        let visGood = isMetric ? 8.0 : 5.0
        let visBad  = isMetric ? 0.8 : 0.5
        let visVal  = c.visibility ?? 10.0  // assume good if unknown
        let visScore = min(100.0, max(0.0, (visVal - visBad) / (visGood - visBad) * 100))
        factors.append(("Low visibility", visScore))

        // AQI
        let aqiScore = invertedScore(value: Double(data.airQuality?.index ?? 0), goodBelow: 50, badAbove: 200)
        factors.append(("Poor air quality", aqiScore))

        let weights: [Double] = [0.30, 0.20, 0.20, 0.15, 0.15]
        return buildScore(activity: .cycling, factors: factors, weights: weights)
    }

    // ──────────────────────────────────────────────────────────────────────
    // Dog Walking: pavement heat cap, cold cap, AQI, rain, wind
    // ──────────────────────────────────────────────────────────────────────

    private static func dogWalkingScore(data: UnifiedWeatherData, isMetric: Bool) -> ActivityScore {
        let c = data.current
        let temp = c.temperature ?? (isMetric ? 20.0 : 68.0)

        // Hard caps for dog safety
        let pavementThreshold = isMetric ? 32.0 : 90.0
        let coldThreshold     = isMetric ? -7.0 : 20.0

        if temp > pavementThreshold {
            return ActivityScore(activity: .dogWalking, score: 15,
                                 rating: .bad, limitingFactor: "Hot pavement danger")
        }
        if temp < coldThreshold {
            return ActivityScore(activity: .dogWalking, score: 20,
                                 rating: .poor, limitingFactor: "Dangerously cold")
        }

        var factors: [(String, Double)] = []

        // Temperature (ideal 50-80°F / 10-27°C)
        let idealLo = isMetric ? 10.0 : 50.0
        let idealHi = isMetric ? 27.0 : 80.0
        let hardLo  = isMetric ? -4.0 : 25.0
        let hardHi  = isMetric ? 32.0 : 90.0
        let tempScore = rangeScore(value: c.temperature, idealLo: idealLo, idealHi: idealHi, hardLo: hardLo, hardHi: hardHi)
        factors.append(("Temperature", tempScore))

        // AQI (dogs are sensitive too)
        let aqiScore = invertedScore(value: Double(data.airQuality?.index ?? 0), goodBelow: 50, badAbove: 150)
        factors.append(("Poor air quality", aqiScore))

        // Precipitation
        let precipScore = precipitationScore(condition: c.condition, hourly: data.hourly, hoursAhead: 1)
        factors.append(("Rain", precipScore))

        // Wind (dogs are less bothered, but still a factor)
        let windGood = isMetric ? 24.0 : 15.0
        let windBad  = isMetric ? 56.0 : 35.0
        let windScore = invertedScore(value: c.windSpeed, goodBelow: windGood, badAbove: windBad)
        factors.append(("Too windy", windScore))

        let weights: [Double] = [0.30, 0.25, 0.25, 0.20]
        return buildScore(activity: .dogWalking, factors: factors, weights: weights)
    }

    // ──────────────────────────────────────────────────────────────────────
    // BBQ / Outdoor Dining: no rain next 3hrs, comfortable temp, low wind, UV
    // ──────────────────────────────────────────────────────────────────────

    private static func outdoorDiningScore(data: UnifiedWeatherData, isMetric: Bool) -> ActivityScore {
        let c = data.current
        var factors: [(String, Double)] = []

        // Rain in next 3 hours
        let precipScore = precipitationScore(condition: c.condition, hourly: data.hourly, hoursAhead: 3)
        factors.append(("Rain expected", precipScore))

        // Temperature (ideal 60-85°F / 16-29°C)
        let idealLo = isMetric ? 16.0 : 60.0
        let idealHi = isMetric ? 29.0 : 85.0
        let hardLo  = isMetric ? 4.0 : 40.0
        let hardHi  = isMetric ? 38.0 : 100.0
        let tempScore = rangeScore(value: c.temperature, idealLo: idealLo, idealHi: idealHi, hardLo: hardLo, hardHi: hardHi)
        factors.append(("Temperature", tempScore))

        // Wind (important for BBQ — napkins, flames)
        let windGood = isMetric ? 19.0 : 12.0
        let windBad  = isMetric ? 40.0 : 25.0
        let windScore = invertedScore(value: c.windSpeed, goodBelow: windGood, badAbove: windBad)
        factors.append(("Too windy", windScore))

        // UV (comfort, not safety — high UV isn't fun for outdoor dining)
        let uvScore = invertedScore(value: c.uvIndex, goodBelow: 5, badAbove: 11)
        factors.append(("High UV", uvScore))

        let weights: [Double] = [0.30, 0.25, 0.25, 0.20]
        return buildScore(activity: .outdoorDining, factors: factors, weights: weights)
    }

    // MARK: - Scoring helpers

    /// Score for a value within an ideal range, with linear falloff to hardLo/hardHi.
    private static func rangeScore(value: Double?, idealLo: Double, idealHi: Double,
                                    hardLo: Double, hardHi: Double) -> Double {
        guard let v = value else { return 50 }  // unknown = neutral
        if v >= idealLo && v <= idealHi { return 100 }
        if v < idealLo {
            return max(0, (v - hardLo) / (idealLo - hardLo) * 100)
        }
        return max(0, (hardHi - v) / (hardHi - idealHi) * 100)
    }

    /// Score that decreases as value increases (e.g. humidity, wind, AQI).
    private static func invertedScore(value: Double?, goodBelow: Double, badAbove: Double) -> Double {
        guard let v = value else { return 80 }  // unknown = assume decent
        if v <= goodBelow { return 100 }
        if v >= badAbove  { return 0 }
        return (badAbove - v) / (badAbove - goodBelow) * 100
    }

    /// Check current condition + upcoming hourly precip chance.
    private static func precipitationScore(condition: WeatherCondition, hourly: [HourlyEntry], hoursAhead: Int) -> Double {
        // Active precipitation is a big penalty
        let activePrecip: Set<WeatherCondition> = [.rain, .heavyRain, .drizzle, .snow, .heavySnow, .lightSnow, .sleet, .thunderstorm]
        if activePrecip.contains(condition) {
            return condition == .drizzle ? 20 : 0
        }

        // Check upcoming precip chance
        let upcoming = hourly.prefix(hoursAhead)
        let maxChance = upcoming.compactMap(\.precipChance).max() ?? 0
        if maxChance > 0.7 { return 15 }   // very likely rain soon
        if maxChance > 0.5 { return 40 }   // decent chance
        if maxChance > 0.3 { return 65 }   // possible but not likely
        return 100                          // clear skies ahead
    }

    /// Build final score from weighted factors and identify the limiting one.
    private static func buildScore(activity: Activity, factors: [(String, Double)], weights: [Double]) -> ActivityScore {
        var weighted = 0.0
        for (i, factor) in factors.enumerated() {
            weighted += factor.1 * weights[i]
        }
        let finalScore = Int(weighted.rounded())

        // Find the worst factor as the limiting one
        let worst = factors.min(by: { $0.1 < $1.1 })
        let limitingFactor: String? = {
            guard let w = worst, w.1 < 60 else { return nil }  // only show if it's actually limiting
            return w.0
        }()

        let rating: ActivityScore.Rating
        switch finalScore {
        case 80...100: rating = .great
        case 60..<80:  rating = .good
        case 40..<60:  rating = .fair
        case 20..<40:  rating = .poor
        default:       rating = .bad
        }

        return ActivityScore(activity: activity, score: finalScore, rating: rating, limitingFactor: limitingFactor)
    }
}

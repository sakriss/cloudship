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

private struct PrecipitationImpact {
    let score: Double
    let cap: Int?
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
        let precip = precipitationImpact(activity: .running, condition: c.condition, hourly: data.hourly, hoursAhead: 2)
        factors.append(("Rain expected", precip.score))

        let weights: [Double] = [0.30, 0.20, 0.20, 0.15, 0.15]
        return buildScore(activity: .running, factors: factors, weights: weights, scoreCap: precip.cap)
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
        let precip = precipitationImpact(activity: .cycling, condition: c.condition, hourly: data.hourly, hoursAhead: 2)
        factors.append(("Rain", precip.score))

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
        return buildScore(activity: .cycling, factors: factors, weights: weights, scoreCap: precip.cap)
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
        let precip = precipitationImpact(activity: .dogWalking, condition: c.condition, hourly: data.hourly, hoursAhead: 1)
        factors.append(("Rain", precip.score))

        // Wind (dogs are less bothered, but still a factor)
        let windGood = isMetric ? 24.0 : 15.0
        let windBad  = isMetric ? 56.0 : 35.0
        let windScore = invertedScore(value: c.windSpeed, goodBelow: windGood, badAbove: windBad)
        factors.append(("Too windy", windScore))

        let weights: [Double] = [0.30, 0.25, 0.25, 0.20]
        return buildScore(activity: .dogWalking, factors: factors, weights: weights, scoreCap: precip.cap)
    }

    // ──────────────────────────────────────────────────────────────────────
    // BBQ / Outdoor Dining: no rain next 3hrs, comfortable temp, low wind, UV
    // ──────────────────────────────────────────────────────────────────────

    private static func outdoorDiningScore(data: UnifiedWeatherData, isMetric: Bool) -> ActivityScore {
        let c = data.current
        var factors: [(String, Double)] = []

        // Rain in next 3 hours
        let precip = precipitationImpact(activity: .outdoorDining, condition: c.condition, hourly: data.hourly, hoursAhead: 3)
        factors.append(("Rain expected", precip.score))

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
        return buildScore(activity: .outdoorDining, factors: factors, weights: weights, scoreCap: precip.cap)
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

    /// Check current condition + upcoming hourly precip chance, including a cap
    /// for active or sustained precipitation so wet days do not look "great".
    private static func precipitationImpact(
        activity: Activity,
        condition: WeatherCondition,
        hourly: [HourlyEntry],
        hoursAhead: Int
    ) -> PrecipitationImpact {
        if activePrecip.contains(condition) {
            return PrecipitationImpact(
                score: condition == .drizzle ? 20 : 0,
                cap: activePrecipitationCap(for: activity, condition: condition)
            )
        }

        let upcoming = hourly.prefix(hoursAhead)
        let maxChance = upcoming.compactMap { normalizedPrecipChance($0.precipChance) }.max() ?? 0
        let sustainedCap = sustainedPrecipitationCap(for: activity, hourly: hourly)

        if maxChance > 70 {
            return PrecipitationImpact(score: 15, cap: minCap(sustainedCap, likelyRainCap(for: activity)))
        }
        if maxChance > 50 {
            return PrecipitationImpact(score: 40, cap: sustainedCap)
        }
        if maxChance > 30 {
            return PrecipitationImpact(score: 65, cap: sustainedCap)
        }
        return PrecipitationImpact(score: 100, cap: sustainedCap)
    }

    /// Build final score from weighted factors and identify the limiting one.
    private static func buildScore(
        activity: Activity,
        factors: [(String, Double)],
        weights: [Double],
        scoreCap: Int? = nil
    ) -> ActivityScore {
        var weighted = 0.0
        for (i, factor) in factors.enumerated() {
            weighted += factor.1 * weights[i]
        }
        let uncappedScore = Int(weighted.rounded())
        let finalScore = min(uncappedScore, scoreCap ?? 100)

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

    private static let activePrecip: Set<WeatherCondition> = [
        .rain, .heavyRain, .drizzle, .snow, .heavySnow, .lightSnow, .sleet, .thunderstorm
    ]

    private static func normalizedPrecipChance(_ chance: Double?) -> Double? {
        guard let chance else { return nil }
        return chance <= 1 ? chance * 100 : chance
    }

    private static func activePrecipitationCap(for activity: Activity, condition: WeatherCondition) -> Int {
        switch condition {
        case .heavyRain, .heavySnow, .thunderstorm:
            switch activity {
            case .running:       return 35
            case .cycling:       return 25
            case .dogWalking:    return 35
            case .outdoorDining: return 25
            }
        case .drizzle:
            switch activity {
            case .running:       return 70
            case .cycling:       return 55
            case .dogWalking:    return 65
            case .outdoorDining: return 55
            }
        default:
            switch activity {
            case .running:       return 65
            case .cycling:       return 55
            case .dogWalking:    return 60
            case .outdoorDining: return 45
            }
        }
    }

    private static func likelyRainCap(for activity: Activity) -> Int {
        switch activity {
        case .running:       return 70
        case .cycling:       return 60
        case .dogWalking:    return 65
        case .outdoorDining: return 55
        }
    }

    private static func sustainedPrecipitationCap(for activity: Activity, hourly: [HourlyEntry]) -> Int? {
        let dayWindow = Array(hourly.prefix(12))
        guard dayWindow.count >= 6 else { return nil }

        let wetHours = dayWindow.filter { entry in
            activePrecip.contains(entry.condition)
                || (normalizedPrecipChance(entry.precipChance) ?? 0) >= 60
                || (entry.precipAmount ?? 0) > 0
        }.count

        guard wetHours >= 6 else { return nil }
        switch activity {
        case .running:       return 60
        case .cycling:       return 50
        case .dogWalking:    return 55
        case .outdoorDining: return 40
        }
    }

    private static func minCap(_ lhs: Int?, _ rhs: Int?) -> Int? {
        switch (lhs, rhs) {
        case let (l?, r?): return min(l, r)
        case let (l?, nil): return l
        case let (nil, r?): return r
        case (nil, nil): return nil
        }
    }
}

//
//  PrecipitationLiveActivityManager.swift
//  Cloudship
//
//  Premium-gated Live Activity manager for precipitation tracking.
//  Call startOrUpdate(weather:) whenever fresh weather data arrives
//  (if the user has premium and has enabled the toggle).
//  Call end() when the feature is disabled or the app goes to background.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
@MainActor
final class PrecipitationLiveActivityManager {

    static let shared = PrecipitationLiveActivityManager()
    private init() {}

    // MARK: - UserDefaults key

    static let enabledKey = "PrecipitationLiveActivityEnabled"

    // MARK: - State

    private var currentActivity: ActivityKit.Activity<PrecipitationActivityAttributes>?

    // MARK: - Public API

    /// Start or update the Live Activity with fresh weather data.
    /// No-op when user is not premium or hasn't enabled the feature.
    func startOrUpdate(weather: UnifiedWeatherData) {
        guard SubscriptionManager.shared.isPremiumCached else { return }
        guard UserDefaults.standard.bool(forKey: Self.enabledKey) else { return }

        let state = makeContentState(from: weather)
        let locationName = weather.locationName ?? "Current Location"

        if let activity = currentActivity, activity.activityState == .active {
            Task {
                await activity.update(
                    ActivityContent(state: state, staleDate: .now.addingTimeInterval(1800))
                )
            }
        } else {
            startNew(state: state, locationName: locationName)
        }
    }

    /// End the activity immediately (e.g. feature toggled off).
    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// End the activity gracefully — keeps it on Lock Screen for up to 5 minutes.
    func endGracefully() {
        guard let activity = currentActivity else { return }
        Task {
            let final = ActivityContent(state: activity.content.state, staleDate: .now)
            await activity.end(final, dismissalPolicy: .after(.now.addingTimeInterval(300)))
            currentActivity = nil
        }
    }

    // MARK: - Private

    private func startNew(state: PrecipitationActivityAttributes.ContentState, locationName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("PrecipitationLiveActivityManager: Live Activities disabled on device")
            return
        }

        let attributes = PrecipitationActivityAttributes(locationName: locationName)
        let content = ActivityContent(state: state, staleDate: .now.addingTimeInterval(1800))

        do {
            let activity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            print("PrecipitationLiveActivityManager: started \(activity.id)")
        } catch {
            print("PrecipitationLiveActivityManager: start failed — \(error.localizedDescription)")
        }
    }

    private func makeContentState(
        from weather: UnifiedWeatherData
    ) -> PrecipitationActivityAttributes.ContentState {
        let tempStr = TemperatureFormatter.format(weather.current.temperature, showUnit: true)

        let summary = PrecipitationAnalyzer.oneLiner(
            minutely: weather.minutely,
            hourly:   weather.hourly,
            current:  weather.current
        )

        let isPrecip = Self.isPrecipitating(weather.current.condition)
        let precipType = Self.precipTypeString(weather.current.condition)
        let intensity = weather.current.precipIntensity ?? 0
        let chance = weather.hourly.first.flatMap { $0.precipChance }.map { Int($0) } ?? 0
        let todayDaily = weather.daily.first { Calendar.current.isDateInToday($0.time) }
            ?? weather.daily.first
        let isNight = WeatherCodeMapper.isNight(
            at: Date(),
            sunrise: todayDaily?.sunrise,
            sunset: todayDaily?.sunset
        )
        let symbol = Self.sfSymbol(for: weather.current.condition, isNight: isNight)
        let transition = Self.transitionMinutes(minutely: weather.minutely, isPrecipitating: isPrecip)

        return PrecipitationActivityAttributes.ContentState(
            summary: summary,
            precipIntensity: intensity,
            precipType: precipType,
            precipChance: chance,
            temperatureString: tempStr,
            conditionSymbol: symbol,
            transitionMinutes: transition,
            isPrecipitating: isPrecip
        )
    }

    // MARK: - Static helpers

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

    private static func precipTypeString(_ condition: WeatherCondition) -> String {
        switch condition {
        case .lightSnow, .snow, .heavySnow: return "snow"
        case .sleet:                        return "sleet"
        case .drizzle, .rain, .heavyRain,
             .thunderstorm:                 return "rain"
        default:                            return ""
        }
    }

    private static func sfSymbol(for condition: WeatherCondition, isNight: Bool) -> String {
        switch condition {
        case .clear:        return isNight ? "moon.stars.fill" : "sun.max.fill"
        case .mostlyClear:  return isNight ? "moon.fill" : "sun.min.fill"
        case .partlyCloudy: return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case .mostlyCloudy: return "cloud.fill"
        case .cloudy:       return "smoke.fill"
        case .fog, .lightFog:   return "cloud.fog.fill"
        case .drizzle:      return "cloud.drizzle.fill"
        case .rain:         return "cloud.rain.fill"
        case .heavyRain:    return "cloud.heavyrain.fill"
        case .lightSnow:    return "cloud.snow.fill"
        case .snow:         return "snowflake"
        case .heavySnow:    return "cloud.snow.fill"
        case .sleet:        return "cloud.sleet.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .windy:        return "wind"
        case .unknown:      return "cloud.fill"
        }
    }

    private static func transitionMinutes(minutely: [MinutelyEntry], isPrecipitating: Bool) -> Int? {
        let now = Date()
        let future = minutely.filter { $0.time >= now.addingTimeInterval(-60) }
        guard future.count >= 2 else { return nil }
        let threshold: Double = 0.1

        if isPrecipitating {
            guard let stop = future.first(where: { ($0.precipIntensity ?? 0) < threshold }) else { return nil }
            return max(1, Int((stop.time.timeIntervalSince(now) / 60).rounded()))
        } else {
            guard let start = future.first(where: { ($0.precipIntensity ?? 0) >= threshold }) else { return nil }
            return max(1, Int((start.time.timeIntervalSince(now) / 60).rounded()))
        }
    }
}

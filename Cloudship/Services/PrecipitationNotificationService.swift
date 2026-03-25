//
//  PrecipitationNotificationService.swift
//  Cloudship
//
//  Analyzes precipitation data and fires local notifications on transitions
//  (dry→wet or wet→dry). Uses PrecipitationAnalyzer for notification body text.
//

import Foundation
import UserNotifications

class PrecipitationNotificationService {

    static let shared = PrecipitationNotificationService()
    private init() {}

    // MARK: - State keys

    private let lastPrecipStateKey = "lastPrecipState"          // "dry" or "wet"
    private let lastNotificationDateKey = "lastPrecipNotificationDate"
    private let cooldownInterval: TimeInterval = 30 * 60        // 30-minute cooldown

    // MARK: - Evaluate and notify

    /// Evaluate current weather data and fire a notification if a precipitation transition occurred.
    /// Called from BackgroundTaskManager during background refresh.
    func evaluateAndNotify(data: UnifiedWeatherData, locationName: String?) {
        guard UserDefaults.standard.bool(forKey: "RainAlertsEnabled") else { return }

        let isCurrentlyPrecipitating = isPrecipitating(data.current.condition)
        let previousState = UserDefaults.standard.string(forKey: lastPrecipStateKey) ?? "dry"
        let currentState = isCurrentlyPrecipitating ? "wet" : "dry"

        // Check for transition
        let transitioned = (previousState != currentState)

        // Also check minutely data for imminent changes
        let imminentChange = checkImminentChange(minutely: data.minutely,
                                                  hourly: data.hourly,
                                                  current: data.current,
                                                  isCurrentlyWet: isCurrentlyPrecipitating)

        guard transitioned || imminentChange else {
            // Update state even if no notification
            UserDefaults.standard.set(currentState, forKey: lastPrecipStateKey)
            return
        }

        // Cooldown check
        if let lastDate = UserDefaults.standard.object(forKey: lastNotificationDateKey) as? Date,
           Date().timeIntervalSince(lastDate) < cooldownInterval {
            return
        }

        // Build notification
        let body = PrecipitationAnalyzer.oneLiner(minutely: data.minutely,
                                                    hourly: data.hourly,
                                                    current: data.current)

        let title: String
        if let name = locationName {
            title = name
        } else {
            title = "Weather Update"
        }

        sendNotification(title: title, body: body)

        // Update state
        UserDefaults.standard.set(currentState, forKey: lastPrecipStateKey)
        UserDefaults.standard.set(Date(), forKey: lastNotificationDateKey)
    }

    /// Per-location evaluation for saved location notifications (Feature 5).
    func evaluateAndNotify(data: UnifiedWeatherData, locationKey: String, locationName: String) {
        let stateKey = "precipState_\(locationKey)"
        let dateKey = "precipNotifDate_\(locationKey)"

        let isCurrentlyPrecipitating = isPrecipitating(data.current.condition)
        let previousState = UserDefaults.standard.string(forKey: stateKey) ?? "dry"
        let currentState = isCurrentlyPrecipitating ? "wet" : "dry"

        let transitioned = (previousState != currentState)
        let imminentChange = checkImminentChange(minutely: data.minutely,
                                                  hourly: data.hourly,
                                                  current: data.current,
                                                  isCurrentlyWet: isCurrentlyPrecipitating)

        guard transitioned || imminentChange else {
            UserDefaults.standard.set(currentState, forKey: stateKey)
            return
        }

        // Cooldown
        if let lastDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
           Date().timeIntervalSince(lastDate) < cooldownInterval {
            return
        }

        let body = PrecipitationAnalyzer.oneLiner(minutely: data.minutely,
                                                    hourly: data.hourly,
                                                    current: data.current)

        sendNotification(title: locationName, body: body)

        UserDefaults.standard.set(currentState, forKey: stateKey)
        UserDefaults.standard.set(Date(), forKey: dateKey)
    }

    // MARK: - Helpers

    private func checkImminentChange(minutely: [MinutelyEntry],
                                      hourly: [HourlyEntry],
                                      current: CurrentConditions,
                                      isCurrentlyWet: Bool) -> Bool {
        // Check if precipitation is starting within 15 minutes (dry→wet imminent)
        if !isCurrentlyWet && !minutely.isEmpty {
            let now = Date()
            let threshold: Double = 0.1
            if let startIndex = minutely.firstIndex(where: { ($0.precipIntensity ?? 0) >= threshold }) {
                let minutesUntil = minutely[startIndex].time.timeIntervalSince(now) / 60
                if minutesUntil > 0 && minutesUntil <= 15 {
                    return true
                }
            }
        }
        return false
    }

    private func isPrecipitating(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .drizzle, .rain, .heavyRain,
             .lightSnow, .snow, .heavySnow,
             .sleet, .thunderstorm:
            return true
        default:
            return false
        }
    }

    // MARK: - Morning / Evening Briefings

    /// Schedule (or update) the morning weather briefing notification.
    /// Reads the configured hour from UserDefaults and uses the latest cached weather data.
    func scheduleMorningBrief() {
        guard SubscriptionManager.shared.isPremiumCached else { return }
        guard UserDefaults.standard.bool(forKey: "MorningBriefEnabled") else {
            cancelBrief(identifier: "morningBrief")
            return
        }

        guard let data = WeatherDataSourceManager.shared.lastData,
              let today = data.daily.first else { return }

        let hour = UserDefaults.standard.object(forKey: "MorningBriefHour") as? Int ?? 7

        let high = TemperatureFormatter.format(today.tempMax)
        let low = TemperatureFormatter.format(today.tempMin)
        let condition = today.condition.description
        let precipChance = Int(today.precipChance ?? 0)
        let body = "Today: \(high)/\(low), \(condition), \(precipChance)% chance of rain"

        let locationName = data.locationName ?? WeatherDataSourceManager.shared.locationName ?? "Weather"

        scheduleBrief(identifier: "morningBrief",
                      title: locationName,
                      body: body,
                      hour: hour)
    }

    /// Schedule (or update) the evening weather briefing notification.
    func scheduleEveningBrief() {
        guard SubscriptionManager.shared.isPremiumCached else { return }
        guard UserDefaults.standard.bool(forKey: "EveningBriefEnabled") else {
            cancelBrief(identifier: "eveningBrief")
            return
        }

        guard let data = WeatherDataSourceManager.shared.lastData,
              let today = data.daily.first else { return }

        let hour = UserDefaults.standard.object(forKey: "EveningBriefHour") as? Int ?? 20

        let tonightLow = TemperatureFormatter.format(today.tempMin)
        let tomorrowEntry = data.daily.count > 1 ? data.daily[1] : today
        let tomorrowCondition = tomorrowEntry.condition.description
        let tomorrowHigh = TemperatureFormatter.format(tomorrowEntry.tempMax)
        let tomorrowLow = TemperatureFormatter.format(tomorrowEntry.tempMin)
        let body = "Tonight: Low \(tonightLow), \(tomorrowCondition). Tomorrow: \(tomorrowHigh)/\(tomorrowLow)"

        let locationName = data.locationName ?? WeatherDataSourceManager.shared.locationName ?? "Weather"

        scheduleBrief(identifier: "eveningBrief",
                      title: locationName,
                      body: body,
                      hour: hour)
    }

    /// Cancel a scheduled briefing by identifier.
    func cancelBrief(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private func scheduleBrief(identifier: String, title: String, body: String, hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Briefing notification error (\(identifier)): \(error)")
            }
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                             content: content,
                                             trigger: nil) // deliver immediately
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

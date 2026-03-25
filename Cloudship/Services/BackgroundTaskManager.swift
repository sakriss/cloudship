//
//  BackgroundTaskManager.swift
//  Cloudship
//
//  Singleton that registers and handles BGAppRefreshTask for precipitation checks.
//  Task handler: get GPS location → fetch minutely/hourly data → pass to
//  PrecipitationNotificationService → schedule next refresh (~15 min).
//

import Foundation
import BackgroundTasks
import CoreLocation

class BackgroundTaskManager: NSObject {

    static let shared = BackgroundTaskManager()
    private override init() { super.init() }

    static let precipCheckID = "com.cloudship.precipCheck"

    // Simple location fetch helper
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private lazy var locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyKilometer
        return lm
    }()

    // MARK: - Registration

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.precipCheckID,
            using: nil
        ) { [weak self] task in
            self?.handlePrecipCheck(task: task as! BGAppRefreshTask)
        }

        // Schedule daily briefing notifications if enabled
        scheduleBriefings()
    }

    /// Schedule morning and evening briefing notifications (premium feature).
    func scheduleBriefings() {
        PrecipitationNotificationService.shared.scheduleMorningBrief()
        PrecipitationNotificationService.shared.scheduleEveningBrief()
    }

    // MARK: - Scheduling

    func scheduleNextRefresh() {
        guard UserDefaults.standard.bool(forKey: "RainAlertsEnabled") else { return }

        let request = BGAppRefreshTaskRequest(identifier: Self.precipCheckID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // ~15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            print("BackgroundTask: scheduled next precip check")
        } catch {
            print("BackgroundTask: failed to schedule — \(error)")
        }
    }

    // MARK: - Task handler

    private func handlePrecipCheck(task: BGAppRefreshTask) {
        // Schedule the next refresh before doing work
        scheduleNextRefresh()

        let workTask = Task {
            do {
                // Get current location
                let location = try await getCurrentLocation()
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                let units = TemperatureFormatter.apiUnits

                // Use Open-Meteo (free, no API key) for background checks
                let source = OpenMeteoDataSource()
                let data = try await source.fetchWeather(lat: lat, lon: lon, units: units)

                // Evaluate primary location
                let locationName = WeatherDataSourceManager.shared.locationName ?? "Current Location"
                PrecipitationNotificationService.shared.evaluateAndNotify(
                    data: data,
                    locationName: locationName
                )

                // Evaluate saved locations with rain alerts
                await self.checkSavedLocations(source: source)

                // Refresh daily briefing notifications with latest data
                self.scheduleBriefings()

                task.setTaskCompleted(success: true)
            } catch {
                print("BackgroundTask: precip check failed — \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        // Handle task expiration
        task.expirationHandler = {
            workTask.cancel()
        }
    }

    // MARK: - Saved locations

    private func checkSavedLocations(source: OpenMeteoDataSource) async {
        guard SubscriptionManager.shared.isPremiumCached else { return }
        let savedLocations = SavedLocationStore.shared.allWithRainAlerts()
        guard !savedLocations.isEmpty else { return }

        let units = TemperatureFormatter.apiUnits

        await withTaskGroup(of: Void.self) { group in
            for loc in savedLocations {
                group.addTask {
                    do {
                        let data = try await source.fetchWeather(lat: loc.lat, lon: loc.lon, units: units)
                        PrecipitationNotificationService.shared.evaluateAndNotify(
                            data: data,
                            locationKey: loc.locationKey,
                            locationName: loc.name
                        )
                    } catch {
                        print("BackgroundTask: saved location check failed for \(loc.name) — \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Location helper

    private func getCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension BackgroundTaskManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

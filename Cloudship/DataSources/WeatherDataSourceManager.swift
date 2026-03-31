//
//  WeatherDataSourceManager.swift
//  Cloudship
//
//  Singleton that owns the active weather data source and drives UI updates.
//  Replaces the role of the old WeatherController as the UI-facing data layer.
//

import Foundation
import UIKit
import CoreLocation

class WeatherDataSourceManager: NSObject {

    static let shared = WeatherDataSourceManager()

    // MARK: - Notifications

    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
    static let weatherDataParseFailed   = Notification.Name("weatherDataParseFailed")

    // MARK: - Feature flag keys

    static let nearestStationEnabledKey = "NearestStationEnabled"
    static let consensusModeEnabledKey  = "ConsensusModeEnabled"

    // MARK: - State

    /// The most recently fetched unified weather data.
    private(set) var lastData: UnifiedWeatherData?

    /// Reverse-geocoded location name.
    var locationName: String?

    /// Whether we're currently displaying historical data.
    var isShowingHistorical: Bool = false

    /// The historical date being displayed, if any.
    var historicalDate: Date?

    /// Nearest NOAA station result for the last resolved location (displayed in Settings).
    private(set) var nearestStationResult: StationProximityService.Result?

    /// Historical data source (always Open-Meteo Archive API).
    private let historicalSource = OpenMeteoHistoricalDataSource()

    /// The currently active data source.
    var activeSource: WeatherDataSource = TomorrowIODataSource() {
        didSet {
            let id: WeatherSourceID
            if activeSource is NOAADataSource              { id = .noaa }
            else if activeSource is OpenMeteoDataSource    { id = .openMeteo }
            else if activeSource is PirateWeatherDataSource { id = .pirateWeather }
            else if activeSource is AppleWeatherDataSource  { id = .appleWeather }
            else if activeSource is AccuWeatherDataSource   { id = .accuWeather }
            else                                            { id = .tomorrowIO }
            UserDefaults.standard.set(id.rawValue, forKey: "WeatherSource")
            WeatherCacheManager.shared.clear()
        }
    }

    // MARK: - Init

    private override init() {
        super.init()
        restoreSelectedSource()
    }

    private func restoreSelectedSource() {
        let raw = UserDefaults.standard.string(forKey: "WeatherSource") ?? WeatherSourceID.noaa.rawValue
        let sourceID = WeatherSourceID(rawValue: raw)

        // Premium sources require an active subscription
        let premiumSources: Set<WeatherSourceID> = [.tomorrowIO, .accuWeather]
        if let id = sourceID, premiumSources.contains(id),
           !SubscriptionManager.shared.isPremiumCached {
            // Fall back to a free source and flag for migration alert
            activeSource = NOAADataSource()
            if !UserDefaults.standard.bool(forKey: "migrationAlertShown_v1") {
                UserDefaults.standard.set(true, forKey: "migrationAlertShown_v1")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    Self.showMigrationAlert()
                }
            }
            return
        }

        switch sourceID {
        case .noaa:           activeSource = NOAADataSource()
        case .openMeteo:      activeSource = OpenMeteoDataSource()
        case .pirateWeather:  activeSource = PirateWeatherDataSource()
        case .appleWeather:   activeSource = AppleWeatherDataSource()
        case .accuWeather:    activeSource = AccuWeatherDataSource()
        default:              activeSource = TomorrowIODataSource()
        }
    }

    private static func showMigrationAlert() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }

        let alert = UIAlertController(
            title: "Weather Source Changed",
            message: "Your previous weather source now requires Cloudship Premium. You've been switched to NOAA. Upgrade in Settings to restore your preferred source.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topVC.present(alert, animated: true)
    }

    // MARK: - Fetch

    func fetchWeather(lat: Double, lon: Double, forceRefresh: Bool = false, updateWidget: Bool = false) async {
        let units = TemperatureFormatter.apiUnits
        let defaults = UserDefaults.standard

        // -- Nearest Station auto-select (free feature) --
        // If the station hasn't been resolved yet for this location, resolve it
        // inline (awaited). This suspends the task but does NOT block the main
        // thread — the caller's Task yields at the await point. Once resolved,
        // activeSource is set to the correct provider and the fetch continues
        // with that source. No second fetch needed.
        if defaults.bool(forKey: Self.nearestStationEnabledKey) {
            let alreadyResolved = defaults.string(forKey: "NearestStationLastSourceID") != nil
            if !alreadyResolved {
                await autoSelectNearestStation(lat: lat, lon: lon)
            }
        }

        // -- Consensus Mode (premium feature) --
        if defaults.bool(forKey: Self.consensusModeEnabledKey) {
            if SubscriptionManager.shared.isPremiumCached {
                await fetchConsensus(lat: lat, lon: lon, units: units, updateWidget: updateWidget)
                return
            }
            // Not premium — turn off the toggle silently and fall through to normal fetch
            defaults.set(false, forKey: Self.consensusModeEnabledKey)
            await postConsensusPaywallNotice()
        }

        // -- Standard single-source fetch --

        // Return cached data if it is fresh, same location, and same source
        if !forceRefresh,
           let cached = WeatherCacheManager.shared.load(),
           cached.isFresh,
           cached.isValid(lat: lat, lon: lon, source: activeSource.name) {
            var entry = cached.data
            entry.locationName = locationName
            lastData = entry
            await MainActor.run {
                NotificationCenter.default.post(name: Self.weatherDataParseComplete, object: nil)
            }
            print("WeatherCache: serving fresh cache (\(cached.ageDescription))")
            return
        }

        do {
            // Fetch weather data and NOAA alerts in parallel
            async let weatherTask = activeSource.fetchWeather(lat: lat, lon: lon, units: units)
            async let alertsTask  = fetchNOAAAlerts(lat: lat, lon: lon)

            var data   = try await weatherTask
            let alerts = await alertsTask          // non-fatal — empty array on failure

            data.locationName = locationName
            data.alerts = alerts
            lastData = data

            // Persist to disk cache
            WeatherCacheManager.shared.save(WeatherCacheEntry(
                data: data,
                fetchDate: Date(),
                latitude: lat,
                longitude: lon,
                sourceName: activeSource.name
            ))

            // Update widget shared data only for GPS/home location fetches
            if updateWidget {
                WidgetDataWriter.shared.write(data)
                if #available(iOS 16.1, *) {
                    await MainActor.run {
                        PrecipitationLiveActivityManager.shared.startOrUpdate(weather: data)
                    }
                }
            }

            await MainActor.run {
                NotificationCenter.default.post(name: WeatherDataSourceManager.weatherDataParseComplete, object: nil)
            }
        } catch let error as NOAAError where error == .outsideUS {
            // Silently fall back to Open-Meteo for non-US locations when NOAA is selected
            print("NOAAError.outsideUS — falling back to Open-Meteo")
            let fallback = OpenMeteoDataSource()
            do {
                async let weatherTask = fallback.fetchWeather(lat: lat, lon: lon, units: units)
                async let alertsTask  = fetchNOAAAlerts(lat: lat, lon: lon)

                var data   = try await weatherTask
                let alerts = await alertsTask

                data.locationName = locationName
                data.alerts = alerts
                lastData = data

                await MainActor.run {
                    NotificationCenter.default.post(
                        name: WeatherDataSourceManager.weatherDataParseComplete,
                        object: "noaa_fallback"
                    )
                }
            } catch {
                await postFailure(error: error)
            }
        } catch {
            await postFailure(error: error)
        }
    }

    // MARK: - Nearest Station auto-select

    /// Clears all cached station results so the next fetch triggers a fresh resolution.
    func clearNearestStationCache() {
        nearestStationResult = nil
        UserDefaults.standard.removeObject(forKey: "NearestStationLastDistanceKm")
        UserDefaults.standard.removeObject(forKey: "NearestStationLastSourceID")
    }

    /// Queries NOAA station metadata and sets `activeSource` to the best free
    /// source for the given location. Caches the result in `nearestStationResult`.
    func autoSelectNearestStation(lat: Double, lon: Double) async {
        let stationResult = await StationProximityService.shared.nearestNOAAStation(lat: lat, lon: lon)

        // If this task was cancelled (a newer location was selected), discard the result.
        guard !Task.isCancelled else { return }

        nearestStationResult = stationResult

        // Cache distance for Settings display without an extra network call
        if let km = stationResult?.distanceKm {
            UserDefaults.standard.set(km, forKey: "NearestStationLastDistanceKm")
            UserDefaults.standard.set(WeatherSourceID.noaa.rawValue, forKey: "NearestStationLastSourceID")
        }

        if stationResult != nil {
            // US location — NOAA has an active nearby station
            if !(activeSource is NOAADataSource) {
                activeSource = NOAADataSource()
            }
        } else {
            // Non-US or station lookup failed — use Open-Meteo (global gridded model)
            UserDefaults.standard.set(WeatherSourceID.openMeteo.rawValue, forKey: "NearestStationLastSourceID")
            UserDefaults.standard.removeObject(forKey: "NearestStationLastDistanceKm")
            if !(activeSource is OpenMeteoDataSource) {
                activeSource = OpenMeteoDataSource()
            }
        }

        // Notify Settings to refresh its subtitle
        await MainActor.run {
            NotificationCenter.default.post(name: Notification.Name("nearestStationResolved"), object: nil)
        }
    }

    // MARK: - Consensus fetch

    private func fetchConsensus(lat: Double, lon: Double, units: String, updateWidget: Bool) async {
        do {
            let (data, breakdown) = try await ConsensusWeatherService.shared.fetch(
                lat: lat,
                lon: lon,
                units: units,
                isPremium: SubscriptionManager.shared.isPremiumCached
            )

            var merged = data
            merged.locationName = locationName
            // Alerts are fetched separately and overlaid
            let alerts = await fetchNOAAAlerts(lat: lat, lon: lon)
            merged.alerts = alerts
            lastData = merged

            WeatherCacheManager.shared.save(WeatherCacheEntry(
                data: merged,
                fetchDate: Date(),
                latitude: lat,
                longitude: lon,
                sourceName: "consensus(\(breakdown.sourcesUsed))"
            ))

            if updateWidget {
                WidgetDataWriter.shared.write(merged)
            }

            await MainActor.run {
                NotificationCenter.default.post(
                    name: WeatherDataSourceManager.weatherDataParseComplete,
                    object: "consensus"
                )
            }
        } catch {
            await postFailure(error: error)
        }
    }

    @MainActor
    private func postConsensusPaywallNotice() {
        NotificationCenter.default.post(
            name: Notification.Name("showConsensusPaywall"),
            object: nil
        )
    }

    // MARK: - Historical fetch

    func fetchHistoricalWeather(lat: Double, lon: Double, date: Date) async {
        do {
            var data = try await historicalSource.fetchWeather(lat: lat, lon: lon, date: date)
            data.locationName = locationName
            lastData = data
            isShowingHistorical = true
            historicalDate = date

            await MainActor.run {
                NotificationCenter.default.post(name: Self.weatherDataParseComplete, object: "historical")
            }
        } catch {
            await postFailure(error: error)
        }
    }

    /// Exit historical mode and clear state.
    func exitHistoricalMode() {
        isShowingHistorical = false
        historicalDate = nil
    }

    // MARK: - NOAA Alerts (free, US-only, always fetched as a best-effort supplement)

    private func fetchNOAAAlerts(lat: Double, lon: Double) async -> [WeatherAlert] {
        let latStr = String(format: "%.4f", lat)
        let lonStr = String(format: "%.4f", lon)
        guard let url = URL(string: "https://api.weather.gov/alerts/active?point=\(latStr),\(lonStr)&status=actual&message_type=alert,update") else {
            return []
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        req.setValue("Cloudship iOS App (contact@cloudshipapp.com)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            // NOAA returns 404 for non-US points — treat as no alerts
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return [] }

            let collection = try JSONDecoder().decode(NOAAAlertCollection.self, from: data)
            let features   = collection.features ?? []

            return features.compactMap { feature -> WeatherAlert? in
                guard let props = feature.properties,
                      let event = props.event,
                      // Skip exercises / tests
                      props.status == "Actual" else { return nil }

                let severity = AlertSeverity(rawValue: props.severity ?? "") ?? .unknown
                let headline = props.headline ?? event

                return WeatherAlert(
                    event:       event,
                    headline:    headline,
                    description: props.description ?? "",
                    instruction: props.instruction,
                    severity:    severity,
                    onset:       DateFormatHelper.date(from: props.onset),
                    expires:     DateFormatHelper.date(from: props.expires ?? props.ends),
                    areaDesc:    props.areaDesc,
                    source:      "NWS"
                )
            }
            // Show most severe first
            .sorted { $0.severity > $1.severity }

        } catch {
            print("NOAA alerts fetch (non-fatal): \(error)")
            return []
        }
    }

    @MainActor
    private func postFailure(error: Error) {
        print("Weather fetch failed: \(error)")
        NotificationCenter.default.post(
            name: WeatherDataSourceManager.weatherDataParseFailed,
            object: error.localizedDescription
        )
    }
}

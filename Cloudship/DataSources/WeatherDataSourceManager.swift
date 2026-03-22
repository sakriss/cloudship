//
//  WeatherDataSourceManager.swift
//  Cloudship
//
//  Singleton that owns the active weather data source and drives UI updates.
//  Replaces the role of the old WeatherController as the UI-facing data layer.
//

import Foundation
import CoreLocation

class WeatherDataSourceManager: NSObject {

    static let shared = WeatherDataSourceManager()

    // MARK: - Notifications

    static let weatherDataParseComplete = Notification.Name("weatherDataParseComplete")
    static let weatherDataParseFailed   = Notification.Name("weatherDataParseFailed")

    // MARK: - State

    /// The most recently fetched unified weather data.
    private(set) var lastData: UnifiedWeatherData?

    /// Reverse-geocoded location name.
    var locationName: String?

    /// Whether we're currently displaying historical data.
    var isShowingHistorical: Bool = false

    /// The historical date being displayed, if any.
    var historicalDate: Date?

    /// Historical data source (always Open-Meteo Archive API).
    private let historicalSource = OpenMeteoHistoricalDataSource()

    /// The currently active data source.
    var activeSource: WeatherDataSource = TomorrowIODataSource() {
        didSet {
            let id: WeatherSourceID
            if activeSource is NOAADataSource           { id = .noaa }
            else if activeSource is OpenMeteoDataSource { id = .openMeteo }
            else                                        { id = .tomorrowIO }
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
        switch WeatherSourceID(rawValue: raw) {
        case .noaa:      activeSource = NOAADataSource()
        case .openMeteo: activeSource = OpenMeteoDataSource()
        default:         activeSource = TomorrowIODataSource()
        }
    }

    // MARK: - Fetch

    func fetchWeather(lat: Double, lon: Double, forceRefresh: Bool = false, updateWidget: Bool = false) async {
        let units = TemperatureFormatter.apiUnits

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
            if updateWidget { WidgetDataWriter.shared.write(data) }

            await MainActor.run {
                NotificationCenter.default.post(name: WeatherDataSourceManager.weatherDataParseComplete, object: nil)
            }
        } catch let error as NOAAError where error == .outsideUS {
            // Silently fall back to Tomorrow.io for non-US locations when NOAA is selected
            print("NOAAError.outsideUS — falling back to Tomorrow.io")
            let fallback = TomorrowIODataSource()
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

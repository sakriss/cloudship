//
//  MapPrecipitationTotalsService.swift
//  Cloudship
//
//  Fetches rolling past and forecast precipitation totals for an arbitrary
//  map coordinate using Open-Meteo forecast + archive endpoints.
//

import Foundation
import CoreLocation

struct MapPrecipitationTotals {
    let coordinate: CLLocationCoordinate2D
    let direction: MapPrecipitationDirection
    let window: MapPrecipitationWindow
    let totalPrecipitation: Double
    let sampleCount: Int
    let sourceName: String
    let fetchedAt: Date
}

enum MapPrecipitationDirection: String, CaseIterable {
    case past = "Past"
    case forecast = "Forecast"
}

enum MapPrecipitationWindow: Int, CaseIterable {
    case hours24 = 24
    case hours48 = 48
    case hours72 = 72

    var title: String { "\(rawValue)h" }
}

enum MapPrecipitationTotalsError: LocalizedError {
    case invalidResponse
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Precipitation data is unavailable."
        case .unavailable:
            return "Rain total unavailable."
        }
    }
}

final class MapPrecipitationTotalsService {

    typealias DataFetcher = (URL) async throws -> Data

    static let shared = MapPrecipitationTotalsService()

    private struct CacheEntry {
        let value: MapPrecipitationTotals
        let storedAt: Date
    }

    private struct CacheKey: Hashable {
        let lat: Double
        let lon: Double
        let direction: MapPrecipitationDirection
        let window: MapPrecipitationWindow
        let units: String
    }

    private let fetchData: DataFetcher
    private let nowProvider: () -> Date
    private let calendar: Calendar
    private let cacheQueue = DispatchQueue(label: "MapPrecipitationTotalsService.cache")
    private var cache: [CacheKey: CacheEntry] = [:]

    init(
        fetchData: @escaping DataFetcher = { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        },
        nowProvider: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.fetchData = fetchData
        self.nowProvider = nowProvider
        self.calendar = calendar
    }

    func fetchTotals(
        coordinate: CLLocationCoordinate2D,
        direction: MapPrecipitationDirection,
        window: MapPrecipitationWindow,
        units: String
    ) async throws -> MapPrecipitationTotals {
        let key = cacheKey(for: coordinate, direction: direction, window: window, units: units)
        let now = nowProvider()

        if let cached = cachedValue(for: key, now: now) {
            return cached
        }

        let url = try makeURL(
            coordinate: coordinate,
            direction: direction,
            window: window,
            units: units,
            now: now
        )

        let data = try await fetchData(url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenMeteoPrecipitationResponse.self, from: data)
        let total = try buildTotals(
            from: response,
            coordinate: coordinate,
            direction: direction,
            window: window,
            now: now
        )

        store(total, for: key)
        return total
    }

    private func cacheKey(
        for coordinate: CLLocationCoordinate2D,
        direction: MapPrecipitationDirection,
        window: MapPrecipitationWindow,
        units: String
    ) -> CacheKey {
        CacheKey(
            lat: round(coordinate.latitude * 100) / 100,
            lon: round(coordinate.longitude * 100) / 100,
            direction: direction,
            window: window,
            units: units
        )
    }

    private func cachedValue(for key: CacheKey, now: Date) -> MapPrecipitationTotals? {
        cacheQueue.sync {
            guard let entry = cache[key] else { return nil }
            let ttl: TimeInterval = key.direction == .past ? 5 * 60 : 10 * 60
            guard now.timeIntervalSince(entry.storedAt) <= ttl else {
                cache.removeValue(forKey: key)
                return nil
            }
            return entry.value
        }
    }

    private func store(_ value: MapPrecipitationTotals, for key: CacheKey) {
        cacheQueue.async {
            self.cache[key] = CacheEntry(value: value, storedAt: self.nowProvider())
        }
    }

    private func makeURL(
        coordinate: CLLocationCoordinate2D,
        direction: MapPrecipitationDirection,
        window: MapPrecipitationWindow,
        units: String,
        now: Date
    ) throws -> URL {
        let imperial = units == "imperial"
        let precipUnit = imperial ? "inch" : "mm"
        let endpoint: String
        let queryItems: [URLQueryItem]

        switch direction {
        case .forecast:
            endpoint = "https://api.open-meteo.com/v1/forecast"
            let forecastDays = max(ceil(Double(window.rawValue) / 24.0), 3)
            queryItems = [
                .init(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
                .init(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
                .init(name: "hourly", value: "precipitation"),
                .init(name: "timezone", value: "auto"),
                .init(name: "precipitation_unit", value: precipUnit),
                .init(name: "forecast_days", value: String(Int(forecastDays)))
            ]
        case .past:
            endpoint = "https://archive-api.open-meteo.com/v1/archive"
            let start = calendar.startOfDay(for: now.addingTimeInterval(-Double(window.rawValue) * 3600 - 3600))
            let end = calendar.startOfDay(for: now)
            queryItems = [
                .init(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
                .init(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
                .init(name: "hourly", value: "precipitation"),
                .init(name: "timezone", value: "auto"),
                .init(name: "precipitation_unit", value: precipUnit),
                .init(name: "start_date", value: Self.dayFormatter.string(from: start)),
                .init(name: "end_date", value: Self.dayFormatter.string(from: end))
            ]
        }

        var components = URLComponents(string: endpoint)
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw MapPrecipitationTotalsError.invalidResponse
        }
        return url
    }

    private func buildTotals(
        from response: OpenMeteoPrecipitationResponse,
        coordinate: CLLocationCoordinate2D,
        direction: MapPrecipitationDirection,
        window: MapPrecipitationWindow,
        now: Date
    ) throws -> MapPrecipitationTotals {
        guard let hourly = response.hourly,
              let times = hourly.time,
              let values = hourly.precipitation,
              times.count == values.count else {
            throw MapPrecipitationTotalsError.invalidResponse
        }

        let timezone = response.timezone.flatMap(TimeZone.init(identifier:))
        let samples = zip(times, values).compactMap { timeString, amount -> (Date, Double)? in
            guard let amount else { return nil }
            guard let date = Self.parseDate(timeString, timezone: timezone) else { return nil }
            return (date, amount)
        }

        let windowSeconds = Double(window.rawValue) * 3600
        let range: ClosedRange<Date>
        switch direction {
        case .past:
            range = now.addingTimeInterval(-windowSeconds)...now
        case .forecast:
            range = now...now.addingTimeInterval(windowSeconds)
        }

        let matching = samples.filter { range.contains($0.0) }
        guard !matching.isEmpty else {
            throw MapPrecipitationTotalsError.unavailable
        }

        return MapPrecipitationTotals(
            coordinate: coordinate,
            direction: direction,
            window: window,
            totalPrecipitation: matching.reduce(0) { $0 + $1.1 },
            sampleCount: matching.count,
            sourceName: "Open-Meteo",
            fetchedAt: now
        )
    }

    private static func parseDate(_ value: String, timezone: TimeZone?) -> Date? {
        if let date = DateFormatHelper.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = timezone
        return formatter.date(from: value)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct OpenMeteoPrecipitationResponse: Codable {
    let timezone: String?
    let hourly: Hourly?

    struct Hourly: Codable {
        let time: [String]?
        let precipitation: [Double?]?
    }
}

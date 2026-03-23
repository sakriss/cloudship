//
//  WeatherCache.swift
//  Cloudship
//
//  Disk-backed cache for UnifiedWeatherData.
//  Prevents unnecessary network calls when data is fresh (< 10 minutes old),
//  the same location is requested, and the same data source is active.
//

import Foundation

// MARK: - Cache entry

struct WeatherCacheEntry: Codable {
    let data: UnifiedWeatherData
    let fetchDate: Date
    let latitude: Double
    let longitude: Double
    let sourceName: String

    /// Data is "fresh" if less than 10 minutes old.
    static let maxAge: TimeInterval = 600

    var isFresh: Bool {
        Date().timeIntervalSince(fetchDate) < Self.maxAge
    }

    /// Returns true if this cache entry is valid for the given request.
    /// Same source, and within ~1 km of the cached location.
    func isValid(lat: Double, lon: Double, source: String) -> Bool {
        guard source == sourceName else { return false }
        let latDiff = abs(lat - latitude)
        let lonDiff = abs(lon - longitude)
        return latDiff < 0.01 && lonDiff < 0.01   // ~1 km
    }

    /// How long ago the data was fetched, formatted for display (e.g. "3 min ago").
    var ageDescription: String {
        let age = Date().timeIntervalSince(fetchDate)
        if age < 60 { return "just now" }
        let minutes = Int(age / 60)
        return "\(minutes) min ago"
    }
}

// MARK: - Cache manager

final class WeatherCacheManager {

    static let shared = WeatherCacheManager()
    private init() {}

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cloudship_weather_cache.json")
    }

    // MARK: - Read

    func load() -> WeatherCacheEntry? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? decoder.decode(WeatherCacheEntry.self, from: data)
    }

    // MARK: - Write

    func save(_ entry: WeatherCacheEntry) {
        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    // MARK: - Invalidate

    func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}

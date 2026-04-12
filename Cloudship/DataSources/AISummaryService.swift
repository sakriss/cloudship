//
//  AISummaryService.swift
//  Cloudship
//
//  Generates and caches an AI weather brief using OpenRouter.
//  Cache is persisted to disk and lasts 2 hours, or until weather
//  conditions change significantly (condition, temp bucket, precip bucket, day).
//

import Foundation

// MARK: - Disk cache entry

private struct AISummaryCacheEntry: Codable {
    let summary: String
    let generatedAt: Date
    let cacheKey: String
}

// MARK: - Service

final class AISummaryService {

    static let shared = AISummaryService()
    private init() { loadFromDisk() }

    // MARK: - State

    private static let cacheMaxAge: TimeInterval = 2 * 60 * 60   // 2 hours
    private static let fileName = "ai_summary_cache.json"

    private var entry: AISummaryCacheEntry?
    private var inFlightTask: Task<String, Error>?
    private var inFlightCacheKey: String?

    // MARK: - Public API

    /// Returns a cached summary synchronously if one exists and is still valid.
    /// Call this before kicking off an async fetch to avoid unnecessary loading states.
    func cachedSummary(for data: UnifiedWeatherData) -> String? {
        guard let e = entry else {
            print("AI Summary: cache miss (no entry)")
            return nil
        }

        let age = Date().timeIntervalSince(e.generatedAt)
        guard age < Self.cacheMaxAge else {
            print("AI Summary: cache miss (expired)")
            return nil
        }

        let key = cacheKey(for: data)
        guard e.cacheKey == key else {
            print("AI Summary: cache miss (hash changed)")
            return nil
        }

        print("AI Summary: using cached summary")
        return e.summary
    }

    /// Fetch (or return cached) AI weather summary asynchronously.
    func fetchSummary(for data: UnifiedWeatherData) async throws -> String {
        let key = cacheKey(for: data)

        // Check in-memory / disk cache first
        if let cached = cachedSummary(for: data) { return cached }

        // If the same summary is already being generated, await that task instead
        // of starting a duplicate network request.
        if let task = inFlightTask, inFlightCacheKey == key {
            print("AI Summary: awaiting in-flight request")
            return try await task.value
        }

        print("AI Summary: requesting new summary")
        let task = Task<String, Error> {
            try await OpenRouterService.shared.sendBrief(weatherData: data)
        }
        inFlightTask = task
        inFlightCacheKey = key

        do {
            let summary = try await task.value

            // Persist
            let newEntry = AISummaryCacheEntry(summary: summary,
                                               generatedAt: Date(),
                                               cacheKey: key)
            entry = newEntry
            saveToDisk(newEntry)

            if inFlightCacheKey == key {
                inFlightTask = nil
                inFlightCacheKey = nil
            }

            return summary
        } catch {
            if inFlightCacheKey == key {
                inFlightTask = nil
                inFlightCacheKey = nil
            }
            throw error
        }
    }

    /// Wipe cache (call on location change or data source switch).
    func invalidateCache() {
        entry = nil
        inFlightTask?.cancel()
        inFlightTask = nil
        inFlightCacheKey = nil
        if let url = cacheFileURL { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - Hash

    private func cacheKey(for data: UnifiedWeatherData) -> String {
        // Use a deterministic cache key for disk persistence.
        // Swift's Hasher is intentionally randomized between process launches,
        // so persisting `finalize()` results would invalidate the cache on relaunch.
        let normalizedLocation = (data.locationName ?? "unknown")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let units = TemperatureFormatter.apiUnits
        return "\(normalizedLocation)|\(dayOfYear)|\(units)"
    }

    // MARK: - Disk persistence

    private var cacheFileURL: URL? {
        guard let baseURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directoryURL = baseURL.appendingPathComponent("Cloudship", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL,
                                                 withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent(Self.fileName)
    }

    private func saveToDisk(_ entry: AISummaryCacheEntry) {
        guard let url = cacheFileURL,
              let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func loadFromDisk() {
        guard let url = cacheFileURL,
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode(AISummaryCacheEntry.self, from: data) else { return }
        // Only restore if not expired — don't bother keeping stale disk entries in memory
        if Date().timeIntervalSince(loaded.generatedAt) < Self.cacheMaxAge {
            entry = loaded
        }
    }
}

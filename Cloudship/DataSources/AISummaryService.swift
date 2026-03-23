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
    let dataHash: Int
}

// MARK: - Service

final class AISummaryService {

    static let shared = AISummaryService()
    private init() { loadFromDisk() }

    // MARK: - State

    private static let cacheMaxAge: TimeInterval = 7200   // 2 hours
    private static let fileName = "ai_summary_cache.json"

    private var entry: AISummaryCacheEntry?

    // MARK: - Public API

    /// Returns a cached summary synchronously if one exists and is still valid.
    /// Call this before kicking off an async fetch to avoid unnecessary loading states.
    func cachedSummary(for data: UnifiedWeatherData) -> String? {
        guard let e = entry,
              Date().timeIntervalSince(e.generatedAt) < Self.cacheMaxAge,
              e.dataHash == dataHash(for: data) else { return nil }
        return e.summary
    }

    /// Fetch (or return cached) AI weather summary asynchronously.
    func fetchSummary(for data: UnifiedWeatherData) async throws -> String {
        // Check in-memory / disk cache first
        if let cached = cachedSummary(for: data) { return cached }

        // Generate a new summary
        let summary = try await OpenRouterService.shared.sendBrief(weatherData: data)

        // Persist
        let newEntry = AISummaryCacheEntry(summary: summary,
                                           generatedAt: Date(),
                                           dataHash: dataHash(for: data))
        entry = newEntry
        saveToDisk(newEntry)

        return summary
    }

    /// Wipe cache (call on location change or data source switch).
    func invalidateCache() {
        entry = nil
        if let url = cacheFileURL { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - Hash

    private func dataHash(for data: UnifiedWeatherData) -> Int {
        var hasher = Hasher()
        if let temp = data.current.temperature { hasher.combine(Int(temp / 5) * 5) }
        hasher.combine(data.current.condition.rawValue)
        hasher.combine(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0)
        if let chance = data.hourly.first?.precipChance { hasher.combine(Int(chance * 4)) }
        return hasher.finalize()
    }

    // MARK: - Disk persistence

    private var cacheFileURL: URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Self.fileName)
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

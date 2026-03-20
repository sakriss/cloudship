//
//  AISummaryService.swift
//  Cloudship
//
//  Generates and caches a 2-3 sentence AI weather brief using OpenRouter.
//  Cache lasts 2 hours or until weather conditions change significantly.
//

import Foundation

final class AISummaryService {

    static let shared = AISummaryService()
    private init() {}

    // MARK: - Cache

    private var cachedSummary: String?
    private var cacheDate: Date?
    private var cachedHash: Int?

    private static let cacheMaxAge: TimeInterval = 7200  // 2 hours

    // MARK: - Public

    /// Fetch (or return cached) AI weather summary.
    func fetchSummary(for data: UnifiedWeatherData) async throws -> String {
        let hash = dataHash(for: data)

        // Return cache if fresh and weather hasn't changed significantly
        if let cached = cachedSummary,
           let date = cacheDate,
           let oldHash = cachedHash,
           Date().timeIntervalSince(date) < Self.cacheMaxAge,
           oldHash == hash {
            return cached
        }

        // Generate new summary
        let summary = try await OpenRouterService.shared.sendBrief(weatherData: data)

        // Cache it
        cachedSummary = summary
        cacheDate = Date()
        cachedHash = hash

        return summary
    }

    /// Clear the cache (e.g. on location change or source switch).
    func invalidateCache() {
        cachedSummary = nil
        cacheDate = nil
        cachedHash = nil
    }

    // MARK: - Hash

    /// Simple hash of key weather values to detect significant changes.
    private func dataHash(for data: UnifiedWeatherData) -> Int {
        var hasher = Hasher()

        // Round temp to nearest 5 degrees so small fluctuations don't invalidate
        if let temp = data.current.temperature {
            hasher.combine(Int(temp / 5) * 5)
        }

        // Condition
        hasher.combine(data.current.condition.rawValue)

        // Day of year
        hasher.combine(Calendar.current.ordinality(of: .day, in: .year, for: Date()))

        // Precip chance bucket (0-25, 25-50, 50-75, 75-100)
        if let firstHourly = data.hourly.first, let chance = firstHourly.precipChance {
            hasher.combine(Int(chance * 4))  // bucket into quarters
        }

        return hasher.finalize()
    }
}

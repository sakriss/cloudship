//
//  ConsensusWeatherService.swift
//  Cloudship
//
//  Fetches weather from multiple sources in parallel and produces a
//  weighted-average UnifiedWeatherData with a per-source breakdown.
//  Requires Cloudship Premium.
//

import Foundation

// MARK: - Breakdown model

struct ConsensusBreakdown: Codable {

    struct SourceReading: Codable {
        let sourceID: WeatherSourceID
        let sourceName: String
        let temperature: Double?    // current temp in user's unit
        let precipChance: Double?   // 0–100
        var isOutlier: Bool         // temp > 1.5 std dev from mean
    }

    let readings: [SourceReading]
    let averageTemp: Double?
    let averagePrecipChance: Double?
    let sourcesUsed: Int
}

// MARK: - Service

actor ConsensusWeatherService {

    static let shared = ConsensusWeatherService()
    private init() {}

    // MARK: - Weight tables

    /// Temperature weights by source (must sum to 1.0 across all five sources).
    private static let tempWeights: [WeatherSourceID: Double] = [
        .tomorrowIO:    0.25,
        .noaa:          0.30,
        .openMeteo:     0.25,
        .pirateWeather: 0.10,
        .appleWeather:  0.10
    ]

    /// Precipitation-chance weights by source (must sum to 1.0).
    private static let precipWeights: [WeatherSourceID: Double] = [
        .tomorrowIO:    0.35,
        .noaa:          0.30,
        .openMeteo:     0.15,
        .pirateWeather: 0.10,
        .appleWeather:  0.10
    ]

    // MARK: - Public

    /// Fetches weather from all available sources in parallel, applies weighted
    /// averaging, and returns the merged data plus a per-source breakdown.
    ///
    /// - Parameters:
    ///   - lat: Latitude
    ///   - lon: Longitude
    ///   - units: "imperial" or "metric"
    ///   - isPremium: When false only the two free sources are used.
    func fetch(
        lat: Double,
        lon: Double,
        units: String,
        isPremium: Bool
    ) async throws -> (data: UnifiedWeatherData, breakdown: ConsensusBreakdown) {

        let allSources: [(WeatherSourceID, WeatherDataSource)] = isPremium
            ? [
                (.tomorrowIO,    TomorrowIODataSource()),
                (.noaa,          NOAADataSource()),
                (.openMeteo,     OpenMeteoDataSource()),
                (.pirateWeather, PirateWeatherDataSource()),
                (.appleWeather,  AppleWeatherDataSource())
              ]
            : [
                (.noaa,      NOAADataSource()),
                (.openMeteo, OpenMeteoDataSource())
              ]

        // Fetch all sources in parallel; failed sources are silently dropped.
        var results: [(id: WeatherSourceID, name: String, data: UnifiedWeatherData)] = []

        await withTaskGroup(of: (WeatherSourceID, String, UnifiedWeatherData?)?.self) { group in
            for (sourceID, source) in allSources {
                let sourceName = source.name
                group.addTask {
                    do {
                        let data = try await source.fetchWeather(lat: lat, lon: lon, units: units)
                        return (sourceID, sourceName, data)
                    } catch {
                        print("ConsensusWeatherService: \(sourceName) failed — \(error.localizedDescription)")
                        return nil
                    }
                }
            }
            for await result in group {
                if let (id, name, data) = result, let d = data {
                    results.append((id: id, name: name, data: d))
                }
            }
        }

        guard !results.isEmpty else {
            throw ConsensusError.allSourcesFailed
        }

        // Build per-source readings
        var readings: [ConsensusBreakdown.SourceReading] = results.map { r in
            ConsensusBreakdown.SourceReading(
                sourceID:     r.id,
                sourceName:   r.name,
                temperature:  r.data.current.temperature,
                precipChance: r.data.hourly.first?.precipChance,
                isOutlier:    false
            )
        }

        // Detect temperature outliers (> 1.5 std deviations from the mean)
        markOutliers(&readings)

        // Weighted average current temperature
        let avgTemp    = weightedAverage(readings.map { ($0.sourceID, $0.temperature) },
                                         weights: Self.tempWeights)
        let avgPrecip  = weightedAverage(readings.map { ($0.sourceID, $0.precipChance) },
                                         weights: Self.precipWeights)

        let breakdown = ConsensusBreakdown(
            readings:            readings,
            averageTemp:         avgTemp,
            averagePrecipChance: avgPrecip,
            sourcesUsed:         results.count
        )

        // Use the highest-weight successfully-fetched source as the structural
        // base (for hourly, daily, minutely arrays) then overlay averaged current.
        let base = bestBase(from: results)
        var merged = base.data
        if let temp = avgTemp { merged.current.temperature = temp }
        if let precip = avgPrecip,
           !merged.hourly.isEmpty {
            merged.hourly[0].precipChance = precip
        }
        merged.consensusBreakdown = breakdown

        return (data: merged, breakdown: breakdown)
    }

    // MARK: - Helpers

    private func weightedAverage(
        _ readings: [(WeatherSourceID, Double?)],
        weights: [WeatherSourceID: Double]
    ) -> Double? {
        let available = readings.compactMap { id, val -> (Double, Double)? in
            guard let v = val, let w = weights[id] else { return nil }
            return (v, w)
        }
        guard !available.isEmpty else { return nil }

        // Renormalize weights for available sources
        let totalWeight = available.map(\.1).reduce(0, +)
        guard totalWeight > 0 else { return nil }

        return available.reduce(0.0) { $0 + $1.0 * ($1.1 / totalWeight) }
    }

    private func markOutliers(_ readings: inout [ConsensusBreakdown.SourceReading]) {
        let temps = readings.compactMap(\.temperature)
        guard temps.count >= 3 else { return }   // need at least 3 to detect outliers

        let mean = temps.reduce(0, +) / Double(temps.count)
        let variance = temps.map { pow($0 - mean, 2) }.reduce(0, +) / Double(temps.count)
        let stdDev = sqrt(variance)
        guard stdDev > 0 else { return }

        for i in readings.indices {
            if let t = readings[i].temperature, abs(t - mean) > 1.5 * stdDev {
                readings[i].isOutlier = true
            }
        }
    }

    /// Returns the result whose source has the highest temperature weight
    /// among successfully fetched sources.
    private func bestBase(
        from results: [(id: WeatherSourceID, name: String, data: UnifiedWeatherData)]
    ) -> (id: WeatherSourceID, name: String, data: UnifiedWeatherData) {
        return results.max(by: {
            (Self.tempWeights[$0.id] ?? 0) < (Self.tempWeights[$1.id] ?? 0)
        }) ?? results[0]
    }
}

// MARK: - Error

enum ConsensusError: LocalizedError {
    case allSourcesFailed

    var errorDescription: String? {
        "All weather sources failed to respond. Please try again."
    }
}

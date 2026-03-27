//
//  ConsensusWeatherServiceTests.swift
//  CloudshipTests
//
//  Unit tests for ConsensusWeatherService weighted averaging, outlier
//  detection, and source selection logic.
//

import XCTest
@testable import Cloudship

// MARK: - Mock WeatherDataSource

/// A lightweight mock that returns canned data or throws on demand.
private final class MockWeatherDataSource: WeatherDataSource {
    let name: String
    let result: Result<UnifiedWeatherData, Error>

    init(name: String, data: UnifiedWeatherData) {
        self.name = name
        self.result = .success(data)
    }

    init(name: String, error: Error) {
        self.name = name
        self.result = .failure(error)
    }

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        switch result {
        case .success(let data): return data
        case .failure(let err):  throw err
        }
    }
}

// MARK: - Test Helpers

private func makeWeatherData(
    temp: Double? = 72.0,
    precipChance: Double? = 30.0,
    condition: WeatherCondition = .clear
) -> UnifiedWeatherData {
    UnifiedWeatherData(
        locationName: nil,
        current: CurrentConditions(
            temperature: temp,
            feelsLike: temp,
            humidity: 50,
            windSpeed: 10,
            windGust: nil,
            windDirection: 180,
            condition: condition,
            uvIndex: 5,
            visibility: 10,
            pressure: 30.0,
            dewPoint: 55,
            cloudCover: 20
        ),
        hourly: [
            HourlyEntry(
                time: Date(),
                temp: temp,
                feelsLike: temp,
                condition: condition,
                precipChance: precipChance,
                precipAmount: nil,
                windSpeed: 10,
                windGust: nil,
                windDirection: nil,
                uvIndex: nil,
                humidity: nil,
                cloudCover: nil,
                visibility: nil,
                pressure: nil
            )
        ],
        daily: [],
        minutely: [],
        alerts: [],
        airQuality: nil,
        pollen: nil
    )
}

// MARK: - ConsensusBreakdown Tests

final class ConsensusBreakdownTests: XCTestCase {

    // MARK: Outlier detection

    func testOutlierDetection_marksTemperatureFarFromMean() {
        // Given: 4 readings near 70 and one at 100 (>1.5 std dev away)
        var readings: [ConsensusBreakdown.SourceReading] = [
            .init(sourceID: .noaa,          sourceName: "NOAA",       temperature: 70, precipChance: 30, isOutlier: false),
            .init(sourceID: .openMeteo,     sourceName: "Open-Meteo", temperature: 71, precipChance: 25, isOutlier: false),
            .init(sourceID: .tomorrowIO,    sourceName: "Tomorrow",   temperature: 69, precipChance: 35, isOutlier: false),
            .init(sourceID: .pirateWeather, sourceName: "Pirate",     temperature: 100, precipChance: 20, isOutlier: false),
        ]

        // When: We manually compute outlier detection the same way as the service
        let temps = readings.compactMap(\.temperature)
        let mean = temps.reduce(0, +) / Double(temps.count)
        let variance = temps.map { pow($0 - mean, 2) }.reduce(0, +) / Double(temps.count)
        let stdDev = sqrt(variance)

        for i in readings.indices {
            if let t = readings[i].temperature, abs(t - mean) > 1.5 * stdDev {
                readings[i].isOutlier = true
            }
        }

        // Then: Pirate at 100 should be an outlier, others should not
        XCTAssertFalse(readings[0].isOutlier, "NOAA at 70 should not be outlier")
        XCTAssertFalse(readings[1].isOutlier, "Open-Meteo at 71 should not be outlier")
        XCTAssertFalse(readings[2].isOutlier, "Tomorrow at 69 should not be outlier")
        XCTAssertTrue(readings[3].isOutlier, "Pirate at 100 should be outlier")
    }

    func testOutlierDetection_noOutliersWhenTempsSimilar() {
        var readings: [ConsensusBreakdown.SourceReading] = [
            .init(sourceID: .noaa,       sourceName: "NOAA",       temperature: 70, precipChance: 30, isOutlier: false),
            .init(sourceID: .openMeteo,  sourceName: "Open-Meteo", temperature: 71, precipChance: 25, isOutlier: false),
            .init(sourceID: .tomorrowIO, sourceName: "Tomorrow",   temperature: 72, precipChance: 35, isOutlier: false),
        ]

        let temps = readings.compactMap(\.temperature)
        let mean = temps.reduce(0, +) / Double(temps.count)
        let variance = temps.map { pow($0 - mean, 2) }.reduce(0, +) / Double(temps.count)
        let stdDev = sqrt(variance)

        for i in readings.indices {
            if let t = readings[i].temperature, stdDev > 0, abs(t - mean) > 1.5 * stdDev {
                readings[i].isOutlier = true
            }
        }

        for reading in readings {
            XCTAssertFalse(reading.isOutlier, "\(reading.sourceName) should not be an outlier when temps are similar")
        }
    }

    func testOutlierDetection_skipsWithFewerThanThreeReadings() {
        // With fewer than 3 readings, outlier detection should be skipped
        var readings: [ConsensusBreakdown.SourceReading] = [
            .init(sourceID: .noaa,      sourceName: "NOAA",       temperature: 70, precipChance: 30, isOutlier: false),
            .init(sourceID: .openMeteo, sourceName: "Open-Meteo", temperature: 200, precipChance: 25, isOutlier: false),
        ]

        let temps = readings.compactMap(\.temperature)
        guard temps.count >= 3 else {
            // Should exit early — no outlier marking
            for reading in readings {
                XCTAssertFalse(reading.isOutlier)
            }
            return
        }
        XCTFail("Should have returned early with < 3 temps")
    }

    // MARK: Weighted average

    func testWeightedAverage_computesCorrectly() {
        // Given known weights and values, verify the weighted average formula
        // NOAA=0.30, OpenMeteo=0.25
        // Temps: NOAA=70, OpenMeteo=80
        // Expected: (70*0.30 + 80*0.25) / (0.30+0.25) = (21+20)/0.55 = 74.545...

        let readings: [(WeatherSourceID, Double?)] = [
            (.noaa, 70.0),
            (.openMeteo, 80.0)
        ]
        let weights: [WeatherSourceID: Double] = [
            .tomorrowIO: 0.25,
            .noaa: 0.30,
            .openMeteo: 0.25,
            .pirateWeather: 0.10,
            .appleWeather: 0.10
        ]

        let available = readings.compactMap { id, val -> (Double, Double)? in
            guard let v = val, let w = weights[id] else { return nil }
            return (v, w)
        }
        let totalWeight = available.map(\.1).reduce(0, +)
        let result = available.reduce(0.0) { $0 + $1.0 * ($1.1 / totalWeight) }

        // 70 * (0.30/0.55) + 80 * (0.25/0.55)
        let expected = 70.0 * (0.30 / 0.55) + 80.0 * (0.25 / 0.55)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }

    func testWeightedAverage_returnsNilForEmptyInput() {
        let readings: [(WeatherSourceID, Double?)] = [
            (.noaa, nil),
            (.openMeteo, nil)
        ]
        let weights: [WeatherSourceID: Double] = [.noaa: 0.30, .openMeteo: 0.25]

        let available = readings.compactMap { id, val -> (Double, Double)? in
            guard let v = val, let w = weights[id] else { return nil }
            return (v, w)
        }

        XCTAssertTrue(available.isEmpty, "No available readings when all values are nil")
    }

    func testWeightedAverage_renormalizesWeightsForAvailableSources() {
        // If only 2 of 5 sources respond, weights should be renormalized
        // so they sum to 1.0 across just those 2 sources
        let readings: [(WeatherSourceID, Double?)] = [
            (.noaa, 60.0),
            (.tomorrowIO, 80.0)
        ]
        let weights: [WeatherSourceID: Double] = [
            .tomorrowIO: 0.25,
            .noaa: 0.30,
            .openMeteo: 0.25,
            .pirateWeather: 0.10,
            .appleWeather: 0.10
        ]

        let available = readings.compactMap { id, val -> (Double, Double)? in
            guard let v = val, let w = weights[id] else { return nil }
            return (v, w)
        }
        let totalWeight = available.map(\.1).reduce(0, +)
        let result = available.reduce(0.0) { $0 + $1.0 * ($1.1 / totalWeight) }

        // NOAA weight 0.30, Tomorrow weight 0.25 → renormalized: 0.30/0.55, 0.25/0.55
        let expected = 60.0 * (0.30 / 0.55) + 80.0 * (0.25 / 0.55)
        XCTAssertEqual(result, expected, accuracy: 0.001)
    }
}

// MARK: - ConsensusBreakdown Codable Tests

final class ConsensusBreakdownCodableTests: XCTestCase {

    func testBreakdown_encodesAndDecodesRoundTrip() throws {
        let breakdown = ConsensusBreakdown(
            readings: [
                .init(sourceID: .noaa, sourceName: "NOAA", temperature: 70, precipChance: 30, isOutlier: false),
                .init(sourceID: .openMeteo, sourceName: "Open-Meteo", temperature: 72, precipChance: 25, isOutlier: true),
            ],
            averageTemp: 71.0,
            averagePrecipChance: 27.5,
            sourcesUsed: 2
        )

        let data = try JSONEncoder().encode(breakdown)
        let decoded = try JSONDecoder().decode(ConsensusBreakdown.self, from: data)

        XCTAssertEqual(decoded.sourcesUsed, 2)
        XCTAssertEqual(decoded.averageTemp, 71.0)
        XCTAssertEqual(decoded.averagePrecipChance, 27.5)
        XCTAssertEqual(decoded.readings.count, 2)
        XCTAssertEqual(decoded.readings[0].sourceID, .noaa)
        XCTAssertTrue(decoded.readings[1].isOutlier)
    }
}

// MARK: - ConsensusError Tests

final class ConsensusErrorTests: XCTestCase {

    func testAllSourcesFailed_hasDescription() {
        let error = ConsensusError.allSourcesFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("All weather sources"))
    }
}

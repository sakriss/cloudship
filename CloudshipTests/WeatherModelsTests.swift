//
//  WeatherModelsTests.swift
//  CloudshipTests
//
//  Unit tests for UnifiedWeatherModels types, including AQI, AlertSeverity,
//  moon phase helpers, and Codable round-trips.
//

import XCTest
@testable import Cloudship

// MARK: - AQI Category Tests

final class AQICategoryTests: XCTestCase {

    func testFrom_goodRange() {
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 0), .good)
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 50), .good)
    }

    func testFrom_moderateRange() {
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 51), .moderate)
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 100), .moderate)
    }

    func testFrom_unhealthySensitiveRange() {
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 101), .unhealthySensitive)
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 150), .unhealthySensitive)
    }

    func testFrom_unhealthyRange() {
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 151), .unhealthy)
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 200), .unhealthy)
    }

    func testFrom_veryUnhealthyRange() {
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 201), .veryUnhealthy)
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 300), .veryUnhealthy)
    }

    func testFrom_hazardousRange() {
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 301), .hazardous)
        XCTAssertEqual(AirQualityData.AQICategory.from(index: 500), .hazardous)
    }
}

// MARK: - Alert Severity Tests

final class AlertSeverityTests: XCTestCase {

    func testComparable_ordering() {
        XCTAssertTrue(AlertSeverity.unknown < AlertSeverity.minor)
        XCTAssertTrue(AlertSeverity.minor < AlertSeverity.moderate)
        XCTAssertTrue(AlertSeverity.moderate < AlertSeverity.severe)
        XCTAssertTrue(AlertSeverity.severe < AlertSeverity.extreme)
    }

    func testComparable_equalNotLessThan() {
        XCTAssertFalse(AlertSeverity.extreme < AlertSeverity.extreme)
    }

    func testEmoji_extreme() {
        XCTAssertFalse(AlertSeverity.extreme.emoji.isEmpty)
    }
}

// MARK: - Moon Phase Tests

final class MoonPhaseTests: XCTestCase {

    private func makeDailyEntry(moonPhase: Double?) -> DailyEntry {
        DailyEntry(
            time: Date(),
            tempMin: nil, tempMax: nil,
            feelsLikeMin: nil, feelsLikeMax: nil,
            condition: .clear, conditionNight: .clear,
            precipChance: nil, precipAmount: nil,
            sunrise: nil, sunset: nil,
            moonPhase: moonPhase,
            dayDescription: nil, nightDescription: nil
        )
    }

    func testMoonPhaseName_newMoon() {
        let entry = makeDailyEntry(moonPhase: 0.0)
        XCTAssertEqual(entry.moonPhaseName, "New Moon")
    }

    func testMoonPhaseName_fullMoon() {
        let entry = makeDailyEntry(moonPhase: 0.5)
        XCTAssertEqual(entry.moonPhaseName, "Full Moon")
    }

    func testMoonPhaseName_firstQuarter() {
        let entry = makeDailyEntry(moonPhase: 0.25)
        XCTAssertEqual(entry.moonPhaseName, "First Quarter")
    }

    func testMoonPhaseName_lastQuarter() {
        let entry = makeDailyEntry(moonPhase: 0.75)
        XCTAssertEqual(entry.moonPhaseName, "Last Quarter")
    }

    func testMoonPhaseName_nil() {
        let entry = makeDailyEntry(moonPhase: nil)
        XCTAssertEqual(entry.moonPhaseName, "")
    }

    func testMoonPhaseEmoji_nil() {
        let entry = makeDailyEntry(moonPhase: nil)
        XCTAssertFalse(entry.moonPhaseEmoji.isEmpty)
    }
}

// MARK: - WeatherCondition Tests

final class WeatherConditionTests: XCTestCase {

    func testDescription_allCasesNonEmpty() {
        let allCases: [WeatherCondition] = [
            .clear, .mostlyClear, .partlyCloudy, .mostlyCloudy,
            .cloudy, .fog, .lightFog, .drizzle, .rain, .heavyRain,
            .lightSnow, .snow, .heavySnow, .sleet, .thunderstorm,
            .windy, .unknown
        ]
        for condition in allCases {
            XCTAssertFalse(condition.description.isEmpty, "\(condition) description should not be empty")
        }
    }

    func testCodable_roundTrip() throws {
        let original: WeatherCondition = .thunderstorm
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WeatherCondition.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}

// MARK: - PollenLevel Tests

final class PollenLevelTests: XCTestCase {

    func testLabel_allCasesNonEmpty() {
        for level in PollenLevel.allCases {
            XCTAssertFalse(level.label.isEmpty, "\(level) label should not be empty")
        }
    }
}

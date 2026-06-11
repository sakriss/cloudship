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

    private func makeTomorrowDailyValues(
        weatherCodeFullDay: Int? = nil,
        weatherCodeDay: Int? = nil,
        weatherCodeNight: Int? = nil,
        weatherCodeAvg: Int? = nil,
        weatherCodeMax: Int? = nil,
        weatherCodeMin: Int? = nil
    ) -> ClimacellV4.ForecastValues {
        ClimacellV4.ForecastValues(
            cloudBase: nil,
            cloudCeiling: nil,
            cloudCover: nil,
            dewPoint: nil,
            freezingRainIntensity: nil,
            humidity: nil,
            precipitationProbability: nil,
            precipitationProbabilityAvg: nil,
            rainAccumulationSum: nil,
            pressureSurfaceLevel: nil,
            rainIntensity: nil,
            sleetIntensity: nil,
            snowIntensity: nil,
            temperature: nil,
            temperatureApparent: nil,
            temperatureApparentMin: nil,
            temperatureApparentMax: nil,
            temperatureMax: nil,
            temperatureMin: nil,
            uvHealthConcern: nil,
            uvIndex: nil,
            visibility: nil,
            weatherCode: nil,
            weatherCodeFullDay: weatherCodeFullDay,
            weatherCodeAvg: weatherCodeAvg,
            weatherCodeDay: weatherCodeDay,
            weatherCodeNight: weatherCodeNight,
            weatherCodeMax: weatherCodeMax,
            weatherCodeMin: weatherCodeMin,
            windDirection: nil,
            windGust: nil,
            windSpeed: nil,
            sunriseTime: nil,
            sunsetTime: nil,
            moonPhase: nil,
            treeIndex: nil,
            grassIndex: nil,
            weedIndex: nil
        )
    }

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

    func testTomorrowDailyCondition_fallsBackToMaxWhenAverageCodeIsUnknown() {
        let values = makeTomorrowDailyValues(weatherCodeAvg: 2576, weatherCodeMax: 4200)
        XCTAssertEqual(WeatherCodeMapper.condition(fromTomorrowDailyValues: values), .rain)
    }

    func testTomorrowNightCondition_prefersNightCodeWhenAvailable() {
        let values = makeTomorrowDailyValues(weatherCodeNight: 5000, weatherCodeMax: 4200)
        XCTAssertEqual(WeatherCodeMapper.nightCondition(fromTomorrowDailyValues: values), .snow)
    }

    func testUnknownIconDefaultsToCloudy() {
        XCTAssertEqual(WeatherCodeMapper.iconName(for: .unknown), "cloudy")
    }

    func testClearIconUsesMoonAtNight() {
        XCTAssertEqual(WeatherCodeMapper.iconName(for: .clear, isNight: true), "clearnight")
        XCTAssertEqual(WeatherCodeMapper.iconName(for: .partlyCloudy, isNight: true), "cloudynight")
    }

    func testNightDetectionUsesForecastHour() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let morning = calendar.date(from: DateComponents(
            year: 2026, month: 6, day: 11, hour: 10
        ))!
        let night = calendar.date(from: DateComponents(
            year: 2026, month: 6, day: 11, hour: 22
        ))!

        XCTAssertFalse(WeatherCodeMapper.isNight(at: morning, calendar: calendar))
        XCTAssertTrue(WeatherCodeMapper.isNight(at: night, calendar: calendar))
    }

    func testNightDetectionUsesSunriseAndSunset() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sunrise = calendar.date(from: DateComponents(
            year: 2026, month: 6, day: 11, hour: 7
        ))!
        let sunset = calendar.date(from: DateComponents(
            year: 2026, month: 6, day: 11, hour: 17
        ))!
        let afterSunset = calendar.date(from: DateComponents(
            year: 2026, month: 6, day: 11, hour: 18
        ))!

        XCTAssertTrue(WeatherCodeMapper.isNight(
            at: afterSunset,
            sunrise: sunrise,
            sunset: sunset,
            calendar: calendar
        ))
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

//
//  SharedWeatherData.swift
//  Cloudship
//
//  Lightweight Codable model shared between the main app and widget extension
//  via the App Group container. Uses plain types (no UIKit dependency).
//

import Foundation

struct SharedWeatherData: Codable {
    let locationName: String
    let temperature: Double
    let feelsLike: Double
    let conditionRaw: String        // WeatherCondition.rawValue
    let hiTemp: Double
    let loTemp: Double
    let isMetric: Bool
    let sunrise: Date?
    let sunset: Date?
    let hourlyForecast: [SharedHourlyEntry]
    let dailyForecast: [SharedDailyEntry]
    let lastUpdated: Date
}

struct SharedHourlyEntry: Codable {
    let time: Date
    let temp: Double
    let conditionRaw: String
}

struct SharedDailyEntry: Codable {
    let time: Date
    let tempMin: Double
    let tempMax: Double
    let conditionRaw: String
}

//
//  PirateWeatherModels.swift
//  Cloudship
//
//  Codable response models for the Pirate Weather API (Dark Sky-compatible).
//  https://pirateweather.net
//

import Foundation

// MARK: - Top-level response

struct PirateWeatherResponse: Codable {
    let latitude: Double?
    let longitude: Double?
    let timezone: String?
    let offset: Double?
    let currently: PWCurrently?
    let minutely: PWMinutelyBlock?
    let hourly: PWHourlyBlock?
    let daily: PWDailyBlock?
    let alerts: [PWAlert]?
}

// MARK: - Currently

struct PWCurrently: Codable {
    let time: Double?
    let summary: String?
    let icon: String?
    let nearestStormDistance: Double?
    let nearestStormBearing: Double?
    let precipIntensity: Double?
    let precipIntensityError: Double?
    let precipProbability: Double?
    let precipType: String?
    let temperature: Double?
    let apparentTemperature: Double?
    let dewPoint: Double?
    let humidity: Double?
    let pressure: Double?
    let windSpeed: Double?
    let windGust: Double?
    let windBearing: Double?
    let cloudCover: Double?
    let uvIndex: Double?
    let visibility: Double?
    let ozone: Double?
}

// MARK: - Minutely

struct PWMinutelyBlock: Codable {
    let summary: String?
    let icon: String?
    let data: [PWMinutelyPoint]?
}

struct PWMinutelyPoint: Codable {
    let time: Double?
    let precipIntensity: Double?
    let precipIntensityError: Double?
    let precipProbability: Double?
    let precipType: String?
}

// MARK: - Hourly

struct PWHourlyBlock: Codable {
    let summary: String?
    let icon: String?
    let data: [PWHourlyPoint]?
}

struct PWHourlyPoint: Codable {
    let time: Double?
    let summary: String?
    let icon: String?
    let precipIntensity: Double?
    let precipIntensityError: Double?
    let precipProbability: Double?
    let precipType: String?
    let precipAccumulation: Double?
    let temperature: Double?
    let apparentTemperature: Double?
    let dewPoint: Double?
    let humidity: Double?
    let pressure: Double?
    let windSpeed: Double?
    let windGust: Double?
    let windBearing: Double?
    let cloudCover: Double?
    let uvIndex: Double?
    let visibility: Double?
    let ozone: Double?

    // v2 fields
    let snowAccumulation: Double?
    let iceAccumulation: Double?
    let liquidAccumulation: Double?
    let fireIndex: Double?
    let smoke: Double?
}

// MARK: - Daily

struct PWDailyBlock: Codable {
    let summary: String?
    let icon: String?
    let data: [PWDailyPoint]?
}

struct PWDailyPoint: Codable {
    let time: Double?
    let summary: String?
    let icon: String?
    let sunriseTime: Double?
    let sunsetTime: Double?
    let dawnTime: Double?
    let duskTime: Double?
    let moonPhase: Double?
    let precipIntensity: Double?
    let precipIntensityMax: Double?
    let precipIntensityMaxTime: Double?
    let precipProbability: Double?
    let precipType: String?
    let precipAccumulation: Double?
    let temperatureHigh: Double?
    let temperatureHighTime: Double?
    let temperatureLow: Double?
    let temperatureLowTime: Double?
    let temperatureMin: Double?
    let temperatureMinTime: Double?
    let temperatureMax: Double?
    let temperatureMaxTime: Double?
    let apparentTemperatureHigh: Double?
    let apparentTemperatureHighTime: Double?
    let apparentTemperatureLow: Double?
    let apparentTemperatureLowTime: Double?
    let apparentTemperatureMin: Double?
    let apparentTemperatureMax: Double?
    let dewPoint: Double?
    let humidity: Double?
    let pressure: Double?
    let windSpeed: Double?
    let windGust: Double?
    let windGustTime: Double?
    let windBearing: Double?
    let cloudCover: Double?
    let uvIndex: Double?
    let uvIndexTime: Double?
    let visibility: Double?
    let ozone: Double?

    // v2 fields
    let snowAccumulation: Double?
    let iceAccumulation: Double?
    let liquidAccumulation: Double?
}

// MARK: - Alerts

struct PWAlert: Codable {
    let title: String?
    let regions: [String]?
    let severity: String?
    let time: Double?
    let expires: Double?
    let description: String?
    let uri: String?
}

//
//  OpenMeteoModels.swift
//  Cloudship
//
//  Codable response models for the Open-Meteo API.
//  Forecast:    https://api.open-meteo.com/v1/forecast
//  Air Quality: https://air-quality-api.open-meteo.com/v1/air-quality
//

import Foundation

// MARK: - Forecast response

struct OpenMeteoForecastResponse: Codable {
    let current: OpenMeteoCurrent?
    let hourly: OpenMeteoHourly?
    let daily: OpenMeteoDaily?
    let minutely15: OpenMeteoMinutely15?

    enum CodingKeys: String, CodingKey {
        case current, hourly, daily
        case minutely15 = "minutely_15"
    }
}

struct OpenMeteoMinutely15: Codable {
    let time: [String]?
    let precipitation: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time, precipitation
    }
}

struct OpenMeteoCurrent: Codable {
    let time: String?
    let temperature2m: Double?
    let relativeHumidity2m: Int?
    let apparentTemperature: Double?
    let precipitation: Double?
    let weatherCode: Int?
    let cloudCover: Int?
    let windSpeed10m: Double?
    let windDirection10m: Double?
    let windGusts10m: Double?
    let uvIndex: Double?
    let surfacePressure: Double?
    let visibility: Double?
    let dewPoint2m: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m         = "temperature_2m"
        case relativeHumidity2m    = "relative_humidity_2m"
        case apparentTemperature   = "apparent_temperature"
        case precipitation
        case weatherCode           = "weather_code"
        case cloudCover            = "cloud_cover"
        case windSpeed10m          = "wind_speed_10m"
        case windDirection10m      = "wind_direction_10m"
        case windGusts10m          = "wind_gusts_10m"
        case uvIndex               = "uv_index"
        case surfacePressure       = "surface_pressure"
        case visibility
        case dewPoint2m            = "dew_point_2m"
    }
}

struct OpenMeteoHourly: Codable {
    let time: [String]?
    let temperature2m: [Double?]?
    let precipitationProbability: [Int?]?
    let weatherCode: [Int?]?
    let windGusts10m: [Double?]?
    let windDirection10m: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m             = "temperature_2m"
        case precipitationProbability  = "precipitation_probability"
        case weatherCode               = "weather_code"
        case windGusts10m              = "wind_gusts_10m"
        case windDirection10m          = "wind_direction_10m"
    }
}

struct OpenMeteoDaily: Codable {
    let time: [String]?
    let weatherCode: [Int?]?
    let temperature2mMax: [Double?]?
    let temperature2mMin: [Double?]?
    let apparentTemperatureMax: [Double?]?
    let apparentTemperatureMin: [Double?]?
    let precipitationSum: [Double?]?
    let precipitationProbabilityMax: [Int?]?
    let sunrise: [String?]?
    let sunset: [String?]?
    let uvIndexMax: [Double?]?
    let moonPhase: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode                 = "weather_code"
        case temperature2mMax            = "temperature_2m_max"
        case temperature2mMin            = "temperature_2m_min"
        case apparentTemperatureMax      = "apparent_temperature_max"
        case apparentTemperatureMin      = "apparent_temperature_min"
        case precipitationSum            = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case sunrise
        case sunset
        case uvIndexMax                  = "uv_index_max"
        case moonPhase                   = "moon_phase"
    }
}

// MARK: - Air quality response

struct OpenMeteoAirQualityResponse: Codable {
    let current: AQCurrent?
    let hourly: AQHourly?

    struct AQCurrent: Codable {
        let usAqi: Int?
        enum CodingKeys: String, CodingKey { case usAqi = "us_aqi" }
    }

    struct AQHourly: Codable {
        let time: [String]?
        let birchPollen: [Double?]?
        let grassPollen: [Double?]?
        let ragweedPollen: [Double?]?

        enum CodingKeys: String, CodingKey {
            case time
            case birchPollen   = "birch_pollen"
            case grassPollen   = "grass_pollen"
            case ragweedPollen = "ragweed_pollen"
        }
    }
}

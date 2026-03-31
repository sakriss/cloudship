//
//  AccuWeatherModels.swift
//  Cloudship
//
//  Codable response models for the AccuWeather Core Weather API.
//  Covers geoposition search, current conditions (details=true),
//  5-day daily forecast, and 12-hour hourly forecast.
//

import Foundation

// MARK: - Location search

struct AccuWeatherLocation: Codable {
    let key: String                     // Location key used by all other endpoints
    let localizedName: String?

    enum CodingKeys: String, CodingKey {
        case key              = "Key"
        case localizedName    = "LocalizedName"
    }
}

// MARK: - Shared value containers

/// Temperature / speed / distance measurement with both metric and imperial values.
struct AWMeasurement: Codable {
    let metric: AWUnitValue?
    let imperial: AWUnitValue?

    enum CodingKeys: String, CodingKey {
        case metric   = "Metric"
        case imperial = "Imperial"
    }
}

struct AWUnitValue: Codable {
    let value: Double?
    let unit: String?
    let unitType: Int?

    enum CodingKeys: String, CodingKey {
        case value    = "Value"
        case unit     = "Unit"
        case unitType = "UnitType"
    }
}

/// Wind object containing direction and speed.
struct AWWind: Codable {
    let direction: AWWindDirection?
    let speed: AWMeasurement?

    enum CodingKeys: String, CodingKey {
        case direction = "Direction"
        case speed     = "Speed"
    }
}

struct AWWindDirection: Codable {
    let degrees: Double?
    let english: String?

    enum CodingKeys: String, CodingKey {
        case degrees = "Degrees"
        case english = "English"
    }
}

struct AWWindGust: Codable {
    let speed: AWMeasurement?

    enum CodingKeys: String, CodingKey {
        case speed = "Speed"
    }
}

// MARK: - Current conditions (details=true)

struct AccuWeatherCurrentCondition: Codable {
    let localObservationDateTime: String?
    let epochTime: Int?
    let weatherText: String?
    let weatherIcon: Int?
    let hasPrecipitation: Bool?
    let precipitationType: String?
    let isDayTime: Bool?
    let temperature: AWMeasurement?
    let realFeelTemperature: AWMeasurement?
    let relativeHumidity: Double?
    let dewPoint: AWMeasurement?
    let wind: AWWind?
    let windGust: AWWindGust?
    let uvIndex: Double?
    let visibility: AWMeasurement?
    let cloudCover: Double?
    let pressure: AWMeasurement?
    let apparentTemperature: AWMeasurement?
    let precip1hr: AWMeasurement?

    enum CodingKeys: String, CodingKey {
        case localObservationDateTime = "LocalObservationDateTime"
        case epochTime                = "EpochTime"
        case weatherText              = "WeatherText"
        case weatherIcon              = "WeatherIcon"
        case hasPrecipitation         = "HasPrecipitation"
        case precipitationType        = "PrecipitationType"
        case isDayTime                = "IsDayTime"
        case temperature              = "Temperature"
        case realFeelTemperature      = "RealFeelTemperature"
        case relativeHumidity         = "RelativeHumidity"
        case dewPoint                 = "DewPoint"
        case wind                     = "Wind"
        case windGust                 = "WindGust"
        case uvIndex                  = "UVIndex"
        case visibility               = "Visibility"
        case cloudCover               = "CloudCover"
        case pressure                 = "Pressure"
        case apparentTemperature      = "ApparentTemperature"
        case precip1hr                = "Precip1hr"
    }
}

// MARK: - 5-day daily forecast

struct AccuWeatherDailyResponse: Codable {
    let headline: AWHeadline?
    let dailyForecasts: [AWDailyForecast]?

    enum CodingKeys: String, CodingKey {
        case headline       = "Headline"
        case dailyForecasts = "DailyForecasts"
    }
}

struct AWHeadline: Codable {
    let effectiveDate: String?
    let severity: Int?
    let text: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case effectiveDate = "EffectiveDate"
        case severity      = "Severity"
        case text          = "Text"
        case category      = "Category"
    }
}

struct AWDailyForecast: Codable {
    let date: String?
    let epochDate: Int?
    let sun: AWSunMoon?
    let moon: AWMoon?
    let temperature: AWMinMax?
    let realFeelTemperature: AWMinMax?
    let day: AWDayNightPeriod?
    let night: AWDayNightPeriod?

    enum CodingKeys: String, CodingKey {
        case date                 = "Date"
        case epochDate            = "EpochDate"
        case sun                  = "Sun"
        case moon                 = "Moon"
        case temperature          = "Temperature"
        case realFeelTemperature  = "RealFeelTemperature"
        case day                  = "Day"
        case night                = "Night"
    }
}

struct AWSunMoon: Codable {
    let rise: String?
    let set: String?
    let epochRise: Int?
    let epochSet: Int?

    enum CodingKeys: String, CodingKey {
        case rise      = "Rise"
        case set       = "Set"
        case epochRise = "EpochRise"
        case epochSet  = "EpochSet"
    }
}

struct AWMoon: Codable {
    let rise: String?
    let set: String?
    let phase: String?
    let age: Int?

    enum CodingKeys: String, CodingKey {
        case rise  = "Rise"
        case set   = "Set"
        case phase = "Phase"
        case age   = "Age"
    }
}

struct AWMinMax: Codable {
    let minimum: AWUnitValue?
    let maximum: AWUnitValue?

    enum CodingKeys: String, CodingKey {
        case minimum = "Minimum"
        case maximum = "Maximum"
    }
}

struct AWDayNightPeriod: Codable {
    let icon: Int?
    let iconPhrase: String?
    let hasPrecipitation: Bool?
    let precipitationType: String?
    let precipitationIntensity: String?
    let wind: AWWind?
    let windGust: AWWindGust?
    let totalLiquid: AWUnitValue?
    let rain: AWUnitValue?
    let snow: AWUnitValue?
    let ice: AWUnitValue?
    let cloudCover: Double?
    let precipitationProbability: Double?
    let thunderstormProbability: Double?
    let rainProbability: Double?
    let snowProbability: Double?
    let iceProbability: Double?

    enum CodingKeys: String, CodingKey {
        case icon                       = "Icon"
        case iconPhrase                 = "IconPhrase"
        case hasPrecipitation           = "HasPrecipitation"
        case precipitationType          = "PrecipitationType"
        case precipitationIntensity     = "PrecipitationIntensity"
        case wind                       = "Wind"
        case windGust                   = "WindGust"
        case totalLiquid                = "TotalLiquid"
        case rain                       = "Rain"
        case snow                       = "Snow"
        case ice                        = "Ice"
        case cloudCover                 = "CloudCover"
        case precipitationProbability   = "PrecipitationProbability"
        case thunderstormProbability    = "ThunderstormProbability"
        case rainProbability            = "RainProbability"
        case snowProbability            = "SnowProbability"
        case iceProbability             = "IceProbability"
    }
}

// MARK: - 12-hour hourly forecast

struct AccuWeatherHourlyForecast: Codable {
    let dateTime: String?
    let epochDateTime: Int?
    let weatherIcon: Int?
    let iconPhrase: String?
    let hasPrecipitation: Bool?
    let precipitationType: String?
    let precipitationIntensity: String?
    let isDaylight: Bool?
    let temperature: AWUnitValue?
    let realFeelTemperature: AWUnitValue?
    let dewPoint: AWUnitValue?
    let wind: AWWind?
    let windGust: AWWindGust?
    let relativeHumidity: Double?
    let visibility: AWUnitValue?
    let uvIndex: Double?
    let precipitationProbability: Double?
    let rainProbability: Double?
    let snowProbability: Double?
    let iceProbability: Double?
    let totalLiquid: AWUnitValue?
    let rain: AWUnitValue?
    let snow: AWUnitValue?
    let ice: AWUnitValue?
    let cloudCover: Double?

    enum CodingKeys: String, CodingKey {
        case dateTime                   = "DateTime"
        case epochDateTime              = "EpochDateTime"
        case weatherIcon                = "WeatherIcon"
        case iconPhrase                 = "IconPhrase"
        case hasPrecipitation           = "HasPrecipitation"
        case precipitationType          = "PrecipitationType"
        case precipitationIntensity     = "PrecipitationIntensity"
        case isDaylight                 = "IsDaylight"
        case temperature                = "Temperature"
        case realFeelTemperature        = "RealFeelTemperature"
        case dewPoint                   = "DewPoint"
        case wind                       = "Wind"
        case windGust                   = "WindGust"
        case relativeHumidity           = "RelativeHumidity"
        case visibility                 = "Visibility"
        case uvIndex                    = "UVIndex"
        case precipitationProbability   = "PrecipitationProbability"
        case rainProbability            = "RainProbability"
        case snowProbability            = "SnowProbability"
        case iceProbability             = "IceProbability"
        case totalLiquid                = "TotalLiquid"
        case rain                       = "Rain"
        case snow                       = "Snow"
        case ice                        = "Ice"
        case cloudCover                 = "CloudCover"
    }
}

// MARK: - Errors

enum AccuWeatherError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case locationNotFound
    case unauthorized
    case rateLimited
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return "AccuWeather API key not configured."
        case .invalidURL:      return "Invalid AccuWeather URL."
        case .locationNotFound: return "AccuWeather could not find a location for these coordinates."
        case .unauthorized:    return "AccuWeather API key is invalid."
        case .rateLimited:     return "AccuWeather API rate limit exceeded."
        case .httpError(let code): return "AccuWeather returned HTTP \(code)."
        }
    }
}

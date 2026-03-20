//
//  NOAAModels.swift
//  Cloudship
//
//  Codable structs for NOAA api.weather.gov responses.
//

import Foundation

// MARK: - /points endpoint

struct NOAAPointsResponse: Codable {
    let properties: NOAAPointsProperties?
}

struct NOAAPointsProperties: Codable {
    let gridId: String?
    let gridX: Int?
    let gridY: Int?
    let forecast: String?               // URL for daily forecast
    let forecastHourly: String?         // URL for hourly forecast
    let observationStations: String?    // URL for observation stations list
}

// MARK: - Observation stations list

struct NOAAStationsResponse: Codable {
    let features: [NOAAStationFeature]?
}

struct NOAAStationFeature: Codable {
    let properties: NOAAStationProperties?
}

struct NOAAStationProperties: Codable {
    let stationIdentifier: String?
}

// MARK: - Latest observation (current conditions)

struct NOAAObservationResponse: Codable {
    let properties: NOAAObservationProperties?
}

struct NOAAObservationProperties: Codable {
    let timestamp: String?
    let textDescription: String?
    let temperature: NOAAMeasurement?
    let dewpoint: NOAAMeasurement?
    let windDirection: NOAAMeasurement?
    let windSpeed: NOAAMeasurement?
    let windGust: NOAAMeasurement?
    let barometricPressure: NOAAMeasurement?
    let visibility: NOAAMeasurement?
    let relativeHumidity: NOAAMeasurement?
    let heatIndex: NOAAMeasurement?
    let windChill: NOAAMeasurement?
    let cloudLayers: [NOAACloudLayer]?
}

struct NOAAMeasurement: Codable {
    let value: Double?
    let unitCode: String?   // e.g. "wmoUnit:degC", "wmoUnit:m_s-1"
}

struct NOAACloudLayer: Codable {
    let amount: String?     // "CLR", "FEW", "SCT", "BKN", "OVC"
}

// MARK: - Forecast (daily / hourly)

struct NOAAForecastResponse: Codable {
    let properties: NOAAForecastProperties?
}

struct NOAAForecastProperties: Codable {
    let periods: [NOAAForecastPeriod]?
}

struct NOAAForecastPeriod: Codable {
    let number: Int?
    let name: String?
    let startTime: String?
    let endTime: String?
    let isDaytime: Bool?
    let temperature: Double?
    let temperatureUnit: String?    // "F" or "C"
    let temperatureTrend: String?
    let windSpeed: String?          // e.g. "10 to 15 mph" — string from NOAA
    let windDirection: String?      // "NW", "SW", etc.
    let shortForecast: String?
    let detailedForecast: String?
    let probabilityOfPrecipitation: NOAAMeasurement?
}

// MARK: - Unit conversion helpers

extension NOAAMeasurement {
    /// Convert a measurement to imperial value based on unitCode.
    /// Celsius → Fahrenheit, m/s → mph, Pa → mb, m → miles, etc.
    func imperialValue() -> Double? {
        guard let value = value, let unit = unitCode else { return nil }
        if unit.contains("degC") || unit.contains("degC") {
            return value * 9 / 5 + 32     // °C → °F
        }
        if unit.contains("m_s-1") || unit.contains("km_h-1") {
            let ms = unit.contains("km_h-1") ? value / 3.6 : value
            return ms * 2.23694            // m/s → mph
        }
        if unit.contains("Pa") {
            return value / 100             // Pa → hPa/mb
        }
        if unit.contains("m") && !unit.contains("Pa") && !unit.contains("degC") {
            return value * 0.000621371     // m → miles
        }
        return value
    }

    /// Metric value (pass-through, converted as needed).
    func metricValue() -> Double? {
        guard let value = value, let unit = unitCode else { return nil }
        if unit.contains("Pa") { return value / 100 }   // Pa → hPa
        return value
    }
}

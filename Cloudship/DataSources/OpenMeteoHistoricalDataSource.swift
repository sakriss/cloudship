//
//  OpenMeteoHistoricalDataSource.swift
//  Cloudship
//
//  Fetches historical weather from Open-Meteo's Archive API.
//  Same response models as forecast (identical JSON shape).
//  Returns UnifiedWeatherData with hourly + daily only (no minutely for historical).
//

import Foundation

class OpenMeteoHistoricalDataSource {

    // MARK: - Fetch historical weather for a single date

    func fetchWeather(lat: Double, lon: Double, date: Date) async throws -> UnifiedWeatherData {
        let imperial = TemperatureFormatter.apiUnits == "imperial"
        let forecast = try await fetchArchive(lat: lat, lon: lon, date: date, imperial: imperial)
        return buildUnified(forecast: forecast, imperial: imperial, date: date)
    }

    // MARK: - API call

    private func fetchArchive(lat: Double, lon: Double, date: Date, imperial: Bool) async throws -> OpenMeteoForecastResponse {
        let tempUnit   = imperial ? "fahrenheit" : "celsius"
        let windUnit   = imperial ? "mph" : "kmh"
        let precipUnit = imperial ? "inch" : "mm"

        let dateStr = Self.dayFormatter.string(from: date)

        let hourlyVars = [
            "temperature_2m", "apparent_temperature", "precipitation_probability",
            "precipitation", "weather_code", "wind_speed_10m", "wind_gusts_10m",
            "wind_direction_10m", "uv_index", "relative_humidity_2m",
            "cloud_cover", "visibility", "surface_pressure"
        ].joined(separator: ",")

        let dailyVars = [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "apparent_temperature_max", "apparent_temperature_min",
            "precipitation_sum", "precipitation_probability_max",
            "sunrise", "sunset", "uv_index_max"
        ].joined(separator: ",")

        var comps = URLComponents(string: "https://archive-api.open-meteo.com/v1/archive")!
        comps.queryItems = [
            .init(name: "latitude",           value: String(format: "%.4f", lat)),
            .init(name: "longitude",          value: String(format: "%.4f", lon)),
            .init(name: "start_date",         value: dateStr),
            .init(name: "end_date",           value: dateStr),
            .init(name: "hourly",             value: hourlyVars),
            .init(name: "daily",              value: dailyVars),
            .init(name: "timezone",           value: "auto"),
            .init(name: "temperature_unit",   value: tempUnit),
            .init(name: "wind_speed_unit",    value: windUnit),
            .init(name: "precipitation_unit", value: precipUnit)
        ]

        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw HistoricalWeatherError.apiError(http.statusCode)
        }
        return try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
    }

    // MARK: - Build unified model

    private func buildUnified(forecast: OpenMeteoForecastResponse, imperial: Bool, date: Date) -> UnifiedWeatherData {
        let hourly  = buildHourly(forecast.hourly, imperial: imperial)
        let daily   = buildDaily(forecast.daily)

        // Build a synthetic "current" from the hourly entry closest to midday
        let current = buildCurrentFromHourly(hourly, date: date)

        return UnifiedWeatherData(
            locationName: nil,
            current:      current,
            hourly:       hourly,
            daily:        daily,
            minutely:     [],     // no minutely for historical data
            alerts:       [],
            airQuality:   nil,
            pollen:       nil
        )
    }

    /// Build synthetic current conditions from the hourly entry closest to midday
    private func buildCurrentFromHourly(_ hourly: [HourlyEntry], date: Date) -> CurrentConditions {
        // Pick the noon entry, or first available
        let calendar = Calendar.current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        let closest = hourly.min(by: { abs($0.time.timeIntervalSince(noon)) < abs($1.time.timeIntervalSince(noon)) })

        return CurrentConditions(
            temperature:   closest?.temp,
            feelsLike:     closest?.feelsLike,
            humidity:      closest?.humidity,
            windSpeed:     closest?.windSpeed,
            windGust:      closest?.windGust,
            windDirection: closest?.windDirection,
            condition:     closest?.condition ?? .unknown,
            uvIndex:       closest?.uvIndex,
            visibility:    closest?.visibility,
            pressure:      closest?.pressure,
            dewPoint:      nil,
            cloudCover:    closest?.cloudCover
        )
    }

    // MARK: - Hourly

    private func buildHourly(_ h: OpenMeteoHourly?, imperial: Bool) -> [HourlyEntry] {
        guard let h = h, let times = h.time else { return [] }

        return times.enumerated().compactMap { i, timeStr -> HourlyEntry? in
            guard let date = parseDate(timeStr) else { return nil }
            let pressure = h.surfacePressure?[safe: i] ?? nil
            return HourlyEntry(
                time:          date,
                temp:          h.temperature2m?[safe: i] ?? nil,
                feelsLike:     h.apparentTemperature?[safe: i] ?? nil,
                condition:     WeatherCodeMapper.condition(fromWMOCode: h.weatherCode?[safe: i] ?? nil),
                precipChance:  (h.precipitationProbability?[safe: i] ?? nil).map(Double.init),
                precipAmount:  h.precipitation?[safe: i] ?? nil,
                windSpeed:     h.windSpeed10m?[safe: i] ?? nil,
                windGust:      h.windGusts10m?[safe: i] ?? nil,
                windDirection: h.windDirection10m?[safe: i] ?? nil,
                uvIndex:       h.uvIndex?[safe: i] ?? nil,
                humidity:      (h.relativeHumidity2m?[safe: i] ?? nil).map(Double.init),
                cloudCover:    (h.cloudCover?[safe: i] ?? nil).map(Double.init),
                visibility:    (h.visibility?[safe: i] ?? nil).map { imperial ? $0 / 5280.0 : $0 / 1000.0 },
                pressure:      pressure.map { imperial ? $0 * 0.02953 : $0 }
            )
        }
    }

    // MARK: - Daily

    private func buildDaily(_ d: OpenMeteoDaily?) -> [DailyEntry] {
        guard let d = d, let times = d.time else { return [] }

        return times.enumerated().compactMap { i, timeStr -> DailyEntry? in
            guard let date = parseDayDate(timeStr) else { return nil }

            let sunriseStr = d.sunrise?[safe: i] ?? nil
            let sunsetStr  = d.sunset?[safe: i] ?? nil

            return DailyEntry(
                time:             date,
                tempMin:          d.temperature2mMin?[safe: i] ?? nil,
                tempMax:          d.temperature2mMax?[safe: i] ?? nil,
                feelsLikeMin:     d.apparentTemperatureMin?[safe: i] ?? nil,
                feelsLikeMax:     d.apparentTemperatureMax?[safe: i] ?? nil,
                condition:        WeatherCodeMapper.condition(fromWMOCode: d.weatherCode?[safe: i] ?? nil),
                conditionNight:   WeatherCodeMapper.condition(fromWMOCode: d.weatherCode?[safe: i] ?? nil),
                precipChance:     (d.precipitationProbabilityMax?[safe: i] ?? nil).map(Double.init),
                precipAmount:     d.precipitationSum?[safe: i] ?? nil,
                sunrise:          sunriseStr.flatMap { self.parseDate($0) },
                sunset:           sunsetStr.flatMap  { self.parseDate($0) },
                moonPhase:        d.moonPhase?[safe: i] ?? nil,
                dayDescription:   nil,
                nightDescription: nil
            )
        }
    }

    // MARK: - Date helpers

    private func parseDate(_ string: String) -> Date? {
        DateFormatHelper.date(from: string) ?? parseLocalDateTime(string)
    }

    private func parseLocalDateTime(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string)
    }

    private func parseDayDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Errors

enum HistoricalWeatherError: Error, LocalizedError {
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .apiError(let code): return "Historical weather API error (HTTP \(code))"
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

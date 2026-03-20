//
//  OpenMeteoDataSource.swift
//  Cloudship
//
//  Open-Meteo weather data source. Free, no API key, global coverage.
//  https://open-meteo.com
//
//  Fetches forecast + air quality in parallel, maps to UnifiedWeatherData.
//

import Foundation

class OpenMeteoDataSource: WeatherDataSource {

    let name = "Open-Meteo"

    // MARK: - WeatherDataSource

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        let imperial = units == "imperial"

        async let forecast  = fetchForecast(lat: lat, lon: lon, imperial: imperial)
        async let airQuality = fetchAirQuality(lat: lat, lon: lon)

        let (fc, aq) = try await (forecast, airQuality)
        return buildUnified(forecast: fc, airQuality: aq, imperial: imperial)
    }

    // MARK: - Fetch

    private func fetchForecast(lat: Double, lon: Double, imperial: Bool) async throws -> OpenMeteoForecastResponse {
        let tempUnit  = imperial ? "fahrenheit" : "celsius"
        let windUnit  = imperial ? "mph" : "kmh"
        let precipUnit = imperial ? "inch" : "mm"

        let currentVars = [
            "temperature_2m", "relative_humidity_2m", "apparent_temperature",
            "precipitation", "weather_code", "cloud_cover",
            "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m",
            "uv_index", "surface_pressure", "visibility", "dew_point_2m"
        ].joined(separator: ",")

        let hourlyVars = "temperature_2m,precipitation_probability,weather_code,wind_gusts_10m"

        let dailyVars = [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "apparent_temperature_max", "apparent_temperature_min",
            "precipitation_sum", "precipitation_probability_max",
            "sunrise", "sunset", "uv_index_max"
            // moon_phase is not a valid Open-Meteo forecast variable
        ].joined(separator: ",")

        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude",           value: String(format: "%.4f", lat)),
            .init(name: "longitude",          value: String(format: "%.4f", lon)),
            .init(name: "current",            value: currentVars),
            .init(name: "hourly",             value: hourlyVars),
            .init(name: "daily",              value: dailyVars),
            .init(name: "timezone",           value: "auto"),
            .init(name: "temperature_unit",   value: tempUnit),
            .init(name: "wind_speed_unit",    value: windUnit),
            .init(name: "precipitation_unit", value: precipUnit),
            .init(name: "forecast_days",      value: "7")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
    }

    private func fetchAirQuality(lat: Double, lon: Double) async throws -> OpenMeteoAirQualityResponse {
        var comps = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        comps.queryItems = [
            .init(name: "latitude",      value: String(format: "%.4f", lat)),
            .init(name: "longitude",     value: String(format: "%.4f", lon)),
            .init(name: "current",       value: "us_aqi"),
            .init(name: "hourly",        value: "birch_pollen,grass_pollen,ragweed_pollen"),
            .init(name: "timezone",      value: "auto"),
            .init(name: "forecast_days", value: "1")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(OpenMeteoAirQualityResponse.self, from: data)
    }

    // MARK: - Build unified model

    private func buildUnified(forecast: OpenMeteoForecastResponse,
                               airQuality: OpenMeteoAirQualityResponse,
                               imperial: Bool) -> UnifiedWeatherData {

        let current  = buildCurrent(forecast.current, imperial: imperial)
        let hourly   = buildHourly(forecast.hourly)
        let daily    = buildDaily(forecast.daily)
        let aq       = buildAirQuality(airQuality)
        let pollen   = buildPollen(airQuality.hourly)

        return UnifiedWeatherData(
            locationName: nil,
            current:      current,
            hourly:       hourly,
            daily:        daily,
            minutely:     [],   // Open-Meteo doesn't provide minutely
            alerts:       [],   // populated by WeatherDataSourceManager
            airQuality:   aq,
            pollen:       pollen
        )
    }

    // MARK: - Current conditions

    private func buildCurrent(_ c: OpenMeteoCurrent?, imperial: Bool) -> CurrentConditions {
        // Visibility: Open-Meteo returns feet (imperial) or meters (metric)
        let visibilityConverted: Double? = {
            guard let v = c?.visibility else { return nil }
            return imperial ? v / 5280.0 : v / 1000.0  // feet→miles or meters→km
        }()

        // Pressure: hPa -> inHg for imperial, keep hPa for metric
        let pressureConverted: Double? = {
            guard let p = c?.surfacePressure else { return nil }
            return imperial ? p * 0.02953 : p
        }()

        return CurrentConditions(
            temperature:   c?.temperature2m,
            feelsLike:     c?.apparentTemperature,
            humidity:      c?.relativeHumidity2m.map(Double.init),
            windSpeed:     c?.windSpeed10m,
            windGust:      c?.windGusts10m,
            windDirection: c?.windDirection10m,
            condition:     WeatherCodeMapper.condition(fromWMOCode: c?.weatherCode),
            uvIndex:       c?.uvIndex,
            visibility:    visibilityConverted,
            pressure:      pressureConverted,
            dewPoint:      c?.dewPoint2m,
            cloudCover:    c?.cloudCover.map(Double.init)
        )
    }

    // MARK: - Hourly

    private func buildHourly(_ h: OpenMeteoHourly?) -> [HourlyEntry] {
        guard let h = h,
              let times = h.time else { return [] }

        // Open-Meteo returns 7 days × 24 hours. Filter to entries starting
        // from the current hour so the card shows upcoming weather, not today's past hours.
        let now = Date().addingTimeInterval(-1800) // half-hour tolerance
        var count = 0
        return times.enumerated().compactMap { i, timeStr -> HourlyEntry? in
            guard count < 24 else { return nil }
            guard let date = parseDate(timeStr) else { return nil }
            guard date >= now else { return nil }
            count += 1
            return HourlyEntry(
                time:         date,
                temp:         h.temperature2m?[safe: i] ?? nil,
                condition:    WeatherCodeMapper.condition(fromWMOCode: h.weatherCode?[safe: i] ?? nil),
                precipChance: (h.precipitationProbability?[safe: i] ?? nil).map(Double.init),
                windGust:     h.windGusts10m?[safe: i] ?? nil
            )
        }
    }

    // MARK: - Daily

    private func buildDaily(_ d: OpenMeteoDaily?) -> [DailyEntry] {
        guard let d = d,
              let times = d.time else { return [] }

        return times.prefix(7).enumerated().compactMap { i, timeStr in
            // Daily times are "YYYY-MM-DD" - parse as start of day
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
                sunrise:          sunriseStr.flatMap { parseDate($0) },
                sunset:           sunsetStr.flatMap  { parseDate($0) },
                moonPhase:        d.moonPhase?[safe: i] ?? nil,
                dayDescription:   nil,
                nightDescription: nil
            )
        }
    }

    // MARK: - Air Quality

    private func buildAirQuality(_ aq: OpenMeteoAirQualityResponse) -> AirQualityData? {
        guard let index = aq.current?.usAqi else { return nil }
        return AirQualityData(index: index, category: AirQualityData.AQICategory.from(index: index))
    }

    // MARK: - Pollen

    private func buildPollen(_ hourly: OpenMeteoAirQualityResponse.AQHourly?) -> PollenData? {
        guard let hourly = hourly else { return nil }

        // Use first available hourly value (current hour)
        let birch   = hourly.birchPollen?.first(where: { $0 != nil }) ?? nil
        let grass   = hourly.grassPollen?.first(where: { $0 != nil }) ?? nil
        let ragweed = hourly.ragweedPollen?.first(where: { $0 != nil }) ?? nil

        // If all are nil, pollen data not available for this region
        guard birch != nil || grass != nil || ragweed != nil else { return nil }

        return PollenData(
            tree:  pollenLevel(birch,   thresholds: [1, 11, 51, 201, 501]),
            grass: pollenLevel(grass,   thresholds: [1,  6, 21,  81, 201]),
            weed:  pollenLevel(ragweed, thresholds: [1, 11, 51, 201, 501]),
            mold:  nil
        )
    }

    /// Convert a raw grains/m3 value to a PollenLevel using the provided thresholds.
    /// thresholds[i] is the minimum value for level (i+1): veryLow, low, medium, high, veryHigh
    private func pollenLevel(_ value: Double?, thresholds: [Double]) -> PollenLevel {
        guard let v = value, v > 0 else { return .none }
        for (i, threshold) in thresholds.reversed().enumerated() {
            if v >= threshold { return PollenLevel(rawValue: thresholds.count - i) ?? .veryHigh }
        }
        return .veryLow
    }

    // MARK: - Date helpers

    private let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    /// Parse a full ISO-8601 datetime string like "2026-03-19T15:00"
    private func parseDate(_ string: String) -> Date? {
        // Open-Meteo returns "2026-03-19T15:00" (no seconds, no Z) for hourly/daily times
        // and ISO-8601 with offset for sunrise/sunset.
        return DateFormatHelper.date(from: string)
            ?? parseLocalDateTime(string)
    }

    private func parseLocalDateTime(_ string: String) -> Date? {
        // "2026-03-19T15:00" -- no timezone, treat as local
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string)
    }

    /// Parse a date-only string "2026-03-19" as midnight local time
    private func parseDayDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string)
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

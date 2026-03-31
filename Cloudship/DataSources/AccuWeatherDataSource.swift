//
//  AccuWeatherDataSource.swift
//  Cloudship
//
//  AccuWeather Core Weather data source.
//  Uses the starter tier endpoints: geoposition search, current conditions,
//  5-day daily forecast, and 12-hour hourly forecast.
//  API key is read from Info.plist (via Secrets.xcconfig).
//

import Foundation

class AccuWeatherDataSource: WeatherDataSource {

    let name = "AccuWeather"

    // MARK: - API key (read from Info.plist → Secrets.xcconfig)

    private let apiKey: String = {
        (Bundle.main.infoDictionary?["AccuWeatherAPIKey"] as? String) ?? ""
    }()

    // MARK: - WeatherDataSource

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        guard !apiKey.isEmpty else { throw AccuWeatherError.missingAPIKey }

        let imperial = units == "imperial"

        // Step 1: Resolve location key from coordinates
        let locationKey = try await fetchLocationKey(lat: lat, lon: lon)

        // Step 2: Fetch current conditions, daily, and hourly in parallel
        async let currentTask = fetchCurrentConditions(locationKey: locationKey)
        async let dailyTask   = fetchDailyForecast(locationKey: locationKey, metric: !imperial)
        async let hourlyTask  = fetchHourlyForecast(locationKey: locationKey, metric: !imperial)

        let (currentConditions, dailyResponse, hourlyForecasts) = try await (currentTask, dailyTask, hourlyTask)

        return buildUnified(
            current: currentConditions,
            daily: dailyResponse,
            hourly: hourlyForecasts,
            imperial: imperial
        )
    }

    // MARK: - API calls

    private func fetchLocationKey(lat: Double, lon: Double) async throws -> String {
        guard var comps = URLComponents(string: "https://dataservice.accuweather.com/locations/v1/cities/geoposition/search") else {
            throw AccuWeatherError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "q", value: "\(lat),\(lon)")
        ]
        guard let url = comps.url else { throw AccuWeatherError.invalidURL }

        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        try checkStatus(response, data: data)

        let location = try JSONDecoder().decode(AccuWeatherLocation.self, from: data)
        return location.key
    }

    private func fetchCurrentConditions(locationKey: String) async throws -> AccuWeatherCurrentCondition {
        guard var comps = URLComponents(string: "https://dataservice.accuweather.com/currentconditions/v1/\(locationKey)") else {
            throw AccuWeatherError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "details", value: "true")
        ]
        guard let url = comps.url else { throw AccuWeatherError.invalidURL }

        var req = URLRequest(url: url)
        req.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data: data)

        // Current conditions endpoint returns a JSON array with a single element
        let conditions = try JSONDecoder().decode([AccuWeatherCurrentCondition].self, from: data)
        guard let first = conditions.first else { throw AccuWeatherError.locationNotFound }
        return first
    }

    private func fetchDailyForecast(locationKey: String, metric: Bool) async throws -> AccuWeatherDailyResponse {
        guard var comps = URLComponents(string: "https://dataservice.accuweather.com/forecasts/v1/daily/5day/\(locationKey)") else {
            throw AccuWeatherError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "details", value: "true"),
            URLQueryItem(name: "metric", value: metric ? "true" : "false")
        ]
        guard let url = comps.url else { throw AccuWeatherError.invalidURL }

        var req = URLRequest(url: url)
        req.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data: data)

        return try JSONDecoder().decode(AccuWeatherDailyResponse.self, from: data)
    }

    private func fetchHourlyForecast(locationKey: String, metric: Bool) async throws -> [AccuWeatherHourlyForecast] {
        guard var comps = URLComponents(string: "https://dataservice.accuweather.com/forecasts/v1/hourly/12hour/\(locationKey)") else {
            throw AccuWeatherError.invalidURL
        }
        comps.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "details", value: "true"),
            URLQueryItem(name: "metric", value: metric ? "true" : "false")
        ]
        guard let url = comps.url else { throw AccuWeatherError.invalidURL }

        var req = URLRequest(url: url)
        req.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data: data)

        return try JSONDecoder().decode([AccuWeatherHourlyForecast].self, from: data)
    }

    // MARK: - HTTP status check

    private func checkStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200: return
        case 401, 403: throw AccuWeatherError.unauthorized
        case 429, 503: throw AccuWeatherError.rateLimited
        default:
            if http.statusCode != 200 {
                throw AccuWeatherError.httpError(http.statusCode)
            }
        }
    }

    // MARK: - Build unified model

    private func buildUnified(
        current: AccuWeatherCurrentCondition,
        daily: AccuWeatherDailyResponse,
        hourly: [AccuWeatherHourlyForecast],
        imperial: Bool
    ) -> UnifiedWeatherData {

        let unitKey: KeyPath<AWMeasurement, AWUnitValue?> = imperial ? \.imperial : \.metric

        // Current conditions
        let currentConditions = CurrentConditions(
            temperature:  current.temperature?[keyPath: unitKey]?.value,
            feelsLike:    current.realFeelTemperature?[keyPath: unitKey]?.value,
            humidity:     current.relativeHumidity,
            windSpeed:    current.wind?.speed?[keyPath: unitKey]?.value,
            windGust:     current.windGust?.speed?[keyPath: unitKey]?.value,
            windDirection: current.wind?.direction?.degrees,
            condition:    WeatherCodeMapper.condition(fromAccuWeatherIcon: current.weatherIcon),
            uvIndex:      current.uvIndex,
            visibility:   current.visibility?[keyPath: unitKey]?.value,
            pressure:     current.pressure?[keyPath: unitKey]?.value,
            dewPoint:     current.dewPoint?[keyPath: unitKey]?.value,
            cloudCover:   current.cloudCover
        )

        // Hourly entries (up to 12)
        let hourlyEntries: [HourlyEntry] = hourly.prefix(12).compactMap { h in
            guard let epoch = h.epochDateTime else { return nil }
            let time = Date(timeIntervalSince1970: TimeInterval(epoch))
            return HourlyEntry(
                time:          time,
                temp:          h.temperature?.value,
                feelsLike:     h.realFeelTemperature?.value,
                condition:     WeatherCodeMapper.condition(fromAccuWeatherIcon: h.weatherIcon),
                precipChance:  h.precipitationProbability,
                precipAmount:  h.totalLiquid?.value,
                windSpeed:     h.wind?.speed?[keyPath: unitKey]?.value,
                windGust:      h.windGust?.speed?[keyPath: unitKey]?.value,
                windDirection: h.wind?.direction?.degrees,
                uvIndex:       h.uvIndex,
                humidity:      h.relativeHumidity,
                cloudCover:    h.cloudCover,
                visibility:    h.visibility?.value,
                pressure:      nil   // not in hourly response
            )
        }

        // Daily entries (up to 5)
        let dailyEntries: [DailyEntry] = (daily.dailyForecasts ?? []).prefix(5).compactMap { d in
            guard let epoch = d.epochDate else { return nil }
            let time = Date(timeIntervalSince1970: TimeInterval(epoch))

            let dayCond  = WeatherCodeMapper.condition(fromAccuWeatherIcon: d.day?.icon)
            let nightCond = WeatherCodeMapper.condition(fromAccuWeatherIcon: d.night?.icon)

            // Moon phase: map AccuWeather phase name to 0-1 range
            let moonPhase = mapMoonPhase(d.moon?.phase)

            return DailyEntry(
                time:             time,
                tempMin:          d.temperature?.minimum?.value,
                tempMax:          d.temperature?.maximum?.value,
                feelsLikeMin:     d.realFeelTemperature?.minimum?.value,
                feelsLikeMax:     d.realFeelTemperature?.maximum?.value,
                condition:        dayCond,
                conditionNight:   nightCond,
                precipChance:     d.day?.precipitationProbability,
                precipAmount:     d.day?.totalLiquid?.value,
                sunrise:          d.sun?.epochRise.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                sunset:           d.sun?.epochSet.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                moonPhase:        moonPhase,
                dayDescription:   d.day?.iconPhrase,
                nightDescription: d.night?.iconPhrase
            )
        }

        return UnifiedWeatherData(
            locationName: nil,       // set externally via geocoder
            current:      currentConditions,
            hourly:       hourlyEntries,
            daily:        dailyEntries,
            minutely:     [],        // not available on starter tier
            alerts:       [],        // populated by WeatherDataSourceManager
            airQuality:   nil,       // not available on starter tier
            pollen:       nil        // not available on starter tier
        )
    }

    // MARK: - Helpers

    /// Maps AccuWeather moon phase name to a 0–1 value.
    private func mapMoonPhase(_ phase: String?) -> Double? {
        guard let phase = phase?.lowercased() else { return nil }
        switch phase {
        case "new":            return 0.0
        case "waxing crescent": return 0.125
        case "first quarter", "first":  return 0.25
        case "waxing gibbous": return 0.375
        case "full":           return 0.5
        case "waning gibbous": return 0.625
        case "last quarter", "third quarter", "last": return 0.75
        case "waning crescent": return 0.875
        default:               return nil
        }
    }
}

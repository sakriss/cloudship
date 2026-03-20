//
//  TomorrowIODataSource.swift
//  Cloudship
//
//  Tomorrow.io v4 REST API data source.
//  Fetches realtime + forecast and maps to UnifiedWeatherData.
//

import Foundation

class TomorrowIODataSource: WeatherDataSource {

    let name = "Tomorrow.io"

    private let apiKey = "KQXY4gdDsX3eiTsTJx8oG6UELO1S6zyM"

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        async let realtime = fetchRealtime(lat: lat, lon: lon, units: units)
        async let forecast = fetchForecast(lat: lat, lon: lon, units: units)

        let (rt, fc) = try await (realtime, forecast)
        return buildUnified(realtime: rt, forecast: fc, units: units)
    }

    // MARK: - Private fetch methods

    private func fetchRealtime(lat: Double, lon: Double, units: String) async throws -> ClimacellV4 {
        var comps = URLComponents(string: "https://api.tomorrow.io/v4/weather/realtime")!
        comps.queryItems = [
            URLQueryItem(name: "location", value: "\(lat),\(lon)"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "units", value: units)
        ]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data: data, endpoint: "realtime")
        return try JSONDecoder().decode(ClimacellV4.self, from: data)
    }

    private func fetchForecast(lat: Double, lon: Double, units: String) async throws -> ClimacellV4.ForecastResponse {
        var comps = URLComponents(string: "https://api.tomorrow.io/v4/weather/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "location", value: "\(lat),\(lon)"),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "units", value: units)
        ]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkStatus(response, data: data, endpoint: "forecast")
        return try JSONDecoder().decode(ClimacellV4.ForecastResponse.self, from: data)
    }

    /// Throws a descriptive error for non-2xx HTTP responses.
    private func checkStatus(_ response: URLResponse, data: Data, endpoint: String) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard http.statusCode == 200 else {
            // Try to extract error message from Tomorrow.io error JSON
            let message: String
            if let errorBody = try? JSONDecoder().decode(TomorrowIOError.self, from: data) {
                message = errorBody.message ?? "HTTP \(http.statusCode)"
            } else {
                message = "HTTP \(http.statusCode)"
            }
            throw NSError(domain: "TomorrowIO", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Tomorrow.io \(endpoint): \(message)"])
        }
    }

    private struct TomorrowIOError: Codable {
        let code: Int?
        let type: String?
        let message: String?
    }

    // MARK: - Map to unified model

    private func buildUnified(realtime: ClimacellV4,
                               forecast: ClimacellV4.ForecastResponse,
                               units: String) -> UnifiedWeatherData {
        let rv = realtime.realtime?.values

        let current = CurrentConditions(
            temperature:  rv?.temperature,
            feelsLike:    rv?.temperatureApparent,
            humidity:     rv?.humidity,
            windSpeed:    rv?.windSpeed,
            windGust:     rv?.windGust,
            windDirection: rv?.windDirection,
            condition:    WeatherCodeMapper.condition(fromTomorrowCode: rv?.weatherCode),
            uvIndex:      rv?.uvIndex,
            visibility:   rv?.visibility,
            pressure:     rv?.pressureSurfaceLevel,
            dewPoint:     rv?.dewPoint,
            cloudCover:   rv?.cloudCover
        )

        let hourly: [HourlyEntry] = (forecast.timelines?.hourly ?? []).prefix(24).compactMap { entry in
            guard let time = DateFormatHelper.date(from: entry.time) else { return nil }
            return HourlyEntry(
                time:         time,
                temp:         entry.values?.temperature,
                condition:    WeatherCodeMapper.condition(fromTomorrowCode: entry.values?.weatherCode),
                precipChance: entry.values?.precipitationProbability,
                windGust:     entry.values?.windGust
            )
        }

        let daily: [DailyEntry] = (forecast.timelines?.daily ?? []).prefix(7).compactMap { entry in
            guard let time = DateFormatHelper.date(from: entry.time) else { return nil }
            let v = entry.values
            // Daily uses weatherCodeAvg (not weatherCode which is hourly-only)
            let dayCode   = v?.weatherCodeAvg
            let nightCode = v?.weatherCodeMax   // closest proxy to "most severe" condition
            let cond      = WeatherCodeMapper.condition(fromTomorrowCode: dayCode)
            let condNight = WeatherCodeMapper.condition(fromTomorrowCode: nightCode)
            return DailyEntry(
                time:             time,
                tempMin:          v?.temperatureMin,
                tempMax:          v?.temperatureMax,
                feelsLikeMin:     v?.temperatureApparentMin,
                feelsLikeMax:     v?.temperatureApparentMax,
                condition:        cond,
                conditionNight:   condNight,
                precipChance:     v?.precipitationProbabilityAvg ?? v?.precipitationProbability,
                precipAmount:     v?.rainAccumulationSum,
                sunrise:          DateFormatHelper.date(from: v?.sunriseTime),
                sunset:           DateFormatHelper.date(from: v?.sunsetTime),
                moonPhase:        nil,   // Not in free tier; use moonriseTime/moonsetTime
                dayDescription:   cond.description,
                nightDescription: condNight.description
            )
        }

        let minutely: [MinutelyEntry] = (forecast.timelines?.minutely ?? []).prefix(60).compactMap { entry in
            guard let time = DateFormatHelper.date(from: entry.time) else { return nil }
            let rain     = entry.values?.rainIntensity ?? 0
            let snow     = entry.values?.snowIntensity ?? 0
            let sleet    = entry.values?.sleetIntensity ?? 0
            let freezing = entry.values?.freezingRainIntensity ?? 0
            let intensity = rain + snow + sleet + freezing
            return MinutelyEntry(time: time, precipIntensity: intensity)
        }

        // Air quality — derived from realtime if epaIndex present
        let airQuality: AirQualityData? = {
            guard let idx = rv?.epaIndex else { return nil }
            return AirQualityData(index: idx, category: AirQualityData.AQICategory.from(index: idx))
        }()

        // Pollen — use today's daily entry pollen data if available,
        // fall back to realtime pollen if present
        let pollen: PollenData? = {
            let todayValues = forecast.timelines?.daily?.first?.values
            let treeRaw  = todayValues?.treeIndex  ?? rv?.treeIndex
            let grassRaw = todayValues?.grassIndex ?? rv?.grassIndex
            let weedRaw  = todayValues?.weedIndex  ?? rv?.weedIndex
            guard treeRaw != nil || grassRaw != nil || weedRaw != nil else { return nil }
            return PollenData(
                tree:  PollenLevel(rawValue: treeRaw  ?? 0) ?? .none,
                grass: PollenLevel(rawValue: grassRaw ?? 0) ?? .none,
                weed:  PollenLevel(rawValue: weedRaw  ?? 0) ?? .none,
                mold:  nil   // Tomorrow.io doesn't currently expose mold index
            )
        }()

        return UnifiedWeatherData(
            locationName: nil,   // set externally via geocoder
            current: current,
            hourly: hourly,
            daily: daily,
            minutely: minutely,
            alerts: [],          // populated by WeatherDataSourceManager
            airQuality: airQuality,
            pollen: pollen
        )
    }
}

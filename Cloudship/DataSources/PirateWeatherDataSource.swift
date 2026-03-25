//
//  PirateWeatherDataSource.swift
//  Cloudship
//
//  Pirate Weather data source — Dark Sky API drop-in replacement.
//  Uses NOAA models (GFS, HRRR, NBM) with 1-minute minutely data,
//  storm proximity, precip uncertainty, and 168h extended hourly.
//  https://pirateweather.net
//

import Foundation

class PirateWeatherDataSource: WeatherDataSource {

    let name = "Pirate Weather"

    // MARK: - WeatherDataSource

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        let imperial = units == "imperial"
        let pwUnits = imperial ? "us" : "si"

        let response = try await fetchForecast(lat: lat, lon: lon, units: pwUnits)
        return buildUnified(response: response, imperial: imperial)
    }

    // MARK: - Fetch

    private func fetchForecast(lat: Double, lon: Double, units: String) async throws -> PirateWeatherResponse {
        let latStr = String(format: "%.4f", lat)
        let lonStr = String(format: "%.4f", lon)

        guard let url = URL(string: "https://api.pirateweather.net/forecast/\(apiKey)/\(latStr),\(lonStr)?units=\(units)&version=2&extend=hourly") else {
            throw PirateWeatherError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200: break
            case 401: throw PirateWeatherError.unauthorized
            case 429: throw PirateWeatherError.rateLimited
            default:  throw PirateWeatherError.httpError(http.statusCode)
            }
        }

        return try JSONDecoder().decode(PirateWeatherResponse.self, from: data)
    }

    // MARK: - API Key

    private let apiKey = "nCmW8159sdpOatt0Sm7a1r3tcflAgDCR"

    // MARK: - Build unified model

    private func buildUnified(response: PirateWeatherResponse, imperial: Bool) -> UnifiedWeatherData {
        let current  = buildCurrent(response.currently, imperial: imperial)
        let hourly   = buildHourly(response.hourly, imperial: imperial)
        let daily    = buildDaily(response.daily, imperial: imperial)
        let minutely = buildMinutely(response.minutely)
        let alerts   = buildAlerts(response.alerts)

        return UnifiedWeatherData(
            locationName: nil,
            current:      current,
            hourly:       hourly,
            daily:        daily,
            minutely:     minutely,
            alerts:       alerts,
            airQuality:   nil,     // Pirate Weather doesn't provide AQI
            pollen:       nil      // Pirate Weather doesn't provide pollen
        )
    }

    // MARK: - Current conditions

    private func buildCurrent(_ c: PWCurrently?, imperial: Bool) -> CurrentConditions {
        CurrentConditions(
            temperature:          c?.temperature,
            feelsLike:            c?.apparentTemperature,
            humidity:             c?.humidity.map { $0 * 100 },  // 0-1 → 0-100
            windSpeed:            c?.windSpeed,
            windGust:             c?.windGust,
            windDirection:        c?.windBearing,
            condition:            WeatherCodeMapper.condition(fromDarkSkyIcon: c?.icon),
            uvIndex:              c?.uvIndex,
            visibility:           c?.visibility,
            pressure:             c?.pressure,
            dewPoint:             c?.dewPoint,
            cloudCover:           c?.cloudCover.map { $0 * 100 },  // 0-1 → 0-100
            nearestStormDistance: c?.nearestStormDistance,
            nearestStormBearing:  c?.nearestStormBearing,
            precipIntensity:      c?.precipIntensity,
            precipType:           c?.precipType
        )
    }

    // MARK: - Hourly

    private func buildHourly(_ h: PWHourlyBlock?, imperial: Bool) -> [HourlyEntry] {
        guard let points = h?.data else { return [] }

        let now = Date().addingTimeInterval(-1800)
        var count = 0

        return points.compactMap { point -> HourlyEntry? in
            guard count < 48 else { return nil }
            guard let timestamp = point.time else { return nil }
            let date = Date(timeIntervalSince1970: timestamp)
            guard date >= now else { return nil }
            count += 1

            return HourlyEntry(
                time:                 date,
                temp:                 point.temperature,
                feelsLike:            point.apparentTemperature,
                condition:            WeatherCodeMapper.condition(fromDarkSkyIcon: point.icon),
                precipChance:         point.precipProbability.map { $0 * 100 },  // 0-1 → 0-100
                precipAmount:         point.precipAccumulation,
                windSpeed:            point.windSpeed,
                windGust:             point.windGust,
                windDirection:        point.windBearing,
                uvIndex:              point.uvIndex,
                humidity:             point.humidity.map { $0 * 100 },
                cloudCover:           point.cloudCover.map { $0 * 100 },
                visibility:           point.visibility,
                pressure:             point.pressure,
                precipIntensityError: point.precipIntensityError,
                precipType:           point.precipType,
                snowAccumulation:     point.snowAccumulation,
                iceAccumulation:      point.iceAccumulation
            )
        }
    }

    // MARK: - Daily

    private func buildDaily(_ d: PWDailyBlock?, imperial: Bool) -> [DailyEntry] {
        guard let points = d?.data else { return [] }

        return points.prefix(7).compactMap { point -> DailyEntry? in
            guard let timestamp = point.time else { return nil }
            let date = Date(timeIntervalSince1970: timestamp)

            return DailyEntry(
                time:              date,
                tempMin:           point.temperatureMin ?? point.temperatureLow,
                tempMax:           point.temperatureMax ?? point.temperatureHigh,
                feelsLikeMin:      point.apparentTemperatureLow.map { min($0, point.apparentTemperatureMin ?? $0) },
                feelsLikeMax:      point.apparentTemperatureHigh.map { max($0, point.apparentTemperatureMax ?? $0) },
                condition:         WeatherCodeMapper.condition(fromDarkSkyIcon: point.icon),
                conditionNight:    WeatherCodeMapper.condition(fromDarkSkyIcon: point.icon),
                precipChance:      point.precipProbability.map { $0 * 100 },
                precipAmount:      point.precipAccumulation,
                sunrise:           point.sunriseTime.map { Date(timeIntervalSince1970: $0) },
                sunset:            point.sunsetTime.map { Date(timeIntervalSince1970: $0) },
                moonPhase:         point.moonPhase,
                dayDescription:    point.summary,
                nightDescription:  nil,
                windSpeed:         point.windSpeed,
                windGust:          point.windGust,
                uvIndex:           point.uvIndex,
                humidity:          point.humidity.map { $0 * 100 }, // 0–1 → 0–100%
                cloudCover:        point.cloudCover.map { $0 * 100 },
                visibility:        point.visibility,
                pressure:          point.pressure,
                dawnTime:          point.dawnTime.map { Date(timeIntervalSince1970: $0) },
                duskTime:          point.duskTime.map { Date(timeIntervalSince1970: $0) },
                snowAccumulation:  point.snowAccumulation,
                iceAccumulation:   point.iceAccumulation
            )
        }
    }

    // MARK: - Minutely

    private func buildMinutely(_ m: PWMinutelyBlock?) -> [MinutelyEntry] {
        guard let points = m?.data else { return [] }

        return points.compactMap { point -> MinutelyEntry? in
            guard let timestamp = point.time else { return nil }
            return MinutelyEntry(
                time:              Date(timeIntervalSince1970: timestamp),
                precipIntensity:   point.precipIntensity,
                precipProbability: point.precipProbability,
                precipType:        point.precipType
            )
        }
    }

    // MARK: - Alerts

    private func buildAlerts(_ pwAlerts: [PWAlert]?) -> [WeatherAlert] {
        guard let pwAlerts = pwAlerts else { return [] }

        return pwAlerts.compactMap { alert -> WeatherAlert? in
            guard let title = alert.title else { return nil }

            let severity: AlertSeverity
            switch alert.severity?.lowercased() {
            case "extreme":  severity = .extreme
            case "severe":   severity = .severe
            case "moderate": severity = .moderate
            case "minor":    severity = .minor
            default:         severity = .unknown
            }

            return WeatherAlert(
                event:       title,
                headline:    title,
                description: alert.description ?? "",
                instruction: nil,
                severity:    severity,
                onset:       alert.time.map { Date(timeIntervalSince1970: $0) },
                expires:     alert.expires.map { Date(timeIntervalSince1970: $0) },
                areaDesc:    alert.regions?.joined(separator: ", "),
                source:      "Pirate Weather"
            )
        }
        .sorted { $0.severity > $1.severity }
    }
}

// MARK: - Errors

enum PirateWeatherError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:    return "Invalid Pirate Weather URL."
        case .unauthorized:  return "Pirate Weather API key is invalid."
        case .rateLimited:   return "Pirate Weather monthly API limit reached."
        case .httpError(let code): return "Pirate Weather returned HTTP \(code)."
        }
    }
}

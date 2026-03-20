//
//  NOAADataSource.swift
//  Cloudship
//
//  NOAA api.weather.gov data source. Free, no API key. US-only.
//  Throws NOAAError.outsideUS for non-US locations so the manager
//  can fall back gracefully.
//

import Foundation

enum NOAAError: LocalizedError {
    case outsideUS
    case noStationsFound
    case missingGridData

    var errorDescription: String? {
        switch self {
        case .outsideUS:        return "NOAA weather is only available for US locations."
        case .noStationsFound:  return "No NOAA observation stations found near this location."
        case .missingGridData:  return "NOAA could not locate a forecast grid for this location."
        }
    }
}

class NOAADataSource: WeatherDataSource {

    let name = "NOAA"

    // NOAA requires a descriptive User-Agent per their API terms
    private let userAgent = "Cloudship iOS App (contact@cloudshipapp.com)"

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        // Step 1: Get grid info
        let points = try await fetchPoints(lat: lat, lon: lon)
        guard let gridId = points.properties?.gridId,
              let gridX = points.properties?.gridX,
              let gridY = points.properties?.gridY else {
            throw NOAAError.missingGridData
        }

        // Step 2: Get nearest observation station
        guard let stationsURL = points.properties?.observationStations else {
            throw NOAAError.noStationsFound
        }
        let stationId = try await fetchNearestStationId(from: stationsURL)

        // Step 3: Fetch current obs + hourly + daily in parallel
        async let obs = fetchObservation(stationId: stationId)
        async let hourlyForecast = fetchForecast(gridId: gridId, gridX: gridX, gridY: gridY, hourly: true)
        async let dailyForecast = fetchForecast(gridId: gridId, gridX: gridX, gridY: gridY, hourly: false)

        let (observation, hourly, daily) = try await (obs, hourlyForecast, dailyForecast)
        return buildUnified(observation: observation, hourlyPeriods: hourly, dailyPeriods: daily, units: units)
    }

    // MARK: - Private fetch methods

    private func fetchPoints(lat: Double, lon: Double) async throws -> NOAAPointsResponse {
        // Round to 4 decimal places as NOAA requires
        let latStr = String(format: "%.4f", lat)
        let lonStr = String(format: "%.4f", lon)
        let url = URL(string: "https://api.weather.gov/points/\(latStr),\(lonStr)")!
        let (data, response) = try await makeRequest(url: url)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw NOAAError.outsideUS
        }
        return try JSONDecoder().decode(NOAAPointsResponse.self, from: data)
    }

    private func fetchNearestStationId(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw NOAAError.noStationsFound }
        let (data, _) = try await makeRequest(url: url)
        let stations = try JSONDecoder().decode(NOAAStationsResponse.self, from: data)
        guard let id = stations.features?.first?.properties?.stationIdentifier else {
            throw NOAAError.noStationsFound
        }
        return id
    }

    private func fetchObservation(stationId: String) async throws -> NOAAObservationResponse {
        let url = URL(string: "https://api.weather.gov/stations/\(stationId)/observations/latest")!
        let (data, _) = try await makeRequest(url: url)
        return try JSONDecoder().decode(NOAAObservationResponse.self, from: data)
    }

    private func fetchForecast(gridId: String, gridX: Int, gridY: Int, hourly: Bool) async throws -> [NOAAForecastPeriod] {
        let path = hourly ? "forecast/hourly" : "forecast"
        let url = URL(string: "https://api.weather.gov/gridpoints/\(gridId)/\(gridX),\(gridY)/\(path)")!
        let (data, _) = try await makeRequest(url: url)
        let fc = try JSONDecoder().decode(NOAAForecastResponse.self, from: data)
        return fc.properties?.periods ?? []
    }

    private func makeRequest(url: URL) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        return try await URLSession.shared.data(for: req)
    }

    // MARK: - Map to unified model

    private func buildUnified(observation: NOAAObservationResponse,
                               hourlyPeriods: [NOAAForecastPeriod],
                               dailyPeriods: [NOAAForecastPeriod],
                               units: String) -> UnifiedWeatherData {
        let obs = observation.properties
        let useImperial = units == "imperial"

        // Current conditions
        let tempRaw = useImperial ? obs?.temperature?.imperialValue() : obs?.temperature?.metricValue()
        let feelsLike: Double? = {
            if let heatIndex = obs?.heatIndex?.imperialValue(), heatIndex > (tempRaw ?? 0) { return useImperial ? heatIndex : obs?.heatIndex?.metricValue() }
            if let windChill = obs?.windChill?.imperialValue() { return useImperial ? windChill : obs?.windChill?.metricValue() }
            return tempRaw
        }()

        let current = CurrentConditions(
            temperature:  tempRaw,
            feelsLike:    feelsLike,
            humidity:     obs?.relativeHumidity?.value,
            windSpeed:    useImperial ? obs?.windSpeed?.imperialValue() : obs?.windSpeed?.metricValue(),
            windGust:     useImperial ? obs?.windGust?.imperialValue() : obs?.windGust?.metricValue(),
            windDirection: obs?.windDirection?.value,
            condition:    WeatherCodeMapper.condition(fromNOAADescription: obs?.textDescription),
            uvIndex:      nil,   // NOAA observations don't include UV
            visibility:   useImperial ? obs?.visibility?.imperialValue() : obs?.visibility?.metricValue(),
            pressure:     useImperial ? obs?.barometricPressure?.imperialValue() : obs?.barometricPressure?.metricValue(),
            dewPoint:     useImperial ? obs?.dewpoint?.imperialValue() : obs?.dewpoint?.metricValue(),
            cloudCover:   cloudCoverPercent(from: obs?.cloudLayers)
        )

        // Hourly entries (first 24, daytime only periods work fine as-is since NOAA hourly has 1-hr intervals)
        let hourly: [HourlyEntry] = hourlyPeriods.prefix(24).compactMap { period in
            guard let timeStr = period.startTime,
                  let time = DateFormatHelper.date(from: timeStr),
                  let temp = period.temperature else { return nil }
            // NOAA hourly temp is already in the requested unit
            let tempConverted = convertPeriodTemp(temp, unit: period.temperatureUnit, targetImperial: useImperial)
            return HourlyEntry(
                time:         time,
                temp:         tempConverted,
                condition:    WeatherCodeMapper.condition(fromNOAADescription: period.shortForecast),
                precipChance: period.probabilityOfPrecipitation?.value,
                windGust:     nil   // NOAA hourly doesn't give gust in structured form
            )
        }

        // Daily entries: NOAA daily has separate day/night periods; take daytime periods
        let daytimePeriods = dailyPeriods.filter { $0.isDaytime == true }.prefix(7)
        let nightPeriods = dailyPeriods.filter { $0.isDaytime == false }

        let daily: [DailyEntry] = daytimePeriods.compactMap { period in
            guard let timeStr = period.startTime,
                  let time = DateFormatHelper.date(from: timeStr),
                  let tempMax = period.temperature else { return nil }
            let maxConverted = convertPeriodTemp(tempMax, unit: period.temperatureUnit, targetImperial: useImperial)

            // Find matching night period for low temp + description
            let dayNum = period.number ?? 0
            let nightPeriod = nightPeriods.first(where: { ($0.number ?? 0) == dayNum + 1 })
            let nightMin = nightPeriod?.temperature
            let minConverted = nightMin.map { convertPeriodTemp($0, unit: period.temperatureUnit, targetImperial: useImperial) }
            let nightCondition = WeatherCodeMapper.condition(fromNOAADescription: nightPeriod?.shortForecast)

            return DailyEntry(
                time:             time,
                tempMin:          minConverted,
                tempMax:          maxConverted,
                feelsLikeMin:     nil,
                feelsLikeMax:     nil,
                condition:        WeatherCodeMapper.condition(fromNOAADescription: period.shortForecast),
                conditionNight:   nightCondition,
                precipChance:     period.probabilityOfPrecipitation?.value,
                precipAmount:     nil,
                sunrise:          nil,   // NOAA doesn't provide structured sunrise in this endpoint
                sunset:           nil,
                moonPhase:        nil,
                dayDescription:   period.detailedForecast,
                nightDescription: nightPeriod?.detailedForecast
            )
        }

        return UnifiedWeatherData(
            locationName: nil,
            current: current,
            hourly: Array(hourly),
            daily: Array(daily),
            minutely: [],      // NOAA doesn't provide minutely data
            alerts: [],        // populated by WeatherDataSourceManager
            airQuality: nil,   // NOAA doesn't expose AQI
            pollen: nil        // NOAA doesn't expose pollen
        )
    }

    // MARK: - Helpers

    private func cloudCoverPercent(from layers: [NOAACloudLayer]?) -> Double? {
        guard let layers = layers, !layers.isEmpty else { return nil }
        let highest = layers.compactMap { $0.amount }.last
        switch highest {
        case "CLR", "SKC": return 0
        case "FEW":        return 15
        case "SCT":        return 40
        case "BKN":        return 70
        case "OVC", "VV":  return 100
        default:           return nil
        }
    }

    private func convertPeriodTemp(_ temp: Double, unit: String?, targetImperial: Bool) -> Double {
        let isF = unit == "F"
        if targetImperial && !isF { return temp * 9/5 + 32 }
        if !targetImperial && isF { return (temp - 32) * 5/9 }
        return temp
    }
}

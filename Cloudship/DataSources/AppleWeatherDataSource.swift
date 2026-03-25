//
//  AppleWeatherDataSource.swift
//  Cloudship
//
//  Premium weather data source using Apple's WeatherKit framework.
//  Requires WeatherKit capability and iOS 16+.
//

import Foundation
import WeatherKit
import CoreLocation

class AppleWeatherDataSource: WeatherDataSource {

    var name: String { "Apple Weather" }

    private let service = WeatherService.shared

    func fetchWeather(lat: Double, lon: Double, units: String) async throws -> UnifiedWeatherData {
        let location = CLLocation(latitude: lat, longitude: lon)
        let imperial = (units == "imperial")

        let weather = try await service.weather(for: location, including:
            .current,
            .minute,
            .hourly,
            .daily
        )

        let current  = buildCurrent(weather.0, imperial: imperial)
        let minutely = buildMinutely(weather.1, imperial: imperial)
        let hourly   = buildHourly(weather.2, imperial: imperial)
        let daily    = buildDaily(weather.3, imperial: imperial)

        return UnifiedWeatherData(
            locationName: nil,
            current:      current,
            hourly:       hourly,
            daily:        daily,
            minutely:     minutely,
            alerts:       [],
            airQuality:   nil
        )
    }

    // MARK: - Current

    private func buildCurrent(_ w: CurrentWeather, imperial: Bool) -> CurrentConditions {
        CurrentConditions(
            temperature:   imperial ? w.temperature.converted(to: .fahrenheit).value : w.temperature.converted(to: .celsius).value,
            feelsLike:     imperial ? w.apparentTemperature.converted(to: .fahrenheit).value : w.apparentTemperature.converted(to: .celsius).value,
            humidity:      w.humidity * 100,
            windSpeed:     imperial ? w.wind.speed.converted(to: .milesPerHour).value : w.wind.speed.converted(to: .kilometersPerHour).value,
            windGust:      imperial ? w.wind.gust?.converted(to: .milesPerHour).value : w.wind.gust?.converted(to: .kilometersPerHour).value,
            windDirection: w.wind.direction.value,
            condition:     mapCondition(w.condition),
            uvIndex:       Double(w.uvIndex.value),
            visibility:    imperial ? w.visibility.converted(to: .miles).value : w.visibility.converted(to: .kilometers).value,
            pressure:      w.pressure.converted(to: .millibars).value,
            dewPoint:      imperial ? w.dewPoint.converted(to: .fahrenheit).value : w.dewPoint.converted(to: .celsius).value,
            cloudCover:    w.cloudCover * 100
        )
    }

    // MARK: - Hourly

    private func buildHourly(_ forecast: Forecast<HourWeather>, imperial: Bool) -> [HourlyEntry] {
        forecast.prefix(48).map { h in
            HourlyEntry(
                time:          h.date,
                temp:          imperial ? h.temperature.converted(to: .fahrenheit).value : h.temperature.converted(to: .celsius).value,
                feelsLike:     imperial ? h.apparentTemperature.converted(to: .fahrenheit).value : h.apparentTemperature.converted(to: .celsius).value,
                condition:     mapCondition(h.condition),
                precipChance:  h.precipitationChance * 100,
                precipAmount:  imperial ? h.precipitationAmount.converted(to: .inches).value : h.precipitationAmount.converted(to: .millimeters).value,
                windSpeed:     imperial ? h.wind.speed.converted(to: .milesPerHour).value : h.wind.speed.converted(to: .kilometersPerHour).value,
                windGust:      imperial ? h.wind.gust?.converted(to: .milesPerHour).value : h.wind.gust?.converted(to: .kilometersPerHour).value,
                windDirection: h.wind.direction.value,
                uvIndex:       Double(h.uvIndex.value),
                humidity:      h.humidity * 100,
                cloudCover:    h.cloudCover * 100
            )
        }
    }

    // MARK: - Daily

    private func buildDaily(_ forecast: Forecast<DayWeather>, imperial: Bool) -> [DailyEntry] {
        forecast.prefix(10).map { d in
            let windSpeedVal = imperial
                ? d.wind.speed.converted(to: .milesPerHour).value
                : d.wind.speed.converted(to: .kilometersPerHour).value
            let windGustVal = d.wind.gust.map { imperial
                ? $0.converted(to: .milesPerHour).value
                : $0.converted(to: .kilometersPerHour).value
            }
            return DailyEntry(
                time:           d.date,
                tempMin:        imperial ? d.lowTemperature.converted(to: .fahrenheit).value : d.lowTemperature.converted(to: .celsius).value,
                tempMax:        imperial ? d.highTemperature.converted(to: .fahrenheit).value : d.highTemperature.converted(to: .celsius).value,
                feelsLikeMin:   nil,
                feelsLikeMax:   nil,
                condition:      mapCondition(d.condition),
                conditionNight: mapCondition(d.condition),
                precipChance:   d.precipitationChance * 100,
                precipAmount:   imperial
                    ? d.precipitationAmount.converted(to: .inches).value
                    : d.precipitationAmount.converted(to: .millimeters).value,
                sunrise:        d.sun.sunrise,
                sunset:         d.sun.sunset,
                moonPhase:      nil,
                dayDescription: nil,
                nightDescription: nil,
                windSpeed:      windSpeedVal,
                windGust:       windGustVal,
                uvIndex:        Double(d.uvIndex.value)
            )
        }
    }

    // MARK: - Minutely

    private func buildMinutely(_ forecast: Forecast<MinuteWeather>?, imperial: Bool) -> [MinutelyEntry] {
        guard let forecast = forecast else { return [] }
        return forecast.prefix(60).map { m in
            MinutelyEntry(
                time:            m.date,
                precipIntensity: m.precipitationIntensity.value
            )
        }
    }

    // MARK: - Condition mapping

    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> Cloudship.WeatherCondition {
        switch condition {
        case .clear, .hot:                             return .clear
        case .mostlyClear:                             return .mostlyClear
        case .partlyCloudy:                            return .partlyCloudy
        case .mostlyCloudy:                            return .mostlyCloudy
        case .cloudy:                                  return .cloudy
        case .foggy:                                   return .fog
        case .haze:                                    return .lightFog
        case .drizzle:                                 return .drizzle
        case .rain:                                    return .rain
        case .heavyRain:                               return .heavyRain
        case .flurries:                                return .lightSnow
        case .snow, .heavySnow, .blizzard:             return .snow
        case .sleet, .freezingRain, .freezingDrizzle,
             .wintryMix, .hail:                        return .sleet
        case .thunderstorms, .tropicalStorm, .hurricane,
             .isolatedThunderstorms, .scatteredThunderstorms,
             .strongStorms:                            return .thunderstorm
        case .windy, .breezy:                          return .windy
        case .smoky, .blowingDust:                     return .fog
        @unknown default:                              return .unknown
        }
    }
}

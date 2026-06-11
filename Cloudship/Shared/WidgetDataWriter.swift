//
//  WidgetDataWriter.swift
//  Cloudship
//
//  Converts UnifiedWeatherData to SharedWeatherData and writes it to the
//  App Group container so the widget extension can read it.
//

import Foundation
import WidgetKit

final class WidgetDataWriter {

    static let shared = WidgetDataWriter()
    private init() {}

    private static let appGroupID = "group.happygiraffe.Cloudship-test"
    private static let fileName   = "widget_weather.json"

    private var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)?
            .appendingPathComponent(Self.fileName)
    }

    /// Convert and write weather data to the shared container, then reload widget timelines.
    func write(_ data: UnifiedWeatherData) {
        guard let url = fileURL else {
            print("WidgetDataWriter: App Group container not available")
            return
        }

        let isMetric = TemperatureFormatter.isMetric
        let todayDaily = data.daily.first

        let shared = SharedWeatherData(
            locationName:   data.locationName ?? "—",
            temperature:    data.current.temperature ?? 0,
            feelsLike:      data.current.feelsLike ?? 0,
            conditionRaw:   data.current.condition.rawValue,
            hiTemp:         todayDaily?.tempMax ?? 0,
            loTemp:         todayDaily?.tempMin ?? 0,
            isMetric:       isMetric,
            sunrise:        todayDaily?.sunrise,
            sunset:         todayDaily?.sunset,
            hourlyForecast: data.hourly.prefix(5).compactMap { entry -> SharedHourlyEntry? in
                guard let temp = entry.temp else { return nil }
                return SharedHourlyEntry(
                    time:         entry.time,
                    temp:         temp,
                    conditionRaw: entry.condition.rawValue
                )
            },
            dailyForecast: data.daily.prefix(5).compactMap { entry -> SharedDailyEntry? in
                guard let min = entry.tempMin, let max = entry.tempMax else { return nil }
                return SharedDailyEntry(
                    time:         entry.time,
                    tempMin:      min,
                    tempMax:      max,
                    conditionRaw: entry.condition.rawValue
                )
            },
            lastUpdated: Date()
        )

        do {
            let encoded = try JSONEncoder().encode(shared)
            try encoded.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
            print("WidgetDataWriter: wrote \(encoded.count) bytes")
        } catch {
            print("WidgetDataWriter: write failed — \(error.localizedDescription)")
        }
    }

    /// Read shared data (used by the widget timeline provider).
    static func read() -> SharedWeatherData? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName) else { return nil }

        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SharedWeatherData.self, from: data)
    }
}

//
//  CloudshipTimelineProvider.swift
//  CloudshipWidget
//
//  Reads cached weather data from the App Group container
//  and provides timeline entries for the widget.
//

import WidgetKit

struct CloudshipTimelineProvider: TimelineProvider {

    private static let appGroupID = "group.happygiraffe.Cloudship-test"
    private static let fileName   = "widget_weather.json"

    func placeholder(in context: Context) -> CloudshipWidgetEntry {
        CloudshipWidgetEntry(date: Date(), data: sampleData())
    }

    func getSnapshot(in context: Context, completion: @escaping (CloudshipWidgetEntry) -> Void) {
        let entry: CloudshipWidgetEntry
        if context.isPreview {
            entry = CloudshipWidgetEntry(date: Date(), data: sampleData())
        } else {
            entry = CloudshipWidgetEntry(date: Date(), data: loadData())
        }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CloudshipWidgetEntry>) -> Void) {
        let data = loadData()
        let entry = CloudshipWidgetEntry(date: Date(), data: data)

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Data loading

    private func loadData() -> SharedWeatherData? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)?
            .appendingPathComponent(Self.fileName) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SharedWeatherData.self, from: data)
    }

    // MARK: - Sample data for previews

    private func sampleData() -> SharedWeatherData {
        let now = Date()
        let cal = Calendar.current

        return SharedWeatherData(
            locationName: "San Francisco",
            temperature: 68,
            feelsLike: 66,
            conditionRaw: "partlyCloudy",
            hiTemp: 72,
            loTemp: 58,
            isMetric: false,
            sunrise: cal.date(bySettingHour: 6, minute: 30, second: 0, of: now),
            sunset: cal.date(bySettingHour: 19, minute: 45, second: 0, of: now),
            hourlyForecast: (0..<5).map { i in
                SharedHourlyEntry(
                    time: cal.date(byAdding: .hour, value: i, to: now)!,
                    temp: 68 + Double(i),
                    conditionRaw: i < 3 ? "partlyCloudy" : "clear"
                )
            },
            dailyForecast: (0..<5).map { i in
                SharedDailyEntry(
                    time: cal.date(byAdding: .day, value: i, to: now)!,
                    tempMin: 55 + Double(i),
                    tempMax: 70 + Double(i * 2),
                    conditionRaw: ["clear", "partlyCloudy", "cloudy", "rain", "clear"][i]
                )
            },
            lastUpdated: now
        )
    }
}

//
//  LargeWidgetView.swift
//  CloudshipWidget
//
//  Large widget: current conditions + hourly strip + 5-day forecast.
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: CloudshipWidgetEntry

    var body: some View {
        if let data = entry.data {
            VStack(alignment: .leading, spacing: 0) {
                // Top: current conditions
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.locationName)
                            .font(.app(.caption))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text(tempString(data.temperature, metric: data.isMetric))
                            .font(.app(size: 40, weight: .thin))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Image(WidgetConditionIcon.assetName(
                            for: data.conditionRaw,
                            isNight: WidgetConditionIcon.isNight(
                                at: entry.date,
                                sunrise: data.sunrise,
                                sunset: data.sunset
                            )
                        ))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)

                        HStack(spacing: 6) {
                            Label(shortTemp(data.hiTemp, metric: data.isMetric), systemImage: "arrow.up")
                            Label(shortTemp(data.loTemp, metric: data.isMetric), systemImage: "arrow.down")
                        }
                        .font(.app(.caption2))
                        .foregroundColor(.secondary)
                    }
                }

                Divider().padding(.vertical, 8)

                // Hourly strip
                HStack(spacing: 0) {
                    ForEach(data.hourlyForecast.indices, id: \.self) { i in
                        let hour = data.hourlyForecast[i]
                        VStack(spacing: 4) {
                            Text(hourLabel(hour.time))
                                .font(.app(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Image(WidgetConditionIcon.assetName(
                                for: hour.conditionRaw,
                                isNight: WidgetConditionIcon.isNight(
                                    at: hour.time,
                                    sunrise: data.sunrise,
                                    sunset: data.sunset
                                )
                            ))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text(shortTemp(hour.temp, metric: data.isMetric))
                                .font(.app(.caption))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Divider().padding(.vertical, 8)

                // Daily forecast
                VStack(spacing: 6) {
                    ForEach(data.dailyForecast.indices, id: \.self) { i in
                        let day = data.dailyForecast[i]
                        HStack {
                            Text(dayLabel(day.time))
                                .font(.app(.caption))
                                .frame(width: 40, alignment: .leading)

                            Image(WidgetConditionIcon.assetName(for: day.conditionRaw))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)

                            Spacer()

                            Text(shortTemp(day.tempMin, metric: data.isMetric))
                                .font(.app(.caption))
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .trailing)

                            // Temperature range bar
                            GeometryReader { geo in
                                let range = tempRange(data.dailyForecast)
                                let barWidth = barFraction(min: day.tempMin, max: day.tempMax, range: range) * geo.size.width
                                let barOffset = barStart(min: day.tempMin, range: range) * geo.size.width

                                ZStack(alignment: .leading) {
                                    // Track
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.secondary.opacity(0.15))

                                    // Fill
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(4, barWidth))
                                        .offset(x: barOffset)
                                }
                            }
                            .frame(height: 4)

                            Text(shortTemp(day.tempMax, metric: data.isMetric))
                                .font(.app(.caption))
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack {
                Image("cloudy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                Text("Open Cloudship to load weather")
                    .font(.app(.caption))
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    // MARK: - Helpers

    private func tempString(_ temp: Double, metric: Bool) -> String {
        "\(Int(temp.rounded()))\(metric ? "°C" : "°F")"
    }

    private func shortTemp(_ temp: Double, metric: Bool) -> String {
        "\(Int(temp.rounded()))°"
    }

    private func hourLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "ha"
        return fmt.string(from: date).lowercased()
    }

    private func dayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    private func tempRange(_ days: [SharedDailyEntry]) -> (min: Double, max: Double) {
        let allMin = days.map(\.tempMin).min() ?? 0
        let allMax = days.map(\.tempMax).max() ?? 100
        return (allMin, allMax)
    }

    private func barFraction(min: Double, max: Double, range: (min: Double, max: Double)) -> CGFloat {
        let totalRange = range.max - range.min
        guard totalRange > 0 else { return 1 }
        return CGFloat((max - min) / totalRange)
    }

    private func barStart(min: Double, range: (min: Double, max: Double)) -> CGFloat {
        let totalRange = range.max - range.min
        guard totalRange > 0 else { return 0 }
        return CGFloat((min - range.min) / totalRange)
    }
}

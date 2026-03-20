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
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text(tempString(data.temperature, metric: data.isMetric))
                            .font(.system(size: 40, weight: .thin))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: WidgetConditionIcon.symbolName(for: data.conditionRaw))
                            .font(.title)
                            .foregroundColor(WidgetConditionIcon.color(for: data.conditionRaw))

                        HStack(spacing: 6) {
                            Label(shortTemp(data.hiTemp, metric: data.isMetric), systemImage: "arrow.up")
                            Label(shortTemp(data.loTemp, metric: data.isMetric), systemImage: "arrow.down")
                        }
                        .font(.caption2)
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
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Image(systemName: WidgetConditionIcon.symbolName(for: hour.conditionRaw))
                                .font(.caption)
                                .foregroundColor(WidgetConditionIcon.color(for: hour.conditionRaw))

                            Text(shortTemp(hour.temp, metric: data.isMetric))
                                .font(.caption)
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
                                .font(.caption)
                                .frame(width: 40, alignment: .leading)

                            Image(systemName: WidgetConditionIcon.symbolName(for: day.conditionRaw))
                                .font(.caption)
                                .foregroundColor(WidgetConditionIcon.color(for: day.conditionRaw))
                                .frame(width: 20)

                            Spacer()

                            Text(shortTemp(day.tempMin, metric: data.isMetric))
                                .font(.caption)
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
                                .font(.caption)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack {
                Image(systemName: "cloud.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Open Cloudship to load weather")
                    .font(.caption)
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
        fmt.dateFormat = "h a"
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

//
//  MediumWidgetView.swift
//  CloudshipWidget
//
//  Medium widget: current conditions on left, 5-hour forecast strip on right.
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: CloudshipWidgetEntry

    var body: some View {
        if let data = entry.data {
            HStack(spacing: 0) {
                // Left: current conditions
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.locationName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: WidgetConditionIcon.symbolName(for: data.conditionRaw))
                        .font(.title2)
                        .foregroundColor(WidgetConditionIcon.color(for: data.conditionRaw))

                    Text(tempString(data.temperature, metric: data.isMetric))
                        .font(.system(size: 36, weight: .thin))
                        .minimumScaleFactor(0.6)

                    HStack(spacing: 6) {
                        Label(tempString(data.hiTemp, metric: data.isMetric), systemImage: "arrow.up")
                        Label(tempString(data.loTemp, metric: data.isMetric), systemImage: "arrow.down")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Right: 5-hour forecast
                HStack(spacing: 0) {
                    ForEach(data.hourlyForecast.indices, id: \.self) { i in
                        let hour = data.hourlyForecast[i]
                        VStack(spacing: 6) {
                            Text(hourLabel(hour.time))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

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
                .frame(maxWidth: .infinity)
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Open Cloudship to load weather")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

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
}

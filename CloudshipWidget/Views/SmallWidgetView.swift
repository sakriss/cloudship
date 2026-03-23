//
//  SmallWidgetView.swift
//  CloudshipWidget
//
//  Small widget: current temp, condition icon, location, hi/lo.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: CloudshipWidgetEntry

    var body: some View {
        if let data = entry.data {
            VStack(alignment: .leading, spacing: 4) {
                // Location
                Text(data.locationName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                // Condition icon
                Image(systemName: WidgetConditionIcon.symbolName(for: data.conditionRaw))
                    .font(.title2)
                    .foregroundColor(WidgetConditionIcon.color(for: data.conditionRaw))

                // Temperature
                Text(tempString(data.temperature, metric: data.isMetric))
                    .font(.system(size: 42, weight: .thin))
                    .minimumScaleFactor(0.6)

                // Hi / Lo
                HStack(spacing: 6) {
                    Label(tempString(data.hiTemp, metric: data.isMetric), systemImage: "arrow.up")
                    Label(tempString(data.loTemp, metric: data.isMetric), systemImage: "arrow.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack {
                Image(systemName: "cloud.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
                Text("Open Cloudship")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    private func tempString(_ temp: Double, metric: Bool) -> String {
        "\(Int(temp.rounded()))\(metric ? "°C" : "°F")"
    }
}

//
//  CloudshipWidget.swift
//  CloudshipWidget
//
//  Created by Scott Kriss on 3/20/26.
//  Copyright © 2026 Scott Kriss. All rights reserved.
//

import WidgetKit
import SwiftUI

struct CloudshipWidget: Widget {
    let kind: String = "CloudshipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CloudshipTimelineProvider()) { entry in
            CloudshipWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cloudship Weather")
        .description("Current conditions and forecast at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CloudshipWidgetEntryView: View {
    var entry: CloudshipWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    CloudshipWidget()
} timeline: {
    CloudshipWidgetEntry(date: .now, data: nil)
}

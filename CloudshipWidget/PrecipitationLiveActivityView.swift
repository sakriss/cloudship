//
//  PrecipitationLiveActivityView.swift
//  CloudshipWidget
//
//  Dynamic Island + Lock Screen Live Activity for precipitation tracking.
//  Requires ActivityKit (iOS 16.1+). Dynamic Island visible on iPhone 14 Pro+.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Widget registration

@available(iOSApplicationExtension 16.1, *)
struct PrecipitationLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrecipitationActivityAttributes.self) { context in
            // Lock Screen / StandBy banner
            PrecipLockScreenView(
                state: context.state,
                locationName: context.attributes.locationName
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(state: context.state)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenter(location: context.attributes.locationName)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(state: context.state)
                }
            } compactLeading: {
                compactLeading(state: context.state)
            } compactTrailing: {
                compactTrailing(state: context.state)
            } minimal: {
                minimal(state: context.state)
            }
            .widgetURL(URL(string: "cloudship://precipitation"))
            .keylineTint(context.state.isPrecipitating ? .blue : .gray)
        }
    }

    // MARK: - Compact

    @ViewBuilder
    private func compactLeading(state: PrecipitationActivityAttributes.ContentState) -> some View {
        Image(systemName: state.conditionSymbol)
            .foregroundStyle(precipColor(state))
            .font(.system(size: 14, weight: .semibold))
    }

    @ViewBuilder
    private func compactTrailing(state: PrecipitationActivityAttributes.ContentState) -> some View {
        if state.isPrecipitating, let mins = state.transitionMinutes {
            Text("\(mins)m")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(precipColor(state))
        } else {
            Text(state.temperatureString)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Minimal

    @ViewBuilder
    private func minimal(state: PrecipitationActivityAttributes.ContentState) -> some View {
        Image(systemName: state.conditionSymbol)
            .foregroundStyle(precipColor(state))
            .font(.system(size: 12, weight: .semibold))
    }

    // MARK: - Expanded regions

    @ViewBuilder
    private func expandedLeading(state: PrecipitationActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: state.conditionSymbol)
                .foregroundStyle(precipColor(state))
                .font(.system(size: 24))
            if state.isPrecipitating, !state.precipType.isEmpty {
                Text(state.precipType.capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 4)
    }

    @ViewBuilder
    private func expandedTrailing(state: PrecipitationActivityAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(state.temperatureString)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text("\(state.precipChance)%")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.trailing, 4)
    }

    @ViewBuilder
    private func expandedCenter(location: String) -> some View {
        Text(location)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    @ViewBuilder
    private func expandedBottom(state: PrecipitationActivityAttributes.ContentState) -> some View {
        HStack {
            Text(state.summary)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
            if state.isPrecipitating {
                intensityDrops(intensity: state.precipIntensity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Helpers

    private func precipColor(_ state: PrecipitationActivityAttributes.ContentState) -> Color {
        guard state.isPrecipitating else { return .secondary }
        switch state.precipType {
        case "snow":  return .cyan
        case "sleet": return .mint
        default:      return .blue
        }
    }

    @ViewBuilder
    private func intensityDrops(intensity: Double) -> some View {
        let filled = intensity < 1.0 ? 1 : (intensity < 4.0 ? 2 : 3)
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "drop.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(i < filled ? Color.blue : Color.gray.opacity(0.3))
            }
        }
    }
}

// MARK: - Lock Screen / StandBy view

@available(iOSApplicationExtension 16.1, *)
struct PrecipLockScreenView: View {
    let state: PrecipitationActivityAttributes.ContentState
    let locationName: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: state.conditionSymbol)
                    .font(.system(size: 36))
                    .foregroundStyle(precipForeground)
                Text(state.temperatureString)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .frame(width: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(locationName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(state.summary)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Label("\(state.precipChance)%", systemImage: "drop.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    if state.isPrecipitating, !state.precipType.isEmpty {
                        Text(state.precipType.capitalized)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.7))
        .activitySystemActionForegroundColor(.white)
    }

    private var precipForeground: Color {
        guard state.isPrecipitating else { return .white.opacity(0.85) }
        switch state.precipType {
        case "snow":  return .cyan
        case "sleet": return .mint
        default:      return Color(red: 0.4, green: 0.7, blue: 1.0)
        }
    }
}

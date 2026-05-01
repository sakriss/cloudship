//
//  AlertBannerCardView.swift
//  Cloudship
//
//  Tappable alert card shown between HeaderCardView and MinutelyCardView
//  when one or more NWS weather alerts are active. Hidden when no alerts.
//  Shows a header row (icon, event, area, count) and a per-alert timeline
//  row visualizing onset → now → expires as a colored horizontal bar.
//

import UIKit

// MARK: - AlertEventColor

enum AlertEventColor {

    static func color(for alert: WeatherAlert) -> UIColor {
        return eventTypeColor(alert.event.lowercased()) ?? severityFallback(alert.severity)
    }

    static func iconName(for alert: WeatherAlert) -> String {
        let name = alert.event.lowercased()
        if name.contains("heat") { return "thermometer.sun.fill" }
        if name.contains("cold") || name.contains("wind chill") || name.contains("freeze") || name.contains("frost") {
            return "thermometer.snowflake"
        }
        if name.contains("snow") || name.contains("blizzard") || name.contains("winter") || name.contains("ice storm") {
            return "snowflake"
        }
        if name.contains("fog") || name.contains("smoke") || name.contains("haze") { return "cloud.fog.fill" }
        if name.contains("flood") { return "drop.triangle.fill" }
        if name.contains("tornado") { return "tornado" }
        if name.contains("severe thunderstorm") { return "cloud.bolt.fill" }
        if name.contains("fire") || name.contains("red flag") { return "flame.fill" }
        if name.contains("wind") || name.contains("dust storm") { return "wind" }
        return severityIconName(alert.severity)
    }

    private static func eventTypeColor(_ name: String) -> UIColor? {
        if name.contains("heat") {
            return UIColor(red: 0.85, green: 0.22, blue: 0.12, alpha: 1)
        }
        if name.contains("cold") || name.contains("wind chill") || name.contains("freeze") || name.contains("frost") {
            return UIColor(red: 0.35, green: 0.65, blue: 0.88, alpha: 1)
        }
        if name.contains("snow") || name.contains("blizzard") || name.contains("winter storm")
            || name.contains("ice storm") || name.contains("winter weather") {
            return UIColor(red: 0.30, green: 0.48, blue: 0.72, alpha: 1)
        }
        if name.contains("fog") || name.contains("smoke") || name.contains("haze") {
            return UIColor(red: 0.52, green: 0.52, blue: 0.56, alpha: 1)
        }
        if name.contains("flood") {
            return UIColor(red: 0.10, green: 0.58, blue: 0.55, alpha: 1)
        }
        if name.contains("tornado") {
            return UIColor(red: 0.38, green: 0.18, blue: 0.65, alpha: 1)
        }
        if name.contains("severe thunderstorm") {
            return UIColor(red: 0.38, green: 0.18, blue: 0.65, alpha: 1)
        }
        if name.contains("fire") || name.contains("red flag") {
            return UIColor(red: 0.78, green: 0.38, blue: 0.12, alpha: 1)
        }
        if name.contains("wind") || name.contains("dust storm") {
            return UIColor(red: 0.55, green: 0.52, blue: 0.28, alpha: 1)
        }
        return nil
    }

    private static func severityFallback(_ severity: AlertSeverity) -> UIColor {
        switch severity {
        case .extreme:  return UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
        case .severe:   return UIColor(red: 0.85, green: 0.35, blue: 0.08, alpha: 1)
        case .moderate: return UIColor(red: 0.80, green: 0.60, blue: 0.05, alpha: 1)
        case .minor:    return UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1)
        case .unknown:  return UIColor(red: 0.40, green: 0.40, blue: 0.50, alpha: 1)
        }
    }

    private static func severityIconName(_ severity: AlertSeverity) -> String {
        switch severity {
        case .extreme:           return "exclamationmark.octagon.fill"
        case .severe, .moderate: return "exclamationmark.triangle.fill"
        case .minor:             return "info.circle.fill"
        case .unknown:           return "bell.badge.fill"
        }
    }
}

// MARK: - AlertTimelineRowView

private final class AlertTimelineRowView: UIView {

    private let eventNameLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let onsetLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor.white.withAlphaComponent(0.70)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let expiresLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor.white.withAlphaComponent(0.70)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Track uses white-over-color rendering for contrast against the colored card background:
    //   trough (22% white) → fill (50% white) → ticks (dark 22%) → now marker (solid white)
    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.22)
        v.layer.cornerRadius = 5
        v.layer.masksToBounds = false   // nowMarker extends ±3 pt outside the trough
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let elapsedView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.50)
        v.layer.cornerRadius = 5
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let nowMarker: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 1.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Three tick marks at 25 / 50 / 75 % — laid out with manual frames in layoutSubviews.
    // Added last so they sit on top of the elapsed fill, visible across the entire track.
    private let tickViews: [UIView] = (0..<3).map { _ in
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.22)
        v.layer.cornerRadius = 0.5
        return v
    }

    private var nowFraction: CGFloat = 0
    private var elapsedWidthConstraint: NSLayoutConstraint?
    private var nowMarkerCenterConstraint: NSLayoutConstraint?

    init(alert: WeatherAlert) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
        configure(alert: alert)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = trackView.bounds.width
        guard w > 0 else { return }
        elapsedWidthConstraint?.constant = w * nowFraction
        nowMarkerCenterConstraint?.constant = w * nowFraction

        // Ticks at 25 / 50 / 75 % — full track height, on top of fill
        let h = trackView.bounds.height
        let tickFractions: [CGFloat] = [0.25, 0.50, 0.75]
        for (tick, frac) in zip(tickViews, tickFractions) {
            let x = (w * frac).rounded() - 0.5
            tick.frame = CGRect(x: x, y: 0, width: 1, height: h)
        }
    }

    private func setupLayout() {
        // z-order: elapsedView → nowMarker → ticks (ticks topmost so they cross both zones)
        trackView.addSubview(elapsedView)
        trackView.addSubview(nowMarker)
        tickViews.forEach { trackView.addSubview($0) }

        let elapsedW = elapsedView.widthAnchor.constraint(equalToConstant: 0)
        elapsedWidthConstraint = elapsedW

        let nowCX = nowMarker.centerXAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 0)
        nowMarkerCenterConstraint = nowCX

        NSLayoutConstraint.activate([
            elapsedView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            elapsedView.topAnchor.constraint(equalTo: trackView.topAnchor),
            elapsedView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            elapsedW,

            // nowMarker extends 3 pt above and below the trough for a bold "current time" pin
            nowMarker.topAnchor.constraint(equalTo: trackView.topAnchor, constant: -3),
            nowMarker.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: 3),
            nowMarker.widthAnchor.constraint(equalToConstant: 3),
            nowCX,

            trackView.heightAnchor.constraint(equalToConstant: 10)
        ])

        // Row layout: [eventNameLabel] [onsetLabel] [trackView(flex)] [expiresLabel]
        let rowStack = UIStackView(arrangedSubviews: [eventNameLabel, onsetLabel, trackView, expiresLabel])
        rowStack.axis = .horizontal
        rowStack.spacing = 6
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            eventNameLabel.widthAnchor.constraint(equalToConstant: 90),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])

        eventNameLabel.setContentHuggingPriority(.required, for: .horizontal)
        onsetLabel.setContentHuggingPriority(.required, for: .horizontal)
        expiresLabel.setContentHuggingPriority(.required, for: .horizontal)
        trackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func configure(alert: WeatherAlert) {
        eventNameLabel.text = alert.event
        accessibilityIdentifier = "alertTimelineRow_\(alert.event.replacingOccurrences(of: " ", with: "_"))"

        let color = AlertEventColor.color(for: alert)
        // Track colors are white-based (set at declaration) — no per-event override needed

        let now = Date()
        let (onset, expires, fraction) = computeTiming(alert: alert, now: now)
        nowFraction = fraction

        if let onset = onset {
            onsetLabel.text = formatAlertTime(onset)
            onsetLabel.isHidden = false
        } else {
            onsetLabel.isHidden = true
        }

        if let expires = expires {
            expiresLabel.text = formatAlertTime(expires)
            expiresLabel.isHidden = false
        } else {
            expiresLabel.isHidden = true
        }

        // Hide now marker if alert is in the future (not started) or already expired
        let alertStarted = onset.map { $0 <= now } ?? true
        let alertActive  = expires.map { $0 > now } ?? true
        nowMarker.isHidden = !alertStarted || !alertActive

        setNeedsLayout()
    }

    private func computeTiming(alert: WeatherAlert, now: Date) -> (onset: Date?, expires: Date?, fraction: CGFloat) {
        let onset   = alert.onset
        let expires = alert.expires

        // Synthesize missing bounds for fraction math
        let effectiveOnset   = onset   ?? expires.map { $0.addingTimeInterval(-86400) }
        let effectiveExpires = expires ?? onset.map   { $0.addingTimeInterval(86400) }

        guard let o = effectiveOnset, let e = effectiveExpires else {
            return (onset, expires, 0)
        }
        let window = e.timeIntervalSince(o)
        guard window > 0 else { return (onset, expires, 0) }
        let fraction = max(0, min(1, now.timeIntervalSince(o) / window))
        return (onset, expires, fraction)
    }

    private func formatAlertTime(_ date: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        if cal.isDateInToday(date) {
            return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else if cal.isDateInTomorrow(date) {
            let t = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            return "Tomorrow \(t)"
        } else {
            // Beyond tomorrow: "Mon 6 AM"
            let f = DateFormatter()
            f.dateFormat = "E h a"
            return f.string(from: date)
        }
    }
}

// MARK: - AlertBannerCardView

class AlertBannerCardView: CardView {

    // MARK: - Callback

    var onTap: (() -> Void)?

    // MARK: - Header subviews

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.white.withAlphaComponent(0.8)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let alertCountBadge: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        l.accessibilityIdentifier = "alertCountBadge"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Timeline stack

    private let timelineStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 6
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - State

    private var alerts: [WeatherAlert] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    // MARK: - Layout

    private func setupLayout() {
        layer.cornerRadius = 14
        accessibilityIdentifier = "alertBannerCard"

        // Header row: icon | textStack | badge | chevron
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIStackView(arrangedSubviews: [iconImageView, textStack, alertCountBadge, chevronImageView])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .center
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        // Separator between header and timeline
        let separator = UIView()
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.20)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        // Content stack: header | separator | timeline rows
        let contentStack = UIStackView(arrangedSubviews: [headerRow, separator, timelineStack])
        contentStack.axis = .vertical
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        let p: CGFloat = 14
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            alertCountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            alertCountBadge.heightAnchor.constraint(equalToConstant: 20),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),

            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: p),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    // MARK: - Configure

    func configure(alerts: [WeatherAlert]) {
        self.alerts = alerts
        guard let top = alerts.first else {
            isHidden = true
            return
        }

        isHidden = false

        let color = AlertEventColor.color(for: top)
        backgroundColor = color

        let symConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImageView.image = UIImage(systemName: AlertEventColor.iconName(for: top), withConfiguration: symConfig)

        titleLabel.text = "\(top.severity.emoji) \(top.event)"

        if let area = top.areaDesc, !area.isEmpty {
            subtitleLabel.text = area.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? area
        } else {
            subtitleLabel.text = top.headline
        }

        if alerts.count > 1 {
            alertCountBadge.text = "+\(alerts.count - 1)"
            alertCountBadge.isHidden = false
        } else {
            alertCountBadge.isHidden = true
        }

        // Rebuild timeline rows
        timelineStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for alert in alerts {
            timelineStack.addArrangedSubview(AlertTimelineRowView(alert: alert))
        }

        // VoiceOver
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        var parts = ["Weather alert: \(top.event)"]
        if let sub = subtitleLabel.text { parts.append(sub) }
        if alerts.count > 1 { parts.append("\(alerts.count) total alerts") }
        accessibilityLabel = parts.joined(separator: ". ")
        accessibilityHint = "Double tap to view alert details"
    }

    // MARK: - Tap

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.75
        }) { _ in
            UIView.animate(withDuration: 0.1) { self.alpha = 1.0 }
        }
        onTap?()
    }
}

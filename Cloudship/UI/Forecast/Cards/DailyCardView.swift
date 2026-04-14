//
//  DailyCardView.swift
//  Cloudship
//
//  7-day daily forecast with temperature range bars.
//

import UIKit

// MARK: - Range bar (Core Graphics)

private class DailyRangeBarView: UIView {

    // MARK: Temperature range mode
    var minTemp: Double = 0
    var maxTemp: Double = 0
    var absMin: Double = 0
    var absMax: Double = 0
    var currentTemp: Double?  // non-nil only for today's row

    // MARK: Progress mode (precip %, amount, etc.)
    /// When non-nil, draws a simple left-to-right solid bar instead of a temp range.
    /// Value should be 0–1.
    var progressFraction: Double? = nil
    var progressColor: UIColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { super.init(coder: coder)!; backgroundColor = .clear }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let h = rect.height
        let w = rect.width

        // Full-width background track
        let trackRect = CGRect(x: 0, y: h / 2 - 3, width: w, height: 6)
        let trackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: 3)
        let trackColor: UIColor = WeatherDataSourceManager.shared.isShowingHistorical
            ? CardView.textColor(for: .tertiary).withAlphaComponent(0.18)
            : UIColor.tertiarySystemFill.resolvedColor(with: traitCollection)
        trackColor.setFill()
        trackPath.fill()

        if let fraction = progressFraction {
            // Progress bar mode: solid color from left edge
            let barW = max(CGFloat(fraction) * w, fraction > 0 ? 6 : 0)
            guard barW > 0 else { return }
            let barRect = CGRect(x: 0, y: h / 2 - 3, width: barW, height: 6)
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: 3)
            progressColor.resolvedColor(with: traitCollection).setFill()
            barPath.fill()
        } else {
            // Temperature range mode
            let range = absMax - absMin
            guard range > 0 else { return }

            let startX = CGFloat((minTemp - absMin) / range) * w
            let endX   = CGFloat((maxTemp - absMin) / range) * w
            let segW = max(endX - startX, 6)
            let segRect = CGRect(x: startX, y: h / 2 - 3, width: segW, height: 6)
            let segPath = UIBezierPath(roundedRect: segRect, cornerRadius: 3)

            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1).cgColor,
                    UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1).cgColor
                ] as CFArray,
                locations: [0, 1]
            ) else { return }

            ctx.saveGState()
            segPath.addClip()
            ctx.drawLinearGradient(gradient,
                start: CGPoint(x: startX, y: 0),
                end:   CGPoint(x: startX + segW, y: 0),
                options: [])
            ctx.restoreGState()

            // Current temperature dot (today only)
            if let current = currentTemp {
                let dotX = CGFloat((current - absMin) / range) * w
                let dotRadius: CGFloat = 5
                let dotRect = CGRect(x: dotX - dotRadius, y: h / 2 - dotRadius,
                                     width: dotRadius * 2, height: dotRadius * 2)
                let dotPath = UIBezierPath(ovalIn: dotRect)
                UIColor.white.setFill()
                dotPath.fill()
                UIColor.black.withAlphaComponent(0.15).setStroke()
                dotPath.lineWidth = 1
                dotPath.stroke()
            }
        }
    }
}

// MARK: - Single row

private class DailyRowView: UIView {

    private enum Layout {
        static let detailColumnWidth: CGFloat = 62
        static let minTempWidth: CGFloat = 34
    }

    private let dayLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .label
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let precipLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        l.lineBreakMode = .byClipping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let snowLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .systemCyan
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        l.lineBreakMode = .byClipping
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private let minTempLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rangeBar = DailyRangeBarView()

    private let maxTempLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .label
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        // Must never clip — compression resistance wins over rangeBar expansion
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return l
    }()

    /// Shown instead of rangeBar + maxTempLabel when a metric has no daily data from this source.
    private let noDataLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .tertiaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        rangeBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dayLabel)
        addSubview(iconView)
        addSubview(snowLabel)
        addSubview(precipLabel)
        addSubview(minTempLabel)
        addSubview(rangeBar)
        addSubview(maxTempLabel)
        addSubview(noDataLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CardView.padding),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            dayLabel.widthAnchor.constraint(equalToConstant: 48),

            iconView.leadingAnchor.constraint(equalTo: dayLabel.trailingAnchor, constant: 4),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            // snowLabel and precipLabel occupy the same slot — same leading/width so
            // minTempLabel position is stable regardless of which one is visible.
            snowLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 2),
            snowLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            snowLabel.widthAnchor.constraint(equalToConstant: Layout.detailColumnWidth),

            precipLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 2),
            precipLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            precipLabel.widthAnchor.constraint(equalToConstant: Layout.detailColumnWidth),

            minTempLabel.leadingAnchor.constraint(equalTo: precipLabel.trailingAnchor, constant: 4),
            minTempLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            minTempLabel.widthAnchor.constraint(equalToConstant: Layout.minTempWidth),

            rangeBar.leadingAnchor.constraint(equalTo: minTempLabel.trailingAnchor, constant: 6),
            rangeBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            rangeBar.heightAnchor.constraint(equalToConstant: 20),

            maxTempLabel.leadingAnchor.constraint(equalTo: rangeBar.trailingAnchor, constant: 6),
            maxTempLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CardView.padding),
            maxTempLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            // No fixed width — content hugging + compression resistance let it size to content

            // noDataLabel spans the full right section (bar + value area)
            noDataLabel.leadingAnchor.constraint(equalTo: minTempLabel.trailingAnchor, constant: 6),
            noDataLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CardView.padding),
            noDataLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(entry: DailyEntry, absMin: Double, absMax: Double, currentTemp: Double? = nil) {
        applyTextPalette()
        dayLabel.text  = DateFormatHelper.dailyLabel(from: entry.time)
        iconView.image = UIImage(named: WeatherCodeMapper.iconName(for: entry.condition,
                                                                    isNight: false))
        precipLabel.text  = entry.precipChance.map { "\(Int($0.rounded()))%" } ?? ""
        minTempLabel.text = TemperatureFormatter.format(entry.tempMin)
        maxTempLabel.text = TemperatureFormatter.format(entry.tempMax)
        minTempLabel.isHidden = false

        // Accumulation label priority:
        //  1. Snow accumulation (frozen depth)   → "0.3" ❄"  / "0.8cm ❄"
        //  2. Rain accumulation (liquid, non-snow) → "1.2" 🌧" / "5.2mm 🌧"
        //  3. Precip chance %                     → "30%"
        let snowConditions: Set<WeatherCondition> = [.lightSnow, .snow, .heavySnow, .sleet]
        let isSnowDay = snowConditions.contains(entry.condition)

        if let snow = entry.snowAccumulation, snow > 0 {
            let unit = TemperatureFormatter.isMetric ? "cm" : "\""
            snowLabel.text = "\(String(format: "%.1f", snow))\(unit) ❄"
            snowLabel.textColor = .systemCyan
            snowLabel.isHidden = false
            precipLabel.isHidden = true
        } else if let rain = entry.precipAmount, rain > 0, !isSnowDay {
            let metric = TemperatureFormatter.isMetric
            let unit = metric ? "mm" : "\""
            let value = metric
                ? String(format: "%.1f", rain)
                : String(format: "%.2f", rain)
            snowLabel.text = "\(value)\(unit) 🌧"
            snowLabel.textColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
            snowLabel.isHidden = false
            precipLabel.isHidden = true
        } else {
            snowLabel.isHidden = true
            precipLabel.isHidden = false
        }

        noDataLabel.isHidden = true        // always reset — only shown in configureForMetric
        rangeBar.isHidden = false
        maxTempLabel.isHidden = false
        rangeBar.progressFraction = nil   // always reset to gradient mode
        rangeBar.absMin  = absMin
        rangeBar.absMax  = absMax
        rangeBar.minTemp = entry.tempMin ?? absMin
        rangeBar.maxTemp = entry.tempMax ?? absMax
        rangeBar.currentTemp = currentTemp
        rangeBar.setNeedsDisplay()

        // VoiceOver
        isAccessibilityElement = true
        var parts: [String] = []
        if let day = dayLabel.text { parts.append(day) }
        let condition = WeatherCodeMapper.description(for: entry.condition)
        if !condition.isEmpty { parts.append(condition) }
        if let hi = maxTempLabel.text { parts.append("High \(hi)") }
        if let lo = minTempLabel.text { parts.append("Low \(lo)") }
        if !precipLabel.isHidden, let precip = precipLabel.text, !precip.isEmpty {
            parts.append("Precipitation \(precip)")
        }
        if !snowLabel.isHidden, let accum = snowLabel.text {
            let label = isSnowDay ? "Snow accumulation" : "Rain accumulation"
            parts.append("\(label) \(accum)")
        }
        accessibilityLabel = parts.joined(separator: ", ")
    }

    /// Switches the bar/label display to reflect a chosen hourly metric without
    /// re-running the full configure path. Resets to temp mode when metric == .temp.
    func configureForMetric(_ metric: HourlyMetric, entry: DailyEntry,
                            absMin: Double, absMax: Double, metricMax: Double) {
        let blue = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        let isMetric = TemperatureFormatter.isMetric

        // Helper: show a progress bar with a value label.
        func showBar(value: Double?, valueText: String, fraction: Double, color: UIColor) {
            minTempLabel.isHidden = true
            snowLabel.isHidden = true
            precipLabel.isHidden = true
            noDataLabel.isHidden = true
            rangeBar.isHidden = false
            maxTempLabel.isHidden = false
            maxTempLabel.text = valueText
            rangeBar.progressFraction = fraction
            rangeBar.progressColor = color
            rangeBar.setNeedsDisplay()
        }

        // Helper: hide bar and show "No [metric] from source" message.
        func showNoData(_ message: String) {
            minTempLabel.isHidden = true
            snowLabel.isHidden = true
            precipLabel.isHidden = true
            rangeBar.isHidden = true
            maxTempLabel.isHidden = true
            noDataLabel.text = message
            noDataLabel.isHidden = false
        }

        switch metric {
        case .temp:
            // Restore normal temp range layout
            noDataLabel.isHidden = true
            rangeBar.isHidden = false
            maxTempLabel.isHidden = false
            minTempLabel.text = TemperatureFormatter.format(entry.tempMin)
            minTempLabel.isHidden = false
            maxTempLabel.text = TemperatureFormatter.format(entry.tempMax)
            snowLabel.isHidden = true
            precipLabel.isHidden = false
            rangeBar.progressFraction = nil
            rangeBar.minTemp = entry.tempMin ?? absMin
            rangeBar.maxTemp = entry.tempMax ?? absMax
            rangeBar.absMin = absMin
            rangeBar.absMax = absMax
            rangeBar.setNeedsDisplay()

        case .feelsLike:
            let fMin = entry.feelsLikeMin ?? entry.tempMin ?? absMin
            let fMax = entry.feelsLikeMax ?? entry.tempMax ?? absMax
            noDataLabel.isHidden = true
            rangeBar.isHidden = false
            maxTempLabel.isHidden = false
            minTempLabel.text = TemperatureFormatter.format(fMin)
            minTempLabel.isHidden = false
            snowLabel.isHidden = true
            precipLabel.isHidden = true
            maxTempLabel.text = TemperatureFormatter.format(fMax)
            rangeBar.progressFraction = nil
            rangeBar.minTemp = fMin
            rangeBar.maxTemp = fMax
            rangeBar.absMin = absMin
            rangeBar.absMax = absMax
            rangeBar.setNeedsDisplay()

        case .precipChance:
            let pct = entry.precipChance ?? 0
            showBar(value: pct,
                    valueText: "\(Int(pct.rounded()))%",
                    fraction: pct / 100.0,
                    color: blue)

        case .precipAmount:
            let amt = entry.precipAmount ?? 0
            let amtText = isMetric
                ? (amt > 0 ? String(format: "%.1fmm", amt) : "0")
                : (amt > 0 ? String(format: "%.2f\"", amt) : "0")
            showBar(value: amt,
                    valueText: amtText,
                    fraction: metricMax > 0 ? min(amt / metricMax, 1.0) : 0,
                    color: blue)

        case .windSpeed:
            if let val = entry.windSpeed {
                let unit = isMetric ? " km/h" : " mph"
                showBar(value: val,
                        valueText: "\(Int(val.rounded()))\(unit)",
                        fraction: min(val / metricMax, 1.0),
                        color: UIColor(red: 0.40, green: 0.75, blue: 0.40, alpha: 1))
            } else {
                showNoData("No wind from source")
            }

        case .windGust:
            if let val = entry.windGust {
                let unit = isMetric ? " km/h" : " mph"
                showBar(value: val,
                        valueText: "\(Int(val.rounded()))\(unit)",
                        fraction: min(val / metricMax, 1.0),
                        color: UIColor(red: 0.60, green: 0.40, blue: 0.85, alpha: 1))
            } else {
                showNoData("No gusts from source")
            }

        case .uvIndex:
            if let val = entry.uvIndex {
                showBar(value: val,
                        valueText: "\(Int(val.rounded()))",
                        fraction: min(val / 11.0, 1.0),
                        color: UIColor(red: 1.00, green: 0.75, blue: 0.10, alpha: 1))
            } else {
                showNoData("No UV index from source")
            }

        case .humidity:
            if let val = entry.humidity {
                showBar(value: val,
                        valueText: "\(Int(val.rounded()))%",
                        fraction: val / 100.0,
                        color: blue)
            } else {
                showNoData("No humidity from source")
            }

        case .cloudCover:
            if let val = entry.cloudCover {
                showBar(value: val,
                        valueText: "\(Int(val.rounded()))%",
                        fraction: val / 100.0,
                        color: .systemGray)
            } else {
                showNoData("No cloud cover from source")
            }

        case .visibility:
            if let val = entry.visibility {
                let unit = isMetric ? " km" : " mi"
                let visMax: Double = isMetric ? 16.0 : 10.0
                showBar(value: val,
                        valueText: "\(Int(val.rounded()))\(unit)",
                        fraction: min(val / visMax, 1.0),
                        color: UIColor(red: 0.40, green: 0.70, blue: 0.90, alpha: 1))
            } else {
                showNoData("No visibility from source")
            }

        case .pressure:
            if let val = entry.pressure {
                let unit = isMetric ? " hPa" : "\""
                let valText = isMetric
                    ? "\(Int(val.rounded()))\(unit)"
                    : String(format: "%.2f\(unit)", val)
                let (pMin, pMax): (Double, Double) = isMetric ? (950, 1050) : (28.05, 31.01)
                showBar(value: val,
                        valueText: valText,
                        fraction: min(max((val - pMin) / (pMax - pMin), 0), 1.0),
                        color: UIColor(red: 0.80, green: 0.45, blue: 0.20, alpha: 1))
            } else {
                showNoData("No pressure from source")
            }
        }
    }

    private func applyTextPalette() {
        dayLabel.textColor = CardView.textColor(for: .primary)
        precipLabel.textColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        minTempLabel.textColor = CardView.textColor(for: .secondary)
        maxTempLabel.textColor = CardView.textColor(for: .primary)
        noDataLabel.textColor = CardView.textColor(for: .tertiary)
        rangeBar.setNeedsDisplay()
    }
}

// MARK: - Card

class DailyCardView: CardView {

    // Callback fired with the tapped DailyEntry and its index
    var onDayTapped: ((DailyEntry, Int) -> Void)?

    private var rowViews: [DailyRowView] = []
    private var dailyEntries: [DailyEntry] = []
    private var absMin: Double = 0
    private var absMax: Double = 0
    private var storedCurrentTemp: Double?
    private var titleLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        let p = CardView.padding
        titleLabel = makeTitleLabel(text: "7-Day Forecast")
        addSubview(titleLabel)

        rowViews = (0..<7).map { _ in DailyRowView() }
        rowViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:)))
            $0.addGestureRecognizer(tap)
            $0.isUserInteractionEnabled = true
        }

        let stack = UIStackView(arrangedSubviews: rowViews)
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    func configure(daily: [DailyEntry], currentTemp: Double? = nil) {
        guard !daily.isEmpty else { return }
        titleLabel.textColor = CardView.textColor(for: .secondary)
        dailyEntries = daily
        storedCurrentTemp = currentTemp
        let allMins = daily.compactMap(\.tempMin)
        let allMaxs = daily.compactMap(\.tempMax)
        absMin = allMins.min() ?? 0
        absMax = allMaxs.max() ?? 100

        let todayStart = Calendar.current.startOfDay(for: Date())

        for (i, row) in rowViews.enumerated() {
            if i < daily.count {
                row.isHidden = false
                let isToday = Calendar.current.isDate(daily[i].time, inSameDayAs: todayStart)
                row.configure(entry: daily[i], absMin: absMin, absMax: absMax,
                              currentTemp: isToday ? currentTemp : nil)
                row.tag = i
            } else {
                row.isHidden = true
            }
        }
    }

    override func applyVintageStyle() {
        super.applyVintageStyle()
        titleLabel?.textColor = CardView.textColor(for: .secondary)
        rowViews.forEach { $0.setNeedsLayout() }
        if !dailyEntries.isEmpty {
            configure(daily: dailyEntries, currentTemp: storedCurrentTemp)
        }
    }

    override func restoreTint() {
        super.restoreTint()
        titleLabel?.textColor = CardView.textColor(for: .secondary)
        if !dailyEntries.isEmpty {
            configure(daily: dailyEntries, currentTemp: storedCurrentTemp)
        }
    }

    /// Called by MainForecastViewController when the hourly metric pill changes.
    func updateMetric(_ metric: HourlyMetric) {
        guard !dailyEntries.isEmpty else { return }

        // For amount/speed-based metrics, compute the max across all days for proportional bars
        let metricMax: Double = {
            switch metric {
            case .precipAmount: return max(dailyEntries.compactMap(\.precipAmount).max() ?? 1, 0.01)
            case .windSpeed:    return max(dailyEntries.compactMap(\.windSpeed).max() ?? 1, 1)
            case .windGust:     return max(dailyEntries.compactMap(\.windGust).max() ?? 1, 1)
            default: return 1
            }
        }()

        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            for (i, row) in self.rowViews.enumerated() {
                guard i < self.dailyEntries.count else { continue }
                let entry = self.dailyEntries[i]
                if metric == .temp {
                    // Full re-configure restores accumulation labels correctly
                    let isToday = Calendar.current.isDate(entry.time, inSameDayAs: Date())
                    row.configure(entry: entry, absMin: self.absMin, absMax: self.absMax,
                                  currentTemp: isToday ? self.storedCurrentTemp : nil)
                } else {
                    row.configureForMetric(metric, entry: entry,
                                          absMin: self.absMin, absMax: self.absMax,
                                          metricMax: metricMax)
                }
            }
        }
    }

    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }
        let idx = row.tag
        guard idx < dailyEntries.count else { return }

        // Brief highlight
        UIView.animate(withDuration: 0.1, animations: { row.alpha = 0.5 }) { _ in
            UIView.animate(withDuration: 0.1) { row.alpha = 1 }
        }
        onDayTapped?(dailyEntries[idx], idx)
    }
}

//
//  MinutelyCardView.swift
//  Cloudship
//
//  60-minute precipitation bar chart using Core Graphics.
//

import UIKit

// MARK: - Bar chart view

private class MinutelyChartView: UIView {

    var entries: [MinutelyEntry] = [] {
        didSet { setNeedsDisplay() }
    }

    // Fixed max for normalization so light drizzle looks appropriately small
    private let fixedMaxIntensity: Double = 4.0  // mm/hr

    // Intensity-to-color mapping (Dark Sky-style)
    private func color(for intensity: Double) -> UIColor {
        if intensity < 0.1 {
            // Very light — pale blue
            return UIColor(red: 0.55, green: 0.78, blue: 0.94, alpha: 0.7)
        } else if intensity < 0.5 {
            // Light rain — medium blue
            return UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 0.85)
        } else if intensity < 2.0 {
            // Heavy rain — dark blue
            return UIColor(red: 0.15, green: 0.45, blue: 0.78, alpha: 0.9)
        } else {
            // Very heavy — purple
            return UIColor(red: 0.45, green: 0.25, blue: 0.80, alpha: 0.95)
        }
    }

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
        guard !entries.isEmpty else { return }
        let intensities = entries.map { $0.precipIntensity ?? 0 }
        let maxIntensity = intensities.max() ?? 0

        if maxIntensity == 0 {
            // Draw a flat baseline
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 0, y: rect.height - 2))
            linePath.addLine(to: CGPoint(x: rect.width, y: rect.height - 2))
            UIColor.tertiarySystemFill.resolvedColor(with: traitCollection).setStroke()
            linePath.lineWidth = 2
            linePath.stroke()
            return
        }

        let n = entries.count
        let barWidth = rect.width / CGFloat(n)
        let gap: CGFloat = 1

        // Draw bars with intensity-based colors, normalized against fixed max
        for (i, intensity) in intensities.enumerated() {
            guard intensity > 0 else { continue }
            let normalizedH = min(CGFloat(intensity / fixedMaxIntensity), 1.0)
            let h = max(normalizedH * rect.height, 2)  // minimum 2pt so light rain is visible
            let x = CGFloat(i) * barWidth
            let barRect = CGRect(x: x + gap/2,
                                 y: rect.height - h,
                                 width: barWidth - gap,
                                 height: h)
            color(for: intensity).setFill()
            let path = UIBezierPath(roundedRect: barRect, byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 2, height: 2))
            path.fill()
        }

        // Draw "Now" marker — vertical dashed line at x=0
        let nowPath = UIBezierPath()
        nowPath.move(to: CGPoint(x: 1, y: 0))
        nowPath.addLine(to: CGPoint(x: 1, y: rect.height))
        UIColor.label.withAlphaComponent(0.3).setStroke()
        nowPath.lineWidth = 1
        nowPath.setLineDash([3, 3], count: 2, phase: 0)
        nowPath.stroke()
    }
}

// MARK: - Card

class MinutelyCardView: CardView {

    private let chartView = MinutelyChartView()
    private var titleLabel: UILabel!
    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .label
        l.numberOfLines = 2
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No precipitation expected"
        l.font = .appFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nowLabel: UILabel = {
        let l = UILabel()
        l.text = "Now"
        l.font = .appFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let endLabel: UILabel = {
        let l = UILabel()
        l.text = "+60 min"
        l.font = .appFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let label15: UILabel = {
        let l = UILabel()
        l.text = "+15"
        l.font = .appFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let label30: UILabel = {
        let l = UILabel()
        l.text = "+30"
        l.font = .appFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let label45: UILabel = {
        let l = UILabel()
        l.text = "+45"
        l.font = .appFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let noSourceLabel: UILabel = {
        let l = UILabel()
        l.text = "Minutely data not available for this source"
        l.font = .appFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.numberOfLines = 2
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        // Hide everything by default until configure() is called
        chartView.isHidden = true
        summaryLabel.isHidden = true
        emptyLabel.isHidden = true
        nowLabel.isHidden = true
        endLabel.isHidden = true
        label15.isHidden = true
        label30.isHidden = true
        label45.isHidden = true
        noSourceLabel.isHidden = true

        let p = CardView.padding
        titleLabel = makeTitleLabel(text: "Precipitation")
        addSubview(titleLabel)

        chartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(summaryLabel)
        addSubview(chartView)
        addSubview(emptyLabel)
        addSubview(nowLabel)
        addSubview(label15)
        addSubview(label30)
        addSubview(label45)
        addSubview(endLabel)
        addSubview(noSourceLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            summaryLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            summaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),

            chartView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 10),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            chartView.heightAnchor.constraint(equalToConstant: 80),

            nowLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            nowLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            nowLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            // Intermediate time labels positioned at 25%, 50%, 75% of chart width
            label15.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            label30.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            label30.centerXAnchor.constraint(equalTo: chartView.centerXAnchor),
            label45.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),

            endLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            endLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            endLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor),

            noSourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            noSourceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            noSourceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            noSourceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])

        // Position +15 at 25% and +45 at 75% of chart width
        // label.centerX = chart.leading + 0.25 * chart.width
        // Trick: use right anchor with multiplier on width anchor won't work,
        // so we use a pair of constraints relative to chart leading/trailing
        let guide15 = UILayoutGuide()
        let guide45 = UILayoutGuide()
        addLayoutGuide(guide15)
        addLayoutGuide(guide45)
        NSLayoutConstraint.activate([
            guide15.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            guide15.widthAnchor.constraint(equalTo: chartView.widthAnchor, multiplier: 0.25),
            label15.centerXAnchor.constraint(equalTo: guide15.trailingAnchor),

            guide45.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            guide45.widthAnchor.constraint(equalTo: chartView.widthAnchor, multiplier: 0.75),
            label45.centerXAnchor.constraint(equalTo: guide45.trailingAnchor),
        ])
    }

    func configure(minutely: [MinutelyEntry],
                   hourly: [HourlyEntry] = [],
                   current: CurrentConditions? = nil) {
        let hasData = !minutely.isEmpty
        let allZero = minutely.allSatisfy { ($0.precipIntensity ?? 0) == 0 }

        chartView.isHidden = !hasData
        nowLabel.isHidden = !hasData
        endLabel.isHidden = !hasData
        label15.isHidden = !hasData
        label30.isHidden = !hasData
        label45.isHidden = !hasData
        noSourceLabel.isHidden = hasData
        emptyLabel.isHidden = !hasData || !allZero

        // One-liner summary (always visible if we have any data to analyze)
        if let current = current {
            let summary = PrecipitationAnalyzer.oneLiner(minutely: minutely,
                                                         hourly: hourly,
                                                         current: current)
            summaryLabel.text = summary
            summaryLabel.isHidden = false
        } else {
            summaryLabel.isHidden = true
        }

        if hasData {
            chartView.entries = minutely

            // Determine interval and set time labels
            if minutely.count >= 2 {
                let interval = minutely[1].time.timeIntervalSince(minutely[0].time)
                if interval > 600 {
                    // 15-minute intervals (Open-Meteo)
                    let totalMinutes = Int(interval / 60) * minutely.count
                    endLabel.text = "+\(totalMinutes) min"
                    let q = totalMinutes / 4
                    label15.text = "+\(q)"
                    label30.text = "+\(q * 2)"
                    label45.text = "+\(q * 3)"
                } else {
                    // 1-minute intervals (Tomorrow.io)
                    endLabel.text = "+60 min"
                    label15.text = "+15"
                    label30.text = "+30"
                    label45.text = "+45"
                }
            }
        }

        // VoiceOver
        isAccessibilityElement = true
        if !hasData {
            accessibilityLabel = "Precipitation: Minutely data not available for this source"
        } else if allZero {
            accessibilityLabel = "Precipitation: No precipitation expected"
        } else if let summary = summaryLabel.text {
            accessibilityLabel = "Precipitation: \(summary)"
        } else {
            accessibilityLabel = "Precipitation timeline"
        }
    }
}

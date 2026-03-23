//
//  DetailsCardView.swift
//  Cloudship
//
//  8-tile grid showing: Wind Speed, Wind Gust, Humidity, UV Index,
//  Visibility, Pressure, Dew Point, Cloud Cover.
//

import UIKit

// MARK: - Individual tile

private class DetailTileView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .label
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(systemIcon: String, value: String, name: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: systemIcon)
        valueLabel.text = value
        nameLabel.text = name

        let stack = UIStackView(arrangedSubviews: [iconView, valueLabel, nameLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(value: String) {
        valueLabel.text = value
    }
}

// MARK: - Sun arc (sunrise/sunset)

private class SunArcView: UIView {

    var sunrise: Date?
    var sunset: Date?
    var dawn: Date?
    var dusk: Date?

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
        guard let sunrise = sunrise, let sunset = sunset else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let insetX: CGFloat = 24
        let arcLeft = insetX
        let arcRight = rect.width - insetX
        let arcWidth = arcRight - arcLeft
        let arcCenterX = rect.midX
        let arcBottom: CGFloat = rect.height - 24  // space for labels
        let arcHeight: CGFloat = arcBottom * 0.7

        // Draw semicircular arc (sunrise left → sunset right)
        let arcPath = UIBezierPath()
        let steps = 60
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = CGFloat.pi * (1 - t)  // π → 0 (left to right semicircle)
            let x = arcCenterX + (arcWidth / 2) * cos(angle)
            let y = arcBottom - arcHeight * sin(angle)
            if i == 0 {
                arcPath.move(to: CGPoint(x: x, y: y))
            } else {
                arcPath.addLine(to: CGPoint(x: x, y: y))
            }
        }

        // Dashed arc line
        UIColor.secondaryLabel.withAlphaComponent(0.3).setStroke()
        arcPath.lineWidth = 1.5
        arcPath.setLineDash([4, 4], count: 2, phase: 0)
        arcPath.stroke()

        // Horizon line
        let horizonPath = UIBezierPath()
        horizonPath.move(to: CGPoint(x: arcLeft - 8, y: arcBottom))
        horizonPath.addLine(to: CGPoint(x: arcRight + 8, y: arcBottom))
        UIColor.separator.resolvedColor(with: traitCollection).setStroke()
        horizonPath.lineWidth = 1
        horizonPath.setLineDash([1], count: 0, phase: 0)  // solid
        horizonPath.stroke()

        // Current sun position
        let now = Date()
        let totalDaylight = sunset.timeIntervalSince(sunrise)
        let elapsed = now.timeIntervalSince(sunrise)

        if totalDaylight > 0 && elapsed >= 0 && elapsed <= totalDaylight {
            let progress = CGFloat(elapsed / totalDaylight)
            let angle = CGFloat.pi * (1 - progress)
            let dotX = arcCenterX + (arcWidth / 2) * cos(angle)
            let dotY = arcBottom - arcHeight * sin(angle)

            // Solid arc up to current position
            let solidPath = UIBezierPath()
            let progressSteps = Int(Double(steps) * Double(progress))
            for i in 0...max(progressSteps, 1) {
                let t = CGFloat(i) / CGFloat(steps)
                let a = CGFloat.pi * (1 - t)
                let x = arcCenterX + (arcWidth / 2) * cos(a)
                let y = arcBottom - arcHeight * sin(a)
                if i == 0 {
                    solidPath.move(to: CGPoint(x: x, y: y))
                } else {
                    solidPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 0.8).setStroke()
            solidPath.lineWidth = 2
            solidPath.stroke()

            // Sun dot
            let dotRadius: CGFloat = 7
            let dotRect = CGRect(x: dotX - dotRadius, y: dotY - dotRadius,
                                 width: dotRadius * 2, height: dotRadius * 2)
            ctx.saveGState()
            // Glow
            ctx.setShadow(offset: .zero, blur: 8,
                          color: UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.6).cgColor)
            UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0).setFill()
            UIBezierPath(ovalIn: dotRect).fill()
            ctx.restoreGState()
        }

        // Sunrise label
        let sunriseStr = timeString(from: sunrise)
        let sunsetStr = timeString(from: sunset)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let riseSize = sunriseStr.size(withAttributes: attrs)
        sunriseStr.draw(at: CGPoint(x: arcLeft - riseSize.width / 2,
                                     y: arcBottom + 4), withAttributes: attrs)
        let setSize = sunsetStr.size(withAttributes: attrs)
        sunsetStr.draw(at: CGPoint(x: arcRight - setSize.width / 2,
                                    y: arcBottom + 4), withAttributes: attrs)

        // Dawn/dusk labels (Pirate Weather)
        let dawnDuskAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        if let dawn = dawn {
            let dawnStr = "Dawn " + timeString(from: dawn)
            let dawnSize = dawnStr.size(withAttributes: dawnDuskAttrs)
            dawnStr.draw(at: CGPoint(x: arcLeft - dawnSize.width / 2,
                                      y: arcBottom + 4 + riseSize.height + 1), withAttributes: dawnDuskAttrs)
        }
        if let dusk = dusk {
            let duskStr = "Dusk " + timeString(from: dusk)
            let duskSize = duskStr.size(withAttributes: dawnDuskAttrs)
            duskStr.draw(at: CGPoint(x: arcRight - duskSize.width / 2,
                                      y: arcBottom + 4 + setSize.height + 1), withAttributes: dawnDuskAttrs)
        }
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Card

class DetailsCardView: CardView {

    private var tiles: [DetailTileView] = []
    private let sunArcView = SunArcView()
    private var sunArcHeightConstraint: NSLayoutConstraint!

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
        let titleLabel = makeTitleLabel(text: "DETAILS")
        addSubview(titleLabel)

        let tileData: [(icon: String, value: String, name: String)] = [
            ("wind.fill",     "—", "Wind"),
            ("wind",          "—", "Gusts"),
            ("humidity.fill", "—", "Humidity"),
            ("sun.max.fill",  "—", "UV Index"),
            ("eye.fill",      "—", "Visibility"),
            ("gauge.medium",  "—", "Pressure"),
            ("thermometer",   "—", "Dew Point"),
            ("cloud.fill",    "—", "Cloud Cover")
        ]

        tiles = tileData.map { DetailTileView(systemIcon: $0.icon, value: $0.value, name: $0.name) }

        // Build rows: each row is a plain UIView that holds left + right tiles plus a centre separator line
        var rowViews: [UIView] = []
        for i in stride(from: 0, to: tiles.count, by: 2) {
            let left  = tiles[i]
            let right = tiles[i + 1]
            left.translatesAutoresizingMaskIntoConstraints  = false
            right.translatesAutoresizingMaskIntoConstraints = false

            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false

            let vSep = UIView()            // thin vertical line between columns
            vSep.backgroundColor = .separator
            vSep.translatesAutoresizingMaskIntoConstraints = false

            row.addSubview(left)
            row.addSubview(vSep)
            row.addSubview(right)

            NSLayoutConstraint.activate([
                // Left tile: leading → centre
                left.topAnchor.constraint(equalTo: row.topAnchor),
                left.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                left.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                left.trailingAnchor.constraint(equalTo: row.centerXAnchor),

                // Vertical separator: 0.5 pt wide, centred
                vSep.topAnchor.constraint(equalTo: row.topAnchor),
                vSep.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                vSep.centerXAnchor.constraint(equalTo: row.centerXAnchor),
                vSep.widthAnchor.constraint(equalToConstant: 0.5),

                // Right tile: centre → trailing
                right.topAnchor.constraint(equalTo: row.topAnchor),
                right.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                right.leadingAnchor.constraint(equalTo: row.centerXAnchor),
                right.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])

            rowViews.append(row)
        }

        // Stack rows vertically with horizontal separator lines between them
        let outer = UIStackView()
        outer.axis = .vertical
        outer.spacing = 0
        outer.translatesAutoresizingMaskIntoConstraints = false

        for (i, row) in rowViews.enumerated() {
            outer.addArrangedSubview(row)
            if i < rowViews.count - 1 {
                let hSep = UIView()
                hSep.backgroundColor = .separator
                hSep.translatesAutoresizingMaskIntoConstraints = false
                hSep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                outer.addArrangedSubview(hSep)
            }
        }

        // Sun arc view (sunrise/sunset visualization)
        sunArcView.translatesAutoresizingMaskIntoConstraints = false
        sunArcView.isHidden = true  // Hidden until sunrise/sunset data is available
        sunArcHeightConstraint = sunArcView.heightAnchor.constraint(equalToConstant: 100)

        addSubview(outer)
        addSubview(sunArcView)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            outer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            outer.leadingAnchor.constraint(equalTo: leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor),

            sunArcView.topAnchor.constraint(equalTo: outer.bottomAnchor, constant: 8),
            sunArcView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            sunArcView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            sunArcHeightConstraint,
            sunArcView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    // MARK: - Configure

    func configure(with current: CurrentConditions, sunrise: Date? = nil, sunset: Date? = nil,
                   dawn: Date? = nil, dusk: Date? = nil) {
        // Update sun arc
        if let rise = sunrise, let set = sunset {
            sunArcView.sunrise = rise
            sunArcView.sunset = set
            sunArcView.dawn = dawn
            sunArcView.dusk = dusk
            sunArcView.isHidden = false
            sunArcHeightConstraint.constant = (dawn != nil || dusk != nil) ? 114 : 100
            sunArcView.setNeedsDisplay()
        } else {
            sunArcView.isHidden = true
            sunArcHeightConstraint.constant = 0
        }

        let isMetric  = TemperatureFormatter.isMetric
        let speedUnit = isMetric ? "km/h" : "mph"
        let distUnit  = isMetric ? "km"   : "mi"

        let windStr  = current.windSpeed.map { "\(Int($0.rounded())) \(speedUnit)" } ?? "—"
        let gustStr  = current.windGust.map  { "\(Int($0.rounded())) \(speedUnit)" } ?? "—"
        let humidStr = current.humidity.map  { "\(Int($0.rounded()))%" }              ?? "—"
        let uvStr    = current.uvIndex.map   { uvLabel(for: $0) }                     ?? "—"
        let visStr   = current.visibility.map { String(format: "%.1f \(distUnit)", $0) } ?? "—"
        let pressStr = current.pressure.map  { "\(Int($0.rounded())) mb" }            ?? "—"
        let dewStr   = TemperatureFormatter.format(current.dewPoint)
        let cloudStr = current.cloudCover.map { "\(Int($0.rounded()))%" }             ?? "—"

        let values = [windStr, gustStr, humidStr, uvStr, visStr, pressStr, dewStr, cloudStr]
        zip(tiles, values).forEach { $0.update(value: $1) }
    }

    private func uvLabel(for uv: Double) -> String {
        let i = Int(uv.rounded())
        switch i {
        case 0...2:  return "\(i) Low"
        case 3...5:  return "\(i) Moderate"
        case 6...7:  return "\(i) High"
        case 8...10: return "\(i) Very High"
        default:     return "\(i) Extreme"
        }
    }
}

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

// MARK: - Card

class DetailsCardView: CardView {

    private var tiles: [DetailTileView] = []

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

        addSubview(outer)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            outer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            outer.leadingAnchor.constraint(equalTo: leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: trailingAnchor),
            outer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure

    func configure(with current: CurrentConditions) {
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

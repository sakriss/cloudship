//
//  HourlyCardView.swift
//  Cloudship
//
//  Horizontal scroll strip showing hourly forecast.
//  Filter pill buttons switch the primary metric displayed and the sparkline curve.
//

import UIKit

// MARK: - Metric definition

enum HourlyMetric: String, CaseIterable {
    case temp         = "Temp"
    case feelsLike    = "Feels Like"
    case precipChance = "Precip %"
    case precipAmount = "Precip Amt"
    case windSpeed    = "Wind"
    case windGust     = "Gusts"
    case uvIndex      = "UV Index"
    case humidity     = "Humidity"
    case cloudCover   = "Cloud Cover"
    case visibility   = "Visibility"
    case pressure     = "Pressure"

    /// Returns nil if no entry has a value for this metric.
    func hasData(in entries: [HourlyEntry]) -> Bool {
        entries.contains { value(from: $0) != nil }
    }

    func value(from entry: HourlyEntry) -> Double? {
        switch self {
        case .temp:         return entry.temp
        case .feelsLike:    return entry.feelsLike
        case .precipChance: return entry.precipChance
        case .precipAmount: return entry.precipAmount
        case .windSpeed:    return entry.windSpeed
        case .windGust:     return entry.windGust
        case .uvIndex:      return entry.uvIndex
        case .humidity:     return entry.humidity
        case .cloudCover:   return entry.cloudCover
        case .visibility:   return entry.visibility
        case .pressure:     return entry.pressure
        }
    }

    func formatted(_ value: Double) -> String {
        let isMetric = TemperatureFormatter.isMetric
        switch self {
        case .temp, .feelsLike:
            return TemperatureFormatter.format(value) ?? "\(Int(value.rounded()))°"
        case .precipChance:
            return "\(Int(value.rounded()))%"
        case .precipAmount:
            return isMetric ? String(format: "%.1f mm", value) : String(format: "%.2f\"", value)
        case .windSpeed, .windGust:
            return isMetric ? "\(Int(value.rounded())) kph" : "\(Int(value.rounded())) mph"
        case .uvIndex:
            return String(format: "%.1f", value)
        case .humidity:
            return "\(Int(value.rounded()))%"
        case .cloudCover:
            return "\(Int(value.rounded()))%"
        case .visibility:
            return isMetric ? String(format: "%.1f km", value) : String(format: "%.1f mi", value)
        case .pressure:
            return isMetric ? "\(Int(value.rounded())) hPa" : String(format: "%.2f inHg", value)
        }
    }

    var accentColor: UIColor {
        switch self {
        case .temp, .feelsLike:    return UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        case .precipChance,
             .precipAmount:        return UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1)
        case .windSpeed, .windGust: return UIColor(red: 0.45, green: 0.85, blue: 0.65, alpha: 1)
        case .uvIndex:             return UIColor(red: 0.95, green: 0.75, blue: 0.20, alpha: 1)
        case .humidity:            return UIColor(red: 0.50, green: 0.70, blue: 0.95, alpha: 1)
        case .cloudCover:          return UIColor(red: 0.75, green: 0.75, blue: 0.80, alpha: 1)
        case .visibility:          return UIColor(red: 0.60, green: 0.85, blue: 0.80, alpha: 1)
        case .pressure:            return UIColor(red: 0.85, green: 0.60, blue: 0.90, alpha: 1)
        }
    }
}

// MARK: - Sparkline curve

private class HourlyCurveView: UIView {

    /// One optional value per hourly column. Nil = no data for that column.
    var values: [Double?] = [] { didSet { setNeedsDisplay() } }
    var color: UIColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1) { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { super.init(coder: coder)!; backgroundColor = .clear }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    /// The width of each hourly column cell — must match `HourlyCardView.itemWidth`.
    var itemWidth: CGFloat = 64 { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        let nonNil = values.compactMap { $0 }
        guard nonNil.count >= 2, let ctx = UIGraphicsGetCurrentContext() else { return }

        let n = values.count
        let minV = nonNil.min()!
        let maxV = nonNil.max()!
        let range = maxV - minV
        // Each dot sits at the horizontal center of its column cell
        let step = itemWidth

        func yPos(_ v: Double) -> CGFloat {
            if range > 0 {
                return rect.height - CGFloat((v - minV) / range) * rect.height * 0.8 - rect.height * 0.1
            }
            return rect.height * 0.5
        }

        // Build segments: consecutive runs of non-nil values share a path
        var segments: [[Int]] = []
        var current: [Int] = []
        for i in 0..<n {
            if values[i] != nil {
                current.append(i)
            } else {
                if current.count >= 2 { segments.append(current) }
                current = []
            }
        }
        if current.count >= 2 { segments.append(current) }

        // Draw each segment
        let halfStep = step / 2
        for seg in segments {
            let path = UIBezierPath()
            for (j, i) in seg.enumerated() {
                let x = CGFloat(i) * step + halfStep
                let y = yPos(values[i]!)
                let pt = CGPoint(x: x, y: y)
                if j == 0 {
                    path.move(to: pt)
                } else {
                    let prevI = seg[j - 1]
                    let prevX = CGFloat(prevI) * step + halfStep
                    let prevY = yPos(values[prevI]!)
                    let prev = CGPoint(x: prevX, y: prevY)
                    let cp1 = CGPoint(x: prev.x + step * 0.4, y: prev.y)
                    let cp2 = CGPoint(x: pt.x  - step * 0.4, y: pt.y)
                    path.addCurve(to: pt, controlPoint1: cp1, controlPoint2: cp2)
                }
            }

            // Gradient fill under each segment
            let fillPath = path.copy() as! UIBezierPath
            let lastI = seg.last!
            fillPath.addLine(to: CGPoint(x: CGFloat(lastI) * step + halfStep, y: rect.height))
            fillPath.addLine(to: CGPoint(x: CGFloat(seg.first!) * step + halfStep, y: rect.height))
            fillPath.close()

            ctx.saveGState()
            fillPath.addClip()
            let gradColors = [color.withAlphaComponent(0.35).cgColor,
                              color.withAlphaComponent(0.00).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: gradColors, locations: [0, 1]) {
                ctx.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: 0),
                                       end:   CGPoint(x: 0, y: rect.height),
                                       options: [])
            }
            ctx.restoreGState()

            color.setStroke()
            path.lineWidth = 2
            path.stroke()

            // Dots at each data point in this segment
            for i in seg {
                let x = CGFloat(i) * step + halfStep
                let y = yPos(values[i]!)
                let dot = UIBezierPath(arcCenter: CGPoint(x: x, y: y),
                                       radius: 3, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                color.setFill()
                dot.fill()
            }
        }
    }
}

// MARK: - Cell

private class HourlyItemCell: UICollectionViewCell {

    static let reuseID = "HourlyItemCell"

    private let hourLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .primary)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let precipLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [hourLabel, iconView, precipLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            precipLabel.heightAnchor.constraint(equalToConstant: 14),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(entry: HourlyEntry, metric: HourlyMetric) {
        hourLabel.textColor = CardView.textColor(for: .secondary)
        hourLabel.text = DateFormatHelper.hourLabel(from: entry.time)
        iconView.image = UIImage(named: WeatherCodeMapper.iconName(for: entry.condition,
                                                                    isNight: WeatherCodeMapper.isNighttime()))

        // Primary value label
        if let v = metric.value(from: entry) {
            valueLabel.text = metric.formatted(v)
            valueLabel.textColor = metric.accentColor
        } else {
            valueLabel.text = "—"
            valueLabel.textColor = CardView.textColor(for: .tertiary)
        }

        // Always show precip % underneath when not already showing it
        if metric != .precipChance, let chance = entry.precipChance, chance > 0 {
            precipLabel.text = "\(Int(chance.rounded()))%"
            precipLabel.isHidden = false
        } else {
            precipLabel.text = nil
            precipLabel.isHidden = true
        }

        // VoiceOver
        isAccessibilityElement = true
        var parts: [String] = []
        if let hour = hourLabel.text { parts.append(hour) }
        let condition = WeatherCodeMapper.description(for: entry.condition)
        if !condition.isEmpty { parts.append(condition) }
        if let val = valueLabel.text, val != "—" { parts.append("\(metric.rawValue): \(val)") }
        if let precip = precipLabel.text, !precipLabel.isHidden { parts.append("Precipitation: \(precip)") }
        accessibilityLabel = parts.joined(separator: ", ")
    }
}

// MARK: - Pill button

private class MetricPillButton: UIButton {

    let metric: HourlyMetric

    init(metric: HourlyMetric) {
        self.metric = metric
        super.init(frame: .zero)
        setTitle(metric.rawValue, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        titleLabel?.adjustsFontForContentSizeCategory = true
        layer.cornerRadius = 14
        layer.borderWidth = 1
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        isSelected = false
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateAppearance() {
        if isSelected {
            let fillAlpha: CGFloat = WeatherDataSourceManager.shared.isShowingHistorical ? 0.26 : 0.20
            backgroundColor = metric.accentColor.withAlphaComponent(fillAlpha)
            layer.borderColor = metric.accentColor.cgColor
            setTitleColor(metric.accentColor, for: .normal)
        } else {
            backgroundColor = .clear
            layer.borderColor = CardView.textColor(for: .tertiary).withAlphaComponent(0.35).cgColor
            setTitleColor(CardView.textColor(for: .secondary), for: .normal)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }
}

// MARK: - Card

class HourlyCardView: CardView {

    /// Called whenever the user taps a metric pill. Use this to sync the daily card.
    var onMetricChanged: ((HourlyMetric) -> Void)?

    private var entries: [HourlyEntry] = []
    private var activeMetric: HourlyMetric = .temp
    private var pillButtons: [MetricPillButton] = []

    private var curveView = HourlyCurveView()
    private var collectionView: UICollectionView!
    private var pillScrollView: UIScrollView!
    private var pillStack: UIStackView!
    private var titleLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private static let itemWidth: CGFloat = 64
    private static let curveHeight: CGFloat = 54

    private func setupLayout() {
        let p = CardView.padding
        titleLabel = makeTitleLabel(text: "Hourly Forecast")

        // Pill scroll view
        pillScrollView = UIScrollView()
        pillScrollView.showsHorizontalScrollIndicator = false
        pillScrollView.translatesAutoresizingMaskIntoConstraints = false

        pillStack = UIStackView()
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.translatesAutoresizingMaskIntoConstraints = false
        pillScrollView.addSubview(pillStack)

        for metric in HourlyMetric.allCases {
            let btn = MetricPillButton(metric: metric)
            btn.isHidden = true
            btn.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)
            pillStack.addArrangedSubview(btn)
            pillButtons.append(btn)
        }

        // Collection view — taller to contain the scrolling curve below cells
        let totalCellHeight: CGFloat = 100
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Self.itemWidth, height: totalCellHeight)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: p, bottom: 0, right: p)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(HourlyItemCell.self, forCellWithReuseIdentifier: HourlyItemCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        // Extra height for the curve that sits below cells but inside the scroll view
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Self.curveHeight, right: 0)

        // Curve lives inside the collection view's scroll area so it scrolls with it
        collectionView.addSubview(curveView)

        addSubview(titleLabel)
        addSubview(pillScrollView)
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            pillScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            pillScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            pillScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            pillScrollView.heightAnchor.constraint(equalToConstant: 30),

            pillStack.topAnchor.constraint(equalTo: pillScrollView.topAnchor),
            pillStack.leadingAnchor.constraint(equalTo: pillScrollView.leadingAnchor),
            pillStack.trailingAnchor.constraint(equalTo: pillScrollView.trailingAnchor),
            pillStack.bottomAnchor.constraint(equalTo: pillScrollView.bottomAnchor),
            pillStack.heightAnchor.constraint(equalTo: pillScrollView.heightAnchor),

            collectionView.topAnchor.constraint(equalTo: pillScrollView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: totalCellHeight + Self.curveHeight),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    func configure(hourly: [HourlyEntry]) {
        applyTextPalette()
        entries = Array(hourly.prefix(24))

        // Reveal only pills that have data; select first available
        var firstWithData: HourlyMetric?
        for btn in pillButtons {
            let has = btn.metric.hasData(in: entries)
            btn.isHidden = !has
            if has && firstWithData == nil {
                firstWithData = btn.metric
            }
        }

        // Keep current selection if still valid, else reset to first available
        if !activeMetric.hasData(in: entries) {
            activeMetric = firstWithData ?? .temp
        }

        updateSelection()
        collectionView.reloadData()
        updateCurve()
    }

    override func applyVintageStyle() {
        super.applyVintageStyle()
        applyTextPalette()
        collectionView.reloadData()
    }

    override func restoreTint() {
        super.restoreTint()
        applyTextPalette()
        collectionView.reloadData()
    }

    private func updateSelection() {
        titleLabel.textColor = CardView.textColor(for: .secondary)
        for btn in pillButtons {
            btn.isSelected = btn.metric == activeMetric
            btn.updateAppearance()
        }
    }

    private func updateCurve() {
        // Use map (not compactMap) so each value aligns with its column index
        let vals = entries.map { activeMetric.value(from: $0) }
        curveView.values = vals
        curveView.color = activeMetric.accentColor
        curveView.itemWidth = Self.itemWidth

        // Position curve below the cells, spanning the full scrollable content width.
        // x = sectionInset.left so column 0 in the curve aligns with cell 0 in the collection.
        let p = CardView.padding
        let curveWidth = CGFloat(entries.count) * Self.itemWidth
        curveView.frame = CGRect(
            x: p,
            y: 100 + 4,
            width: max(curveWidth, 0),
            height: Self.curveHeight - 4
        )
    }

    @objc private func pillTapped(_ sender: MetricPillButton) {
        guard activeMetric != sender.metric else { return }
        activeMetric = sender.metric
        updateSelection()
        collectionView.reloadData()
        UIView.transition(with: curveView, duration: 0.25, options: .transitionCrossDissolve) {
            self.updateCurve()
        }
        onMetricChanged?(activeMetric)
    }

    private func applyTextPalette() {
        titleLabel?.textColor = CardView.textColor(for: .secondary)
        pillButtons.forEach { $0.updateAppearance() }
    }
}

// MARK: - UICollectionViewDataSource

extension HourlyCardView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        entries.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyItemCell.reuseID, for: indexPath) as! HourlyItemCell
        cell.configure(entry: entries[indexPath.item], metric: activeMetric)
        return cell
    }
}

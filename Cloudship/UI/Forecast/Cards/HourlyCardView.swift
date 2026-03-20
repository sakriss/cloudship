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

    var values: [Double] = [] { didSet { setNeedsDisplay() } }
    var color: UIColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1) { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { super.init(coder: coder)!; backgroundColor = .clear }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard values.count >= 2, let ctx = UIGraphicsGetCurrentContext() else { return }
        let minV = values.min()!
        let maxV = values.max()!
        let range = maxV - minV
        let n = values.count
        let step = rect.width / CGFloat(n - 1)

        func point(at i: Int) -> CGPoint {
            let x = CGFloat(i) * step
            let y: CGFloat
            if range > 0 {
                y = rect.height - CGFloat((values[i] - minV) / range) * rect.height * 0.8 - rect.height * 0.1
            } else {
                y = rect.height * 0.5
            }
            return CGPoint(x: x, y: y)
        }

        let path = UIBezierPath()
        path.move(to: point(at: 0))
        for i in 1..<n {
            let prev = point(at: i - 1)
            let curr = point(at: i)
            let cp1  = CGPoint(x: prev.x + step * 0.4, y: prev.y)
            let cp2  = CGPoint(x: curr.x - step * 0.4, y: curr.y)
            path.addCurve(to: curr, controlPoint1: cp1, controlPoint2: cp2)
        }

        // Gradient fill
        let fillPath = path.copy() as! UIBezierPath
        fillPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        fillPath.addLine(to: CGPoint(x: 0, y: rect.height))
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

        // Stroke
        color.setStroke()
        path.lineWidth = 2
        path.stroke()

        // Dots
        for i in 0..<n {
            let p = point(at: i)
            let dot = UIBezierPath(arcCenter: p, radius: 3, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            color.setFill()
            dot.fill()
        }
    }
}

// MARK: - Cell

private class HourlyItemCell: UICollectionViewCell {

    static let reuseID = "HourlyItemCell"

    private let hourLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .secondaryLabel
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
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let precipLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
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
        hourLabel.text = DateFormatHelper.hourLabel(from: entry.time)
        iconView.image = UIImage(named: WeatherCodeMapper.iconName(for: entry.condition,
                                                                    isNight: WeatherCodeMapper.isNighttime()))

        // Primary value label
        if let v = metric.value(from: entry) {
            valueLabel.text = metric.formatted(v)
            valueLabel.textColor = metric.accentColor
        } else {
            valueLabel.text = "—"
            valueLabel.textColor = .tertiaryLabel
        }

        // Always show precip % underneath when not already showing it
        if metric != .precipChance, let chance = entry.precipChance, chance > 0 {
            precipLabel.text = "\(Int(chance.rounded()))%"
            precipLabel.isHidden = false
        } else {
            precipLabel.text = nil
            precipLabel.isHidden = true
        }
    }
}

// MARK: - Pill button

private class MetricPillButton: UIButton {

    let metric: HourlyMetric

    init(metric: HourlyMetric) {
        self.metric = metric
        super.init(frame: .zero)
        setTitle(metric.rawValue, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        layer.cornerRadius = 14
        layer.borderWidth = 1
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        isSelected = false
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateAppearance() {
        if isSelected {
            backgroundColor = metric.accentColor.withAlphaComponent(0.20)
            layer.borderColor = metric.accentColor.cgColor
            setTitleColor(metric.accentColor, for: .normal)
        } else {
            backgroundColor = .clear
            layer.borderColor = UIColor.separator.cgColor
            setTitleColor(.secondaryLabel, for: .normal)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }
}

// MARK: - Card

class HourlyCardView: CardView {

    private var entries: [HourlyEntry] = []
    private var activeMetric: HourlyMetric = .temp
    private var pillButtons: [MetricPillButton] = []

    private var curveView = HourlyCurveView()
    private var collectionView: UICollectionView!
    private var pillScrollView: UIScrollView!
    private var pillStack: UIStackView!

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
        let titleLabel = makeTitleLabel(text: "Hourly Forecast")

        // Pill scroll view
        pillScrollView = UIScrollView()
        pillScrollView.showsHorizontalScrollIndicator = false
        pillScrollView.translatesAutoresizingMaskIntoConstraints = false

        pillStack = UIStackView()
        pillStack.axis = .horizontal
        pillStack.spacing = 8
        pillStack.translatesAutoresizingMaskIntoConstraints = false
        pillScrollView.addSubview(pillStack)

        // Build all pills (hidden until configure() reveals only those with data)
        for metric in HourlyMetric.allCases {
            let btn = MetricPillButton(metric: metric)
            btn.isHidden = true
            btn.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)
            pillStack.addArrangedSubview(btn)
            pillButtons.append(btn)
        }

        // Collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 64, height: 100)
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: p, bottom: 0, right: p)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(HourlyItemCell.self, forCellWithReuseIdentifier: HourlyItemCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        curveView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(pillScrollView)
        addSubview(collectionView)
        addSubview(curveView)

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
            collectionView.heightAnchor.constraint(equalToConstant: 100),

            curveView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 4),
            curveView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            curveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            curveView.heightAnchor.constraint(equalToConstant: 50),
            curveView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    func configure(hourly: [HourlyEntry]) {
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

    private func updateSelection() {
        for btn in pillButtons {
            btn.isSelected = btn.metric == activeMetric
            btn.updateAppearance()
        }
    }

    private func updateCurve() {
        let vals = entries.compactMap { activeMetric.value(from: $0) }
        curveView.values = vals
        curveView.color = activeMetric.accentColor
    }

    @objc private func pillTapped(_ sender: MetricPillButton) {
        guard activeMetric != sender.metric else { return }
        activeMetric = sender.metric
        updateSelection()
        collectionView.reloadData()
        UIView.transition(with: curveView, duration: 0.25, options: .transitionCrossDissolve) {
            self.updateCurve()
        }
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

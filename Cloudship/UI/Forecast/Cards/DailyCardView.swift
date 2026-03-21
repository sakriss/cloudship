//
//  DailyCardView.swift
//  Cloudship
//
//  7-day daily forecast with temperature range bars.
//

import UIKit

// MARK: - Range bar (Core Graphics)

private class DailyRangeBarView: UIView {

    var minTemp: Double = 0
    var maxTemp: Double = 0
    var absMin: Double = 0
    var absMax: Double = 0

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
        let range = absMax - absMin
        guard range > 0 else { return }

        // Full-width background track
        let trackRect = CGRect(x: 0, y: h / 2 - 3, width: w, height: 6)
        let trackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: 3)
        UIColor.tertiarySystemFill.resolvedColor(with: traitCollection).setFill()
        trackPath.fill()

        // Colored segment for this day's range
        let startX = CGFloat((minTemp - absMin) / range) * w
        let endX   = CGFloat((maxTemp - absMin) / range) * w
        let segW = max(endX - startX, 6)
        let segRect = CGRect(x: startX, y: h / 2 - 3, width: segW, height: 6)
        let segPath = UIBezierPath(roundedRect: segRect, cornerRadius: 3)

        // Gradient: cool blue → warm orange
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
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: startX, y: 0),
            end:   CGPoint(x: startX + segW, y: 0),
            options: []
        )
        ctx.restoreGState()
    }
}

// MARK: - Single row

private class DailyRowView: UIView {

    private let dayLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
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
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let minTempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rangeBar = DailyRangeBarView()

    private let maxTempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .left
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        rangeBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dayLabel)
        addSubview(iconView)
        addSubview(precipLabel)
        addSubview(minTempLabel)
        addSubview(rangeBar)
        addSubview(maxTempLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CardView.padding),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            dayLabel.widthAnchor.constraint(equalToConstant: 48),

            iconView.leadingAnchor.constraint(equalTo: dayLabel.trailingAnchor, constant: 4),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            precipLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            precipLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            precipLabel.widthAnchor.constraint(equalToConstant: 36),

            minTempLabel.leadingAnchor.constraint(equalTo: precipLabel.trailingAnchor, constant: 6),
            minTempLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            minTempLabel.widthAnchor.constraint(equalToConstant: 38),

            rangeBar.leadingAnchor.constraint(equalTo: minTempLabel.trailingAnchor, constant: 6),
            rangeBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            rangeBar.heightAnchor.constraint(equalToConstant: 20),

            maxTempLabel.leadingAnchor.constraint(equalTo: rangeBar.trailingAnchor, constant: 6),
            maxTempLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -CardView.padding),
            maxTempLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            maxTempLabel.widthAnchor.constraint(equalToConstant: 38)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(entry: DailyEntry, absMin: Double, absMax: Double) {
        dayLabel.text  = DateFormatHelper.dailyLabel(from: entry.time)
        iconView.image = UIImage(named: WeatherCodeMapper.iconName(for: entry.condition,
                                                                    isNight: false))
        precipLabel.text  = entry.precipChance.map { "\(Int($0.rounded()))%" } ?? ""
        minTempLabel.text = TemperatureFormatter.format(entry.tempMin)
        maxTempLabel.text = TemperatureFormatter.format(entry.tempMax)

        rangeBar.absMin  = absMin
        rangeBar.absMax  = absMax
        rangeBar.minTemp = entry.tempMin ?? absMin
        rangeBar.maxTemp = entry.tempMax ?? absMax
        rangeBar.setNeedsDisplay()
    }
}

// MARK: - Card

class DailyCardView: CardView {

    // Callback fired with the tapped DailyEntry and its index
    var onDayTapped: ((DailyEntry, Int) -> Void)?

    private var rowViews: [DailyRowView] = []
    private var dailyEntries: [DailyEntry] = []

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
        let titleLabel = makeTitleLabel(text: "7-Day Forecast")
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

    func configure(daily: [DailyEntry]) {
        guard !daily.isEmpty else { return }
        dailyEntries = daily
        let allMins = daily.compactMap(\.tempMin)
        let allMaxs = daily.compactMap(\.tempMax)
        let absMin = allMins.min() ?? 0
        let absMax = allMaxs.max() ?? 100

        for (i, row) in rowViews.enumerated() {
            if i < daily.count {
                row.isHidden = false
                row.configure(entry: daily[i], absMin: absMin, absMax: absMax)
                row.tag = i
            } else {
                row.isHidden = true
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

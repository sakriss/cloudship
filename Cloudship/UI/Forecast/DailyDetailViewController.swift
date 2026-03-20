//
//  DailyDetailViewController.swift
//  Cloudship
//
//  Pushed when the user taps a day in the 7-day forecast.
//  Shows day/night conditions, an hourly icon strip, and detail tiles.
//

import UIKit

class DailyDetailViewController: UIViewController {

    // MARK: - Data

    private let entry: DailyEntry
    private let hourly: [HourlyEntry]   // all hourly data — filtered to this day
    private let units: String           // "imperial" or "metric"

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    init(entry: DailyEntry, allHourly: [HourlyEntry]) {
        self.entry  = entry
        self.units  = UserDefaults.standard.string(forKey: "Units") ?? "imperial"
        // Filter hourly entries that fall on the same calendar day as entry.time
        let cal = Calendar.current
        self.hourly = allHourly.filter { cal.isDate($0.time, inSameDayAs: entry.time) }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(entry:allHourly:)") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        // Title: "Saturday, March 21"
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"
        title = df.string(from: entry.time)
        navigationItem.largeTitleDisplayMode = .never

        setupLayout()
        buildContent()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Content

    private func buildContent() {
        // 1. Day / Night condition card
        contentStack.addArrangedSubview(makeDayNightCard())

        // 2. Hourly icon strip (if we have hourly data for this day)
        if !hourly.isEmpty {
            contentStack.addArrangedSubview(makeHourlyStripCard())
        }

        // 3. Detail tiles grid
        contentStack.addArrangedSubview(makeDetailTilesCard())
    }

    // MARK: - Day / Night card

    private func makeDayNightCard() -> UIView {
        let card = roundedCard()

        let iconDay = WeatherCodeMapper.iconName(for: entry.condition, isNight: false)
        let iconNight = WeatherCodeMapper.iconName(for: entry.conditionNight, isNight: true)

        let dayRow = makeConditionRow(
            imageName: iconDay,
            label: dayName(),
            description: entry.dayDescription ?? entry.condition.description
        )
        let nightRow = makeConditionRow(
            imageName: iconNight,
            label: dayName() + " Night",
            description: entry.nightDescription ?? entry.conditionNight.description
        )

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let stack = UIStackView(arrangedSubviews: [dayRow, divider, nightRow])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeConditionRow(imageName: String, label: String, description: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let img = UIImageView(image: UIImage(named: imageName))
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(img)
        container.addSubview(textStack)

        NSLayoutConstraint.activate([
            img.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            img.topAnchor.constraint(equalTo: container.topAnchor),
            img.widthAnchor.constraint(equalToConstant: 32),
            img.heightAnchor.constraint(equalToConstant: 32),

            textStack.leadingAnchor.constraint(equalTo: img.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        return container
    }

    // MARK: - Hourly icon strip

    private func makeHourlyStripCard() -> UIView {
        let card = roundedCard()
        let strip = DailyHourlyStripView(entries: hourly)
        strip.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(strip)
        NSLayoutConstraint.activate([
            strip.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            strip.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            strip.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            strip.heightAnchor.constraint(equalToConstant: 64)
        ])
        return card
    }

    // MARK: - Detail tiles

    private func makeDetailTilesCard() -> UIView {
        let card = roundedCard()
        let isImperial = units == "imperial"

        // Build tile data
        var tiles: [(icon: String, value: String, name: String)] = []

        if let tMax = entry.tempMax, let tMin = entry.tempMin {
            tiles.append(("thermometer.medium", "\(fmt(tMin))–\(fmt(tMax))\(degSymbol)", "Temperature"))
        }
        if let fMax = entry.feelsLikeMax, let fMin = entry.feelsLikeMin {
            tiles.append(("thermometer.low", "\(fmt(fMin))–\(fmt(fMax))\(degSymbol)", "Feels Like"))
        }
        if let p = entry.precipChance {
            tiles.append(("umbrella", "\(Int(p))%", "Precip Chance"))
        }
        if let a = entry.precipAmount {
            let unit = isImperial ? "in" : "mm"
            tiles.append(("drop", String(format: "%.2f \(unit)", a), "Precip Amount"))
        }
        if let sunrise = entry.sunrise {
            tiles.append(("sunrise", timeString(sunrise), "Sunrise"))
        }
        if let sunset = entry.sunset {
            tiles.append(("sunset", timeString(sunset), "Sunset"))
        }
        if !entry.moonPhaseName.isEmpty {
            tiles.append(("moon.stars", entry.moonPhaseName, "Moon Phase"))
        }

        // Layout tiles in a 2-column grid
        var rows: [UIView] = []
        var i = 0
        while i < tiles.count {
            let left  = makeTile(icon: tiles[i].icon, value: tiles[i].value, name: tiles[i].name)
            var right: UIView
            if i + 1 < tiles.count {
                right = makeTile(icon: tiles[i+1].icon, value: tiles[i+1].value, name: tiles[i+1].name)
            } else {
                // Last tile alone — fill with empty spacer
                right = UIView()
            }

            let row = UIStackView(arrangedSubviews: [left, right])
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 0
            rows.append(row)
            i += 2
        }

        let grid = UIStackView(arrangedSubviews: rows)
        grid.axis = .vertical
        grid.spacing = 0
        grid.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            grid.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])
        return card
    }

    private func makeTile(icon: String, value: String, name: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Top separator
        let topLine = UIView()
        topLine.backgroundColor = .separator
        topLine.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = name.uppercased()
        nameLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .medium)
        valueLabel.textColor = .label
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(topLine)
        container.addSubview(iconView)
        container.addSubview(nameLabel)
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: container.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 0.5),

            iconView.topAnchor.constraint(equalTo: topLine.bottomAnchor, constant: 14),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            nameLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),

            valueLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
        return container
    }

    // MARK: - Helpers

    private func roundedCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func dayName() -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: entry.time)
    }

    private var degSymbol: String { "°" }

    private func fmt(_ val: Double) -> String {
        return "\(Int(val.rounded()))"
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df.string(from: date)
    }
}

// MARK: - Horizontal hourly icon strip (no temps, just icons + time labels)

private class DailyHourlyStripView: UIScrollView {

    init(entries: [HourlyEntry]) {
        super.init(frame: .zero)
        showsHorizontalScrollIndicator = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // Time formatter
        let df = DateFormatter()
        df.dateFormat = "ha"

        for entry in entries {
            let cell = makeCell(entry: entry, df: df)
            stack.addArrangedSubview(cell)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeCell(entry: HourlyEntry, df: DateFormatter) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let timeLabel = UILabel()
        timeLabel.text = df.string(from: entry.time).lowercased()
        timeLabel.font = .systemFont(ofSize: 10, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconName = WeatherCodeMapper.iconName(for: entry.condition, isNight: false)
        let iconView = UIImageView(image: UIImage(named: iconName))
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(timeLabel)
        container.addSubview(iconView)

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: container.topAnchor),
            timeLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            iconView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            iconView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }
}

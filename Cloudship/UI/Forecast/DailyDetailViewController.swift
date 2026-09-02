//
//  DailyDetailViewController.swift
//  Cloudship
//
//  Shows all 7 daily forecasts stacked vertically.
//  Automatically scrolls to the day that was tapped.
//

import UIKit

class DailyDetailViewController: UIViewController {

    // MARK: - Data

    private let entries: [DailyEntry]
    private let selectedIndex: Int
    private let allHourly: [HourlyEntry]
    private let units: String

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Y offsets for each day section, set during layout
    private var sectionOffsets: [CGFloat] = []

    // MARK: - Init

    init(entries: [DailyEntry], selectedIndex: Int, allHourly: [HourlyEntry]) {
        self.entries       = entries
        self.selectedIndex = selectedIndex
        self.allHourly     = allHourly
        self.units         = UserDefaults.standard.string(forKey: "Units") ?? "imperial"
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(entries:selectedIndex:allHourly:)") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "7-Day Forecast"
        navigationItem.largeTitleDisplayMode = .never

        setupLayout()
        buildAllDays()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToSelected()
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

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Build all day sections

    private func buildAllDays() {
        let cal = Calendar.current

        for (i, entry) in entries.enumerated() {
            // Day header
            let header = makeDayHeader(entry: entry, index: i)
            contentStack.addArrangedSubview(header)

            // Inner padding container
            let sectionStack = UIStackView()
            sectionStack.axis = .vertical
            sectionStack.spacing = 12
            sectionStack.translatesAutoresizingMaskIntoConstraints = false

            let padding = UIView()
            padding.translatesAutoresizingMaskIntoConstraints = false
            let innerStack = UIStackView(arrangedSubviews: [sectionStack])
            innerStack.axis = .vertical
            innerStack.translatesAutoresizingMaskIntoConstraints = false

            let wrapper = UIView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false
            wrapper.addSubview(sectionStack)
            NSLayoutConstraint.activate([
                sectionStack.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 12),
                sectionStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
                sectionStack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
                sectionStack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -20)
            ])
            contentStack.addArrangedSubview(wrapper)

            // Day/Night card
            sectionStack.addArrangedSubview(makeDayNightCard(entry: entry))

            // Hourly strip
            let dayHourly = allHourly.filter { cal.isDate($0.time, inSameDayAs: entry.time) }
            if !dayHourly.isEmpty {
                sectionStack.addArrangedSubview(makeHourlyStripCard(hourly: dayHourly))
            }

            // Detail tiles
            sectionStack.addArrangedSubview(makeDetailTilesCard(entry: entry))

            // Separator between days (not after last)
            if i < entries.count - 1 {
                let sep = makeSectionSeparator()
                contentStack.addArrangedSubview(sep)
            }
        }
    }

    private func scrollToSelected() {
        guard selectedIndex > 0 else { return }

        // Walk subviews to find the header for selectedIndex
        // Each day = header + wrapper + (optional separator) = 2 or 3 arranged subviews
        // Easier: collect all headers and wrappers, then scroll to the right header
        let arrangedViews = contentStack.arrangedSubviews
        // Pattern: [header0, wrapper0, sep0, header1, wrapper1, sep1, ..., headerN, wrapperN]
        // Each day takes 3 subviews (header + wrapper + sep), except last (2 subviews)
        let subviewsPerDay = entries.count > 1 ? 3 : 2
        let targetSubviewIndex = selectedIndex * subviewsPerDay  // header of selected day
        guard targetSubviewIndex < arrangedViews.count else { return }

        let targetView = arrangedViews[targetSubviewIndex]
        let targetY = targetView.frame.origin.y

        let maxOffset = scrollView.contentSize.height - scrollView.bounds.height
        let offset = CGPoint(x: 0, y: min(targetY, max(0, maxOffset)))
        scrollView.setContentOffset(offset, animated: true)
    }

    // MARK: - Day header

    private func makeDayHeader(entry: DailyEntry, index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGroupedBackground
        container.translatesAutoresizingMaskIntoConstraints = false

        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        // "Today", "Tomorrow", or day name
        let cal = Calendar.current
        let isToday    = cal.isDateInToday(entry.time)
        let isTomorrow = cal.isDateInTomorrow(entry.time)

        if isToday {
            label.text = "Today — " + df.string(from: entry.time)
        } else if isTomorrow {
            label.text = "Tomorrow — " + df.string(from: entry.time)
        } else {
            label.text = df.string(from: entry.time)
        }

        label.font = .appFont(size: 15, weight: .bold)
        label.textColor = index == selectedIndex
            ? UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
            : .secondaryLabel

        // Selected day gets an accent indicator bar on the left
        let accentBar = UIView()
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        accentBar.backgroundColor = index == selectedIndex
            ? UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
            : .clear
        accentBar.layer.cornerRadius = 2

        container.addSubview(accentBar)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            accentBar.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            label.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        return container
    }

    // MARK: - Day / Night card

    private func makeDayNightCard(entry: DailyEntry) -> UIView {
        let card = roundedCard()

        let iconDay   = WeatherCodeMapper.iconName(for: entry.condition, isNight: false)
        let iconNight = WeatherCodeMapper.iconName(for: entry.conditionNight, isNight: true)

        let dayRow   = makeConditionRow(imageName: iconDay,
                                        label: dayName(entry.time),
                                        description: entry.dayDescription ?? entry.condition.description)
        let divider  = makeDivider()
        let nightRow = makeConditionRow(imageName: iconNight,
                                        label: dayName(entry.time) + " Night",
                                        description: entry.nightDescription ?? entry.conditionNight.description)

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
        nameLabel.font = .appFont(size: 15, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .appFont(size: 14, weight: .regular)
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

    // MARK: - Hourly strip

    private func makeHourlyStripCard(hourly: [HourlyEntry]) -> UIView {
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

    private func makeDetailTilesCard(entry: DailyEntry) -> UIView {
        let card = roundedCard()
        let isImperial = units == "imperial"

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
        if let snow = entry.snowAccumulation, snow > 0 {
            let unit = isImperial ? "in" : "cm"
            tiles.append(("snowflake", String(format: "%.1f \(unit)", snow), "Snow"))
        }
        if let ice = entry.iceAccumulation, ice > 0 {
            let unit = isImperial ? "in" : "cm"
            tiles.append(("thermometer.snowflake", String(format: "%.2f \(unit)", ice), "Ice"))
        }
        if let dawn = entry.dawnTime {
            tiles.append(("sunrise", timeString(dawn), "Dawn"))
        }
        if let sunrise = entry.sunrise {
            tiles.append(("sunrise", timeString(sunrise), "Sunrise"))
        }
        if let sunset = entry.sunset {
            tiles.append(("sunset", timeString(sunset), "Sunset"))
        }
        if let dusk = entry.duskTime {
            tiles.append(("sunset", timeString(dusk), "Dusk"))
        }
        if !entry.moonPhaseName.isEmpty {
            tiles.append(("moon.stars", entry.moonPhaseName, "Moon Phase"))
        }

        var rows: [UIView] = []
        var i = 0
        while i < tiles.count {
            let left  = makeTile(icon: tiles[i].icon, value: tiles[i].value, name: tiles[i].name)
            let right: UIView = i + 1 < tiles.count
                ? makeTile(icon: tiles[i+1].icon, value: tiles[i+1].value, name: tiles[i+1].name)
                : UIView()
            let row = UIStackView(arrangedSubviews: [left, right])
            row.axis = .horizontal
            row.distribution = .fillEqually
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

        let topLine = UIView()
        topLine.backgroundColor = .separator
        topLine.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = name.uppercased()
        nameLabel.font = .appFont(size: 10, weight: .semibold)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .appFont(size: 18, weight: .medium)
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

    // MARK: - Section separator

    private func makeSectionSeparator() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let line = UIView()
        line.backgroundColor = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: v.topAnchor, constant: 8),
            line.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            line.heightAnchor.constraint(equalToConstant: 0.5),
            line.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -8)
        ])
        return v
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
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

    private func dayName(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: date)
    }

    private var degSymbol: String { "°" }

    private func fmt(_ val: Double) -> String { "\(Int(val.rounded()))" }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df.string(from: date)
    }
}

// MARK: - Horizontal hourly icon strip

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

        let df = DateFormatter()
        df.dateFormat = "ha"

        for entry in entries {
            stack.addArrangedSubview(makeCell(entry: entry, df: df))
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
        timeLabel.font = .appFont(size: 10, weight: .regular)
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

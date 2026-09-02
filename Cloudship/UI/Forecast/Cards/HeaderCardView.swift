//  HeaderCardView.swift
//
//  HeaderCardView.swift
//  Cloudship
//
//  Current conditions header: location, large temp, condition, feels like, hi/lo.
//

import UIKit

class HeaderCardView: CardView {

    // MARK: - Subviews

    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let temperatureLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .largeTitle)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .primary)
        l.textAlignment = .left
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let conditionLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let feelsLikeLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .left
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let hiLoLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .left
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let stormProximityLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private let conditionIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let callTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "TODAY'S CALL"
        label.font = .appFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = CardView.textColor(for: .secondary)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let todayCallLabel: UILabel = {
        let label = UILabel()
        label.font = .appFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = CardView.textColor(for: .primary)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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
        let p = CardView.padding
        accessibilityIdentifier = "forecastHeaderCard"
        locationLabel.accessibilityIdentifier = "forecastLocationLabel"
        temperatureLabel.accessibilityIdentifier = "forecastTemperatureLabel"

        let temperatureStack = UIStackView(arrangedSubviews: [
            locationLabel, temperatureLabel, conditionLabel, feelsLikeLabel, hiLoLabel
        ])
        temperatureStack.axis = .vertical
        temperatureStack.spacing = 3
        temperatureStack.alignment = .leading

        let currentRow = UIStackView(arrangedSubviews: [temperatureStack, conditionIcon])
        currentRow.axis = .horizontal
        currentRow.spacing = 12
        currentRow.alignment = .center

        let callStack = UIStackView(arrangedSubviews: [callTitleLabel, todayCallLabel, stormProximityLabel])
        callStack.axis = .vertical
        callStack.spacing = 6
        callStack.alignment = .fill

        let stack = UIStackView(arrangedSubviews: [currentRow, divider, callStack])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            conditionIcon.widthAnchor.constraint(equalToConstant: 88),
            conditionIcon.heightAnchor.constraint(equalToConstant: 88),
            divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: p),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    // MARK: - Configure

    func configure(with data: UnifiedWeatherData, todayDaily: DailyEntry?) {
        applyTextPalette()
        let c = data.current
        locationLabel.text = data.locationName ?? "—"
        temperatureLabel.text = TemperatureFormatter.format(c.temperature)
        conditionLabel.text = WeatherCodeMapper.description(for: c.condition)
        conditionIcon.image = UIImage(
            named: WeatherCodeMapper.iconName(
                for: c.condition,
                isNight: WeatherCodeMapper.isNight(
                    at: Date(),
                    sunrise: todayDaily?.sunrise,
                    sunset: todayDaily?.sunset
                )
            )
        )
        conditionIcon.accessibilityLabel = conditionLabel.text

        if let fl = c.feelsLike, let temp = c.temperature {
            let diff = fl - temp
            let absDiff = abs(diff)
            feelsLikeLabel.text = "Feels like \(TemperatureFormatter.format(fl))"

            if absDiff >= 5 {
                // Prominent display when feels-like differs significantly
                feelsLikeLabel.font = .appFont(forTextStyle: .headline)
                feelsLikeLabel.textColor = diff > 0
                    ? UIColor.systemOrange   // feels hotter
                    : UIColor.systemCyan     // feels colder
            } else {
                feelsLikeLabel.font = .appFont(forTextStyle: .body)
                feelsLikeLabel.textColor = CardView.textColor(for: .secondary)
            }
        } else if let fl = c.feelsLike {
            feelsLikeLabel.text = "Feels like \(TemperatureFormatter.format(fl))"
            feelsLikeLabel.font = .appFont(forTextStyle: .body)
            feelsLikeLabel.textColor = CardView.textColor(for: .secondary)
        } else {
            feelsLikeLabel.text = nil
        }

        if let hi = todayDaily?.tempMax, let lo = todayDaily?.tempMin {
            hiLoLabel.text = "High \(TemperatureFormatter.format(hi))  ·  Low \(TemperatureFormatter.format(lo))"
        } else {
            hiLoLabel.text = nil
        }

        todayCallLabel.text = Self.todayCall(for: data, todayDaily: todayDaily)

        // Storm proximity (Pirate Weather only)
        if let distance = c.nearestStormDistance, distance < 100 {
            let direction = Self.cardinalDirection(from: c.nearestStormBearing)
            let distStr = TemperatureFormatter.isMetric
                ? String(format: "%.0f km", distance)
                : String(format: "%.0f mi", distance)
            stormProximityLabel.text = "⛈ Storm \(distStr) \(direction)"
            stormProximityLabel.textColor = Self.stormColor(distance: distance)
            stormProximityLabel.isHidden = false
        } else {
            stormProximityLabel.isHidden = true
        }

        // VoiceOver: combine key info into a single accessibility element
        isAccessibilityElement = true
        var accessibilityParts: [String] = []
        if let location = locationLabel.text, !location.isEmpty {
            accessibilityParts.append(location)
        }
        if let temp = temperatureLabel.text {
            accessibilityParts.append("Current temperature \(temp)")
        }
        if let feels = feelsLikeLabel.text, !feels.isEmpty {
            accessibilityParts.append(feels)
        }
        if let condition = conditionLabel.text, !condition.isEmpty {
            accessibilityParts.append(condition)
        }
        if let hiLo = hiLoLabel.text, !hiLo.isEmpty {
            accessibilityParts.append(hiLo)
        }
        if let call = todayCallLabel.text, !call.isEmpty {
            accessibilityParts.append("Today's call: \(call)")
        }
        if let storm = stormProximityLabel.text, !stormProximityLabel.isHidden {
            accessibilityParts.append(storm)
        }
        accessibilityLabel = accessibilityParts.joined(separator: ", ")
    }

    override func applyVintageStyle() {
        super.applyVintageStyle()
        applyTextPalette()
    }

    override func restoreTint() {
        super.restoreTint()
        applyTextPalette()
    }

    // MARK: - Storm helpers

    private static func cardinalDirection(from bearing: Double?) -> String {
        guard let b = bearing else { return "" }
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((b + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return dirs[min(index, dirs.count - 1)]
    }

    private static func stormColor(distance: Double) -> UIColor {
        switch distance {
        case ..<10:  return .systemRed
        case ..<20:  return .systemOrange
        case ..<50:  return .systemYellow
        default:     return CardView.textColor(for: .secondary)
        }
    }

    private func applyTextPalette() {
        locationLabel.textColor = CardView.textColor(for: .secondary)
        temperatureLabel.textColor = CardView.textColor(for: .primary)
        conditionLabel.textColor = CardView.textColor(for: .secondary)
        hiLoLabel.textColor = CardView.textColor(for: .secondary)
        callTitleLabel.textColor = CardView.textColor(for: .secondary)
        todayCallLabel.textColor = CardView.textColor(for: .primary)
        divider.backgroundColor = CardView.textColor(for: .tertiary).withAlphaComponent(0.28)

        if feelsLikeLabel.textColor != .systemOrange && feelsLikeLabel.textColor != .systemCyan {
            feelsLikeLabel.textColor = CardView.textColor(for: .secondary)
        }
    }

    private static func todayCall(for data: UnifiedWeatherData, todayDaily: DailyEntry?) -> String {
        if let alert = data.alerts.max(by: { $0.severity < $1.severity }) {
            return "Plan around the \(alert.event.lowercased()) and review the alert before heading out."
        }

        let precip = PrecipitationAnalyzer.oneLiner(
            minutely: data.minutely,
            hourly: data.hourly,
            current: data.current
        )
        let lowercasedPrecip = precip.lowercased()
        let namesPrecipitation = ["rain", "snow", "sleet", "drizzle", "storm"].contains {
            lowercasedPrecip.contains($0)
        }
        if namesPrecipitation {
            return "\(precip). Keep weather protection close until conditions settle."
        }

        if let uv = todayDaily?.uvIndex ?? data.current.uvIndex, uv >= 6 {
            return "Good outdoor window, with strong sun. Add shade or sunscreen around midday."
        }

        if let gust = todayDaily?.windGust ?? data.current.windGust, gust >= 25 {
            return "Usable outside, but gusty. Secure loose items and choose sheltered plans."
        }

        if let high = todayDaily?.tempMax {
            let hotThreshold = TemperatureFormatter.isMetric ? 30.0 : 86.0
            let coldThreshold = TemperatureFormatter.isMetric ? 5.0 : 41.0
            if high >= hotThreshold {
                return "Best outside earlier or later. The warmest part of the day may feel demanding."
            }
            if high <= coldThreshold {
                return "A cold day for outdoor plans. Dress in layers and watch exposed conditions."
            }
        }

        return "A comfortable day for outdoor plans, with no major weather disruption expected."
    }
}

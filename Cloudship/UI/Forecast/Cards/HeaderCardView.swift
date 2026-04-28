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
        l.font = .preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let temperatureLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .largeTitle)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .primary)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let conditionLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let feelsLikeLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let hiLoLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .secondary)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let stormProximityLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
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

        let stack = UIStackView(arrangedSubviews: [
            locationLabel,
            temperatureLabel,
            conditionLabel,
            feelsLikeLabel,
            hiLoLabel,
            stormProximityLabel
        ])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
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

        if let fl = c.feelsLike, let temp = c.temperature {
            let diff = fl - temp
            let absDiff = abs(diff)
            feelsLikeLabel.text = "Feels like \(TemperatureFormatter.format(fl))"

            if absDiff >= 5 {
                // Prominent display when feels-like differs significantly
                feelsLikeLabel.font = .preferredFont(forTextStyle: .headline)
                feelsLikeLabel.textColor = diff > 0
                    ? UIColor.systemOrange   // feels hotter
                    : UIColor.systemCyan     // feels colder
            } else {
                feelsLikeLabel.font = .preferredFont(forTextStyle: .body)
                feelsLikeLabel.textColor = CardView.textColor(for: .secondary)
            }
        } else if let fl = c.feelsLike {
            feelsLikeLabel.text = "Feels like \(TemperatureFormatter.format(fl))"
            feelsLikeLabel.font = .preferredFont(forTextStyle: .body)
            feelsLikeLabel.textColor = CardView.textColor(for: .secondary)
        } else {
            feelsLikeLabel.text = nil
        }

        if let hi = todayDaily?.tempMax, let lo = todayDaily?.tempMin {
            hiLoLabel.text = "H: \(TemperatureFormatter.format(hi))  L: \(TemperatureFormatter.format(lo))"
        } else {
            hiLoLabel.text = nil
        }

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

        if feelsLikeLabel.textColor != .systemOrange && feelsLikeLabel.textColor != .systemCyan {
            feelsLikeLabel.textColor = CardView.textColor(for: .secondary)
        }
    }
}

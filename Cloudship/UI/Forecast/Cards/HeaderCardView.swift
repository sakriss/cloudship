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
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let temperatureLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 80, weight: .thin)
        l.textColor = .label
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let conditionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .light)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let feelsLikeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let hiLoLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
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

        let stack = UIStackView(arrangedSubviews: [
            locationLabel,
            temperatureLabel,
            conditionLabel,
            feelsLikeLabel,
            hiLoLabel
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
        let c = data.current
        locationLabel.text = data.locationName ?? "—"
        temperatureLabel.text = TemperatureFormatter.format(c.temperature)
        conditionLabel.text = WeatherCodeMapper.description(for: c.condition)

        if let fl = c.feelsLike {
            feelsLikeLabel.text = "Feels like \(TemperatureFormatter.format(fl))"
        } else {
            feelsLikeLabel.text = nil
        }

        if let hi = todayDaily?.tempMax, let lo = todayDaily?.tempMin {
            hiLoLabel.text = "H: \(TemperatureFormatter.format(hi))  L: \(TemperatureFormatter.format(lo))"
        } else {
            hiLoLabel.text = nil
        }
    }
}

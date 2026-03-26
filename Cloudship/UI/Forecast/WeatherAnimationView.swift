//
//  WeatherAnimationView.swift
//  Cloudship
//
//  Full-screen background photo layer. Sits behind the main scroll view at z-index 0.
//

import UIKit

final class WeatherAnimationView: UIView {

    private(set) var currentCondition: WeatherCondition = .unknown

    func transition(to condition: WeatherCondition, animated: Bool = true) {
        guard condition != currentCondition else { return }
        currentCondition = condition

        let newImage = UIImage(named: backgroundImageName(for: condition))

        if animated {
            UIView.transition(with: backgroundImageView,
                              duration: 0.6,
                              options: .transitionCrossDissolve) {
                self.backgroundImageView.image = newImage
            }
        } else {
            backgroundImageView.image = newImage
        }
    }

    /// Swap to the vintage Time Machine background image.
    func transitionToTimeMachine(animated: Bool = true) {
        let newImage = UIImage(named: "TimeMachineBackground")
        if animated {
            UIView.transition(with: backgroundImageView,
                              duration: 0.8,
                              options: .transitionCrossDissolve) {
                self.backgroundImageView.image = newImage
            }
        } else {
            backgroundImageView.image = newImage
        }
    }

    /// Restore the background for the last known weather condition.
    func restoreWeatherBackground(animated: Bool = true) {
        let image = UIImage(named: backgroundImageName(for: currentCondition))
        if animated {
            UIView.transition(with: backgroundImageView,
                              duration: 0.6,
                              options: .transitionCrossDissolve) {
                self.backgroundImageView.image = image
            }
        } else {
            backgroundImageView.image = image
        }
    }

    // MARK: - Subviews

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let scrimView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let scrimLayer = CAGradientLayer()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false

        addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        scrimLayer.startPoint = CGPoint(x: 0.5, y: 0)
        scrimLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        scrimLayer.colors = [
            UIColor.black.withAlphaComponent(0.35).cgColor,
            UIColor.black.withAlphaComponent(0.10).cgColor
        ]
        scrimView.layer.addSublayer(scrimLayer)
        addSubview(scrimView)
        NSLayoutConstraint.activate([
            scrimView.topAnchor.constraint(equalTo: topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrimLayer.frame = scrimView.bounds
    }

    // MARK: - Condition → photo asset

    private func backgroundImageName(for condition: WeatherCondition) -> String {
        let isNight = WeatherCodeMapper.isNighttime()
        switch condition {
        case .clear:
            return isNight ? "clearnightbackground" : "rainierbackground"
        case .mostlyClear:
            return isNight ? "clearnightbackground" : "partlycloudybackground"
        case .partlyCloudy:
            return isNight ? "partlycloudynightbackground" : "partlycloudybackground"
        case .mostlyCloudy, .cloudy:
            return "mostlycloudybackground"
        case .fog, .lightFog:
            return "fogbackground"
        case .drizzle, .rain, .heavyRain:
            return "rainbackground"
        case .sleet:
            return "sleetbackground"
        case .lightSnow, .snow, .heavySnow:
            return "snowbackground"
        case .thunderstorm:
            return "rainbackground"
        case .windy:
            return "windybackground"
        case .unknown:
            return "rainierbackground"
        }
    }
}

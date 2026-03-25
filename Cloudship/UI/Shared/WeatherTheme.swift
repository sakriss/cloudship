//
//  WeatherTheme.swift
//  Cloudship
//
//  Weather-reactive color themes that shift based on current conditions
//  and time of day. Provides background gradients, card colors, and
//  accent colors that make the app feel alive.
//

import UIKit

// MARK: - Theme definition

struct WeatherTheme {

    let gradientTop: UIColor
    let gradientBottom: UIColor
    let cardBackground: UIColor
    let accentColor: UIColor
    let textPrimary: UIColor
    let textSecondary: UIColor

    /// Blended solid background (for views that can't show gradients).
    var backgroundColor: UIColor {
        gradientTop.withAlphaComponent(0.15)
            .blended(with: .systemBackground)
    }

    /// True when the gradientTop is dark enough to require light (white) text/icons on top.
    var isDark: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        gradientTop.getRed(&r, green: &g, blue: &b, alpha: &a)
        // Standard relative luminance (sRGB)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.50
    }

    /// The appropriate status bar style for this theme.
    var statusBarStyle: UIStatusBarStyle {
        isDark ? .lightContent : .darkContent
    }

    // MARK: - Factory

    /// Derive a theme from a weather condition + whether it's currently night.
    static func theme(for condition: WeatherCondition, isNight: Bool) -> WeatherTheme {
        if isNight {
            return nightTheme(for: condition)
        }
        return dayTheme(for: condition)
    }

    // MARK: - Day themes

    private static func dayTheme(for condition: WeatherCondition) -> WeatherTheme {
        switch condition {
        case .clear, .mostlyClear:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.98, green: 0.85, blue: 0.55, alpha: 1),
                gradientBottom: UIColor(red: 0.95, green: 0.65, blue: 0.30, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.95, green: 0.65, blue: 0.20, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .partlyCloudy, .mostlyCloudy:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.70, green: 0.80, blue: 0.92, alpha: 1),
                gradientBottom: UIColor(red: 0.55, green: 0.68, blue: 0.82, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.50, green: 0.70, blue: 0.90, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .cloudy:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.62, green: 0.66, blue: 0.72, alpha: 1),
                gradientBottom: UIColor(red: 0.50, green: 0.54, blue: 0.60, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.55, green: 0.60, blue: 0.68, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .drizzle, .rain:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.30, green: 0.45, blue: 0.65, alpha: 1),
                gradientBottom: UIColor(red: 0.20, green: 0.35, blue: 0.55, alpha: 1),
                cardBackground: UIColor(red: 0.15, green: 0.20, blue: 0.30, alpha: 0.3)
                    .blended(with: .secondarySystemBackground),
                accentColor:    UIColor(red: 0.30, green: 0.65, blue: 0.90, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .heavyRain:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.20, green: 0.30, blue: 0.50, alpha: 1),
                gradientBottom: UIColor(red: 0.12, green: 0.20, blue: 0.38, alpha: 1),
                cardBackground: UIColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 0.3)
                    .blended(with: .secondarySystemBackground),
                accentColor:    UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .thunderstorm:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.25, green: 0.18, blue: 0.42, alpha: 1),
                gradientBottom: UIColor(red: 0.15, green: 0.10, blue: 0.30, alpha: 1),
                cardBackground: UIColor(red: 0.12, green: 0.10, blue: 0.22, alpha: 0.3)
                    .blended(with: .secondarySystemBackground),
                accentColor:    UIColor(red: 0.95, green: 0.85, blue: 0.30, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .lightSnow, .snow, .heavySnow:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.85, green: 0.90, blue: 0.95, alpha: 1),
                gradientBottom: UIColor(red: 0.72, green: 0.80, blue: 0.90, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.55, green: 0.75, blue: 0.92, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .sleet:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.60, green: 0.70, blue: 0.80, alpha: 1),
                gradientBottom: UIColor(red: 0.45, green: 0.55, blue: 0.68, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.45, green: 0.65, blue: 0.82, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .fog, .lightFog:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.72, green: 0.75, blue: 0.72, alpha: 1),
                gradientBottom: UIColor(red: 0.60, green: 0.64, blue: 0.62, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.60, green: 0.68, blue: 0.65, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .windy:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.55, green: 0.72, blue: 0.82, alpha: 1),
                gradientBottom: UIColor(red: 0.42, green: 0.58, blue: 0.70, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.50, green: 0.70, blue: 0.85, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .unknown:
            return defaultTheme
        }
    }

    // MARK: - Night themes

    private static func nightTheme(for condition: WeatherCondition) -> WeatherTheme {
        switch condition {
        case .clear, .mostlyClear:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.08, green: 0.10, blue: 0.22, alpha: 1),
                gradientBottom: UIColor(red: 0.05, green: 0.06, blue: 0.15, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.55, green: 0.60, blue: 0.85, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .partlyCloudy, .mostlyCloudy, .cloudy:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.12, green: 0.14, blue: 0.22, alpha: 1),
                gradientBottom: UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.45, green: 0.50, blue: 0.65, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .rain, .drizzle, .heavyRain:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.10, green: 0.15, blue: 0.28, alpha: 1),
                gradientBottom: UIColor(red: 0.06, green: 0.10, blue: 0.20, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.30, green: 0.55, blue: 0.80, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .thunderstorm:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.12, green: 0.08, blue: 0.25, alpha: 1),
                gradientBottom: UIColor(red: 0.06, green: 0.04, blue: 0.15, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.85, green: 0.75, blue: 0.25, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        case .lightSnow, .snow, .heavySnow:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1),
                gradientBottom: UIColor(red: 0.12, green: 0.15, blue: 0.25, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.60, green: 0.72, blue: 0.88, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )

        default:
            return WeatherTheme(
                gradientTop:    UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1),
                gradientBottom: UIColor(red: 0.06, green: 0.08, blue: 0.15, alpha: 1),
                cardBackground: .secondarySystemBackground,
                accentColor:    UIColor(red: 0.50, green: 0.55, blue: 0.70, alpha: 1),
                textPrimary:    .label,
                textSecondary:  .secondaryLabel
            )
        }
    }

    // MARK: - Default

    static let defaultTheme = WeatherTheme(
        gradientTop:    .systemBackground,
        gradientBottom: .systemBackground,
        cardBackground: .secondarySystemBackground,
        accentColor:    .systemBlue,
        textPrimary:    .label,
        textSecondary:  .secondaryLabel
    )
}

// MARK: - UIColor blending helper

extension UIColor {
    func blended(with other: UIColor, ratio: CGFloat = 0.5) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red:   r1 * ratio + r2 * (1 - ratio),
            green: g1 * ratio + g2 * (1 - ratio),
            blue:  b1 * ratio + b2 * (1 - ratio),
            alpha: a1 * ratio + a2 * (1 - ratio)
        )
    }
}

// MARK: - Gradient layer helper

class WeatherGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func applyTheme(_ theme: WeatherTheme, animated: Bool = true) {
        let newColors = [theme.gradientTop.cgColor, theme.gradientBottom.cgColor]

        if animated, let oldColors = gradientLayer.colors {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = oldColors
            anim.toValue = newColors
            anim.duration = 1.0
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            gradientLayer.add(anim, forKey: "themeTransition")
        }

        gradientLayer.colors = newColors
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}

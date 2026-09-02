//
//  AirQualityCardView.swift
//  Cloudship
//
//  Displays EPA Air Quality Index with a colored gradient bar and dot indicator.
//

import UIKit

class AirQualityCardView: CardView {

    // MARK: - Subviews

    private let indexLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .largeTitle)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let categoryLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let gradientBarView = AQIGradientBarView()

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
        let titleLabel = makeTitleLabel(text: "AIR QUALITY")
        addSubview(titleLabel)
        addSubview(indexLabel)
        addSubview(categoryLabel)
        addSubview(descriptionLabel)

        gradientBarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gradientBarView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            indexLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            indexLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            categoryLabel.centerYAnchor.constraint(equalTo: indexLabel.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: indexLabel.trailingAnchor, constant: 10),

            descriptionLabel.topAnchor.constraint(equalTo: indexLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),

            gradientBarView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            gradientBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            gradientBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            gradientBarView.heightAnchor.constraint(equalToConstant: 20),
            gradientBarView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    // MARK: - Configure

    func configure(with data: AirQualityData) {
        indexLabel.text = "\(data.index)"
        categoryLabel.text = data.category.rawValue
        descriptionLabel.text = data.category.description
        categoryLabel.textColor = color(for: data.index)
        gradientBarView.aqiIndex = data.index

        // VoiceOver
        isAccessibilityElement = true
        accessibilityLabel = "Air Quality Index \(data.index), \(data.category.rawValue). \(data.category.description)"
    }

    private func color(for index: Int) -> UIColor {
        switch index {
        case 0...50:   return UIColor(red: 0.18, green: 0.72, blue: 0.27, alpha: 1)  // Green
        case 51...100: return UIColor(red: 0.95, green: 0.76, blue: 0.05, alpha: 1)  // Yellow
        case 101...150: return UIColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1) // Orange
        case 151...200: return UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 1) // Red
        case 201...300: return UIColor(red: 0.55, green: 0.22, blue: 0.72, alpha: 1) // Purple
        default:        return UIColor(red: 0.45, green: 0.08, blue: 0.15, alpha: 1) // Maroon
        }
    }
}

// MARK: - Gradient bar

private class AQIGradientBarView: UIView {

    var aqiIndex: Int = 0 {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)!
        backgroundColor = .clear
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // Draw the rainbow gradient bar
        // Colors: Green → Yellow → Orange → Red → Purple → Maroon
        let colors: [UIColor] = [
            UIColor(red: 0.18, green: 0.72, blue: 0.27, alpha: 1),  // Good (green)
            UIColor(red: 0.95, green: 0.76, blue: 0.05, alpha: 1),  // Moderate (yellow)
            UIColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1),  // Unhealthy SG (orange)
            UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 1),  // Unhealthy (red)
            UIColor(red: 0.55, green: 0.22, blue: 0.72, alpha: 1),  // Very Unhealthy (purple)
            UIColor(red: 0.45, green: 0.08, blue: 0.15, alpha: 1),  // Hazardous (maroon)
        ]

        let cgColors = colors.map { $0.cgColor }
        let locations: [CGFloat] = [0, 0.2, 0.4, 0.6, 0.8, 1.0]

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace,
                                        colors: cgColors as CFArray,
                                        locations: locations) else { return }

        let barHeight: CGFloat = 8
        let barY = (rect.height - barHeight) / 2
        let barRect = CGRect(x: 0, y: barY, width: rect.width, height: barHeight)

        let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: 4)
        ctx.saveGState()
        barPath.addClip()
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: barY),
                               end: CGPoint(x: rect.width, y: barY),
                               options: [])
        ctx.restoreGState()

        // Draw the dot indicator
        // AQI 0-500, clamp to width
        let maxAQI: CGFloat = 500
        let fraction = CGFloat(min(aqiIndex, 500)) / maxAQI
        let dotX = fraction * rect.width
        let dotRadius: CGFloat = 10
        let dotY = rect.height / 2

        // White circle with border
        let dotRect = CGRect(x: dotX - dotRadius, y: dotY - dotRadius,
                             width: dotRadius * 2, height: dotRadius * 2)
        let dotPath = UIBezierPath(ovalIn: dotRect)

        UIColor.white.setFill()
        dotPath.fill()

        UIColor(white: 0.6, alpha: 1).setStroke()
        dotPath.lineWidth = 1
        dotPath.stroke()
    }
}

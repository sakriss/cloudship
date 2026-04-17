//
//  AlertBannerCardView.swift
//  Cloudship
//
//  Tappable alert banner shown between HeaderCardView and MinutelyCardView
//  when one or more NWS weather alerts are active. Hidden when no alerts.
//

import UIKit

class AlertBannerCardView: CardView {

    // MARK: - Callback

    var onTap: (() -> Void)?

    // MARK: - Subviews

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.numberOfLines = 1
        l.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.white.withAlphaComponent(0.8)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let alertCountBadge: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - State

    private var alerts: [WeatherAlert] = []

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
        // Override card shadow/corner to look distinct from weather cards
        layer.cornerRadius = 14

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)
        addSubview(textStack)
        addSubview(alertCountBadge)
        addSubview(chevronImageView)

        let p: CGFloat = 14

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            iconImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: p),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: p),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            alertCountBadge.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 8),
            alertCountBadge.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            alertCountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            alertCountBadge.heightAnchor.constraint(equalToConstant: 20),

            chevronImageView.leadingAnchor.constraint(equalTo: alertCountBadge.trailingAnchor, constant: 6),
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        textStack.setContentCompressionResistancePriority(.required, for: .vertical)

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    // MARK: - Configure

    func configure(alerts: [WeatherAlert]) {
        self.alerts = alerts
        guard let top = alerts.first else {
            isHidden = true
            return
        }

        isHidden = false

        // Background gradient color based on severity
        let (bgColor, iconName) = appearance(for: top.severity)
        backgroundColor = bgColor

        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)

        // Title: emoji + event name
        titleLabel.text = "\(top.severity.emoji) \(top.event)"

        // Subtitle: headline or area
        if let area = top.areaDesc, !area.isEmpty {
            let shortArea = area.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? area
            subtitleLabel.text = shortArea
        } else {
            subtitleLabel.text = top.headline
        }

        // Badge: count if more than 1
        if alerts.count > 1 {
            alertCountBadge.text = "+\(alerts.count - 1)"
            alertCountBadge.isHidden = false
        } else {
            alertCountBadge.isHidden = true
        }

        // VoiceOver
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        var accParts = ["Weather alert: \(top.event)"]
        if let sub = subtitleLabel.text { accParts.append(sub) }
        if alerts.count > 1 { accParts.append("\(alerts.count) total alerts") }
        accessibilityLabel = accParts.joined(separator: ". ")
        accessibilityHint = "Double tap to view alert details"
    }

    // MARK: - Tap

    @objc private func handleTap() {
        // Brief visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.75
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
        }
        onTap?()
    }

    // MARK: - Appearance helpers

    private func appearance(for severity: AlertSeverity) -> (UIColor, String) {
        switch severity {
        case .extreme:
            return (UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1), "exclamationmark.octagon.fill")
        case .severe:
            return (UIColor(red: 0.85, green: 0.35, blue: 0.08, alpha: 1), "exclamationmark.triangle.fill")
        case .moderate:
            return (UIColor(red: 0.80, green: 0.60, blue: 0.05, alpha: 1), "exclamationmark.triangle.fill")
        case .minor:
            return (UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1), "info.circle.fill")
        case .unknown:
            return (UIColor(red: 0.40, green: 0.40, blue: 0.50, alpha: 1), "bell.badge.fill")
        }
    }
}

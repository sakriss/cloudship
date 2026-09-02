//
//  PollenCardView.swift
//  Cloudship
//
//  Shows Tree, Grass, Weed, and Mold pollen levels in a simple list layout.
//

import UIKit

class PollenCardView: CardView {

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
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
        let titleLabel = makeTitleLabel(text: "POLLEN")
        addSubview(titleLabel)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    // MARK: - Configure

    func configure(with data: PollenData) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let allergens: [(icon: String, name: String, level: PollenLevel)] = [
            ("🌲", "Tree",  data.tree),
            ("🌿", "Grass", data.grass),
            ("🌾", "Weed",  data.weed),
        ]
        var all: [(icon: String, name: String, level: PollenLevel)] = allergens
        if let mold = data.mold {
            all.append(("🍄", "Mold", mold))
        }

        for (idx, item) in all.enumerated() {
            let row = makeRow(icon: item.icon, name: item.name, level: item.level)
            stackView.addArrangedSubview(row)

            // Divider between rows
            if idx < all.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .separator
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }
    }

    // MARK: - Row builder

    private func makeRow(icon: String, name: String, level: PollenLevel) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .appFont(forTextStyle: .title3)
        iconLabel.adjustsFontForContentSizeCategory = true
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let badge = UIView()
        badge.layer.cornerRadius = 6
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.backgroundColor = levelColor(level).withAlphaComponent(0.15)

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .appFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let levelLabel = UILabel()
        levelLabel.text = level.label
        levelLabel.font = .appFont(forTextStyle: .body)
        levelLabel.adjustsFontForContentSizeCategory = true
        levelLabel.textColor = levelColor(level)
        levelLabel.textAlignment = .right
        levelLabel.translatesAutoresizingMaskIntoConstraints = false

        badge.addSubview(iconLabel)
        container.addSubview(badge)
        container.addSubview(nameLabel)
        container.addSubview(levelLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 48),

            badge.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            badge.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 36),
            badge.heightAnchor.constraint(equalToConstant: 36),

            iconLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            levelLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            levelLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8)
        ])

        // VoiceOver
        container.isAccessibilityElement = true
        container.accessibilityLabel = "\(name) pollen: \(level.label)"

        return container
    }

    private func levelColor(_ level: PollenLevel) -> UIColor {
        switch level {
        case .none:     return .tertiaryLabel
        case .veryLow:  return UIColor(red: 0.18, green: 0.72, blue: 0.27, alpha: 1)
        case .low:      return UIColor(red: 0.18, green: 0.72, blue: 0.27, alpha: 1)
        case .medium:   return UIColor(red: 0.95, green: 0.62, blue: 0.05, alpha: 1)
        case .high:     return UIColor(red: 0.85, green: 0.30, blue: 0.10, alpha: 1)
        case .veryHigh: return UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
        }
    }
}

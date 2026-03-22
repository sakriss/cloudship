//
//  TimeMachineBannerView.swift
//  Cloudship
//
//  Amber-tinted banner shown when viewing historical weather data.
//  Displays the date being viewed and a "Back to Today" button.
//

import UIKit

class TimeMachineBannerView: UIView {

    var onBackToToday: (() -> Void)?

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = UIColor(red: 0.55, green: 0.35, blue: 0.0, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "clock.arrow.circlepath"))
        iv.tintColor = UIColor(red: 0.55, green: 0.35, blue: 0.0, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Back to Today", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        b.tintColor = UIColor(red: 0.55, green: 0.35, blue: 0.0, alpha: 1)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        backgroundColor = UIColor(red: 1.0, green: 0.88, blue: 0.65, alpha: 1.0)
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(iconView)
        addSubview(dateLabel)
        addSubview(backButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            dateLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            backButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.leadingAnchor.constraint(greaterThanOrEqualTo: dateLabel.trailingAnchor, constant: 8)
        ])
    }

    func configure(date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        dateLabel.text = "Viewing \(formatter.string(from: date))"
    }

    @objc private func backTapped() {
        onBackToToday?()
    }
}

//
//  ActivityScoresCardView.swift
//  Cloudship
//
//  Card showing scored ratings for outdoor activities based on current weather.
//

import UIKit

class ActivityScoresCardView: CardView {

    // MARK: - Subviews

    private let row1 = ActivityRowView()
    private let row2 = ActivityRowView()
    private let row3 = ActivityRowView()
    private let row4 = ActivityRowView()

    private var rows: [ActivityRowView] { [row1, row2, row3, row4] }
    private var titleLabel: UILabel!
    private var separatorViews: [UIView] = []

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
        titleLabel = makeTitleLabel(text: "ACTIVITY SCORES")
        addSubview(titleLabel)

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        // Add separators between rows
        for i in 0..<(rows.count - 1) {
            let sep = UIView()
            sep.backgroundColor = separatorColor()
            sep.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sep)
            separatorViews.append(sep)

            let rowView = rows[i]
            NSLayoutConstraint.activate([
                sep.topAnchor.constraint(equalTo: rowView.bottomAnchor),
                sep.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p + 36),
                sep.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
                sep.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    // MARK: - Configure

    func configure(with data: UnifiedWeatherData) {
        applyTextPalette()
        let scores = ActivityScoreEngine.scores(from: data)
        for (i, score) in scores.enumerated() where i < rows.count {
            rows[i].configure(with: score)
        }
    }

    override func applyVintageStyle() {
        super.applyVintageStyle()
        applyTextPalette()
    }

    override func restoreTint() {
        super.restoreTint()
        applyTextPalette()
    }

    private func applyTextPalette() {
        titleLabel?.textColor = CardView.textColor(for: .secondary)
        separatorViews.forEach { $0.backgroundColor = separatorColor() }
        rows.forEach { $0.applyTextPalette() }
    }

    private func separatorColor() -> UIColor {
        if WeatherDataSourceManager.shared.isShowingHistorical {
            return CardView.textColor(for: .tertiary).withAlphaComponent(0.28)
        }
        return .separator
    }
}

// MARK: - Row view

private class ActivityRowView: UIView {

    private let emojiLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .title3)
        l.adjustsFontForContentSizeCategory = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .primary)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return l
    }()

    private let scoreBar = ScoreBarView()

    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .primary)
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let ratingLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.adjustsFontForContentSizeCategory = true
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    private let factorLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption2)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = CardView.textColor(for: .tertiary)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        scoreBar.translatesAutoresizingMaskIntoConstraints = false

        // Right side: score value + rating stacked
        let rightStack = UIStackView(arrangedSubviews: [scoreLabel, ratingLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 0
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(emojiLabel)
        addSubview(nameLabel)
        addSubview(scoreBar)
        addSubview(rightStack)
        addSubview(factorLabel)

        NSLayoutConstraint.activate([
            // Emoji
            emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            emojiLabel.widthAnchor.constraint(equalToConstant: 28),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),

            // Score bar
            scoreBar.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            scoreBar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            scoreBar.heightAnchor.constraint(equalToConstant: 6),
            scoreBar.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -12),

            // Right stack (score + rating)
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            rightStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),

            // Factor label (below bar)
            factorLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            factorLabel.topAnchor.constraint(equalTo: scoreBar.bottomAnchor, constant: 3),
            factorLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            factorLabel.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -12),

            // Min height
            heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    func configure(with score: ActivityScore) {
        applyTextPalette()
        emojiLabel.text = score.activity.emoji
        nameLabel.text = score.activity.displayName
        scoreLabel.text = "\(score.score)"
        ratingLabel.text = score.rating.displayName
        factorLabel.text = score.limitingFactor

        let color = scoreColor(for: score.score)
        ratingLabel.textColor = color
        scoreBar.progress = CGFloat(score.score) / 100.0
        scoreBar.barColor = color

        // VoiceOver
        isAccessibilityElement = true
        var parts = ["\(score.activity.displayName): \(score.score) out of 100, \(score.rating.displayName)"]
        if let factor = score.limitingFactor, !factor.isEmpty {
            parts.append(factor)
        }
        accessibilityLabel = parts.joined(separator: ". ")
    }

    private func scoreColor(for score: Int) -> UIColor {
        switch score {
        case 80...100: return .systemGreen
        case 60..<80:  return UIColor(red: 0.55, green: 0.78, blue: 0.25, alpha: 1)  // yellow-green
        case 40..<60:  return .systemYellow
        case 20..<40:  return .systemOrange
        default:       return .systemRed
        }
    }

    func applyTextPalette() {
        nameLabel.textColor = CardView.textColor(for: .primary)
        scoreLabel.textColor = CardView.textColor(for: .primary)
        factorLabel.textColor = CardView.textColor(for: .tertiary)
        scoreBar.setNeedsLayout()
    }
}

// MARK: - Score bar (thin rounded progress bar)

private class ScoreBarView: UIView {

    var progress: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    var barColor: UIColor = .systemGreen {
        didSet { fillLayer.backgroundColor = barColor.cgColor }
    }

    private let trackLayer = CALayer()
    private let fillLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.addSublayer(trackLayer)
        layer.addSublayer(fillLayer)
        layer.cornerRadius = 3
        layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        trackLayer.backgroundColor = trackColor().cgColor
        trackLayer.cornerRadius = 3

        let fillWidth = bounds.width * min(1, max(0, progress))
        fillLayer.frame = CGRect(x: 0, y: 0, width: fillWidth, height: bounds.height)
        fillLayer.cornerRadius = 3
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        trackLayer.backgroundColor = trackColor().cgColor
    }

    private func trackColor() -> UIColor {
        if WeatherDataSourceManager.shared.isShowingHistorical {
            return CardView.textColor(for: .tertiary).withAlphaComponent(0.18)
        }
        return .tertiarySystemFill
    }
}

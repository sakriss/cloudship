//
//  AISummaryCardView.swift
//  Cloudship
//
//  Always-visible card showing an AI-generated 2-3 sentence daily weather brief.
//  Shows a shimmer loading state while the AI generates, with tap-to-retry on error.
//

import UIKit

class AISummaryCardView: CardView {

    // MARK: - State

    enum State {
        case loading
        case loaded(String)
        case error
    }

    var state: State = .loading {
        didSet { updateForState() }
    }

    /// Called when the user taps the retry button.
    var onRetry: (() -> Void)?

    // MARK: - Subviews

    private let sparkleIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "sparkles"))
        iv.tintColor = UIColor(red: 0.55, green: 0.35, blue: 0.85, alpha: 1)  // purple
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let retryLabel: UILabel = {
        let l = UILabel()
        l.text = "Couldn't load brief. Tap to retry."
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let shimmerContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var shimmerBars: [UIView] = []
    private var shimmerLayers: [CAGradientLayer] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        setupTapGesture()
    }

    // MARK: - Layout

    private func setupLayout() {
        let p = CardView.padding
        let titleLabel = makeTitleLabel(text: "DAILY BRIEF")
        addSubview(sparkleIcon)
        addSubview(titleLabel)
        addSubview(summaryLabel)
        addSubview(retryLabel)
        addSubview(shimmerContainer)

        // Create shimmer bars
        let barWidths: [CGFloat] = [1.0, 0.85, 0.6]
        for width in barWidths {
            let bar = UIView()
            bar.backgroundColor = .tertiarySystemFill
            bar.layer.cornerRadius = 4
            bar.translatesAutoresizingMaskIntoConstraints = false
            shimmerContainer.addSubview(bar)
            shimmerBars.append(bar)

            NSLayoutConstraint.activate([
                bar.leadingAnchor.constraint(equalTo: shimmerContainer.leadingAnchor),
                bar.heightAnchor.constraint(equalToConstant: 10)
            ])

            // Width as fraction of container
            bar.widthAnchor.constraint(equalTo: shimmerContainer.widthAnchor, multiplier: width).isActive = true
        }

        // Stack shimmer bars vertically
        if shimmerBars.count >= 3 {
            NSLayoutConstraint.activate([
                shimmerBars[0].topAnchor.constraint(equalTo: shimmerContainer.topAnchor),
                shimmerBars[1].topAnchor.constraint(equalTo: shimmerBars[0].bottomAnchor, constant: 8),
                shimmerBars[2].topAnchor.constraint(equalTo: shimmerBars[1].bottomAnchor, constant: 8),
                shimmerBars[2].bottomAnchor.constraint(equalTo: shimmerContainer.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            sparkleIcon.topAnchor.constraint(equalTo: topAnchor, constant: p),
            sparkleIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            sparkleIcon.widthAnchor.constraint(equalToConstant: 14),
            sparkleIcon.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.centerYAnchor.constraint(equalTo: sparkleIcon.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: sparkleIcon.trailingAnchor, constant: 5),

            summaryLabel.topAnchor.constraint(equalTo: sparkleIcon.bottomAnchor, constant: 10),
            summaryLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            summaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            summaryLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            shimmerContainer.topAnchor.constraint(equalTo: sparkleIcon.bottomAnchor, constant: 10),
            shimmerContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            shimmerContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            shimmerContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            retryLabel.topAnchor.constraint(equalTo: sparkleIcon.bottomAnchor, constant: 10),
            retryLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            retryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            retryLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        if case .error = state {
            onRetry?()
        }
    }

    // MARK: - State management

    private func updateForState() {
        switch state {
        case .loading:
            summaryLabel.isHidden = true
            retryLabel.isHidden = true
            shimmerContainer.isHidden = false
            startShimmer()

        case .loaded(let text):
            summaryLabel.text = text
            summaryLabel.isHidden = false
            retryLabel.isHidden = true
            shimmerContainer.isHidden = true
            stopShimmer()

        case .error:
            summaryLabel.isHidden = true
            retryLabel.isHidden = false
            shimmerContainer.isHidden = true
            stopShimmer()
        }
    }

    // MARK: - Shimmer animation

    private func startShimmer() {
        stopShimmer()

        for bar in shimmerBars {
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor.tertiarySystemFill.cgColor,
                UIColor.quaternarySystemFill.cgColor,
                UIColor.tertiarySystemFill.cgColor
            ]
            gradient.locations = [0, 0.5, 1]
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.frame = CGRect(x: 0, y: 0, width: 300, height: 10)
            bar.layer.addSublayer(gradient)
            shimmerLayers.append(gradient)

            let animation = CABasicAnimation(keyPath: "locations")
            animation.fromValue = [-1.0, -0.5, 0.0]
            animation.toValue = [1.0, 1.5, 2.0]
            animation.duration = 1.5
            animation.repeatCount = .infinity
            gradient.add(animation, forKey: "shimmer")
        }
    }

    private func stopShimmer() {
        for layer in shimmerLayers {
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
        shimmerLayers.removeAll()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shimmer layer frames to match bar sizes
        for (i, layer) in shimmerLayers.enumerated() where i < shimmerBars.count {
            layer.frame = shimmerBars[i].bounds
        }
    }
}

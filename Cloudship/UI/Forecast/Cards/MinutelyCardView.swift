//
//  MinutelyCardView.swift
//  Cloudship
//
//  60-minute precipitation bar chart using Core Graphics.
//

import UIKit

// MARK: - Bar chart view

private class MinutelyChartView: UIView {

    var entries: [MinutelyEntry] = [] {
        didSet { setNeedsDisplay() }
    }

    private let accentColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 0.85)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { super.init(coder: coder)!; backgroundColor = .clear }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard !entries.isEmpty else { return }
        let intensities = entries.map { $0.precipIntensity ?? 0 }
        let maxIntensity = intensities.max() ?? 0

        if maxIntensity == 0 {
            // Draw a flat baseline
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 0, y: rect.height - 2))
            linePath.addLine(to: CGPoint(x: rect.width, y: rect.height - 2))
            UIColor.tertiarySystemFill.resolvedColor(with: traitCollection).setStroke()
            linePath.lineWidth = 2
            linePath.stroke()
            return
        }

        let n = entries.count
        let barWidth = rect.width / CGFloat(n)
        let gap: CGFloat = 1

        accentColor.setFill()
        for (i, intensity) in intensities.enumerated() {
            let h = CGFloat(intensity / maxIntensity) * rect.height
            let x = CGFloat(i) * barWidth
            let barRect = CGRect(x: x + gap/2,
                                 y: rect.height - h,
                                 width: barWidth - gap,
                                 height: h)
            let path = UIBezierPath(roundedRect: barRect, byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 2, height: 2))
            path.fill()
        }
    }
}

// MARK: - Card

class MinutelyCardView: CardView {

    private let chartView = MinutelyChartView()
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No precipitation expected"
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nowLabel: UILabel = {
        let l = UILabel()
        l.text = "Now"
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let endLabel: UILabel = {
        let l = UILabel()
        l.text = "+60 min"
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let noSourceLabel: UILabel = {
        let l = UILabel()
        l.text = "Minutely data not available for this source"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
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
        // Hide everything by default until configure() is called
        chartView.isHidden = true
        emptyLabel.isHidden = true
        nowLabel.isHidden = true
        endLabel.isHidden = true
        noSourceLabel.isHidden = true

        let p = CardView.padding
        let titleLabel = makeTitleLabel(text: "Next Hour")
        addSubview(titleLabel)

        chartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)
        addSubview(emptyLabel)
        addSubview(nowLabel)
        addSubview(endLabel)
        addSubview(noSourceLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            chartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            chartView.heightAnchor.constraint(equalToConstant: 60),

            nowLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            nowLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            nowLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            endLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            endLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            endLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor),

            noSourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            noSourceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            noSourceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            noSourceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    func configure(minutely: [MinutelyEntry]) {
        let hasData = !minutely.isEmpty
        let allZero = minutely.allSatisfy { ($0.precipIntensity ?? 0) == 0 }

        chartView.isHidden = !hasData
        nowLabel.isHidden = !hasData
        endLabel.isHidden = !hasData
        noSourceLabel.isHidden = hasData
        emptyLabel.isHidden = !hasData || !allZero

        if hasData {
            chartView.entries = minutely
        }
    }
}

//
//  WindGustCardView.swift
//  Cloudship
//
//  24-hour wind gust line chart with Y-axis labels and gradient fill.
//

import UIKit

// MARK: - Line chart view

private class WindGustChartView: UIView {

    var gusts: [Double] = [] {
        didSet { setNeedsDisplay() }
    }

    private let accentColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)

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
        guard gusts.count >= 2, let ctx = UIGraphicsGetCurrentContext() else { return }
        let minG = gusts.min()!
        let maxG = gusts.max()!
        let range = maxG - minG
        let effectiveRange = range > 0 ? range : 1

        let n    = gusts.count
        let step = rect.width / CGFloat(n - 1)

        func point(at i: Int) -> CGPoint {
            let x = CGFloat(i) * step
            let y = rect.height - CGFloat((gusts[i] - minG) / effectiveRange) * rect.height * 0.8 - rect.height * 0.1
            return CGPoint(x: x, y: y)
        }

        // Build bezier path
        let path = UIBezierPath()
        path.move(to: point(at: 0))
        for i in 1..<n {
            let prev = point(at: i - 1)
            let curr = point(at: i)
            let cp1  = CGPoint(x: prev.x + step * 0.4, y: prev.y)
            let cp2  = CGPoint(x: curr.x - step * 0.4, y: curr.y)
            path.addCurve(to: curr, controlPoint1: cp1, controlPoint2: cp2)
        }

        // Gradient fill
        let fillPath = path.copy() as! UIBezierPath
        fillPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        fillPath.addLine(to: CGPoint(x: 0, y: rect.height))
        fillPath.close()

        ctx.saveGState()
        fillPath.addClip()
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                accentColor.withAlphaComponent(0.30).cgColor,
                accentColor.withAlphaComponent(0.00).cgColor
            ] as CFArray,
            locations: [0, 1]
        ) else { ctx.restoreGState(); return }
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end:   CGPoint(x: 0, y: rect.height),
                               options: [])
        ctx.restoreGState()

        // Dashed mean line
        let mean = gusts.reduce(0, +) / Double(gusts.count)
        let meanY = rect.height - CGFloat((mean - minG) / effectiveRange) * rect.height * 0.8 - rect.height * 0.1
        let dashPath = UIBezierPath()
        dashPath.move(to: CGPoint(x: 0, y: meanY))
        dashPath.addLine(to: CGPoint(x: rect.width, y: meanY))
        dashPath.setLineDash([4, 4], count: 2, phase: 0)
        UIColor.quaternaryLabel.resolvedColor(with: traitCollection).setStroke()
        dashPath.lineWidth = 1
        dashPath.stroke()

        // Stroke the curve
        accentColor.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
}

// MARK: - Card

class WindGustCardView: CardView {

    private let chartView = WindGustChartView()
    private let maxLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .regular)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let minLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .regular)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // X-axis tick labels (every 6 hours)
    private let nowTickLabel = WindGustCardView.makeTickLabel("Now")
    private let mid1TickLabel = WindGustCardView.makeTickLabel("")
    private let mid2TickLabel = WindGustCardView.makeTickLabel("")
    private let endTickLabel  = WindGustCardView.makeTickLabel("")

    private static func makeTickLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10, weight: .regular)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        let p = CardView.padding
        let titleLabel = makeTitleLabel(text: "Wind Gusts")
        addSubview(titleLabel)

        chartView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chartView)
        addSubview(maxLabel)
        addSubview(minLabel)
        addSubview(nowTickLabel)
        addSubview(mid1TickLabel)
        addSubview(mid2TickLabel)
        addSubview(endTickLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            chartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            chartView.heightAnchor.constraint(equalToConstant: 100),

            maxLabel.trailingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: -2),
            maxLabel.topAnchor.constraint(equalTo: chartView.topAnchor),

            minLabel.trailingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: -2),
            minLabel.bottomAnchor.constraint(equalTo: chartView.bottomAnchor),

            nowTickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            nowTickLabel.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            nowTickLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            mid1TickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            mid1TickLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor,
                                                    constant: -chartView.frame.width/3),

            mid2TickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            mid2TickLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor,
                                                    constant: chartView.frame.width/6),

            endTickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            endTickLabel.trailingAnchor.constraint(equalTo: chartView.trailingAnchor)
        ])
    }

    func configure(hourly: [HourlyEntry]) {
        let gustData = hourly.prefix(24).compactMap(\.windGust)
        guard !gustData.isEmpty else { return }

        chartView.gusts = gustData
        let isMetric = TemperatureFormatter.isMetric
        let unit = isMetric ? "km/h" : "mph"

        if let maxG = gustData.max(), let minG = gustData.min() {
            maxLabel.text = "\(Int(maxG.rounded())) \(unit)"
            minLabel.text = "\(Int(minG.rounded()))"
        }

        // Set X-axis tick labels from actual times
        let times = hourly.prefix(24).map(\.time)
        if times.count > 6 {
            mid1TickLabel.text = DateFormatHelper.hourString(from: times[6])
        }
        if times.count > 12 {
            mid2TickLabel.text = DateFormatHelper.hourString(from: times[12])
        }
        if times.count > 18 {
            endTickLabel.text = DateFormatHelper.hourString(from: times[min(23, times.count - 1)])
        }
    }
}

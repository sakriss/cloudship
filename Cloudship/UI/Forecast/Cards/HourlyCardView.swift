//
//  HourlyCardView.swift
//  Cloudship
//
//  Horizontal scroll strip showing hourly forecast with a smooth
//  temperature curve line chart below.
//

import UIKit

// MARK: - Temperature curve (Core Graphics)

private class HourlyTempCurveView: UIView {

    var temps: [Double] = [] {
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
        guard temps.count >= 2, let ctx = UIGraphicsGetCurrentContext() else { return }
        let minT = temps.min()!
        let maxT = temps.max()!
        let range = maxT - minT
        guard range > 0 else { return }

        let n    = temps.count
        let step = rect.width / CGFloat(n - 1)

        func point(at i: Int) -> CGPoint {
            let x = CGFloat(i) * step
            let y = rect.height - CGFloat((temps[i] - minT) / range) * rect.height * 0.8 - rect.height * 0.1
            return CGPoint(x: x, y: y)
        }

        // Build smooth bezier
        let path = UIBezierPath()
        path.move(to: point(at: 0))
        for i in 1..<n {
            let prev = point(at: i - 1)
            let curr = point(at: i)
            let cp1  = CGPoint(x: prev.x + step * 0.4, y: prev.y)
            let cp2  = CGPoint(x: curr.x - step * 0.4, y: curr.y)
            path.addCurve(to: curr, controlPoint1: cp1, controlPoint2: cp2)
        }

        // Gradient fill below curve
        let fillPath = path.copy() as! UIBezierPath
        fillPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        fillPath.addLine(to: CGPoint(x: 0, y: rect.height))
        fillPath.close()

        ctx.saveGState()
        fillPath.addClip()
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                accentColor.withAlphaComponent(0.35).cgColor,
                accentColor.withAlphaComponent(0.00).cgColor
            ] as CFArray,
            locations: [0, 1]
        ) else { ctx.restoreGState(); return }
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end:   CGPoint(x: 0, y: rect.height),
                               options: [])
        ctx.restoreGState()

        // Stroke
        accentColor.setStroke()
        path.lineWidth = 2
        path.stroke()

        // Dots at each point
        for i in 0..<n {
            let p = point(at: i)
            let dot = UIBezierPath(arcCenter: p, radius: 3, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            accentColor.setFill()
            dot.fill()
        }
    }
}

// MARK: - Cell

private class HourlyItemCell: UICollectionViewCell {

    static let reuseID = "HourlyItemCell"

    private let hourLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let tempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let precipLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [hourLabel, iconView, precipLabel, tempLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            precipLabel.heightAnchor.constraint(equalToConstant: 14),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(entry: HourlyEntry) {
        hourLabel.text = DateFormatHelper.hourLabel(from: entry.time)
        tempLabel.text = TemperatureFormatter.format(entry.temp)
        iconView.image = UIImage(named: WeatherCodeMapper.iconName(for: entry.condition,
                                                                    isNight: WeatherCodeMapper.isNighttime()))
        // Show precip chance only when > 0%
        if let chance = entry.precipChance, chance > 0 {
            precipLabel.text = "\(Int(chance.rounded()))%"
            precipLabel.isHidden = false
        } else {
            precipLabel.text = nil
            precipLabel.isHidden = true
        }
    }
}

// MARK: - Card

class HourlyCardView: CardView {

    private var entries: [HourlyEntry] = []
    private var curveView = HourlyTempCurveView()
    private var collectionView: UICollectionView!

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
        let titleLabel = makeTitleLabel(text: "Hourly Forecast")
        addSubview(titleLabel)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 64, height: 100)
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: p, bottom: 0, right: p)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(HourlyItemCell.self, forCellWithReuseIdentifier: HourlyItemCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        curveView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(collectionView)
        addSubview(curveView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 100),

            curveView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 4),
            curveView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            curveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            curveView.heightAnchor.constraint(equalToConstant: 50),
            curveView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    func configure(hourly: [HourlyEntry]) {
        entries = Array(hourly.prefix(24))
        curveView.temps = entries.compactMap(\.temp)
        collectionView.reloadData()
    }
}

extension HourlyCardView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        entries.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyItemCell.reuseID, for: indexPath) as! HourlyItemCell
        cell.configure(entry: entries[indexPath.item])
        return cell
    }
}

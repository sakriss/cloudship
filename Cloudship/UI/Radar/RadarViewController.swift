//
//  RadarViewController.swift
//  Cloudship
//
//  Animated weather radar powered by RainViewer (free, no API key).
//  Layers: Precipitation (animated), Satellite Infrared (animated).
//  Settings: color scheme, opacity, animation speed, loop range, map type.
//

import UIKit
import MapKit
import CoreLocation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Data models

private struct RainViewerResponse: Codable {
    let host: String?
    let radar: RadarData?
    let satellite: SatelliteData?

    struct RadarData: Codable {
        let past: [Frame]?
        let nowcast: [Frame]?
    }
    struct SatelliteData: Codable {
        let infrared: [Frame]?
    }
    struct Frame: Codable {
        let time: Int
        let path: String
    }
}

private struct OpenMeteoWindResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: CurrentWind?

    struct CurrentWind: Codable {
        let windSpeed10m: Double?
        let windDirection10m: Double?

        private enum CodingKeys: String, CodingKey {
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
        }
    }
}

// MARK: - Enums

enum RadarLayer: String, CaseIterable {
    case precipitation = "Precipitation"
    case satellite     = "Satellite"
    case temperature   = "Temperature"
    case wind          = "Wind"
    case clouds        = "Clouds"
    case pressure      = "Pressure"

    var icon: String {
        switch self {
        case .precipitation: return "cloud.rain.fill"
        case .satellite:     return "globe.americas.fill"
        case .temperature:   return "thermometer.medium"
        case .wind:          return "wind"
        case .clouds:        return "cloud.fill"
        case .pressure:      return "gauge.medium"
        }
    }

    /// Whether this layer supports animated playback (RainViewer layers only).
    var isAnimatable: Bool {
        switch self {
        case .precipitation, .satellite: return true
        case .temperature, .wind, .clouds, .pressure: return false
        }
    }

    var supportsColorSchemeSelection: Bool {
        self == .precipitation
    }

    struct LegendInfo {
        let title: String
        let colors: [UIColor]
        let minLabel: String
        let maxLabel: String
    }

    /// Returns legend color scale info, or nil if the layer has no discrete legend
    /// (precipitation / satellite have colors baked into the RainViewer tiles).
    /// Labels automatically reflect the user's metric/imperial preference.
    var legendInfo: LegendInfo? {
        let metric = TemperatureFormatter.isMetric
        switch self {
        case .precipitation, .satellite:
            return nil
        case .temperature:
            return LegendInfo(
                title: "Temperature",
                colors: [
                    UIColor(red: 0.10, green: 0.00, blue: 0.50, alpha: 1), // deep violet
                    UIColor(red: 0.00, green: 0.40, blue: 0.90, alpha: 1), // blue
                    UIColor(red: 0.00, green: 0.85, blue: 0.85, alpha: 1), // cyan
                    UIColor(red: 0.10, green: 0.75, blue: 0.10, alpha: 1), // green
                    UIColor(red: 1.00, green: 1.00, blue: 0.00, alpha: 1), // yellow
                    UIColor(red: 1.00, green: 0.50, blue: 0.00, alpha: 1), // orange
                    UIColor(red: 0.90, green: 0.00, blue: 0.00, alpha: 1), // red
                ],
                minLabel: metric ? "−30°C" : "−22°F",
                maxLabel: metric ? "50°C"  : "122°F"
            )
        case .wind:
            return LegendInfo(
                title: "Wind Speed",
                colors: [
                    UIColor(red: 0.10, green: 0.55, blue: 0.10, alpha: 1), // dark green
                    UIColor(red: 0.55, green: 0.85, blue: 0.15, alpha: 1), // yellow-green
                    UIColor(red: 1.00, green: 0.90, blue: 0.00, alpha: 1), // yellow
                    UIColor(red: 1.00, green: 0.55, blue: 0.00, alpha: 1), // orange
                    UIColor(red: 0.90, green: 0.05, blue: 0.05, alpha: 1), // red
                    UIColor(red: 0.55, green: 0.00, blue: 0.55, alpha: 1), // purple
                ],
                minLabel: "0 \(metric ? "km/h" : "mph")",
                maxLabel: "100+ \(metric ? "km/h" : "mph")"
            )
        case .clouds:
            return LegendInfo(
                title: "Cloud Cover",
                colors: [
                    UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 0.2), // nearly clear
                    UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 0.6), // light gray
                    UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.9), // mid gray
                    UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0), // dark gray
                ],
                minLabel: "0%",
                maxLabel: "100%"
            )
        case .pressure:
            // OWM pressure tiles use hPa regardless; show inHg conversion for imperial users
            return LegendInfo(
                title: "Pressure",
                colors: [
                    UIColor(red: 0.00, green: 0.00, blue: 0.80, alpha: 1), // blue (low)
                    UIColor(red: 0.00, green: 0.75, blue: 0.50, alpha: 1), // teal
                    UIColor(red: 0.15, green: 0.80, blue: 0.15, alpha: 1), // green
                    UIColor(red: 1.00, green: 0.90, blue: 0.00, alpha: 1), // yellow
                    UIColor(red: 1.00, green: 0.40, blue: 0.00, alpha: 1), // orange
                    UIColor(red: 0.85, green: 0.00, blue: 0.00, alpha: 1), // red (high)
                ],
                minLabel: metric ? "950 hPa"  : "28.05\"",
                maxLabel: metric ? "1050 hPa" : "31.01\""
            )
        }
    }
}

enum ColorScheme: Int, CaseIterable {
    case nexrad    = 6
    case blue      = 1
    case titan     = 2
    case twc       = 3
    case meteored  = 4
    case darkSky   = 7

    var label: String {
        switch self {
        case .nexrad:   return "NEXRAD"
        case .blue:     return "Blue"
        case .titan:    return "TITAN"
        case .twc:      return "TWC"
        case .meteored: return "Meteored"
        case .darkSky:  return "Dark Sky"
        }
    }

    /// RainViewer public tiles currently expose Universal Blue; custom schemes are
    /// generated client-side from that source image.
    static let sourceRadarValue = 2

    var palette: [UIColor]? {
        switch self {
        case .blue:
            return nil
        case .nexrad:
            return [
                UIColor(red: 0.23, green: 0.70, blue: 0.95, alpha: 1),
                UIColor(red: 0.06, green: 0.78, blue: 0.36, alpha: 1),
                UIColor(red: 0.88, green: 0.89, blue: 0.08, alpha: 1),
                UIColor(red: 0.99, green: 0.57, blue: 0.09, alpha: 1),
                UIColor(red: 0.91, green: 0.14, blue: 0.09, alpha: 1),
                UIColor(red: 0.74, green: 0.09, blue: 0.58, alpha: 1)
            ]
        case .titan:
            return [
                UIColor(red: 0.53, green: 0.82, blue: 1.00, alpha: 1),
                UIColor(red: 0.29, green: 0.59, blue: 0.98, alpha: 1),
                UIColor(red: 0.63, green: 0.74, blue: 0.22, alpha: 1),
                UIColor(red: 1.00, green: 0.78, blue: 0.16, alpha: 1),
                UIColor(red: 0.97, green: 0.36, blue: 0.12, alpha: 1),
                UIColor(red: 0.73, green: 0.12, blue: 0.16, alpha: 1)
            ]
        case .twc:
            return [
                UIColor(red: 0.19, green: 0.85, blue: 0.93, alpha: 1),
                UIColor(red: 0.11, green: 0.75, blue: 0.43, alpha: 1),
                UIColor(red: 0.95, green: 0.87, blue: 0.16, alpha: 1),
                UIColor(red: 0.95, green: 0.54, blue: 0.11, alpha: 1),
                UIColor(red: 0.88, green: 0.16, blue: 0.13, alpha: 1),
                UIColor(red: 0.78, green: 0.30, blue: 0.76, alpha: 1)
            ]
        case .meteored:
            return [
                UIColor(red: 0.64, green: 0.88, blue: 0.98, alpha: 1),
                UIColor(red: 0.20, green: 0.78, blue: 0.93, alpha: 1),
                UIColor(red: 0.36, green: 0.75, blue: 0.39, alpha: 1),
                UIColor(red: 1.00, green: 0.82, blue: 0.24, alpha: 1),
                UIColor(red: 1.00, green: 0.47, blue: 0.15, alpha: 1),
                UIColor(red: 0.84, green: 0.11, blue: 0.27, alpha: 1)
            ]
        case .darkSky:
            return [
                UIColor(red: 0.51, green: 0.73, blue: 1.00, alpha: 1),
                UIColor(red: 0.36, green: 0.57, blue: 0.98, alpha: 1),
                UIColor(red: 0.69, green: 0.79, blue: 0.42, alpha: 1),
                UIColor(red: 0.98, green: 0.74, blue: 0.27, alpha: 1),
                UIColor(red: 0.92, green: 0.43, blue: 0.18, alpha: 1),
                UIColor(red: 0.80, green: 0.27, blue: 0.68, alpha: 1)
            ]
        }
    }
}

private final class RecoloredRadarTileOverlay: MKTileOverlay {
    private let scheme: ColorScheme
    private let session = URLSession(configuration: .ephemeral)
    private static let tileCache = NSCache<NSString, NSData>()

    init(urlTemplate: String, scheme: ColorScheme) {
        self.scheme = scheme
        super.init(urlTemplate: urlTemplate)
        canReplaceMapContent = false
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, (any Error)?) -> Void) {
        let url = url(forTilePath: path)
        let cacheKey = url.absoluteString as NSString

        if let cached = Self.tileCache.object(forKey: cacheKey) {
            result(cached as Data, nil)
            return
        }

        session.dataTask(with: url) { [scheme] data, _, error in
            guard let data, error == nil else {
                result(nil, error)
                return
            }

            guard scheme != .blue, let recolored = Self.recoloredTileData(from: data, scheme: scheme) else {
                Self.tileCache.setObject(data as NSData, forKey: cacheKey)
                result(data, nil)
                return
            }

            Self.tileCache.setObject(recolored as NSData, forKey: cacheKey)
            result(recolored, nil)
        }.resume()
    }

    private static func recoloredTileData(from data: Data, scheme: ColorScheme) -> Data? {
        guard let palette = scheme.palette,
              let image = UIImage(data: data),
              let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for index in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let alpha = CGFloat(pixels[index + 3]) / 255
            guard alpha > 0.02 else { continue }

            let red = CGFloat(pixels[index]) / 255
            let green = CGFloat(pixels[index + 1]) / 255
            let blue = CGFloat(pixels[index + 2]) / 255

            let maxComponent = max(red, green, blue)
            let minComponent = min(red, green, blue)
            let brightness = maxComponent
            let saturation = maxComponent > 0 ? (maxComponent - minComponent) / maxComponent : 0
            let intensity = min(1, max(0, pow((brightness * 0.70 + saturation * 0.30) * alpha, 0.90)))
            let mapped = interpolateColor(in: palette, fraction: intensity)

            var mappedRed: CGFloat = 0
            var mappedGreen: CGFloat = 0
            var mappedBlue: CGFloat = 0
            var mappedAlpha: CGFloat = 0
            mapped.getRed(&mappedRed, green: &mappedGreen, blue: &mappedBlue, alpha: &mappedAlpha)

            pixels[index] = UInt8(clamping: Int((mappedRed * 255).rounded()))
            pixels[index + 1] = UInt8(clamping: Int((mappedGreen * 255).rounded()))
            pixels[index + 2] = UInt8(clamping: Int((mappedBlue * 255).rounded()))
            pixels[index + 3] = UInt8(clamping: Int((max(alpha, intensity * 0.75) * 255).rounded()))
        }

        guard let outputImage = context.makeImage() else { return nil }
        return pngData(from: outputImage)
    }

    private static func interpolateColor(in palette: [UIColor], fraction: CGFloat) -> UIColor {
        guard let first = palette.first else { return .clear }
        guard palette.count > 1 else { return first }

        let normalized = min(max(fraction, 0), 1)
        let segmentWidth = 1 / CGFloat(palette.count - 1)
        let segment = min(Int(normalized / segmentWidth), palette.count - 2)
        let start = palette[segment]
        let end = palette[segment + 1]
        let localFraction = (normalized - CGFloat(segment) * segmentWidth) / segmentWidth

        var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
        var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
        start.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
        end.getRed(&er, green: &eg, blue: &eb, alpha: &ea)

        let r = sr + (er - sr) * localFraction
        let g = sg + (eg - sg) * localFraction
        let b = sb + (eb - sb) * localFraction
        let a = sa + (ea - sa) * localFraction
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    private static func pngData(from image: CGImage) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}

enum AnimationSpeed: Double, CaseIterable {
    case slow   = 1.0
    case normal = 0.6
    case fast   = 0.25

    var label: String {
        switch self {
        case .slow:   return "Slow"
        case .normal: return "Normal"
        case .fast:   return "Fast"
        }
    }
}

enum LoopRange: Int, CaseIterable {
    case all     = 0
    case oneHour = 3600
    case halfHour = 1800

    var label: String {
        switch self {
        case .all:      return "All"
        case .oneHour:  return "1 hr"
        case .halfHour: return "30 min"
        }
    }
}

// MARK: - Legend pill

private class RadarLegendPillView: UIView {

    // MARK: Subviews
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let minLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedSystemFont(ofSize: 10, size: 10)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let maxLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedSystemFont(ofSize: 10, size: 10)
        l.textColor = .secondaryLabel
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let gradientContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let gradientLayer = CAGradientLayer()
    private let chevronButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        b.setImage(UIImage(systemName: "chevron.down", withConfiguration: cfg), for: .normal)
        b.tintColor = .tertiaryLabel
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: State
    private var isCollapsed = false
    private var expandedConstraints: [NSLayoutConstraint] = []
    private var collapsedConstraints: [NSLayoutConstraint] = []

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 14
        layer.masksToBounds = true

        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let content = blur.contentView

        // Gradient bar
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        gradientContainer.layer.addSublayer(gradientLayer)

        // Header row: title + chevron
        let header = UIStackView(arrangedSubviews: [titleLabel, chevronButton])
        header.axis = .horizontal; header.spacing = 4; header.alignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false

        // Min/max row
        let labelsRow = UIStackView(arrangedSubviews: [minLabel, maxLabel])
        labelsRow.axis = .horizontal; labelsRow.distribution = .equalSpacing
        labelsRow.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(header)
        content.addSubview(gradientContainer)
        content.addSubview(labelsRow)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),

            gradientContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 6),
            gradientContainer.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            gradientContainer.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            gradientContainer.heightAnchor.constraint(equalToConstant: 10),

            labelsRow.topAnchor.constraint(equalTo: gradientContainer.bottomAnchor, constant: 4),
            labelsRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            labelsRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            labelsRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8),
        ])

        // Tap to toggle
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleCollapsed))
        addGestureRecognizer(tap)
    }

    // MARK: Public API
    func configure(with info: RadarLayer.LegendInfo) {
        titleLabel.text = info.title
        minLabel.text   = info.minLabel
        maxLabel.text   = info.maxLabel
        gradientLayer.colors = info.colors.map { $0.cgColor }
        if isCollapsed { expandCollapsed() }
    }

    // MARK: Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientContainer.bounds
    }

    // MARK: Collapse
    @objc private func toggleCollapsed() {
        isCollapsed ? expandCollapsed() : collapseToTitle()
    }

    private func collapseToTitle() {
        isCollapsed = true
        let cfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        chevronButton.setImage(UIImage(systemName: "chevron.up", withConfiguration: cfg), for: .normal)
        UIView.animate(withDuration: 0.25) {
            self.gradientContainer.alpha = 0
            self.minLabel.alpha = 0
            self.maxLabel.alpha = 0
        }
    }

    private func expandCollapsed() {
        isCollapsed = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        chevronButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: cfg), for: .normal)
        UIView.animate(withDuration: 0.25) {
            self.gradientContainer.alpha = 1
            self.minLabel.alpha = 1
            self.maxLabel.alpha = 1
        }
    }
}

private extension UIFont {
    static func monospacedSystemFont(ofSize size: CGFloat, size _: CGFloat) -> UIFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }
}

private final class RadarCrosshairView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let stroke = UIColor.white.withAlphaComponent(0.95)
        let shadow = UIColor.black.withAlphaComponent(0.45)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let lineLength: CGFloat = 12
        let gap: CGFloat = 5

        func drawLine(color: UIColor, width: CGFloat, from start: CGPoint, to end: CGPoint) {
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(width)
            context.setLineCap(.round)
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }

        let segments: [(CGPoint, CGPoint)] = [
            (CGPoint(x: center.x - lineLength, y: center.y), CGPoint(x: center.x - gap, y: center.y)),
            (CGPoint(x: center.x + gap, y: center.y), CGPoint(x: center.x + lineLength, y: center.y)),
            (CGPoint(x: center.x, y: center.y - lineLength), CGPoint(x: center.x, y: center.y - gap)),
            (CGPoint(x: center.x, y: center.y + gap), CGPoint(x: center.x, y: center.y + lineLength))
        ]

        for (start, end) in segments {
            drawLine(color: shadow, width: 4, from: start, to: end)
            drawLine(color: stroke, width: 2, from: start, to: end)
        }

        context.setFillColor(shadow.cgColor)
        context.fillEllipse(in: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
        context.setFillColor(stroke.cgColor)
        context.fillEllipse(in: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5))
    }
}

private final class RadarTotalsCardView: UIVisualEffectView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 18
        layer.masksToBounds = true
        isHidden = true

        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        contentView.addSubview(spinner)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            spinner.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            spinner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func showLoading(title: String, subtitle: String) {
        isHidden = false
        titleLabel.text = title
        valueLabel.text = "Loading…"
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .secondaryLabel
        spinner.startAnimating()
    }

    func showResult(title: String, value: String, subtitle: String) {
        isHidden = false
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .secondaryLabel
        spinner.stopAnimating()
    }

    func showError(title: String, subtitle: String) {
        isHidden = false
        titleLabel.text = title
        valueLabel.text = "Unavailable"
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .systemRed
        spinner.stopAnimating()
    }
}

// MARK: - Settings sheet

private class RadarSettingsViewController: UIViewController {

    var activeLayer: RadarLayer = .precipitation
    var colorScheme: ColorScheme = .nexrad { didSet { updateColorUI() } }
    var animationSpeed: AnimationSpeed = .normal { didSet { updateSpeedUI() } }
    var loopRange: LoopRange = .all { didSet { updateLoopUI() } }
    var radarOpacity: Float = 0.75 { didSet { opacitySlider.value = radarOpacity } }

    var onColorSchemeChanged: ((ColorScheme) -> Void)?
    var onSpeedChanged: ((AnimationSpeed) -> Void)?
    var onLoopChanged: ((LoopRange) -> Void)?
    var onOpacityChanged: ((Float) -> Void)?

    private let opacitySlider: UISlider = {
        let s = UISlider(); s.minimumValue = 0.3; s.maximumValue = 1.0; s.value = 0.75
        s.tintColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private var colorButtons: [UIButton] = []
    private var speedButtons: [UIButton] = []
    private var loopButtons: [UIButton]  = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Radar Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:)))
        setupLayout()
    }

    @objc private func dismiss(_ sender: Any) { dismiss(animated: true) }

    private func setupLayout() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 28
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        stack.addArrangedSubview(makeSection("Radar Opacity", view: makeOpacityRow()))
        if activeLayer.supportsColorSchemeSelection {
            stack.addArrangedSubview(makeSection("Color Scheme", view: makeColorRow()))
        }
        stack.addArrangedSubview(makeSection("Animation Speed", view: makeSpeedRow()))
        stack.addArrangedSubview(makeSection("Loop Range", view: makeLoopRow()))

        updateColorUI(); updateSpeedUI(); updateLoopUI()
    }

    private func makeSection(_ title: String, view sub: UIView) -> UIView {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = title.uppercased()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        sub.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label); v.addSubview(sub)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: v.topAnchor),
            label.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            sub.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            sub.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            sub.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            sub.bottomAnchor.constraint(equalTo: v.bottomAnchor)
        ])
        return v
    }

    private func makeOpacityRow() -> UIView {
        let row = UIStackView(arrangedSubviews: [
            iconLabel("sun.min"), opacitySlider, iconLabel("sun.max")
        ])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        opacitySlider.addTarget(self, action: #selector(opacityChanged), for: .valueChanged)
        return row
    }

    private func iconLabel(_ systemName: String) -> UIView {
        let img = UIImageView(image: UIImage(systemName: systemName))
        img.tintColor = .secondaryLabel
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([img.widthAnchor.constraint(equalToConstant: 20)])
        return img
    }

    private func makeColorRow() -> UIView {
        let scroll = UIScrollView(); scroll.showsHorizontalScrollIndicator = false
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.topAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scroll.heightAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 36)
        ])
        for scheme in ColorScheme.allCases {
            let btn = makeChip(scheme.label, tag: scheme.rawValue, action: #selector(colorTapped(_:)))
            row.addArrangedSubview(btn); colorButtons.append(btn)
        }
        return scroll
    }

    private func makeSpeedRow() -> UIView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 8; row.distribution = .fillEqually
        for (i, speed) in AnimationSpeed.allCases.enumerated() {
            let btn = makeChip(speed.label, tag: i, action: #selector(speedTapped(_:)))
            row.addArrangedSubview(btn); speedButtons.append(btn)
        }
        return row
    }

    private func makeLoopRow() -> UIView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 8; row.distribution = .fillEqually
        for (i, loop) in LoopRange.allCases.enumerated() {
            let btn = makeChip(loop.label, tag: i, action: #selector(loopTapped(_:)))
            row.addArrangedSubview(btn); loopButtons.append(btn)
        }
        return row
    }

    private func makeChip(_ title: String, tag: Int, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.layer.cornerRadius = 14; btn.layer.borderWidth = 1
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        btn.tag = tag
        btn.addTarget(self, action: action, for: .touchUpInside)
        applyChipStyle(btn, selected: false)
        return btn
    }

    private func applyChipStyle(_ btn: UIButton, selected: Bool) {
        let accent = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        btn.backgroundColor = selected ? accent : .secondarySystemBackground
        btn.setTitleColor(selected ? .white : .label, for: .normal)
        btn.layer.borderColor = selected ? accent.cgColor : UIColor.separator.cgColor
    }

    private func updateColorUI() {
        for btn in colorButtons {
            applyChipStyle(btn, selected: btn.tag == colorScheme.rawValue)
        }
    }
    private func updateSpeedUI() {
        for (i, btn) in speedButtons.enumerated() {
            applyChipStyle(btn, selected: AnimationSpeed.allCases[i] == animationSpeed)
        }
    }
    private func updateLoopUI() {
        for (i, btn) in loopButtons.enumerated() {
            applyChipStyle(btn, selected: LoopRange.allCases[i] == loopRange)
        }
    }

    @objc private func opacityChanged() {
        onOpacityChanged?(opacitySlider.value)
    }
    @objc private func colorTapped(_ sender: UIButton) {
        if let scheme = ColorScheme(rawValue: sender.tag) {
            colorScheme = scheme; onColorSchemeChanged?(scheme)
        }
    }
    @objc private func speedTapped(_ sender: UIButton) {
        let speed = AnimationSpeed.allCases[sender.tag]
        animationSpeed = speed; onSpeedChanged?(speed)
    }
    @objc private func loopTapped(_ sender: UIButton) {
        let loop = LoopRange.allCases[sender.tag]
        loopRange = loop; onLoopChanged?(loop)
    }
}

// MARK: - Main RadarViewController

class RadarViewController: UIViewController {

    private enum InteractionMode: Int {
        case radar
        case totals
    }

    // MARK: Settings state
    private var activeLayer: RadarLayer = .precipitation
    private var colorScheme: ColorScheme = .nexrad
    private var animationSpeed: AnimationSpeed = .normal
    private var loopRange: LoopRange = .all
    private var radarOpacity: Float = 0.75
    private var interactionMode: InteractionMode = .radar
    private var totalsDirection: MapPrecipitationDirection = .past
    private var totalsWindow: MapPrecipitationWindow = .hours24
    private var totalsFetchTask: Task<Void, Never>?
    private var pendingTotalsRefreshWorkItem: DispatchWorkItem?
    private var totalsRequestID = UUID()
    private var lastTotals: MapPrecipitationTotals?
    private let geocoder = CLGeocoder()
    private var locationNameCache: [String: String] = [:]
    private var geocodeTask: Task<Void, Never>?

    // MARK: OpenWeatherMap
    private let owmAPIKey = APIConfiguration.openWeatherMapAPIKey
    private let owmFrames = [RainViewerResponse.Frame(time: 0, path: "")]

    // MARK: Radar data
    private var precipFrames: [RainViewerResponse.Frame] = []
    private var satelliteFrames: [RainViewerResponse.Frame] = []
    private var currentIndex: Int = 0
    private var isPlaying = false
    private var animationTimer: Timer?
    private let tileSize = 512
    private var tileHost = "https://tilecache.rainviewer.com"
    private var currentOverlay: MKTileOverlay?
    private var overlayRefreshToken = UUID().uuidString
    private var windAnnotations: [WindAnnotation] = []
    private var pendingWindRefreshWorkItem: DispatchWorkItem?
    private var windFetchTask: Task<Void, Never>?

    // MARK: UI
    private let mapView: MKMapView = {
        let m = MKMapView()
        m.mapType = .standard
        m.showsUserLocation = true
        m.showsScale = true
        m.translatesAutoresizingMaskIntoConstraints = false
        return m
    }()

    private let controlPanel: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        v.layer.cornerRadius = 20; v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Radar", "Rain Totals"])
        control.selectedSegmentIndex = InteractionMode.radar.rawValue
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return control
    }()

    private var layerButtons: [UIButton] = []
    private var totalsWindowButtons: [UIButton] = []
    private let crosshairView = RadarCrosshairView()
    private let totalsCard = RadarTotalsCardView(effect: UIBlurEffect(style: .systemThickMaterial))
    private let totalsDirectionControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Past", "Future"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    private let totalsWindowRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private let layerScroll: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    private lazy var timeRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [liveBadge, timeLabel])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()
    private lazy var playbackRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [playPauseButton, UIView(), settingsButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    private let totalsControlsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private func makeLayerButtons() -> [UIButton] {
        return RadarLayer.allCases.enumerated().map { index, layer in
            let btn = UIButton(type: .system)
            btn.tag = index
            let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            let icon = UIImage(systemName: layer.icon, withConfiguration: config)
            btn.setImage(icon, for: .normal)
            btn.setTitle("  " + layer.rawValue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
            btn.layer.cornerRadius = 14; btn.layer.borderWidth = 1
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 14)
            btn.addTarget(self, action: #selector(layerTapped(_:)), for: .touchUpInside)
            return btn
        }
    }

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.text = "Loading…"
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let liveBadge: UILabel = {
        let l = UILabel()
        l.text = " LIVE "
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 1)
        l.layer.cornerRadius = 4; l.layer.masksToBounds = true
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let frameSlider: UISlider = {
        let s = UISlider(); s.minimumValue = 0; s.maximumValue = 1; s.value = 1
        s.tintColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var playPauseButton: UIButton = makeControlButton("play.fill", action: #selector(togglePlayback))
    private lazy var prevButton: UIButton     = makeControlButton("backward.frame.fill", action: #selector(stepBackward))
    private lazy var nextButton: UIButton     = makeControlButton("forward.frame.fill", action: #selector(stepForward))

    private lazy var settingsButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        b.setImage(UIImage(systemName: "slider.horizontal.3", withConfiguration: config), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        return b
    }()

    private let legendView = RadarLegendPillView()

    private lazy var mapTypeButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        b.setImage(UIImage(systemName: "map", withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        b.layer.cornerRadius = 20; b.layer.masksToBounds = true
        b.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        b.addTarget(self, action: #selector(cycleMapType), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    /// Set by the tab bar controller to center on the forecast location instead of GPS.
    var initialCoordinate: CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false
    private var mapTypes: [MKMapType] = [.standard, .satellite, .hybrid]
    private var mapTypeIndex = 0

    private final class WindAnnotation: NSObject, MKAnnotation {
        let coordinate: CLLocationCoordinate2D
        let speed: Double
        let direction: Double

        init(coordinate: CLLocationCoordinate2D, speed: Double, direction: Double) {
            self.coordinate = coordinate
            self.speed = speed
            self.direction = direction
            super.init()
        }

        var title: String? { "\(Int(speed.rounded())) \(TemperatureFormatter.isMetric ? "km/h" : "mph")" }
    }

    private final class WindAnnotationView: MKAnnotationView {
        static let reuseIdentifier = "WindAnnotationView"

        private let glyphBackground = UIView()
        private let arrowView = UIImageView()
        private let speedLabel = UILabel()

        override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
            super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
            setup()
        }

        required init?(coder: NSCoder) {
            fatalError()
        }

        private func setup() {
            frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            centerOffset = CGPoint(x: 0, y: -2)
            backgroundColor = .clear
            collisionMode = .rectangle
            displayPriority = .defaultHigh

            glyphBackground.backgroundColor = UIColor.black.withAlphaComponent(0.42)
            glyphBackground.layer.cornerRadius = 14
            glyphBackground.translatesAutoresizingMaskIntoConstraints = false
            addSubview(glyphBackground)

            arrowView.image = UIImage(systemName: "location.north.fill")
            arrowView.tintColor = .white
            arrowView.contentMode = .scaleAspectFit
            arrowView.translatesAutoresizingMaskIntoConstraints = false
            glyphBackground.addSubview(arrowView)

            speedLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
            speedLabel.textColor = .white
            speedLabel.textAlignment = .center
            speedLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(speedLabel)

            NSLayoutConstraint.activate([
                glyphBackground.topAnchor.constraint(equalTo: topAnchor),
                glyphBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
                glyphBackground.widthAnchor.constraint(equalToConstant: 28),
                glyphBackground.heightAnchor.constraint(equalToConstant: 28),

                arrowView.centerXAnchor.constraint(equalTo: glyphBackground.centerXAnchor),
                arrowView.centerYAnchor.constraint(equalTo: glyphBackground.centerYAnchor),
                arrowView.widthAnchor.constraint(equalToConstant: 16),
                arrowView.heightAnchor.constraint(equalToConstant: 16),

                speedLabel.topAnchor.constraint(equalTo: glyphBackground.bottomAnchor, constant: 2),
                speedLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                speedLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                speedLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        func configure(with annotation: WindAnnotation) {
            speedLabel.text = "\(Int(annotation.speed.rounded()))"

            // Meteorological direction indicates where the wind comes from.
            // Rotate the arrow to show where the wind is moving toward.
            let heading = CGFloat((annotation.direction + 180) * .pi / 180)
            arrowView.transform = CGAffineTransform(rotationAngle: heading)

            let tint: UIColor
            switch annotation.speed {
            case ..<10: tint = UIColor(red: 0.55, green: 0.85, blue: 0.15, alpha: 1)
            case ..<20: tint = UIColor(red: 1.00, green: 0.90, blue: 0.00, alpha: 1)
            case ..<30: tint = UIColor(red: 1.00, green: 0.55, blue: 0.00, alpha: 1)
            default:    tint = UIColor(red: 0.90, green: 0.15, blue: 0.15, alpha: 1)
            }
            arrowView.tintColor = tint
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Radar"
        view.backgroundColor = .systemBackground

        layerButtons = makeLayerButtons()

        mapView.delegate = self
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(mapTypeButton)
        NSLayoutConstraint.activate([
            mapTypeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 40),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        setupControlPanel()
        setupCrosshair()
        setupLegend()
        updateLayerUI()
        updateTotalsSelectionUI()
        updateInteractionUI()

        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged),
                                               name: Notification.Name("settingsChanged"), object: nil)

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        Task { await fetchRadarData() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-center every time the tab appears if a forecast coordinate was provided
        if let coord = initialCoordinate {
            let region = MKCoordinateRegion(center: coord,
                                            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0))
            mapView.setRegion(region, animated: animated)
            didCenterOnUser = true   // skip GPS centering since we have a coordinate
        }
        if interactionMode == .totals {
            scheduleTotalsRefresh(force: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
        windFetchTask?.cancel()
        totalsFetchTask?.cancel()
        geocodeTask?.cancel()
        pendingTotalsRefreshWorkItem?.cancel()
    }

    // MARK: - Control panel layout

    private func setupCrosshair() {
        crosshairView.isHidden = true
        totalsCard.isHidden = true

        view.addSubview(crosshairView)
        view.addSubview(totalsCard)

        NSLayoutConstraint.activate([
            crosshairView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            crosshairView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -14),
            crosshairView.widthAnchor.constraint(equalToConstant: 36),
            crosshairView.heightAnchor.constraint(equalToConstant: 36),

            totalsCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            totalsCard.bottomAnchor.constraint(equalTo: controlPanel.topAnchor, constant: -10),
            totalsCard.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            totalsCard.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            totalsCard.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupControlPanel() {
        view.addSubview(controlPanel)

        // Layer scroll
        let layerRow = UIStackView(arrangedSubviews: layerButtons)
        layerRow.axis = .horizontal; layerRow.spacing = 8
        layerRow.translatesAutoresizingMaskIntoConstraints = false
        layerScroll.addSubview(layerRow)
        NSLayoutConstraint.activate([
            layerRow.topAnchor.constraint(equalTo: layerScroll.topAnchor),
            layerRow.leadingAnchor.constraint(equalTo: layerScroll.leadingAnchor),
            layerRow.trailingAnchor.constraint(equalTo: layerScroll.trailingAnchor),
            layerRow.bottomAnchor.constraint(equalTo: layerScroll.bottomAnchor),
            layerRow.heightAnchor.constraint(equalTo: layerScroll.heightAnchor),
            layerScroll.heightAnchor.constraint(equalToConstant: 34)
        ])

        totalsDirectionControl.addTarget(self, action: #selector(totalsDirectionChanged), for: .valueChanged)

        for (index, window) in MapPrecipitationWindow.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(window.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.layer.cornerRadius = 14
            button.layer.borderWidth = 1
            button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
            button.addTarget(self, action: #selector(totalsWindowTapped(_:)), for: .touchUpInside)
            totalsWindowButtons.append(button)
            totalsWindowRow.addArrangedSubview(button)
        }

        totalsControlsStack.addArrangedSubview(totalsDirectionControl)
        totalsControlsStack.addArrangedSubview(totalsWindowRow)

        // Main vertical stack
        let inner = UIStackView(arrangedSubviews: [modeControl, layerScroll, totalsControlsStack, timeRow, frameSlider, playbackRow])
        inner.axis = .vertical; inner.spacing = 10; inner.alignment = .fill
        inner.translatesAutoresizingMaskIntoConstraints = false

        frameSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        controlPanel.contentView.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: controlPanel.contentView.topAnchor, constant: 14),
            inner.leadingAnchor.constraint(equalTo: controlPanel.contentView.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: controlPanel.contentView.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: controlPanel.contentView.bottomAnchor, constant: -14),

            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            controlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }

    private func setupLegend() {
        legendView.isHidden = true
        view.addSubview(legendView)
        NSLayoutConstraint.activate([
            legendView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            legendView.bottomAnchor.constraint(equalTo: controlPanel.topAnchor, constant: -8),
            legendView.widthAnchor.constraint(equalToConstant: 190),
        ])
    }

    private func updateLegend() {
        if let info = activeLayer.legendInfo {
            legendView.configure(with: info)
            if legendView.isHidden {
                legendView.alpha = 0
                legendView.isHidden = false
                UIView.animate(withDuration: 0.2) { self.legendView.alpha = 1 }
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: { self.legendView.alpha = 0 }) { _ in
                self.legendView.isHidden = true
            }
        }
    }

    private func makeControlButton(_ systemName: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        b.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        return b
    }

    private func updateTotalsSelectionUI() {
        let accent = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        totalsDirectionControl.selectedSegmentIndex = totalsDirection == .past ? 0 : 1
        for (index, button) in totalsWindowButtons.enumerated() {
            let selected = MapPrecipitationWindow.allCases[index] == totalsWindow
            button.backgroundColor = selected ? accent : .secondarySystemBackground
            button.setTitleColor(selected ? .white : .label, for: .normal)
            button.layer.borderColor = selected ? accent.cgColor : UIColor.separator.cgColor
        }
    }

    private func updateInteractionUI() {
        let isTotalsMode = interactionMode == .totals
        totalsControlsStack.isHidden = !isTotalsMode
        crosshairView.isHidden = !isTotalsMode
        layerScroll.isHidden = isTotalsMode
        totalsCard.isHidden = !isTotalsMode && lastTotals == nil

        if isTotalsMode {
            stopAnimation()
            timeRow.isHidden = true
            frameSlider.isHidden = true
            playbackRow.isHidden = true
            if let totals = lastTotals {
                renderTotals(totals)
            } else {
                totalsCard.showLoading(
                    title: "\(totalsDirection.rawValue) \(totalsWindow.title)",
                    subtitle: displayLocation(for: mapView.centerCoordinate)
                )
            }
            scheduleTotalsRefresh(force: true)
        } else {
            totalsFetchTask?.cancel()
            pendingTotalsRefreshWorkItem?.cancel()
            totalsCard.isHidden = true
            updatePlaybackVisibility()
            if activeLayer.isAnimatable, !activeFrames.isEmpty {
                startAnimation()
            }
        }
    }

    private func updatePlaybackVisibility() {
        let showPlayback = interactionMode == .radar && activeLayer.isAnimatable
        timeRow.isHidden = !showPlayback
        frameSlider.isHidden = !showPlayback
        playPauseButton.isHidden = !showPlayback
        playbackRow.isHidden = interactionMode != .radar
        if !showPlayback {
            liveBadge.isHidden = true
        }
    }

    // MARK: - Layer chip styling

    private func updateLayerUI() {
        let accent = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        for (i, btn) in layerButtons.enumerated() {
            let selected = RadarLayer.allCases[i] == activeLayer
            btn.backgroundColor = selected ? accent : .secondarySystemBackground
            btn.tintColor = selected ? .white : .secondaryLabel
            btn.setTitleColor(selected ? .white : .label, for: .normal)
            btn.layer.borderColor = selected ? accent.cgColor : UIColor.separator.cgColor
        }
        // Legend is set up after setupLegend() is called; guard prevents crash during init ordering
        if legendView.superview != nil { updateLegend() }
    }

    // MARK: - Fetch radar data

    private func fetchRadarData() async {
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

            await MainActor.run {
                self.tileHost = response.host ?? self.tileHost

                var precip: [RainViewerResponse.Frame] = []
                precip += response.radar?.past ?? []
                precip += response.radar?.nowcast ?? []
                self.precipFrames = self.applyLoopRange(precip)

                self.satelliteFrames = self.applyLoopRange(response.satellite?.infrared ?? [])

                self.reloadFrames()
            }
        } catch {
            await MainActor.run { self.timeLabel.text = "Radar unavailable" }
        }
    }

    private func applyLoopRange(_ frames: [RainViewerResponse.Frame]) -> [RainViewerResponse.Frame] {
        guard loopRange != .all else { return frames }
        let cutoff = Int(Date().timeIntervalSince1970) - loopRange.rawValue
        return frames.filter { $0.time >= cutoff }
    }

    private func reloadFrames() {
        if let old = currentOverlay { mapView.removeOverlay(old); currentOverlay = nil }
        if activeLayer != .wind {
            clearWindAnnotations()
        }

        let animatable = activeLayer.isAnimatable

        liveBadge.isHidden = true

        if activeLayer == .wind {
            timeLabel.text = activeLayer.rawValue
            scheduleWindRefresh(for: mapView.region, force: true)
            updatePlaybackVisibility()
            return
        }

        let frames = activeFrames
        guard !frames.isEmpty else {
            timeLabel.text = activeLayer == .satellite
                ? "Satellite data unavailable from RainViewer"
                : "No radar data available"
            updatePlaybackVisibility()
            return
        }
        frameSlider.maximumValue = Float(frames.count - 1)
        currentIndex = frames.count - 1
        frameSlider.value = Float(currentIndex)
        showCurrentFrame()

        if interactionMode == .radar && animatable {
            startAnimation()
        } else if interactionMode == .radar {
            timeLabel.text = activeLayer.rawValue
        }
        updatePlaybackVisibility()
    }

    private var activeFrames: [RainViewerResponse.Frame] {
        switch activeLayer {
        case .precipitation: return precipFrames
        case .satellite:     return satelliteFrames
        case .temperature, .wind, .clouds, .pressure:
            return owmFrames
        }
    }

    // MARK: - Frame display

    private func overlayTemplate(for frame: RainViewerResponse.Frame) -> String? {
        switch activeLayer {
        case .precipitation:
            return "\(tileHost)\(frame.path)/\(tileSize)/{z}/{x}/{y}/\(ColorScheme.sourceRadarValue)/1_1.png?refresh=\(overlayRefreshToken)"
        case .satellite:
            return "\(tileHost)\(frame.path)/\(tileSize)/{z}/{x}/{y}/0/0_0.png?refresh=\(overlayRefreshToken)"
        case .temperature:
            guard !owmAPIKey.isEmpty else { return nil }
            return "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=\(owmAPIKey)"
        case .wind:
            return nil
        case .clouds:
            guard !owmAPIKey.isEmpty else { return nil }
            return "https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=\(owmAPIKey)"
        case .pressure:
            guard !owmAPIKey.isEmpty else { return nil }
            return "https://tile.openweathermap.org/map/pressure_new/{z}/{x}/{y}.png?appid=\(owmAPIKey)"
        }
    }

    private func showCurrentFrame() {
        let frames = activeFrames
        guard currentIndex < frames.count else { return }
        let frame = frames[currentIndex]

        guard let template = overlayTemplate(for: frame) else {
            if let old = currentOverlay { mapView.removeOverlay(old); currentOverlay = nil }
            updateTimeLabel(for: frame)
            frameSlider.value = Float(currentIndex)
            return
        }

        // Keep old overlay visible while new one loads (simple crossfade)
        let oldOverlay = currentOverlay

        let overlay: MKTileOverlay
        if activeLayer == .precipitation {
            overlay = RecoloredRadarTileOverlay(urlTemplate: template, scheme: colorScheme)
        } else {
            overlay = MKTileOverlay(urlTemplate: template)
            overlay.canReplaceMapContent = false
        }
        overlay.tileSize = CGSize(width: tileSize, height: tileSize)
        mapView.addOverlay(overlay, level: .aboveLabels)
        currentOverlay = overlay

        // Remove old overlay after short delay so tiles have time to appear
        if let old = oldOverlay {
            let removalDelay: TimeInterval
            if activeLayer == .precipitation && colorScheme != .blue {
                removalDelay = max(1.1, animationSpeed.rawValue + 0.7)
            } else {
                removalDelay = 0.4
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay) { [weak self] in
                self?.mapView.removeOverlay(old)
            }
        }

        updateTimeLabel(for: frame)
        frameSlider.value = Float(currentIndex)
    }

    private func updateTimeLabel(for frame: RainViewerResponse.Frame) {
        // Static OWM layers have no meaningful timestamp
        guard activeLayer.isAnimatable else {
            timeLabel.text = activeLayer.rawValue
            liveBadge.isHidden = true
            return
        }
        let date = Date(timeIntervalSince1970: TimeInterval(frame.time))
        let now = Date()
        let diff = Int(now.timeIntervalSince(date))
        let isNowcast = date > now

        if isNowcast {
            let mins = Int(date.timeIntervalSince(now) / 60)
            timeLabel.text = "+\(mins) min forecast"
            liveBadge.isHidden = true
        } else if diff < 300 {
            timeLabel.text = "Now"
            liveBadge.isHidden = false
        } else if diff < 3600 {
            timeLabel.text = "\(diff / 60) min ago"
            liveBadge.isHidden = true
        } else {
            let df = DateFormatter(); df.timeStyle = .short; df.dateStyle = .none
            timeLabel.text = df.string(from: date)
            liveBadge.isHidden = true
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        guard !activeFrames.isEmpty else { return }
        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        scheduleNextFrame()
    }

    private func stopAnimation() {
        isPlaying = false
        animationTimer?.invalidate(); animationTimer = nil
        playPauseButton.setImage(UIImage(systemName: "play.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
    }

    private func scheduleNextFrame() {
        animationTimer?.invalidate()
        let isLast = currentIndex >= activeFrames.count - 1
        let delay: TimeInterval = isLast ? 2.0 : animationSpeed.rawValue
        animationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.currentIndex = (self.currentIndex + 1) % max(1, self.activeFrames.count)
            self.showCurrentFrame()
            self.scheduleNextFrame()
        }
    }

    // MARK: - Actions

    @objc private func layerTapped(_ sender: UIButton) {
        let newLayer = RadarLayer.allCases[sender.tag]
        guard newLayer != activeLayer else { return }

        // Tear down old layer
        stopAnimation()
        if let old = currentOverlay { mapView.removeOverlay(old); currentOverlay = nil }
        clearWindAnnotations()

        activeLayer = newLayer
        updateLayerUI()
        updateLegend()
        reloadFrames()
        if interactionMode == .totals {
            scheduleTotalsRefresh(force: true)
        }
    }

    @objc private func modeChanged() {
        interactionMode = InteractionMode(rawValue: modeControl.selectedSegmentIndex) ?? .radar
        updateInteractionUI()
    }

    @objc private func togglePlayback() {
        if isPlaying { stopAnimation() } else { startAnimation() }
    }

    @objc private func stepBackward() {
        stopAnimation()
        guard !activeFrames.isEmpty else { return }
        currentIndex = max(0, currentIndex - 1)
        showCurrentFrame()
    }

    @objc private func stepForward() {
        stopAnimation()
        guard !activeFrames.isEmpty else { return }
        currentIndex = min(activeFrames.count - 1, currentIndex + 1)
        showCurrentFrame()
    }

    @objc private func sliderChanged() {
        stopAnimation()
        currentIndex = Int(frameSlider.value.rounded())
        showCurrentFrame()
    }

    @objc private func settingsChanged() {
        // Re-read legend info so unit labels (°C/°F, km/h/mph, hPa/inHg) stay current
        updateLegend()
    }

    @objc private func cycleMapType() {
        mapTypeIndex = (mapTypeIndex + 1) % mapTypes.count
        mapView.mapType = mapTypes[mapTypeIndex]
        let icons = ["map", "globe.americas.fill", "map.fill"]
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        mapTypeButton.setImage(UIImage(systemName: icons[mapTypeIndex], withConfiguration: config), for: .normal)
    }

    @objc private func totalsDirectionChanged() {
        totalsDirection = totalsDirectionControl.selectedSegmentIndex == 0 ? .past : .forecast
        updateTotalsSelectionUI()
        scheduleTotalsRefresh(force: true)
    }

    @objc private func totalsWindowTapped(_ sender: UIButton) {
        let selected = MapPrecipitationWindow.allCases[sender.tag]
        guard selected != totalsWindow else { return }
        totalsWindow = selected
        updateTotalsSelectionUI()
        scheduleTotalsRefresh(force: true)
    }

    @objc private func openSettings() {
        let vc = RadarSettingsViewController()
        vc.activeLayer     = activeLayer
        vc.colorScheme    = colorScheme
        vc.animationSpeed = animationSpeed
        vc.loopRange      = loopRange
        vc.radarOpacity   = radarOpacity

        vc.onColorSchemeChanged = { [weak self] scheme in
            guard let self else { return }
            self.colorScheme = scheme
            self.overlayRefreshToken = UUID().uuidString
            // Color scheme changes the URL template, so rebuild all overlays
            self.stopAnimation()
            if let old = self.currentOverlay { self.mapView.removeOverlay(old); self.currentOverlay = nil }
            self.reloadFrames()
        }
        vc.onSpeedChanged = { [weak self] speed in
            self?.animationSpeed = speed
        }
        vc.onLoopChanged = { [weak self] range in
            guard let self = self else { return }
            self.loopRange = range
            self.precipFrames   = self.applyLoopRange(self.precipFrames)
            self.satelliteFrames = self.applyLoopRange(self.satelliteFrames)
            self.reloadFrames()
        }
        vc.onOpacityChanged = { [weak self] opacity in
            guard let self else { return }
            self.radarOpacity = opacity
            self.overlayRefreshToken = UUID().uuidString
            // Re-add current overlay to pick up new opacity via rendererFor delegate
            if let overlay = self.currentOverlay {
                self.mapView.removeOverlay(overlay)
                self.mapView.addOverlay(overlay, level: .aboveLabels)
            }
        }

        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func clearWindAnnotations() {
        pendingWindRefreshWorkItem?.cancel()
        windFetchTask?.cancel()
        if !windAnnotations.isEmpty {
            mapView.removeAnnotations(windAnnotations)
            windAnnotations.removeAll()
        }
    }

    private func scheduleTotalsRefresh(force: Bool = false) {
        guard interactionMode == .totals else { return }

        pendingTotalsRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchTotalsForMapCenter()
        }
        pendingTotalsRefreshWorkItem = workItem
        let delay: TimeInterval = force ? 0.05 : 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func fetchTotalsForMapCenter() {
        guard interactionMode == .totals else { return }

        let coordinate = mapView.centerCoordinate
        let title = "\(totalsDirection.rawValue) \(totalsWindow.title)"
        totalsCard.showLoading(title: title, subtitle: displayLocation(for: coordinate))

        totalsFetchTask?.cancel()
        let requestID = UUID()
        totalsRequestID = requestID
        let units = TemperatureFormatter.apiUnits

        totalsFetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let totals = try await MapPrecipitationTotalsService.shared.fetchTotals(
                    coordinate: coordinate,
                    direction: self.totalsDirection,
                    window: self.totalsWindow,
                    units: units
                )
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard self.interactionMode == .totals,
                          self.totalsRequestID == requestID else { return }
                    self.lastTotals = totals
                    self.renderTotals(totals)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard self.interactionMode == .totals,
                          self.totalsRequestID == requestID else { return }
                    self.totalsCard.showError(
                        title: title,
                        subtitle: error.localizedDescription
                    )
                }
            }
        }
    }

    private func renderTotals(_ totals: MapPrecipitationTotals) {
        let unitLabel = TemperatureFormatter.isMetric ? "mm" : "in"
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = totals.totalPrecipitation < 10 ? 2 : 1
        formatter.maximumFractionDigits = totals.totalPrecipitation < 10 ? 2 : 1
        let value = formatter.string(from: NSNumber(value: totals.totalPrecipitation)) ?? String(format: "%.2f", totals.totalPrecipitation)
        let title = "\(totals.direction.rawValue) \(totals.window.title)"
        let subtitle = "\(displayLocation(for: totals.coordinate))\n\(totals.sourceName) model estimate"
        totalsCard.showResult(title: title, value: "\(value) \(unitLabel)", subtitle: subtitle)
        resolveLocationName(for: totals.coordinate)
    }

    private func displayLocation(for coordinate: CLLocationCoordinate2D) -> String {
        let coordinateText = coordinateSubtitle(for: coordinate)
        let key = locationCacheKey(for: coordinate)
        if let cached = locationNameCache[key] {
            return "\(cached) • \(coordinateText)"
        }
        resolveLocationName(for: coordinate)
        return coordinateText
    }

    private func resolveLocationName(for coordinate: CLLocationCoordinate2D) {
        let key = locationCacheKey(for: coordinate)
        if locationNameCache[key] != nil {
            return
        }

        geocodeTask?.cancel()
        geocodeTask = Task { [weak self] in
            guard let self else { return }
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(
                    CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                )
                guard !Task.isCancelled else { return }
                let name = placemarks.first.flatMap(Self.makeLocationName(from:))
                await MainActor.run {
                    guard let name else { return }
                    self.locationNameCache[key] = name
                    if let totals = self.lastTotals,
                       abs(totals.coordinate.latitude - coordinate.latitude) < 0.01,
                       abs(totals.coordinate.longitude - coordinate.longitude) < 0.01 {
                        self.renderTotals(totals)
                    } else if self.interactionMode == .totals {
                        self.totalsCard.showLoading(
                            title: "\(self.totalsDirection.rawValue) \(self.totalsWindow.title)",
                            subtitle: self.displayLocation(for: coordinate)
                        )
                    }
                }
            } catch {
                // Leave coordinates visible as the fallback label.
            }
        }
    }

    private static func makeLocationName(from placemark: CLPlacemark) -> String? {
        if let city = placemark.locality, let state = placemark.administrativeArea {
            return "\(city), \(state)"
        }
        if let city = placemark.locality, let country = placemark.country {
            return "\(city), \(country)"
        }
        if let name = placemark.locality ?? placemark.name ?? placemark.subAdministrativeArea {
            return name
        }
        return nil
    }

    private func locationCacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        let lat = round(coordinate.latitude * 100) / 100
        let lon = round(coordinate.longitude * 100) / 100
        return String(format: "%.2f,%.2f", lat, lon)
    }

    private func coordinateSubtitle(for coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.2f, %.2f", coordinate.latitude, coordinate.longitude)
    }

    private func scheduleWindRefresh(for region: MKCoordinateRegion, force: Bool = false) {
        guard activeLayer == .wind else { return }

        pendingWindRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchWindAnnotations(for: region, force: force)
        }
        pendingWindRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + (force ? 0.05 : 0.35), execute: workItem)
    }

    private func fetchWindAnnotations(for region: MKCoordinateRegion, force: Bool) {
        guard activeLayer == .wind else { return }

        let points = windSampleCoordinates(for: region)
        guard !points.isEmpty else { return }

        windFetchTask?.cancel()
        windFetchTask = Task { [weak self] in
            guard let self else { return }

            let latitudes = points.map { String(format: "%.4f", $0.latitude) }.joined(separator: ",")
            let longitudes = points.map { String(format: "%.4f", $0.longitude) }.joined(separator: ",")
            let speedUnit = TemperatureFormatter.isMetric ? "kmh" : "mph"
            let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitudes)&longitude=\(longitudes)&current=wind_speed_10m,wind_direction_10m&wind_speed_unit=\(speedUnit)&timezone=GMT"

            guard let url = URL(string: urlString) else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }

                let decoder = JSONDecoder()
                let responses: [OpenMeteoWindResponse]
                if let list = try? decoder.decode([OpenMeteoWindResponse].self, from: data) {
                    responses = list
                } else {
                    responses = [try decoder.decode(OpenMeteoWindResponse.self, from: data)]
                }

                let annotations = responses.compactMap { item -> WindAnnotation? in
                    guard let current = item.current,
                          let speed = current.windSpeed10m,
                          let direction = current.windDirection10m else { return nil }
                    return WindAnnotation(
                        coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
                        speed: speed,
                        direction: direction
                    )
                }

                await MainActor.run {
                    guard self.activeLayer == .wind else { return }
                    self.mapView.removeAnnotations(self.windAnnotations)
                    self.windAnnotations = annotations
                    self.mapView.addAnnotations(annotations)
                    self.timeLabel.text = annotations.isEmpty ? "Wind unavailable" : "Wind Direction"
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if self.activeLayer == .wind {
                        self.timeLabel.text = "Wind unavailable"
                    }
                }
            }
        }
    }

    private func windSampleCoordinates(for region: MKCoordinateRegion) -> [CLLocationCoordinate2D] {
        let rows = 4
        let columns = 5

        let latDelta = max(region.span.latitudeDelta, 0.8)
        let lonDelta = max(region.span.longitudeDelta, 0.8)
        let minLat = max(region.center.latitude - latDelta * 0.42, -85)
        let maxLat = min(region.center.latitude + latDelta * 0.42, 85)
        let minLon = region.center.longitude - lonDelta * 0.42
        let maxLon = region.center.longitude + lonDelta * 0.42

        guard maxLat > minLat, maxLon > minLon else { return [] }

        var coords: [CLLocationCoordinate2D] = []
        for row in 0..<rows {
            let latProgress = Double(row) / Double(rows - 1)
            let lat = maxLat - (maxLat - minLat) * latProgress
            for column in 0..<columns {
                let lonProgress = Double(column) / Double(columns - 1)
                let lon = minLon + (maxLon - minLon) * lonProgress
                coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        return coords
    }
}

// MARK: - MKMapViewDelegate

extension RadarViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tile = overlay as? MKTileOverlay else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKTileOverlayRenderer(tileOverlay: tile)
        renderer.alpha = CGFloat(radarOpacity)
        return renderer
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        scheduleWindRefresh(for: mapView.region)
        scheduleTotalsRefresh()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let windAnnotation = annotation as? WindAnnotation else { return nil }

        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: WindAnnotationView.reuseIdentifier
        ) as? WindAnnotationView ?? WindAnnotationView(
            annotation: windAnnotation,
            reuseIdentifier: WindAnnotationView.reuseIdentifier
        )
        view.annotation = windAnnotation
        view.configure(with: windAnnotation)
        return view
    }

}

// MARK: - CLLocationManagerDelegate

extension RadarViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first, !didCenterOnUser else { return }
        didCenterOnUser = true
        manager.stopUpdatingLocation()
        let region = MKCoordinateRegion(center: loc.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0))
        mapView.setRegion(region, animated: false)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Radar location error: \(error)")
    }
}

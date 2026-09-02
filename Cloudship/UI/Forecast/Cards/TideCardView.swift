//
//  TideCardView.swift
//  Cloudship
//
//  Compact tide card for Forecast. Prefers NOAA CO-OPS station predictions and
//  falls back to clearly-labeled modeled sea level when authoritative tides are
//  unavailable.
//

import UIKit
import CoreLocation

// MARK: - Tide domain

enum TideDataQuality: String, Codable {
    case noaa
    case modeled

    var sourceName: String {
        switch self {
        case .noaa: return "NOAA tide station"
        case .modeled: return "Modeled sea level"
        }
    }

    var datumLabel: String {
        switch self {
        case .noaa: return "MLLW"
        case .modeled: return "MSL"
        }
    }
}

enum TideEventKind: String, Codable {
    case high = "H"
    case low = "L"

    var label: String {
        switch self {
        case .high: return "High"
        case .low: return "Low"
        }
    }
}

struct TideSample: Codable {
    let time: Date
    let heightMeters: Double
}

struct TideEvent: Codable {
    let time: Date
    let heightMeters: Double
    let kind: TideEventKind
}

struct TideReport: Codable {
    let quality: TideDataQuality
    let stationName: String?
    let stationDistanceKilometers: Double?
    let generatedAt: Date
    let samples: [TideSample]
    let events: [TideEvent]

    var currentHeightMeters: Double? {
        interpolatedHeight(at: Date())
    }

    var nextEvent: TideEvent? {
        let now = Date()
        return events.filter { $0.time >= now }.min { $0.time < $1.time }
    }

    var nextLowEvent: TideEvent? {
        let now = Date()
        return events.filter { $0.kind == .low && $0.time >= now }.min { $0.time < $1.time }
    }

    var tideDirection: String? {
        let now = Date()
        guard let before = samples.last(where: { $0.time <= now }),
              let after = samples.first(where: { $0.time > now }) else { return nil }
        let delta = after.heightMeters - before.heightMeters
        if abs(delta) < 0.01 { return "Holding steady" }
        return delta > 0 ? "Rising" : "Falling"
    }

    var insight: String {
        if let low = nextLowEvent {
            if low.time.timeIntervalSinceNow < 8 * 3600 {
                let start = max(Date(), low.time.addingTimeInterval(-90 * 60))
                let end = low.time.addingTimeInterval(90 * 60)
                let label = quality == .noaa && low.heightMeters < 0 ? "Negative tide window" : "Best beach window"
                return "\(label): \(TideFormatters.timeRange(start: start, end: end))"
            }

            if tideDirection == "Falling" {
                return "Falling tide — more beach by \(DateFormatHelper.hourString(from: low.time))"
            }
        }

        if let event = nextEvent {
            if event.kind == .high && tideDirection == "Rising" {
                return "Rising tide — go earlier for more exposed beach"
            }
            return "\(event.kind.label) tide at \(DateFormatHelper.hourString(from: event.time))"
        }
        return quality == .noaa ? "Station prediction for the next 24 hours" : "Approximate coastal sea-level trend"
    }

    func interpolatedHeight(at date: Date) -> Double? {
        guard !samples.isEmpty else { return nil }
        if let exact = samples.first(where: { abs($0.time.timeIntervalSince(date)) < 60 }) {
            return exact.heightMeters
        }
        guard let before = samples.last(where: { $0.time <= date }) else {
            return samples.first?.heightMeters
        }
        guard let after = samples.first(where: { $0.time > date }) else {
            return samples.last?.heightMeters
        }
        let total = after.time.timeIntervalSince(before.time)
        guard total > 0 else { return before.heightMeters }
        let progress = date.timeIntervalSince(before.time) / total
        return before.heightMeters + (after.heightMeters - before.heightMeters) * progress
    }
}

enum TideFormatters {
    static func height(_ meters: Double, includeUnit: Bool) -> String {
        if TemperatureFormatter.isMetric {
            let value = meters
            return includeUnit ? String(format: "%.2f m", value) : String(format: "%.2f", value)
        } else {
            let value = meters * 3.28084
            return includeUnit ? String(format: "%.1f ft", value) : String(format: "%.1f", value)
        }
    }

    static func timeRange(start: Date, end: Date) -> String {
        "\(time(start))–\(time(end))"
    }

    private static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Provider

final class TideConditionsService {
    static let shared = TideConditionsService()

    private let cacheKeyPrefix = "tideReport_v1_"
    private let cacheLifetime: TimeInterval = 30 * 60
    private let maximumNOAAStationDistanceKm: Double = 80
    private let maximumModeledLatitude: Double = 80

    private init() {}

    func fetchReport(for coordinate: CLLocationCoordinate2D) async throws -> TideReport? {
        if let cached = cachedReport(for: coordinate) {
            return cached
        }

        if let station = try? await nearestNOAAStation(to: coordinate),
           station.distanceKilometers <= maximumNOAAStationDistanceKm,
           let report = try? await fetchNOAAReport(station: station) {
            cache(report, for: coordinate)
            return report
        }

        if abs(coordinate.latitude) <= maximumModeledLatitude,
           let modeled = try? await fetchModeledReport(for: coordinate) {
            cache(modeled, for: coordinate)
            return modeled
        }

        return nil
    }

    private func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        "\(cacheKeyPrefix)\(String(format: "%.2f", coordinate.latitude))_\(String(format: "%.2f", coordinate.longitude))"
    }

    private func cachedReport(for coordinate: CLLocationCoordinate2D) -> TideReport? {
        let key = cacheKey(for: coordinate)
        guard let data = UserDefaults.standard.data(forKey: key),
              let report = try? JSONDecoder().decode(TideReport.self, from: data),
              Date().timeIntervalSince(report.generatedAt) < cacheLifetime else {
            return nil
        }
        return report
    }

    private func cache(_ report: TideReport, for coordinate: CLLocationCoordinate2D) {
        guard let data = try? JSONEncoder().encode(report) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey(for: coordinate))
    }
}

// MARK: NOAA

private extension TideConditionsService {
    struct NOAAStationList: Decodable {
        let stations: [NOAAStation]
    }

    struct NOAAStation: Decodable {
        let id: String
        let name: String
        let lat: Double
        let lng: Double

        var coordinate: CLLocation {
            CLLocation(latitude: lat, longitude: lng)
        }
    }

    struct NearbyNOAAStation {
        let station: NOAAStation
        let distanceKilometers: Double
    }

    struct NOAAPredictionsResponse: Decodable {
        let predictions: [NOAAPrediction]?
    }

    struct NOAAPrediction: Decodable {
        let t: String
        let v: String
        let type: String?
    }

    func nearestNOAAStation(to coordinate: CLLocationCoordinate2D) async throws -> NearbyNOAAStation? {
        var comps = URLComponents(string: "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json")!
        comps.queryItems = [.init(name: "type", value: "tidepredictions")]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let response = try JSONDecoder().decode(NOAAStationList.self, from: data)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return response.stations
            .map { NearbyNOAAStation(station: $0, distanceKilometers: location.distance(from: $0.coordinate) / 1000) }
            .min { $0.distanceKilometers < $1.distanceKilometers }
    }

    func fetchNOAAReport(station: NearbyNOAAStation) async throws -> TideReport? {
        async let interval = fetchNOAAPredictions(stationID: station.station.id, interval: "15")
        async let hilo = fetchNOAAPredictions(stationID: station.station.id, interval: "hilo")
        let (intervalPredictions, eventPredictions) = try await (interval, hilo)

        let samples = intervalPredictions.compactMap { prediction -> TideSample? in
            guard let date = TideDateParsing.noaaDate(from: prediction.t),
                  let value = Double(prediction.v) else { return nil }
            return TideSample(time: date, heightMeters: value)
        }

        let events = eventPredictions.compactMap { prediction -> TideEvent? in
            guard let date = TideDateParsing.noaaDate(from: prediction.t),
                  let value = Double(prediction.v),
                  let rawType = prediction.type,
                  let kind = TideEventKind(rawValue: rawType) else { return nil }
            return TideEvent(time: date, heightMeters: value, kind: kind)
        }

        guard samples.count >= 4 else { return nil }
        return TideReport(
            quality: .noaa,
            stationName: station.station.name,
            stationDistanceKilometers: station.distanceKilometers,
            generatedAt: Date(),
            samples: samples,
            events: events
        )
    }

    func fetchNOAAPredictions(stationID: String, interval: String) async throws -> [NOAAPrediction] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"

        var comps = URLComponents(string: "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter")!
        comps.queryItems = [
            .init(name: "product", value: "predictions"),
            .init(name: "application", value: "Cloudship"),
            .init(name: "begin_date", value: formatter.string(from: Date())),
            .init(name: "range", value: "36"),
            .init(name: "datum", value: "MLLW"),
            .init(name: "station", value: stationID),
            .init(name: "time_zone", value: "lst_ldt"),
            .init(name: "units", value: "metric"),
            .init(name: "interval", value: interval),
            .init(name: "format", value: "json")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(NOAAPredictionsResponse.self, from: data).predictions ?? []
    }
}

// MARK: Open-Meteo marine fallback

private extension TideConditionsService {
    struct OpenMeteoMarineResponse: Decodable {
        let hourly: Hourly?

        struct Hourly: Decodable {
            let time: [String]?
            let seaLevelHeight: [Double?]?

            enum CodingKeys: String, CodingKey {
                case time
                case seaLevelHeight = "sea_level_height_msl"
            }
        }
    }

    func fetchModeledReport(for coordinate: CLLocationCoordinate2D) async throws -> TideReport? {
        var comps = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")!
        comps.queryItems = [
            .init(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            .init(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            .init(name: "hourly", value: "sea_level_height_msl"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "2")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let response = try JSONDecoder().decode(OpenMeteoMarineResponse.self, from: data)
        guard let hourly = response.hourly,
              let times = hourly.time,
              let heights = hourly.seaLevelHeight else { return nil }

        let samples: [TideSample] = times.enumerated().compactMap { index, timeString in
            guard let date = TideDateParsing.openMeteoDate(from: timeString),
                  index < heights.count,
                  let height = heights[index] else { return nil }
            return TideSample(time: date, heightMeters: height)
        }

        guard samples.count >= 6 else { return nil }
        return TideReport(
            quality: .modeled,
            stationName: nil,
            stationDistanceKilometers: nil,
            generatedAt: Date(),
            samples: Array(samples.prefix(36)),
            events: TideEventFinder.events(from: samples)
        )
    }
}

private enum TideDateParsing {
    static func noaaDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)
    }

    static func openMeteoDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: string)
    }
}

private enum TideEventFinder {
    static func events(from samples: [TideSample]) -> [TideEvent] {
        guard samples.count >= 3 else { return [] }
        var events: [TideEvent] = []
        for index in 1..<(samples.count - 1) {
            let previous = samples[index - 1]
            let current = samples[index]
            let next = samples[index + 1]

            if current.heightMeters >= previous.heightMeters && current.heightMeters > next.heightMeters {
                events.append(TideEvent(time: current.time, heightMeters: current.heightMeters, kind: .high))
            } else if current.heightMeters <= previous.heightMeters && current.heightMeters < next.heightMeters {
                events.append(TideEvent(time: current.time, heightMeters: current.heightMeters, kind: .low))
            }
        }
        return events
    }
}

// MARK: - Chart

private final class TideChartView: UIView {
    var report: TideReport? {
        didSet { setNeedsDisplay() }
    }

    private let oceanColor = UIColor(red: 0.10, green: 0.55, blue: 0.85, alpha: 1)
    private let lowTideColor = UIColor(red: 0.08, green: 0.70, blue: 0.65, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let report, report.samples.count >= 2, let ctx = UIGraphicsGetCurrentContext() else { return }

        let now = Date()
        let end = now.addingTimeInterval(24 * 3600)
        let visibleSamples = report.samples.filter { $0.time >= now.addingTimeInterval(-900) && $0.time <= end }
        guard visibleSamples.count >= 2 else { return }

        let heights = visibleSamples.map(\.heightMeters)
        let minHeight = heights.min() ?? 0
        let maxHeight = heights.max() ?? 1
        let range = max(maxHeight - minHeight, 0.1)
        let topPadding: CGFloat = 12
        let bottomPadding: CGFloat = 16
        let drawingHeight = rect.height - topPadding - bottomPadding

        func point(for sample: TideSample) -> CGPoint {
            let progress = sample.time.timeIntervalSince(now) / (24 * 3600)
            let x = CGFloat(max(0, min(1, progress))) * rect.width
            let normalized = (sample.heightMeters - minHeight) / range
            let y = topPadding + (1 - CGFloat(normalized)) * drawingHeight
            return CGPoint(x: x, y: y)
        }

        drawGrid(in: rect, context: ctx)

        let path = UIBezierPath()
        path.move(to: point(for: visibleSamples[0]))
        for index in 1..<visibleSamples.count {
            let previous = point(for: visibleSamples[index - 1])
            let current = point(for: visibleSamples[index])
            let step = current.x - previous.x
            path.addCurve(
                to: current,
                controlPoint1: CGPoint(x: previous.x + step * 0.45, y: previous.y),
                controlPoint2: CGPoint(x: current.x - step * 0.45, y: current.y)
            )
        }

        let fill = path.copy() as! UIBezierPath
        fill.addLine(to: CGPoint(x: rect.width, y: rect.height))
        fill.addLine(to: CGPoint(x: 0, y: rect.height))
        fill.close()

        ctx.saveGState()
        fill.addClip()
        let colors = [
            oceanColor.withAlphaComponent(0.34).cgColor,
            lowTideColor.withAlphaComponent(0.08).cgColor
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: rect.height), options: [])
        }
        ctx.restoreGState()

        oceanColor.setStroke()
        path.lineWidth = 2.5
        path.lineCapStyle = .round
        path.stroke()

        drawNowMarker(in: rect, context: ctx, report: report, minHeight: minHeight, range: range, topPadding: topPadding, drawingHeight: drawingHeight)
        drawEvents(report.events.filter { $0.time >= now && $0.time <= end }, in: rect, now: now, minHeight: minHeight, range: range, topPadding: topPadding, drawingHeight: drawingHeight)
    }

    private func drawGrid(in rect: CGRect, context: CGContext) {
        let color: UIColor = WeatherDataSourceManager.shared.isShowingHistorical
            ? CardView.textColor(for: .tertiary).withAlphaComponent(0.22)
            : UIColor.separator.withAlphaComponent(0.28)
        color.setStroke()
        let grid = UIBezierPath()
        for fraction in [0.25, 0.5, 0.75] {
            let x = rect.width * CGFloat(fraction)
            grid.move(to: CGPoint(x: x, y: 6))
            grid.addLine(to: CGPoint(x: x, y: rect.height - 10))
        }
        grid.lineWidth = 0.7
        grid.setLineDash([3, 5], count: 2, phase: 0)
        grid.stroke()
    }

    private func drawNowMarker(in rect: CGRect, context: CGContext, report: TideReport, minHeight: Double, range: Double, topPadding: CGFloat, drawingHeight: CGFloat) {
        guard let current = report.currentHeightMeters else { return }
        let normalized = (current - minHeight) / range
        let y = topPadding + (1 - CGFloat(normalized)) * drawingHeight
        let center = CGPoint(x: 0, y: y)

        UIColor.systemBackground.withAlphaComponent(0.9).setFill()
        UIColor(red: 0.10, green: 0.55, blue: 0.85, alpha: 1).setStroke()
        let dot = UIBezierPath(ovalIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
        dot.lineWidth = 2
        dot.fill()
        dot.stroke()
    }

    private func drawEvents(_ events: [TideEvent], in rect: CGRect, now: Date, minHeight: Double, range: Double, topPadding: CGFloat, drawingHeight: CGFloat) {
        for event in events.prefix(5) {
            let progress = event.time.timeIntervalSince(now) / (24 * 3600)
            let x = CGFloat(max(0, min(1, progress))) * rect.width
            let normalized = (event.heightMeters - minHeight) / range
            let y = topPadding + (1 - CGFloat(normalized)) * drawingHeight
            let isLow = event.kind == .low
            let color = isLow ? UIColor(red: 0.08, green: 0.70, blue: 0.65, alpha: 1) : UIColor(red: 0.33, green: 0.66, blue: 1, alpha: 1)

            color.setFill()
            let marker = UIBezierPath(ovalIn: CGRect(x: x - 3.5, y: y - 3.5, width: 7, height: 7))
            marker.fill()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let label = event.kind == .low ? "L" : "H"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.appFont(forTextStyle: .caption2),
                .foregroundColor: CardView.textColor(for: .tertiary),
                .paragraphStyle: paragraph
            ]
            NSString(string: label).draw(in: CGRect(x: x - 8, y: y + (isLow ? 5 : -18), width: 16, height: 14), withAttributes: attributes)
        }
    }
}

// MARK: - Card

final class TideCardView: CardView {
    private let titleLabel: UILabel
    private let statusLabel = UILabel()
    private let currentLabel = UILabel()
    private let nextEventLabel = UILabel()
    private let insightLabel = UILabel()
    private let sourceLabel = UILabel()
    private let chartView = TideChartView()

    private let nowTickLabel = TideCardView.makeTickLabel("Now")
    private let sixHourTickLabel = TideCardView.makeTickLabel("")
    private let twelveHourTickLabel = TideCardView.makeTickLabel("")
    private let dayTickLabel = TideCardView.makeTickLabel("")

    private var report: TideReport?

    override init(frame: CGRect) {
        titleLabel = UILabel()
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        titleLabel = UILabel()
        super.init(coder: coder)
        setupLayout()
    }

    func configure(report: TideReport) {
        self.report = report
        chartView.report = report
        isHidden = false
        applyTextPalette()

        let current = report.currentHeightMeters.map { TideFormatters.height($0, includeUnit: true) } ?? "—"
        currentLabel.text = current
        statusLabel.text = [report.tideDirection, "now"].compactMap { $0 }.joined(separator: " ")

        if let next = report.nextEvent {
            nextEventLabel.text = "\(next.kind.label) \(DateFormatHelper.hourString(from: next.time)) · \(TideFormatters.height(next.heightMeters, includeUnit: true))"
        } else {
            nextEventLabel.text = "Next tide unavailable"
        }

        insightLabel.text = report.insight
        sourceLabel.text = sourceText(for: report)
        updateTickLabels()
        updateAccessibility()
    }

    func showLoading() {
        isHidden = false
        report = nil
        chartView.report = nil
        currentLabel.text = "—"
        statusLabel.text = "Loading tide"
        nextEventLabel.text = "Finding nearby coastal data…"
        insightLabel.text = "Tides appear here for coastal locations."
        sourceLabel.text = nil
        updateTickLabels()
        applyTextPalette()
        accessibilityLabel = "Tides loading"
    }

    func showUnavailable() {
        isHidden = true
        report = nil
        chartView.report = nil
    }

    override func applyVintageStyle() {
        super.applyVintageStyle()
        applyTextPalette()
        chartView.setNeedsDisplay()
    }

    override func restoreTint() {
        super.restoreTint()
        applyTextPalette()
        chartView.setNeedsDisplay()
    }

    private func setupLayout() {
        let p = CardView.padding
        titleLabel.text = "TIDES"
        titleLabel.font = .appFont(forTextStyle: .caption1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .appFont(forTextStyle: .caption1)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        currentLabel.font = .appFont(size: 38, weight: .semibold)
        currentLabel.adjustsFontForContentSizeCategory = true
        currentLabel.translatesAutoresizingMaskIntoConstraints = false
        currentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        nextEventLabel.font = .appFont(forTextStyle: .subheadline)
        nextEventLabel.adjustsFontForContentSizeCategory = true
        nextEventLabel.translatesAutoresizingMaskIntoConstraints = false

        insightLabel.font = .appFont(forTextStyle: .caption1)
        insightLabel.adjustsFontForContentSizeCategory = true
        insightLabel.numberOfLines = 2
        insightLabel.translatesAutoresizingMaskIntoConstraints = false

        sourceLabel.font = .appFont(forTextStyle: .caption2)
        sourceLabel.adjustsFontForContentSizeCategory = true
        sourceLabel.numberOfLines = 1
        sourceLabel.lineBreakMode = .byTruncatingTail
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false

        chartView.translatesAutoresizingMaskIntoConstraints = false

        let labelsStack = UIStackView(arrangedSubviews: [nextEventLabel, insightLabel, sourceLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(statusLabel)
        addSubview(currentLabel)
        addSubview(labelsStack)
        addSubview(chartView)
        addSubview(nowTickLabel)
        addSubview(sixHourTickLabel)
        addSubview(twelveHourTickLabel)
        addSubview(dayTickLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            statusLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),

            currentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            currentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            labelsStack.leadingAnchor.constraint(equalTo: currentLabel.trailingAnchor, constant: 16),
            labelsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            labelsStack.centerYAnchor.constraint(equalTo: currentLabel.centerYAnchor),
            labelsStack.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 8),

            chartView.topAnchor.constraint(equalTo: currentLabel.bottomAnchor, constant: 12),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            chartView.heightAnchor.constraint(equalToConstant: 104),

            nowTickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            nowTickLabel.leadingAnchor.constraint(equalTo: chartView.leadingAnchor),
            nowTickLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),

            sixHourTickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            twelveHourTickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),

            dayTickLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            dayTickLabel.trailingAnchor.constraint(equalTo: chartView.trailingAnchor)
        ])

        NSLayoutConstraint(item: sixHourTickLabel, attribute: .centerX, relatedBy: .equal,
                           toItem: chartView, attribute: .centerX, multiplier: 0.5, constant: 0).isActive = true
        NSLayoutConstraint(item: twelveHourTickLabel, attribute: .centerX, relatedBy: .equal,
                           toItem: chartView, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
    }

    private func sourceText(for report: TideReport) -> String {
        var pieces: [String]
        switch report.quality {
        case .noaa:
            pieces = ["NOAA"]
            if let station = report.stationName {
                pieces.append(shortStationName(station))
            }
        case .modeled:
            pieces = ["Modeled sea level"]
        }
        if let distance = report.stationDistanceKilometers {
            pieces.append(formattedDistance(distance))
        }
        pieces.append(report.quality.datumLabel)
        if report.quality == .modeled {
            pieces.append("approximate")
        }
        return pieces.joined(separator: " · ")
    }

    private func shortStationName(_ station: String) -> String {
        let primaryName = station
            .split(separator: ",", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? station
        let trimmed = primaryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 28 else { return trimmed }
        return String(trimmed.prefix(25)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private func formattedDistance(_ kilometers: Double) -> String {
        if TemperatureFormatter.isMetric {
            return String(format: "%.0f km", kilometers)
        }
        return String(format: "%.0f mi", kilometers * 0.621371)
    }

    private func updateTickLabels() {
        let now = Date()
        sixHourTickLabel.text = DateFormatHelper.hourString(from: now.addingTimeInterval(6 * 3600))
        twelveHourTickLabel.text = DateFormatHelper.hourString(from: now.addingTimeInterval(12 * 3600))
        dayTickLabel.text = DateFormatHelper.hourString(from: now.addingTimeInterval(24 * 3600))
    }

    private func updateAccessibility() {
        guard let report else {
            accessibilityLabel = "Tides"
            return
        }
        isAccessibilityElement = true
        var parts = ["Tides"]
        if let current = report.currentHeightMeters {
            parts.append("current height \(TideFormatters.height(current, includeUnit: true))")
        }
        if let direction = report.tideDirection {
            parts.append(direction.lowercased())
        }
        if let next = report.nextEvent {
            parts.append("next \(next.kind.label.lowercased()) tide at \(DateFormatHelper.hourString(from: next.time)), \(TideFormatters.height(next.heightMeters, includeUnit: true))")
        }
        parts.append(report.quality == .noaa ? "NOAA station data" : "modeled approximate data")
        accessibilityLabel = parts.joined(separator: ", ")
    }

    private func applyTextPalette() {
        titleLabel.textColor = CardView.textColor(for: .secondary)
        statusLabel.textColor = CardView.textColor(for: .tertiary)
        currentLabel.textColor = CardView.textColor(for: .primary)
        nextEventLabel.textColor = CardView.textColor(for: .primary)
        insightLabel.textColor = CardView.textColor(for: .secondary)
        sourceLabel.textColor = CardView.textColor(for: .tertiary)
        nowTickLabel.textColor = CardView.textColor(for: .tertiary)
        sixHourTickLabel.textColor = CardView.textColor(for: .tertiary)
        twelveHourTickLabel.textColor = CardView.textColor(for: .tertiary)
        dayTickLabel.textColor = CardView.textColor(for: .tertiary)
    }

    private static func makeTickLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .appFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = CardView.textColor(for: .tertiary)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}

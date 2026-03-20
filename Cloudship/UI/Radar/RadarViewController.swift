//
//  RadarViewController.swift
//  Cloudship
//
//  Animated weather radar powered by RainViewer (free, no API key).
//  Layers: Precipitation (animated), Satellite Infrared (animated),
//          Lightning Strikes (live via Blitzortung WebSocket).
//  Settings: color scheme, opacity, animation speed, loop range, map type.
//

import UIKit
import MapKit
import CoreLocation

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

private struct LightningStrike {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
}

// MARK: - Enums

enum RadarLayer: String, CaseIterable {
    case precipitation = "Precipitation"
    case satellite     = "Satellite"
    case lightning     = "Lightning"

    var icon: String {
        switch self {
        case .precipitation: return "cloud.rain.fill"
        case .satellite:     return "globe.americas.fill"
        case .lightning:     return "bolt.fill"
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

// MARK: - Lightning annotation

private class LightningAnnotation: MKPointAnnotation {
    var strikeDate: Date = Date()
}

private class LightningAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        backgroundColor = .clear
        isOpaque = false
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let strike = annotation as? LightningAnnotation
        let age = Date().timeIntervalSince(strike?.strikeDate ?? Date())
        let alpha = max(0.2, 1.0 - age / 300.0)   // fade over 5 min

        let color = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: alpha)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        if let img = UIImage(systemName: "bolt.fill", withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) {
            ctx.translateBy(x: (rect.width - 14) / 2, y: (rect.height - 14) / 2)
            img.draw(in: CGRect(x: 0, y: 0, width: 14, height: 14))
        }
    }
}

// MARK: - Settings sheet

private class RadarSettingsViewController: UIViewController {

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
        stack.addArrangedSubview(makeSection("Color Scheme", view: makeColorRow()))
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

    // MARK: Settings state
    private var activeLayer: RadarLayer = .precipitation
    private var colorScheme: ColorScheme = .nexrad
    private var animationSpeed: AnimationSpeed = .normal
    private var loopRange: LoopRange = .all
    private var radarOpacity: Float = 0.75

    // MARK: Radar data
    private var precipFrames: [RainViewerResponse.Frame] = []
    private var satelliteFrames: [RainViewerResponse.Frame] = []
    private var currentIndex: Int = 0
    private var isPlaying = false
    private var animationTimer: Timer?
    private var currentOverlay: MKTileOverlay?
    private let tileSize = 512
    private var tileHost = "https://tilecache.rainviewer.com"

    // MARK: Lightning state
    private var lightningStrikes: [LightningStrike] = []
    private var lightningAnnotations: [LightningAnnotation] = []
    private var webSocketTask: URLSessionWebSocketTask?
    private let maxStrikes = 300
    private var lightningFadeTimer: Timer?

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

    private var layerButtons: [UIButton] = []

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

    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false
    private var mapTypes: [MKMapType] = [.standard, .satellite, .hybrid]
    private var mapTypeIndex = 0

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

        mapView.register(LightningAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: "lightning")

        view.addSubview(mapTypeButton)
        NSLayoutConstraint.activate([
            mapTypeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 40),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        setupControlPanel()
        updateLayerUI()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        Task { await fetchRadarData() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
        disconnectLightning()
        lightningFadeTimer?.invalidate()
    }

    // MARK: - Control panel layout

    private func setupControlPanel() {
        view.addSubview(controlPanel)

        // Layer scroll
        let layerScroll = UIScrollView()
        layerScroll.showsHorizontalScrollIndicator = false
        layerScroll.translatesAutoresizingMaskIntoConstraints = false

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

        // Time row
        let timeRow = UIStackView(arrangedSubviews: [liveBadge, timeLabel])
        timeRow.axis = .horizontal; timeRow.spacing = 6; timeRow.alignment = .center

        // Playback row
        let playbackRow = UIStackView(arrangedSubviews: [prevButton, playPauseButton, nextButton,
                                                          UIView(), settingsButton])
        playbackRow.axis = .horizontal; playbackRow.spacing = 20; playbackRow.alignment = .center

        // Main vertical stack
        let inner = UIStackView(arrangedSubviews: [layerScroll, timeRow, frameSlider, playbackRow])
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

    private func makeControlButton(_ systemName: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        b.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
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

        let hasFrames = activeLayer == .precipitation || activeLayer == .satellite
        frameSlider.isHidden = !hasFrames
        prevButton.isEnabled = hasFrames
        nextButton.isEnabled = hasFrames
        playPauseButton.isEnabled = hasFrames
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
        let frames = activeFrames
        guard !frames.isEmpty else {
            timeLabel.text = activeLayer == .satellite ? "Satellite unavailable" : "No data"
            return
        }
        frameSlider.maximumValue = Float(frames.count - 1)
        currentIndex = frames.count - 1
        frameSlider.value = Float(currentIndex)
        showCurrentFrame()
        startAnimation()
    }

    private var activeFrames: [RainViewerResponse.Frame] {
        switch activeLayer {
        case .precipitation: return precipFrames
        case .satellite:     return satelliteFrames
        case .lightning:     return []
        }
    }

    // MARK: - Frame display

    private func showCurrentFrame() {
        let frames = activeFrames
        guard currentIndex < frames.count else { return }
        let frame = frames[currentIndex]

        if let old = currentOverlay { mapView.removeOverlay(old) }

        let template: String
        switch activeLayer {
        case .precipitation:
            template = "\(tileHost)\(frame.path)/\(tileSize)/{z}/{x}/{y}/\(colorScheme.rawValue)/1_1.png"
        case .satellite:
            template = "\(tileHost)\(frame.path)/\(tileSize)/{z}/{x}/{y}/0/0_0.png"
        case .lightning:
            currentOverlay = nil
            return
        }

        let overlay = MKTileOverlay(urlTemplate: template)
        overlay.canReplaceMapContent = false
        overlay.tileSize = CGSize(width: tileSize, height: tileSize)
        mapView.addOverlay(overlay, level: .aboveLabels)
        currentOverlay = overlay

        updateTimeLabel(for: frame)
        frameSlider.value = Float(currentIndex)
    }

    private func updateTimeLabel(for frame: RainViewerResponse.Frame) {
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

    // MARK: - Lightning WebSocket

    private func connectLightning() {
        let servers = ["ws1.blitzortung.org", "ws7.blitzortung.org", "ws8.blitzortung.org"]
        let host = servers.randomElement()!
        guard let url = URL(string: "wss://\(host)/") else { return }

        timeLabel.text = "Connecting…"
        liveBadge.isHidden = true

        var request = URLRequest(url: url)
        request.setValue("https://www.blitzortung.org", forHTTPHeaderField: "Origin")
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        // Send subscription for global coverage
        let sub = #"{"west":-180,"east":180,"south":-90,"north":90}"#
        webSocketTask?.send(.string(sub)) { _ in }

        receiveNextStrike()
        timeLabel.text = "Live Lightning"
        liveBadge.isHidden = false

        // Fade old strikes every 30s
        lightningFadeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.removeOldStrikes()
        }
    }

    private func disconnectLightning() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        lightningFadeTimer?.invalidate()
        lightningFadeTimer = nil
        mapView.removeAnnotations(lightningAnnotations)
        lightningAnnotations.removeAll()
        lightningStrikes.removeAll()
    }

    private func receiveNextStrike() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self.parseStrike(text)
                }
                self.receiveNextStrike()
            case .failure:
                break
            }
        }
    }

    private func parseStrike(_ json: String) {
        guard let data = json.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let lat = dict["lat"] as? Double,
              let lon = dict["lon"] as? Double else { return }

        let strike = LightningStrike(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            timestamp: Date()
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lightningStrikes.append(strike)

            let ann = LightningAnnotation()
            ann.coordinate = strike.coordinate
            ann.strikeDate = strike.timestamp
            self.lightningAnnotations.append(ann)
            self.mapView.addAnnotation(ann)

            // Keep capped
            if self.lightningStrikes.count > self.maxStrikes {
                let toRemove = Array(self.lightningAnnotations.prefix(
                    self.lightningAnnotations.count - self.maxStrikes))
                self.mapView.removeAnnotations(toRemove)
                self.lightningAnnotations = Array(self.lightningAnnotations.suffix(self.maxStrikes))
                self.lightningStrikes = Array(self.lightningStrikes.suffix(self.maxStrikes))
            }

            // Redraw all lightning views to update fade
            for ann in self.lightningAnnotations {
                self.mapView.view(for: ann)?.setNeedsDisplay()
            }
        }
    }

    private func removeOldStrikes() {
        let cutoff = Date().addingTimeInterval(-300) // 5 min
        let stale = lightningAnnotations.filter { $0.strikeDate < cutoff }
        mapView.removeAnnotations(stale)
        lightningAnnotations.removeAll { $0.strikeDate < cutoff }
        lightningStrikes.removeAll { $0.timestamp < cutoff }
    }

    // MARK: - Actions

    @objc private func layerTapped(_ sender: UIButton) {
        let newLayer = RadarLayer.allCases[sender.tag]
        guard newLayer != activeLayer else { return }

        // Tear down old layer
        stopAnimation()
        if activeLayer == .lightning { disconnectLightning() }
        if let old = currentOverlay { mapView.removeOverlay(old); currentOverlay = nil }

        activeLayer = newLayer
        updateLayerUI()

        switch activeLayer {
        case .precipitation, .satellite:
            reloadFrames()
        case .lightning:
            frameSlider.isHidden = true
            timeLabel.text = "Connecting…"
            connectLightning()
        }
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

    @objc private func cycleMapType() {
        mapTypeIndex = (mapTypeIndex + 1) % mapTypes.count
        mapView.mapType = mapTypes[mapTypeIndex]
        let icons = ["map", "globe.americas.fill", "map.fill"]
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        mapTypeButton.setImage(UIImage(systemName: icons[mapTypeIndex], withConfiguration: config), for: .normal)
    }

    @objc private func openSettings() {
        let vc = RadarSettingsViewController()
        vc.colorScheme    = colorScheme
        vc.animationSpeed = animationSpeed
        vc.loopRange      = loopRange
        vc.radarOpacity   = radarOpacity

        vc.onColorSchemeChanged = { [weak self] scheme in
            self?.colorScheme = scheme
            self?.showCurrentFrame()
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
            self?.radarOpacity = opacity
            // Update current overlay renderer opacity
            if let overlay = self?.currentOverlay {
                self?.mapView.removeOverlay(overlay)
                self?.mapView.addOverlay(overlay, level: .aboveLabels)
            }
        }

        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
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

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is LightningAnnotation else { return nil }
        let v = mapView.dequeueReusableAnnotationView(withIdentifier: "lightning", for: annotation)
        return v
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

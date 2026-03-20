//
//  RadarViewController.swift
//  Cloudship
//
//  Animated precipitation radar powered by RainViewer (free, no API key).
//  Fetches up to 12 historical frames + forecast frames and animates them
//  over a MapKit base map.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - RainViewer models

private struct RainViewerResponse: Codable {
    let host: String?
    let radar: RadarData?

    struct RadarData: Codable {
        let past: [Frame]?
        let nowcast: [Frame]?
    }

    struct Frame: Codable {
        let time: Int
        let path: String
    }
}

// MARK: - Main VC

class RadarViewController: UIViewController {

    // MARK: - State

    private var frames: [RainViewerResponse.Frame] = []
    private var currentIndex: Int = 0
    private var isPlaying = false
    private var animationTimer: Timer?
    private var currentOverlay: MKTileOverlay?

    private let tileHost = "https://tilecache.rainviewer.com"
    private let tileSize = 512       // pixels
    private let colorScheme = 6      // NEXRAD Level III – classic green→red
    private let tileOptions = "1_1"  // smooth=1, snow=1

    // MARK: - UI

    private let mapView: MKMapView = {
        let m = MKMapView()
        m.mapType = .standard
        m.showsUserLocation = true
        m.showsScale = true
        m.translatesAutoresizingMaskIntoConstraints = false
        return m
    }()

    private let controlPanel: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThickMaterial)
        let v = UIVisualEffectView(effect: blur)
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.text = "Loading radar…"
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
        l.layer.cornerRadius = 4
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    private lazy var playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "play.fill"), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        return b
    }()

    private lazy var prevButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "backward.frame.fill"), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(stepBackward), for: .touchUpInside)
        return b
    }()

    private lazy var nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "forward.frame.fill"), for: .normal)
        b.tintColor = .label
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(stepForward), for: .touchUpInside)
        return b
    }()

    private let frameSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0
        s.maximumValue = 1
        s.value = 1
        s.tintColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let locationManager = CLLocationManager()
    private var didCenterOnUser = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Radar"
        view.backgroundColor = .systemBackground

        setupMap()
        setupControls()
        setupLocation()

        Task { await fetchRadarFrames() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }

    // MARK: - Layout

    private func setupMap() {
        mapView.delegate = self
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupControls() {
        view.addSubview(controlPanel)

        // Time label row
        let topRow = UIStackView(arrangedSubviews: [liveBadge, timeLabel])
        topRow.axis = .horizontal
        topRow.spacing = 6
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // Playback buttons row
        let btnRow = UIStackView(arrangedSubviews: [prevButton, playPauseButton, nextButton])
        btnRow.axis = .horizontal
        btnRow.spacing = 24
        btnRow.alignment = .center
        btnRow.distribution = .equalSpacing
        btnRow.translatesAutoresizingMaskIntoConstraints = false

        frameSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let inner = UIStackView(arrangedSubviews: [topRow, frameSlider, btnRow])
        inner.axis = .vertical
        inner.spacing = 8
        inner.alignment = .center
        inner.translatesAutoresizingMaskIntoConstraints = false

        controlPanel.contentView.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: controlPanel.contentView.topAnchor, constant: 12),
            inner.leadingAnchor.constraint(equalTo: controlPanel.contentView.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: controlPanel.contentView.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: controlPanel.contentView.bottomAnchor, constant: -12),

            frameSlider.leadingAnchor.constraint(equalTo: inner.leadingAnchor),
            frameSlider.trailingAnchor.constraint(equalTo: inner.trailingAnchor),

            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - Radar data

    private func fetchRadarFrames() async {
        guard let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

            var all: [RainViewerResponse.Frame] = []
            all += response.radar?.past ?? []
            all += response.radar?.nowcast ?? []

            await MainActor.run {
                self.frames = all
                guard !all.isEmpty else { return }
                self.frameSlider.maximumValue = Float(all.count - 1)
                self.frameSlider.value = Float(all.count - 1)
                self.currentIndex = all.count - 1
                self.showFrame(at: self.currentIndex)
                self.startAnimation()
            }
        } catch {
            print("RainViewer fetch error: \(error)")
            await MainActor.run {
                self.timeLabel.text = "Radar unavailable"
            }
        }
    }

    // MARK: - Frame display

    private func showFrame(at index: Int) {
        guard index < frames.count else { return }
        let frame = frames[index]

        // Remove old overlay
        if let old = currentOverlay {
            mapView.removeOverlay(old)
        }

        // Build tile URL template
        let template = "\(tileHost)\(frame.path)/\(tileSize)/{z}/{x}/{y}/\(colorScheme)/\(tileOptions).png"
        let overlay = MKTileOverlay(urlTemplate: template)
        overlay.canReplaceMapContent = false
        overlay.tileSize = CGSize(width: tileSize, height: tileSize)
        mapView.addOverlay(overlay, level: .aboveLabels)
        currentOverlay = overlay

        // Update time label
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
            let mins = diff / 60
            timeLabel.text = "\(mins) min ago"
            liveBadge.isHidden = true
        } else {
            let df = DateFormatter()
            df.timeStyle = .short
            df.dateStyle = .none
            timeLabel.text = df.string(from: date)
            liveBadge.isHidden = true
        }

        frameSlider.value = Float(index)
    }

    // MARK: - Animation

    private func startAnimation() {
        guard !frames.isEmpty else { return }
        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        scheduleNextFrame()
    }

    private func stopAnimation() {
        isPlaying = false
        animationTimer?.invalidate()
        animationTimer = nil
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }

    private func scheduleNextFrame() {
        animationTimer?.invalidate()
        // Pause longer on the last (latest) frame
        let isLast = currentIndex >= frames.count - 1
        let delay: TimeInterval = isLast ? 2.0 : 0.6
        animationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.currentIndex = (self.currentIndex + 1) % self.frames.count
            self.showFrame(at: self.currentIndex)
            self.scheduleNextFrame()
        }
    }

    // MARK: - Controls

    @objc private func togglePlayback() {
        if isPlaying { stopAnimation() } else { startAnimation() }
    }

    @objc private func stepBackward() {
        stopAnimation()
        guard !frames.isEmpty else { return }
        currentIndex = max(0, currentIndex - 1)
        showFrame(at: currentIndex)
    }

    @objc private func stepForward() {
        stopAnimation()
        guard !frames.isEmpty else { return }
        currentIndex = min(frames.count - 1, currentIndex + 1)
        showFrame(at: currentIndex)
    }

    @objc private func sliderChanged() {
        stopAnimation()
        currentIndex = Int(frameSlider.value.rounded())
        showFrame(at: currentIndex)
    }
}

// MARK: - MKMapViewDelegate

extension RadarViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tile = overlay as? MKTileOverlay else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKTileOverlayRenderer(tileOverlay: tile)
        renderer.alpha = 0.75
        return renderer
    }
}

// MARK: - CLLocationManagerDelegate

extension RadarViewController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first, !didCenterOnUser else { return }
        didCenterOnUser = true
        manager.stopUpdatingLocation()

        let region = MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
        mapView.setRegion(region, animated: false)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Radar location error: \(error)")
    }
}

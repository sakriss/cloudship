//
//  MainForecastViewController.swift
//  Cloudship
//
//  Scroll view host for all weather cards.
//  Owns CLLocationManager, UISearchController, pull-to-refresh, and card reordering.
//

import UIKit
import CoreLocation
import MapKit
import GoogleMobileAds

class MainForecastViewController: UIViewController {

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var currentLocation: CLLocation?
    private var isShowingGPSLocation = false
    private var bannerView: GADBannerView?

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// Small pill shown above the header card indicating the active data source.
    private lazy var sourceLabel: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "antenna.radiowaves.left.and.right"))
        icon.tintColor = .secondaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 99  // used to find and update later

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 14),
            icon.heightAnchor.constraint(equalToConstant: 12),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 24)
        ])
        return container
    }()

    private let headerCard      = HeaderCardView()
    private let alertBannerCard = AlertBannerCardView()
    private let minutelyCard    = MinutelyCardView()
    private let hourlyCard      = HourlyCardView()
    private let dailyCard       = DailyCardView()
    private let detailsCard     = DetailsCardView()
    private let windGustCard    = WindGustCardView()
    private let airQualityCard  = AirQualityCardView()
    private let pollenCard      = PollenCardView()
    private let activityScoresCard = ActivityScoresCardView()
    private let aiSummaryCard      = AISummaryCardView()

    /// Cards the user can reorder, in current display order.
    private var reorderableCards: [CardView] = []

    // Drag-to-reorder state
    private var dragSnapshot: UIView?
    private var draggingCard: CardView?
    private var initialSnapshotCenter: CGPoint = .zero

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    // Search
    private var searchController: UISearchController!
    private var searchResultsVC: SearchResultsViewController!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupReorderableCards()   // must come before setupLayout
        setupLayout()
        setupLocation()
        setupNotifications()
        setupBannerAd()
        setupAlertCard()
        setupDailyCard()
        setupAISummaryCard()
        activityIndicator.startAnimating()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Navigation

    private func setupNavBar() {
        navigationItem.title = "Weather"
        navigationController?.navigationBar.prefersLargeTitles = false

        // Search
        searchResultsVC = SearchResultsViewController()
        searchResultsVC.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsVC)
        searchController.searchResultsUpdater = searchResultsVC
        searchController.searchBar.placeholder = "Search for a city"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.showsSearchResultsController = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true

        // AI chat button
        let aiButton = UIBarButtonItem(
            image: UIImage(systemName: "sparkles"),
            style: .plain,
            target: self,
            action: #selector(openAIChat)
        )
        navigationItem.rightBarButtonItem = aiButton
    }

    @objc private func openAIChat() {
        guard let data = WeatherDataSourceManager.shared.lastData else {
            let alert = UIAlertController(title: nil,
                                          message: "Weather data not loaded yet. Please wait a moment.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let vc = AIWeatherChatViewController(weatherData: data)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }

    // MARK: - Card Reordering Setup

    private static let cardOrderKey = "cardOrder_v2"

    private static let defaultCardIDs = ["aiSummary", "hourly", "daily", "minutely", "details", "windGust", "airQuality", "pollen", "activityScores"]

    private func setupReorderableCards() {
        // Map ID → card
        let idToCard: [String: CardView] = [
            "minutely":   minutelyCard,
            "hourly":     hourlyCard,
            "daily":      dailyCard,
            "details":    detailsCard,
            "windGust":   windGustCard,
            "airQuality":     airQualityCard,
            "pollen":         pollenCard,
            "activityScores": activityScoresCard,
            "aiSummary":      aiSummaryCard
        ]

        // Assign IDs
        idToCard.forEach { id, card in card.cardID = id }

        // Load saved order; fall back to default
        let savedIDs = UserDefaults.standard.array(forKey: Self.cardOrderKey) as? [String]
            ?? Self.defaultCardIDs

        var ordered: [CardView] = savedIDs.compactMap { idToCard[$0] }
        // Append cards not present in saved order (e.g. newly added cards)
        let seen = Set(ordered.map { $0.cardID })
        for id in Self.defaultCardIDs {
            if !seen.contains(id), let card = idToCard[id] {
                ordered.append(card)
            }
        }
        reorderableCards = ordered

        // Fixed cards — no handle
        headerCard.showsReorderHandle = false
        alertBannerCard.showsReorderHandle = false

        // Attach pan gesture to each reorderable card's handle
        for card in reorderableCards {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCardDrag(_:)))
            card.reorderHandle.addGestureRecognizer(pan)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.refreshControl = refreshControl

        // Source label sits above the header card (not a CardView, so added separately)
        stackView.addArrangedSubview(sourceLabel)

        // Fixed cards first, then reorderable in saved order
        let allCards: [CardView] = [headerCard, alertBannerCard] + reorderableCards
        allCards.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview($0)
        }

        view.addSubview(activityIndicator)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Drag-to-Reorder

    @objc private func handleCardDrag(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view,
              let card = handle.superview as? CardView else { return }

        switch gesture.state {
        case .began:
            draggingCard = card

            // Convert card frame into scroll view coordinates
            let cardFrameInScroll = stackView.convert(card.frame, to: scrollView)
            guard let snapshot = card.snapshotView(afterScreenUpdates: false) else { break }
            snapshot.frame = cardFrameInScroll
            snapshot.layer.cornerRadius = 18
            snapshot.layer.masksToBounds = true
            snapshot.layer.shadowColor = UIColor.black.cgColor
            snapshot.layer.shadowOpacity = 0.20
            snapshot.layer.shadowRadius = 14
            snapshot.layer.shadowOffset = .zero
            scrollView.addSubview(snapshot)
            dragSnapshot = snapshot
            initialSnapshotCenter = snapshot.center

            UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseOut) {
                card.alpha = 0.25
                snapshot.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            }

        case .changed:
            guard let snapshot = dragSnapshot, let card = draggingCard else { return }
            let translation = gesture.translation(in: scrollView)
            snapshot.center = CGPoint(x: initialSnapshotCenter.x,
                                      y: initialSnapshotCenter.y + translation.y)

            let newIndex = reorderTargetIndex(for: snapshot, dragging: card)
            if let currentIndex = reorderableCards.firstIndex(of: card),
               newIndex != currentIndex {
                UIView.animate(withDuration: 0.22, delay: 0,
                               options: [.allowUserInteraction, .beginFromCurrentState]) {
                    self.moveCard(card, toIndex: newIndex)
                }
            }

        case .ended, .cancelled:
            guard let snapshot = dragSnapshot, let card = draggingCard else { break }

            // Animate snapshot to card's final position
            let finalFrame = stackView.convert(card.frame, to: scrollView)
            UIView.animate(withDuration: 0.28, delay: 0,
                           usingSpringWithDamping: 0.82,
                           initialSpringVelocity: 0,
                           options: []) {
                snapshot.frame = finalFrame
                snapshot.transform = .identity
            } completion: { _ in
                snapshot.removeFromSuperview()
                UIView.animate(withDuration: 0.12) { card.alpha = 1.0 }
                self.dragSnapshot = nil
                self.draggingCard = nil
                self.saveCardOrder()
            }

        default:
            break
        }
    }

    /// Returns the index in `reorderableCards` where `card` should be placed,
    /// based on how many other reorderable cards have their centers above the snapshot.
    private func reorderTargetIndex(for snapshot: UIView, dragging card: CardView) -> Int {
        let snapshotMidY = snapshot.frame.midY  // in scrollView coordinate space
        var aboveCount = 0
        for other in reorderableCards {
            guard other != card else { continue }
            let otherFrame = stackView.convert(other.frame, to: scrollView)
            if otherFrame.midY < snapshotMidY { aboveCount += 1 }
        }
        return aboveCount
    }

    private func moveCard(_ card: CardView, toIndex newIndex: Int) {
        guard let currentIndex = reorderableCards.firstIndex(of: card),
              newIndex != currentIndex else { return }
        reorderableCards.remove(at: currentIndex)
        reorderableCards.insert(card, at: max(0, min(newIndex, reorderableCards.count)))
        rebuildStack()
    }

    private func rebuildStack() {
        let allOrdered: [CardView] = [headerCard, alertBannerCard] + reorderableCards
        for (i, card) in allOrdered.enumerated() {
            stackView.removeArrangedSubview(card)
            stackView.insertArrangedSubview(card, at: i)
        }
    }

    private func saveCardOrder() {
        let ids = reorderableCards.map { $0.cardID }
        UserDefaults.standard.set(ids, forKey: Self.cardOrderKey)
    }

    // MARK: - Location

    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000   // update every 1km
        locationManager.requestWhenInUseAuthorization()
        // Also start updating (simulator-friendly; we'll stop after first fix)
        locationManager.startUpdatingLocation()
    }

    private func fetchWeather(for location: CLLocation, isGPSLocation: Bool = false) {
        currentLocation = location
        isShowingGPSLocation = isGPSLocation
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Kick off geocode in parallel — don't block weather fetch
        Task {
            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let pm = placemarks.first {
                let name = pm.locality ?? pm.name ?? pm.administrativeArea ?? "My Location"
                WeatherDataSourceManager.shared.locationName = name
                await MainActor.run {
                    self.navigationItem.title = name
                }
            }
        }

        Task {
            await WeatherDataSourceManager.shared.fetchWeather(lat: lat, lon: lon,
                                                               updateWidget: isGPSLocation)
        }
    }

    /// Updates the "Current Location" search row with the user's real GPS fix.
    /// Called ONLY from CLLocationManagerDelegate — never from search selections.
    private func updateGPSLocationInSearch(_ location: CLLocation) {
        searchResultsVC.gpsLocation = location
        // Reverse geocode just for the display name in the search row
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self else { return }
            let name = placemarks?.first.flatMap {
                $0.locality ?? $0.name ?? $0.administrativeArea
            } ?? "Current Location"
            DispatchQueue.main.async {
                self.searchResultsVC.gpsLocationName = name
                self.searchResultsVC.tableView.reloadData()
            }
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataReady(_:)),
            name: WeatherDataSourceManager.weatherDataParseComplete,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataFailed(_:)),
            name: WeatherDataSourceManager.weatherDataParseFailed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: Notification.Name("settingsChanged"),
            object: nil
        )
    }

    @objc private func handleSettingsChanged() {
        guard let loc = currentLocation else { return }
        activityIndicator.startAnimating()
        fetchWeather(for: loc)
    }

    @objc private func handleDataReady(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let data = WeatherDataSourceManager.shared.lastData else { return }
            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            self.configureCards(with: data)
            // Show NOAA fallback info if needed
            if let obj = notification.object as? String, obj == "noaa_fallback" {
                self.showNOAAFallbackBanner()
            }
        }
    }

    @objc private func handleDataFailed(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            let message = (notification.object as? String) ?? "Unable to fetch weather data."
            self.showErrorAlert(message: message)
        }
    }

    private func setupAlertCard() {
        alertBannerCard.isHidden = true
        alertBannerCard.onTap = { [weak self] in
            self?.showAlertDetail()
        }
    }

    private func setupDailyCard() {
        dailyCard.onDayTapped = { [weak self] entry in
            guard let self = self,
                  let allHourly = WeatherDataSourceManager.shared.lastData?.hourly else { return }
            let vc = DailyDetailViewController(entry: entry, allHourly: allHourly)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func setupAISummaryCard() {
        aiSummaryCard.onRetry = { [weak self] in
            guard let data = WeatherDataSourceManager.shared.lastData else { return }
            self?.fetchAISummary(for: data)
        }
    }

    private func fetchAISummary(for data: UnifiedWeatherData) {
        // Show cached summary immediately — no loading spinner needed
        if let cached = AISummaryService.shared.cachedSummary(for: data) {
            aiSummaryCard.state = .loaded(cached)
            return
        }

        // No valid cache — show spinner and fetch
        aiSummaryCard.state = .loading
        Task { [weak self] in
            do {
                let summary = try await AISummaryService.shared.fetchSummary(for: data)
                await MainActor.run { self?.aiSummaryCard.state = .loaded(summary) }
            } catch {
                print("AI Summary failed: \(error.localizedDescription)")
                await MainActor.run { self?.aiSummaryCard.state = .error }
            }
        }
    }

    private func showAlertDetail() {
        guard let alerts = WeatherDataSourceManager.shared.lastData?.alerts, !alerts.isEmpty else { return }
        let vc = AlertDetailViewController(alerts: alerts)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func updateSourceLabel() {
        guard let label = sourceLabel.viewWithTag(99) as? UILabel else { return }
        label.text = WeatherDataSourceManager.shared.activeSource.name
    }

    private func configureCards(with data: UnifiedWeatherData) {
        updateSourceLabel()
        let todayDaily = data.daily.first { DateFormatHelper.isToday($0.time) } ?? data.daily.first
        headerCard.configure(with: data, todayDaily: todayDaily)
        alertBannerCard.configure(alerts: data.alerts)

        minutelyCard.configure(minutely: data.minutely)
        minutelyCard.isHidden = data.minutely.isEmpty

        hourlyCard.configure(hourly: data.hourly)
        dailyCard.configure(daily: data.daily)
        detailsCard.configure(with: data.current)
        windGustCard.configure(hourly: data.hourly)

        // Air quality — show card only when data is available
        if let aq = data.airQuality {
            airQualityCard.configure(with: aq)
            airQualityCard.isHidden = false
        } else {
            airQualityCard.isHidden = true
        }

        // Pollen — show card only when data is available
        if let pollen = data.pollen {
            pollenCard.configure(with: pollen)
            pollenCard.isHidden = false
        } else {
            pollenCard.isHidden = true
        }

        // Activity scores — always available (computed from existing data)
        activityScoresCard.configure(with: data)

        // AI daily brief — async fetch with cache
        fetchAISummary(for: data)

        scrollView.setContentOffset(.zero, animated: false)
    }

    // MARK: - Refresh

    @objc private func handleRefresh() {
        guard let loc = currentLocation else {
            refreshControl.endRefreshing()
            return
        }
        Task {
            await WeatherDataSourceManager.shared.fetchWeather(
                lat: loc.coordinate.latitude,
                lon: loc.coordinate.longitude,
                forceRefresh: true,
                updateWidget: isShowingGPSLocation
            )
        }
    }

    // MARK: - Error handling

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Unable to Load Weather",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let loc = self?.currentLocation else { return }
            self?.fetchWeather(for: loc)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showNOAAFallbackBanner() {
        let banner = UIAlertController(
            title: nil,
            message: "NOAA is US-only. Showing Tomorrow.io data for this location.",
            preferredStyle: .alert
        )
        banner.addAction(UIAlertAction(title: "OK", style: .default))
        present(banner, animated: true)
    }

    // MARK: - Banner Ad

    private func setupBannerAd() {
        let banner = GADBannerView(adSize: kGADAdSizeBanner)
        banner.adUnitID = "ca-app-pub-8795986379052808/6427921529"
        banner.rootViewController = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        additionalSafeAreaInsets.bottom = CGSizeFromGADAdSize(kGADAdSizeBanner).height
        banner.load(GADRequest())
        self.bannerView = banner
    }
}

// MARK: - CLLocationManagerDelegate

extension MainForecastViewController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            activityIndicator.stopAnimating()
            showErrorAlert(message: "Location access is required to show local weather. Enable it in Settings.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        // Stop continuous updates — just need a single fix
        manager.stopUpdatingLocation()
        // Update the "Current Location" search row with the real GPS fix (only from here)
        updateGPSLocationInSearch(loc)
        fetchWeather(for: loc, isGPSLocation: true)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        activityIndicator.stopAnimating()
    }
}

// MARK: - Search delegate

extension MainForecastViewController: SearchResultsDelegate {
    func didSelectLocation(_ location: CLLocation, name: String, saveToRecents: Bool) {
        searchController.isActive = false
        navigationItem.title = name
        WeatherDataSourceManager.shared.locationName = name
        activityIndicator.startAnimating()
        if saveToRecents {
            RecentSearchStore.shared.add(name: name, location: location)
        }
        fetchWeather(for: location)
    }
}

// MARK: - Search Results VC

protocol SearchResultsDelegate: AnyObject {
    func didSelectLocation(_ location: CLLocation, name: String, saveToRecents: Bool)
}

// MARK: - Recent search store

struct RecentSearch {
    let name: String
    let latitude: Double
    let longitude: Double
    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
}

final class RecentSearchStore {
    static let shared = RecentSearchStore()
    private init() {}

    private let key = "recentSearches_v1"
    private let maxCount = 5

    var searches: [RecentSearch] {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else { return [] }
        return arr.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let lat  = dict["lat"]  as? Double,
                  let lon  = dict["lon"]  as? Double else { return nil }
            return RecentSearch(name: name, latitude: lat, longitude: lon)
        }
    }

    func add(name: String, location: CLLocation) {
        var current = searches.filter { $0.name != name } // deduplicate
        current.insert(RecentSearch(name: name,
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude), at: 0)
        let trimmed = Array(current.prefix(maxCount))
        UserDefaults.standard.set(trimmed.map { ["name": $0.name, "lat": $0.latitude, "lon": $0.longitude] },
                                  forKey: key)
    }

    func remove(at index: Int) {
        var current = searches
        guard index < current.count else { return }
        current.remove(at: index)
        UserDefaults.standard.set(current.map { ["name": $0.name, "lat": $0.latitude, "lon": $0.longitude] },
                                  forKey: key)
    }
}

// MARK: - Search results view controller

class SearchResultsViewController: UITableViewController, UISearchResultsUpdating {

    weak var delegate: SearchResultsDelegate?
    private var results: [MKMapItem] = []
    private var isSearching = false

    var gpsLocation: CLLocation?
    var gpsLocationName: String = "Current Location"

    private enum Section: Int, CaseIterable {
        case currentLocation = 0
        case recents         = 1
        case searchResults   = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        isSearching = !query.isEmpty

        if query.isEmpty {
            results = []
            tableView.reloadData()
            return
        }

        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = query
        req.resultTypes = .address
        MKLocalSearch(request: req).start { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.results = response?.mapItems ?? []
                self?.tableView.reloadData()
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .currentLocation: return gpsLocation != nil ? 1 : 0
        case .recents:         return isSearching ? 0 : RecentSearchStore.shared.searches.count
        case .searchResults:   return isSearching ? results.count : 0
        default:               return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .recents:
            return (!isSearching && !RecentSearchStore.shared.searches.isEmpty) ? "Recent" : nil
        case .searchResults:
            return (isSearching && !results.isEmpty) ? "Results" : nil
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()

        switch Section(rawValue: indexPath.section) {
        case .currentLocation:
            config.text = gpsLocationName
            config.secondaryText = "Your current location"
            config.image = UIImage(systemName: "location.fill")
            config.imageProperties.tintColor = .systemBlue

        case .recents:
            let recent = RecentSearchStore.shared.searches[indexPath.row]
            config.text = recent.name
            config.image = UIImage(systemName: "clock.arrow.circlepath")
            config.imageProperties.tintColor = .secondaryLabel

        case .searchResults:
            let item = results[indexPath.row]
            config.text = item.name
            config.secondaryText = [item.placemark.locality,
                                    item.placemark.administrativeArea,
                                    item.placemark.country]
                .compactMap { $0 }.joined(separator: ", ")
            config.image = UIImage(systemName: "mappin.circle.fill")
            config.imageProperties.tintColor = .secondaryLabel

        default: break
        }

        cell.contentConfiguration = config
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .currentLocation:
            guard let loc = gpsLocation else { return }
            delegate?.didSelectLocation(loc, name: gpsLocationName, saveToRecents: false)

        case .recents:
            let recent = RecentSearchStore.shared.searches[indexPath.row]
            delegate?.didSelectLocation(recent.location, name: recent.name, saveToRecents: false)

        case .searchResults:
            let item = results[indexPath.row]
            guard let loc = item.placemark.location else { return }
            let name = item.name ?? item.placemark.locality ?? "Unknown"
            delegate?.didSelectLocation(loc, name: name, saveToRecents: true)

        default: break
        }
    }

    // Swipe to delete recent searches
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        Section(rawValue: indexPath.section) == .recents
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                             forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, Section(rawValue: indexPath.section) == .recents {
            RecentSearchStore.shared.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

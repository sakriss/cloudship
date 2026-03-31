//
//  SettingsViewController.swift
//  Cloudship
//
//  Programmatic UITableViewController for app settings:
//  data source selection, units, appearance, and about.
//

import UIKit
import CoreLocation
import MessageUI

class SettingsViewController: UITableViewController {

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case dataSource = 0
        case units
        case appearance
        case notifications
        case subscription
        case about
    }

    // MARK: - Cached controls

    private lazy var rainAlertsSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = UserDefaults.standard.bool(forKey: "RainAlertsEnabled")
        sw.addTarget(self, action: #selector(rainAlertsChanged(_:)), for: .valueChanged)
        return sw
    }()

    private lazy var liveActivitySwitch: UISwitch = {
        let sw = UISwitch()
        if #available(iOS 16.1, *) {
            sw.isOn = UserDefaults.standard.bool(forKey: PrecipitationLiveActivityManager.enabledKey)
        } else {
            sw.isOn = false
            sw.isEnabled = false
        }
        sw.addTarget(self, action: #selector(liveActivityChanged(_:)), for: .valueChanged)
        return sw
    }()

    private lazy var morningBriefSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = UserDefaults.standard.bool(forKey: "MorningBriefEnabled")
        sw.addTarget(self, action: #selector(morningBriefChanged(_:)), for: .valueChanged)
        return sw
    }()

    private lazy var eveningBriefSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = UserDefaults.standard.bool(forKey: "EveningBriefEnabled")
        sw.addTarget(self, action: #selector(eveningBriefChanged(_:)), for: .valueChanged)
        return sw
    }()

    private lazy var sourceControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["NOAA", "O-Meteo", "Pirate", "Apple", "Tmrw", "Accu"])
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11)], for: .normal)
        let active = WeatherDataSourceManager.shared.activeSource
        if active is NOAADataSource                { sc.selectedSegmentIndex = 0 }
        else if active is OpenMeteoDataSource      { sc.selectedSegmentIndex = 1 }
        else if active is PirateWeatherDataSource  { sc.selectedSegmentIndex = 2 }
        else if active is AppleWeatherDataSource   { sc.selectedSegmentIndex = 3 }
        else if active is TomorrowIODataSource     { sc.selectedSegmentIndex = 4 }
        else if active is AccuWeatherDataSource    { sc.selectedSegmentIndex = 5 }
        else                                        { sc.selectedSegmentIndex = 0 }
        sc.addTarget(self, action: #selector(sourceChanged(_:)), for: .valueChanged)
        return sc
    }()

    private lazy var nearestStationSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = UserDefaults.standard.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey)
        sw.addTarget(self, action: #selector(nearestStationChanged(_:)), for: .valueChanged)
        return sw
    }()

    private lazy var consensusModeSwitch: UISwitch = {
        let sw = UISwitch()
        sw.isOn = UserDefaults.standard.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        sw.addTarget(self, action: #selector(consensusModeChanged(_:)), for: .valueChanged)
        return sw
    }()

    private lazy var unitsControl: UISegmentedControl = {
        let isMetric = TemperatureFormatter.isMetric
        let sc = UISegmentedControl(items: ["°F (Imperial)", "°C (Metric)"])
        sc.selectedSegmentIndex = isMetric ? 1 : 0
        sc.addTarget(self, action: #selector(unitsChanged(_:)), for: .valueChanged)
        return sc
    }()

    private lazy var appearanceControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["System", "Light", "Dark", "Auto"])
        sc.selectedSegmentIndex = savedAppearanceIndex()
        sc.addTarget(self, action: #selector(appearanceChanged(_:)), for: .valueChanged)
        return sc
    }()

    // MARK: - Reload debouncing

    private var pendingReloadWorkItem: DispatchWorkItem?
    private var pendingSettingsChangedWorkItem: DispatchWorkItem?

    private func debounceReloadSections(_ sections: IndexSet, delay: TimeInterval = 0.15) {
        pendingReloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.tableView.reloadSections(sections, with: .none)
        }
        pendingReloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func postSettingsChangedDebounced(delay: TimeInterval = 0.2) {
        pendingSettingsChangedWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(name: Notification.Name("settingsChanged"), object: nil)
        }
        pendingSettingsChangedWorkItem = work
        if tableView.isDragging || tableView.isDecelerating {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
        }
    }

    // MARK: - Notification row helpers

    /// Dynamic row count for the notifications section.
    /// Rows: 0 = Rain Alerts, 1 = Manage Locations,
    ///        2 = Live Activity (premium, iOS 16.1+),
    ///        3 = Morning Brief toggle, 4 = Morning Brief Time (if enabled),
    ///        next = Evening Brief toggle, next = Evening Brief Time (if enabled)
    private var notificationRowCount: Int {
        var count = 5 // Rain Alerts, Manage Locations, Live Activity, Morning Brief, Evening Brief
        if UserDefaults.standard.bool(forKey: "MorningBriefEnabled") { count += 1 }
        if UserDefaults.standard.bool(forKey: "EveningBriefEnabled") { count += 1 }
        return count
    }

    /// Returns the logical role of a row in the notifications section accounting for conditional time picker rows.
    private enum NotificationRow {
        case rainAlerts
        case manageLocations
        case liveActivity
        case morningBriefToggle
        case morningBriefTime
        case eveningBriefToggle
        case eveningBriefTime
    }

    private func notificationRow(for index: Int) -> NotificationRow {
        let morningEnabled = UserDefaults.standard.bool(forKey: "MorningBriefEnabled")
        switch index {
        case 0: return .rainAlerts
        case 1: return .manageLocations
        case 2: return .liveActivity
        case 3: return .morningBriefToggle
        case 4 where morningEnabled: return .morningBriefTime
        case 4: return .eveningBriefToggle
        case 5 where morningEnabled: return .eveningBriefToggle
        case 5: return .eveningBriefTime
        case 6: return .eveningBriefTime
        default: return .rainAlerts
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(ControlCell.self, forCellReuseIdentifier: "ControlCell_source")
        tableView.register(ControlCell.self, forCellReuseIdentifier: "ControlCell_units")
        tableView.register(ControlCell.self, forCellReuseIdentifier: "ControlCell_appearance")
        tableView.register(CardTintPickerCell.self, forCellReuseIdentifier: "CardTintPickerCell")

        NotificationCenter.default.addObserver(self,
            selector: #selector(nearestStationResolved),
            name: Notification.Name("nearestStationResolved"),
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(reloadNearestStationRow),
            name: Notification.Name("settingsChanged"),
            object: nil)
        NotificationCenter.default.addObserver(self,
            selector: #selector(premiumStatusChanged),
            name: SubscriptionManager.premiumStatusChanged,
            object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSourceControlState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UITableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .dataSource:     return 3   // source picker + nearest station + consensus mode
        case .units:          return 1
        case .appearance:     return 2
        case .notifications:  return notificationRowCount
        case .subscription:   return 1
        case .about:          return 5
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .dataSource:     return "Data Source"
        case .units:          return "Units"
        case .appearance:     return "Appearance"
        case .notifications:  return "Notifications"
        case .subscription:   return "Subscription"
        case .about:          return "About"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if Section(rawValue: section) == .dataSource {
            return "NOAA: US-only. Open-Meteo, Pirate Weather, Apple Weather: global.\nTomorrow.io and AccuWeather require Premium.\nNearest Station and Consensus Mode override the source selector above."
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {

        case .dataSource:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCell_source", for: indexPath) as! ControlCell
                cell.configure(label: "Weather Source", control: sourceControl)
                return cell

            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                var config = cell.defaultContentConfiguration()
                config.text = "Nearest Active Station"
                config.secondaryText = nearestStationSubtitle
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = nearestStationSwitch
                cell.selectionStyle = .none
                return cell

            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                var config = cell.defaultContentConfiguration()
                // "Consensus Mode" with a star badge for Premium
                let title = NSMutableAttributedString(string: "Consensus Mode  ")
                let star  = NSAttributedString(
                    string: "\u{2605}",
                    attributes: [.foregroundColor: UIColor.systemYellow,
                                 .font: UIFont.systemFont(ofSize: 14)]
                )
                title.append(star)
                config.attributedText = title
                config.secondaryText = "Weighted average of all sources"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = consensusModeSwitch
                cell.selectionStyle = .none
                return cell
            }

        case .units:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCell_units", for: indexPath) as! ControlCell
            cell.configure(label: "Temperature", control: unitsControl)
            return cell

        case .appearance:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCell_appearance", for: indexPath) as! ControlCell
                cell.configure(label: "Theme", control: appearanceControl)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CardTintPickerCell", for: indexPath) as! CardTintPickerCell
                cell.onSelect = { [weak self] _ in
                    // Notify forecast to re-apply tints without a full refetch
                    NotificationCenter.default.post(name: Notification.Name("cardTintChanged"), object: nil)
                }
                return cell
            }

        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            cell.accessoryView = nil
            cell.accessoryType = .none
            cell.selectionStyle = .none

            switch notificationRow(for: indexPath.row) {
            case .rainAlerts:
                config.text = "Rain Alerts"
                config.secondaryText = "Get notified when rain is starting or stopping"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = rainAlertsSwitch

            case .manageLocations:
                config.text = "Manage Locations"
                config.secondaryText = "Set up rain alerts for specific locations"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default

            case .liveActivity:
                config.text = "Precipitation Live Activity"
                config.secondaryText = "Real-time rain tracking in Dynamic Island"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                if #available(iOS 16.1, *) {
                    cell.accessoryView = liveActivitySwitch
                } else {
                    var unavailConfig = cell.defaultContentConfiguration()
                    unavailConfig.text = "Precipitation Live Activity"
                    unavailConfig.secondaryText = "Requires iOS 16.1+"
                    unavailConfig.secondaryTextProperties.color = .tertiaryLabel
                    unavailConfig.secondaryTextProperties.font = .systemFont(ofSize: 12)
                    cell.contentConfiguration = unavailConfig
                }

            case .morningBriefToggle:
                config.text = "Morning Brief"
                config.secondaryText = "Daily weather summary"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = morningBriefSwitch

            case .morningBriefTime:
                config.text = "Morning Brief Time"
                let hour = UserDefaults.standard.object(forKey: "MorningBriefHour") as? Int ?? 7
                config.secondaryText = formattedHour(hour)
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default

            case .eveningBriefToggle:
                config.text = "Evening Brief"
                config.secondaryText = "Tonight and tomorrow outlook"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = eveningBriefSwitch

            case .eveningBriefTime:
                config.text = "Evening Brief Time"
                let hour = UserDefaults.standard.object(forKey: "EveningBriefHour") as? Int ?? 20
                config.secondaryText = formattedHour(hour)
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
            return cell

        case .subscription:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            if SubscriptionManager.shared.isPremiumCached {
                config.text = "Cloudship Premium"
                config.image = UIImage(systemName: "checkmark.seal.fill")
                config.imageProperties.tintColor = .systemBlue
                cell.accessoryType = .disclosureIndicator
            } else {
                config.text = "Upgrade to Premium"
                config.image = UIImage(systemName: "star.fill")
                config.imageProperties.tintColor = .systemYellow
                cell.accessoryType = .disclosureIndicator
            }
            cell.contentConfiguration = config
            return cell

        case .about:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            switch indexPath.row {
            case 0:
                config.text = "Version"
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
                let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
                #if DEBUG
                let demoActive = UserDefaults.standard.bool(forKey: "DemoModeEnabled")
                config.secondaryText = demoActive
                    ? "\(version) (\(build)) — DEMO"
                    : "\(version) (\(build))"
                #else
                config.secondaryText = "\(version) (\(build))"
                #endif
                cell.accessoryType = .none
                cell.selectionStyle = .none
            case 1:
                config.text = "Send Feedback"
                cell.accessoryType = .disclosureIndicator
            case 2:
                config.text = "Rate on App Store"
                cell.accessoryType = .disclosureIndicator
            case 3:
                config.text = "Privacy Policy"
                cell.accessoryType = .disclosureIndicator
            case 4:
                config.text = "Terms & Conditions"
                cell.accessoryType = .disclosureIndicator
            default:
                break
            }
            cell.contentConfiguration = config
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if Section(rawValue: indexPath.section) == .notifications {
            let role = notificationRow(for: indexPath.row)
            switch role {
            case .manageLocations:
                let vc = ManageLocationsViewController(style: .grouped)
                navigationController?.pushViewController(vc, animated: true)
            case .morningBriefTime:
                presentTimePicker(forKey: "MorningBriefHour", defaultHour: 7, title: "Morning Brief Time")
            case .eveningBriefTime:
                presentTimePicker(forKey: "EveningBriefHour", defaultHour: 20, title: "Evening Brief Time")
            default:
                break
            }
            return
        }

        if Section(rawValue: indexPath.section) == .subscription {
            if SubscriptionManager.shared.isPremiumCached {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } else {
                presentPaywall()
            }
            return
        }

        guard Section(rawValue: indexPath.section) == .about else { return }
        switch indexPath.row {
        case 0:
            #if DEBUG
            handleVersionTap()
            #endif
        case 1: sendFeedbackEmail()
        case 2: openAppStore()
        case 3: showLegalText(title: "Privacy Policy", text: Self.privacyPolicyText)
        case 4: showLegalText(title: "Terms & Conditions", text: Self.termsAndConditionsText)
        default: break
        }
    }

    // MARK: - Demo Mode (DEBUG)

    #if DEBUG
    private var versionTapCount = 0
    private var lastVersionTap: Date = .distantPast
    #endif

    // MARK: - Actions

    @objc private func sourceChanged(_ sender: UISegmentedControl) {
        let premiumIndices: Set<Int> = [4, 5]  // Tomorrow.io, AccuWeather
        if premiumIndices.contains(sender.selectedSegmentIndex)
            && !SubscriptionManager.shared.isPremiumCached {
            // Revert to current selection
            let active = WeatherDataSourceManager.shared.activeSource
            if active is NOAADataSource                { sender.selectedSegmentIndex = 0 }
            else if active is OpenMeteoDataSource      { sender.selectedSegmentIndex = 1 }
            else if active is PirateWeatherDataSource  { sender.selectedSegmentIndex = 2 }
            else if active is AppleWeatherDataSource   { sender.selectedSegmentIndex = 3 }
            else if active is TomorrowIODataSource     { sender.selectedSegmentIndex = 4 }
            else if active is AccuWeatherDataSource    { sender.selectedSegmentIndex = 5 }
            else                                        { sender.selectedSegmentIndex = 0 }
            presentPaywall()
            return
        }

        switch sender.selectedSegmentIndex {
        case 0:  WeatherDataSourceManager.shared.activeSource = NOAADataSource()
        case 1:  WeatherDataSourceManager.shared.activeSource = OpenMeteoDataSource()
        case 2:  WeatherDataSourceManager.shared.activeSource = PirateWeatherDataSource()
        case 3:  WeatherDataSourceManager.shared.activeSource = AppleWeatherDataSource()
        case 4:  WeatherDataSourceManager.shared.activeSource = TomorrowIODataSource()
        case 5:  WeatherDataSourceManager.shared.activeSource = AccuWeatherDataSource()
        default: WeatherDataSourceManager.shared.activeSource = NOAADataSource()
        }
        triggerRefetch()
    }

    // MARK: - Nearest Station

    @objc private func nearestStationChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        defaults.set(sender.isOn, forKey: WeatherDataSourceManager.nearestStationEnabledKey)

        if sender.isOn {
            // Mutual exclusion: turn off consensus mode
            if consensusModeSwitch.isOn {
                consensusModeSwitch.setOn(false, animated: true)
                defaults.set(false, forKey: WeatherDataSourceManager.consensusModeEnabledKey)
            }
            // Clear any stale station cache so the next fetch triggers a fresh lookup
            WeatherDataSourceManager.shared.clearNearestStationCache()
        }
        updateSourceControlState()
        triggerRefetch()
    }

    @objc private func nearestStationResolved() {
        let indexPath = IndexPath(row: 1, section: Section.dataSource.rawValue)
        if let visible = tableView.indexPathsForVisibleRows, visible.contains(indexPath) {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    /// Updates the nearest-station cell's subtitle in place (no row reload).
    /// Called when settingsChanged fires so the km/mi label tracks the unit preference.
    @objc private func reloadNearestStationRow() {
        guard UserDefaults.standard.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey) else { return }
        let indexPath = IndexPath(row: 1, section: Section.dataSource.rawValue)
        if let visible = tableView.indexPathsForVisibleRows, visible.contains(indexPath) {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    private var nearestStationSubtitle: String {
        guard UserDefaults.standard.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey) else {
            return "Use the source with the nearest active weather station"
        }
        let sourceID = UserDefaults.standard.string(forKey: "NearestStationLastSourceID")
        let km = UserDefaults.standard.double(forKey: "NearestStationLastDistanceKm")
        if sourceID == WeatherSourceID.noaa.rawValue, km > 0 {
            if TemperatureFormatter.isMetric {
                return String(format: "NOAA · %.1f km away", km)
            } else {
                return String(format: "NOAA · %.1f mi away", km * 0.621371)
            }
        } else if sourceID == WeatherSourceID.openMeteo.rawValue {
            return "Open-Meteo (global model)"
        }
        return "Resolving nearest station…"
    }

    // MARK: - Consensus Mode

    @objc private func consensusModeChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard

        if sender.isOn {
            guard SubscriptionManager.shared.isPremiumCached else {
                sender.setOn(false, animated: true)
                presentPaywall()
                return
            }
            // Mutual exclusion: turn off nearest station
            if nearestStationSwitch.isOn {
                nearestStationSwitch.setOn(false, animated: true)
                defaults.set(false, forKey: WeatherDataSourceManager.nearestStationEnabledKey)
            }
        }

        defaults.set(sender.isOn, forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        updateSourceControlState()
        triggerRefetch()
    }

    @objc private func premiumStatusChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let sections = IndexSet([Section.dataSource.rawValue, Section.subscription.rawValue])
            self.debounceReloadSections(sections)
        }
    }

    /// Dims/enables the source segmented control based on whether an override mode is active.
    private func updateSourceControlState() {
        let overrideActive = UserDefaults.standard.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey)
                          || UserDefaults.standard.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        sourceControl.isEnabled = !overrideActive
        sourceControl.alpha = overrideActive ? 0.40 : 1.0
    }

    #if DEBUG
    private func handleVersionTap() {
        let now = Date()
        // Reset counter if more than 2 seconds since last tap
        if now.timeIntervalSince(lastVersionTap) > 2.0 {
            versionTapCount = 0
        }
        lastVersionTap = now
        versionTapCount += 1

        if versionTapCount >= 5 {
            versionTapCount = 0
            let isEnabled = SubscriptionManager.shared.demoModeEnabled
            SubscriptionManager.shared.demoModeEnabled = !isEnabled

            let message = !isEnabled ? "Demo Mode Enabled" : "Demo Mode Disabled"
            let toast = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            present(toast, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                toast.dismiss(animated: true) {
                    // Reload after the toast is fully dismissed to avoid
                    // conflicting with the reloadSections triggered by
                    // the premiumStatusChanged notification.
                    self?.tableView.reloadData()
                }
            }
        }
    }
    #endif

    private func presentPaywall() {
        let presentBlock = { [weak self] in
            guard let self else { return }
            let paywall = PaywallViewController()
            paywall.modalPresentationStyle = .pageSheet
            if let sheet = paywall.sheetPresentationController {
                sheet.detents = [.large()]
            }
            self.present(paywall, animated: true)
        }
        if tableView.isDragging || tableView.isDecelerating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: presentBlock)
        } else {
            presentBlock()
        }
    }

    @objc private func unitsChanged(_ sender: UISegmentedControl) {
        let newUnits = sender.selectedSegmentIndex == 0 ? "imperial" : "metric"
        UserDefaults.standard.set(newUnits, forKey: "Units")
        triggerRefetch()
    }

    @objc private func rainAlertsChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "RainAlertsEnabled")
        if sender.isOn {
            BackgroundTaskManager.shared.scheduleNextRefresh()
        }
        postSettingsChangedDebounced()
    }

    @objc private func liveActivityChanged(_ sender: UISwitch) {
        guard SubscriptionManager.shared.isPremiumCached else {
            sender.setOn(false, animated: true)
            presentPaywall()
            return
        }
        if #available(iOS 16.1, *) {
            UserDefaults.standard.set(sender.isOn, forKey: PrecipitationLiveActivityManager.enabledKey)
            if !sender.isOn {
                PrecipitationLiveActivityManager.shared.end()
            }
        }
    }

    @objc private func morningBriefChanged(_ sender: UISwitch) {
        guard SubscriptionManager.shared.isPremiumCached else {
            sender.setOn(false, animated: true)
            presentPaywall()
            return
        }
        let wasEnabled = UserDefaults.standard.bool(forKey: "MorningBriefEnabled")
        UserDefaults.standard.set(sender.isOn, forKey: "MorningBriefEnabled")
        if sender.isOn {
            PrecipitationNotificationService.shared.scheduleMorningBrief()
        } else {
            PrecipitationNotificationService.shared.cancelBrief(identifier: "morningBrief")
        }
        // Insert or delete only the time-picker row; leave the toggle cell untouched
        // so the UISwitch isn't destroyed mid-touch.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.beginUpdates()
            let timeRow = IndexPath(row: 4, section: Section.notifications.rawValue)
            if sender.isOn && !wasEnabled {
                self.tableView.insertRows(at: [timeRow], with: .automatic)
            } else if !sender.isOn && wasEnabled {
                self.tableView.deleteRows(at: [timeRow], with: .automatic)
            }
            self.tableView.endUpdates()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let toggleIndex = IndexPath(row: 3, section: Section.notifications.rawValue)
                if let visible = self.tableView.indexPathsForVisibleRows, visible.contains(toggleIndex) {
                    self.tableView.reloadRows(at: [toggleIndex], with: .none)
                }
            }
        }
    }

    @objc private func eveningBriefChanged(_ sender: UISwitch) {
        guard SubscriptionManager.shared.isPremiumCached else {
            sender.setOn(false, animated: true)
            presentPaywall()
            return
        }
        let wasEnabled = UserDefaults.standard.bool(forKey: "EveningBriefEnabled")
        UserDefaults.standard.set(sender.isOn, forKey: "EveningBriefEnabled")
        if sender.isOn {
            PrecipitationNotificationService.shared.scheduleEveningBrief()
        } else {
            PrecipitationNotificationService.shared.cancelBrief(identifier: "eveningBrief")
        }
        // Insert or delete only the time-picker row; leave the toggle cell untouched.
        let morningEnabled = UserDefaults.standard.bool(forKey: "MorningBriefEnabled")
        let timeRowIndex = morningEnabled ? 6 : 5
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.beginUpdates()
            let timeRow = IndexPath(row: timeRowIndex, section: Section.notifications.rawValue)
            if sender.isOn && !wasEnabled {
                self.tableView.insertRows(at: [timeRow], with: .automatic)
            } else if !sender.isOn && wasEnabled {
                self.tableView.deleteRows(at: [timeRow], with: .automatic)
            }
            self.tableView.endUpdates()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let toggleIndex = IndexPath(row: morningEnabled ? 5 : 4, section: Section.notifications.rawValue)
                if let visible = self.tableView.indexPathsForVisibleRows, visible.contains(toggleIndex) {
                    self.tableView.reloadRows(at: [toggleIndex], with: .none)
                }
            }
        }
    }

    private func presentTimePicker(forKey key: String, defaultHour: Int, title: String) {
        let currentHour = UserDefaults.standard.object(forKey: key) as? Int ?? defaultHour

        let alert = UIAlertController(title: title, message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.frame = CGRect(x: 0, y: 40, width: alert.view.bounds.width, height: 200)
        datePicker.autoresizingMask = [.flexibleWidth]

        // Set initial time
        var components = DateComponents()
        components.hour = currentHour
        components.minute = 0
        if let date = Calendar.current.date(from: components) {
            datePicker.date = date
        }

        alert.view.addSubview(datePicker)

        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let selectedHour = Calendar.current.component(.hour, from: datePicker.date)
            UserDefaults.standard.set(selectedHour, forKey: key)
            // Re-schedule with new time
            if key == "MorningBriefHour" {
                PrecipitationNotificationService.shared.scheduleMorningBrief()
            } else {
                PrecipitationNotificationService.shared.scheduleEveningBrief()
            }
            self?.debounceReloadSections(IndexSet(integer: Section.notifications.rawValue))
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func formattedHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        guard let date = Calendar.current.date(from: components) else { return "\(hour):00" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    @objc private func appearanceChanged(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "AppearanceIndex")
        let styles: [UIUserInterfaceStyle] = [.unspecified, .light, .dark, .unspecified]
        let idx = min(sender.selectedSegmentIndex, styles.count - 1)
        view.window?.overrideUserInterfaceStyle = styles[idx]
        // Notify forecast to update weather-reactive theme
        postSettingsChangedDebounced()
    }

    private func triggerRefetch() {
        postSettingsChangedDebounced()
    }

    // MARK: - Helpers

    private func savedAppearanceIndex() -> Int {
        UserDefaults.standard.integer(forKey: "AppearanceIndex")   // defaults to 0 = System
    }

    private func sendFeedbackEmail() {
        guard MFMailComposeViewController.canSendMail() else { return }
        let mc = MFMailComposeViewController()
        mc.setToRecipients(["feedback@cloudshipapp.com"])
        mc.setSubject("Cloudship Feedback")
        mc.mailComposeDelegate = self
        present(mc, animated: true)
    }

    private func openAppStore() {
        // Replace with actual App Store ID when published
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id000000000") {
            UIApplication.shared.open(url)
        }
    }

    private func showLegalText(title: String, text: String) {
        let vc = LegalTextViewController(title: title, text: text)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Legal text

    static let privacyPolicyText = """
    HappyGiraffe built the Cloudship Weather app as a Free appw ith optional Premium feature. This SERVICE is provided by HappyGiraffe at no cost and is intended for use as is.

    This page is used to inform visitors regarding my policies with the collection, use, and disclosure of Personal Information if anyone decided to use my Service.

    If you choose to use my Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that I collect is used for providing and improving the Service. I will not use or share your information with anyone except as described in this Privacy Policy.

    The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible at Cloudship Weather unless otherwise defined in this Privacy Policy.

    Information Collection and Use

    For a better experience, while using our Service, I may require you to provide us with certain personally identifiable information, including but not limited to Location(GPS). The information that I request will be retained on your device and is not collected by me in any way.

    The app does use third party services that may collect information used to identify you.
    
    Premium Subscriptions and Payments

    Cloudship Weather offers a paid Premium version. By subscribing to the Premium Service, you agree to the pricing and payment terms as updated from time to time.

    * Payment Processing: All payments are handled securely through the respective App Store. Please refer to the Apple or Google Privacy Policies for details on how your payment information is managed.

    * Subscription Management: Users can manage or cancel their subscriptions through their device account settings.

    Log Data

    I want to inform you that whenever you use my Service, in a case of an error in the app I collect data and information (through third party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol ("IP") address, device name, operating system version, the configuration of the app when utilizing my Service, the time and date of your use of the Service, and other statistics.

    Cookies

    Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.

    This Service does not use these "cookies" explicitly. However, the app may use third party code and libraries that use "cookies" to collect information and improve their services. You have the option to either accept or refuse these cookies and know when a cookie is being sent to your device. If you choose to refuse our cookies, you may not be able to use some portions of this Service.

    Service Providers

    I may employ third-party companies and individuals due to the following reasons:
    \u{2022} To facilitate our Service;
    \u{2022} To provide the Service on our behalf;
    \u{2022} To perform Service-related services; or
    \u{2022} To assist us in analyzing how our Service is used.

    I want to inform users of this Service that these third parties have access to your Personal Information. The reason is to perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for any other purpose.

    Security

    I value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and I cannot guarantee its absolute security.

    Links to Other Sites

    This Service may contain links to other sites. If you click on a third-party link, you will be directed to that site. Note that these external sites are not operated by me. Therefore, I strongly advise you to review the Privacy Policy of these websites. I have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.

    Children's Privacy

    These Services do not address anyone under the age of 13. I do not knowingly collect personally identifiable information from children under 13. In the case I discover that a child under 13 has provided me with personal information, I immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact me so that I will be able to do necessary actions.

    Changes to This Privacy Policy

    I may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. I will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted on this page.

    Contact Us

    If you have any questions or suggestions about my Privacy Policy, do not hesitate to contact me.
    """

    static let termsAndConditionsText = """
    By downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You're not allowed to copy, or modify the app, any part of the app, or our trademarks in any way. You're not allowed to attempt to extract the source code of the app, and you also shouldn't try to translate the app into other languages, or make derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to HappyGiraffe.

    HappyGiraffe is committed to ensuring that the app is as useful and efficient as possible. For that reason, we reserve the right to make changes to the app or to charge for its services, at any time and for any reason.

    * Free vs. Premium: We offer both free and paid (Premium) versions of the app.

    * Clear Billing: We will never charge you for the app or its services without making it very clear to you exactly what you're paying for.

    * Subscription Management: All Premium subscriptions are handled via the Apple App Store. You are responsible for managing your subscriptions and cancellations through your Apple ID settings.

    The Cloudship Weather app stores and processes personal data that you have provided to us, in order to provide my Service. It's your responsibility to keep your phone and access to the app secure. We therefore recommend that you do not jailbreak or root your phone, which is the process of removing software restrictions and limitations imposed by the official operating system of your device. It could make your phone vulnerable to malware/viruses/malicious programs, compromise your phone's security features and it could mean that the Cloudship Weather app won't work properly or at all.

    You should be aware that there are certain things that HappyGiraffe will not take responsibility for. Certain functions of the app will require the app to have an active internet connection. The connection can be Wi-Fi, or provided by your mobile network provider, but HappyGiraffe cannot take responsibility for the app not working at full functionality if you don't have access to Wi-Fi, and you don't have any of your data allowance left.

    If you're using the app outside of an area with Wi-Fi, you should remember that your terms of the agreement with your mobile network provider will still apply. As a result, you may be charged by your mobile provider for the cost of data for the duration of the connection while accessing the app, or other third party charges. In using the app, you're accepting responsibility for any such charges, including roaming data charges if you use the app outside of your home territory (i.e. region or country) without turning off data roaming. If you are not the bill payer for the device on which you're using the app, please be aware that we assume that you have received permission from the bill payer for using the app.

    Along the same lines, HappyGiraffe cannot always take responsibility for the way you use the app i.e. You need to make sure that your device stays charged – if it runs out of battery and you can't turn it on to avail the Service, HappyGiraffe cannot accept responsibility.
    
    Limitation of Liability and Weather Data

    While we endeavour to ensure that the app is updated and correct at all times, we rely on third-party weather data providers to supply information. Cloudship Weather is for informational purposes only.

    * HappyGiraffe accepts no liability for any loss, direct or indirect, you experience as a result of relying wholly on the weather forecasts or alerts provided by the app.

    * We do not guarantee the absolute accuracy of weather data and advise users to exercise common sense during severe weather events.

    With respect to HappyGiraffe's responsibility for your use of the app, when you're using the app, it's important to bear in mind that although we endeavour to ensure that it is updated and correct at all times, we do rely on third parties to provide information to us so that we can make it available to you. HappyGiraffe accepts no liability for any loss, direct or indirect, you experience as a result of relying wholly on this functionality of the app.

    At some point, we may wish to update the app. The app is currently available on iOS – the requirements for system (and for any additional systems we decide to extend the availability of the app to) may change, and you'll need to download the updates if you want to keep using the app. HappyGiraffe does not promise that it will always update the app so that it is relevant to you and/or works with the iOS version that you have installed on your device. However, you promise to always accept updates to the application when offered to you. We may also wish to stop providing the app, and may terminate use of it at any time without giving notice of termination to you. Unless we tell you otherwise, upon any termination, (a) the rights and licenses granted to you in these terms will end; (b) you must stop using the app, and (if needed) delete it from your device.

    Changes to This Terms and Conditions

    I may update our Terms and Conditions from time to time. Thus, you are advised to review this page periodically for any changes. I will notify you of any changes by posting the new Terms and Conditions on this page. These changes are effective immediately after they are posted on this page.

    Contact Us

    If you have any questions or suggestions about my Terms and Conditions, do not hesitate to contact me.
    """
}

// MARK: - MFMailComposeViewControllerDelegate

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Card tint picker cell

private class CardTintPickerCell: UITableViewCell {

    var onSelect: ((CardTintStyle) -> Void)?

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.text = "Card Color"
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var swatchStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var swatchButtons: [UIButton] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(nameLabel)
        contentView.addSubview(swatchStack)

        for tint in CardTintStyle.allCases {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = tint.swatchColor
            btn.layer.cornerRadius = 15
            btn.layer.borderWidth = 2.5
            btn.layer.borderColor = UIColor.clear.cgColor
            btn.translatesAutoresizingMaskIntoConstraints = false

            let action = UIAction { [weak self] _ in
                UserDefaults.standard.set(tint.rawValue, forKey: "CardTintStyle")
                self?.refresh()
                self?.onSelect?(tint)
            }
            btn.addAction(action, for: .touchUpInside)

            swatchStack.addArrangedSubview(btn)
            swatchButtons.append(btn)

            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 30),
                btn.heightAnchor.constraint(equalToConstant: 30)
            ])
        }

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            swatchStack.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            swatchStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            swatchStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func refresh() {
        let selected = CardTintStyle.saved
        for (i, btn) in swatchButtons.enumerated() {
            let isSelected = i == selected.rawValue
            UIView.animate(withDuration: 0.15) {
                btn.layer.borderColor = isSelected ? UIColor.label.cgColor : UIColor.clear.cgColor
                btn.transform = isSelected ? CGAffineTransform(scaleX: 1.20, y: 1.20) : .identity
            }
        }
    }
}

// MARK: - Legal text viewer

private class LegalTextViewController: UIViewController {

    private let legalText: String

    init(title: String, text: String) {
        self.legalText = text
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let textView = UITextView()
        textView.text = legalText
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .label
        textView.isEditable = false
        textView.isSelectable = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Control cell

private class ControlCell: UITableViewCell {

    static let reuseID = "ControlCell"

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let controlContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var currentControl: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(nameLabel)
        contentView.addSubview(controlContainer)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            controlContainer.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            controlContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            controlContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            controlContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(label: String, control: UIView) {
        nameLabel.text = label
        control.translatesAutoresizingMaskIntoConstraints = false

        if currentControl !== control {
            currentControl?.removeFromSuperview()
            controlContainer.addSubview(control)
            NSLayoutConstraint.activate([
                control.topAnchor.constraint(equalTo: controlContainer.topAnchor),
                control.leadingAnchor.constraint(equalTo: controlContainer.leadingAnchor),
                control.trailingAnchor.constraint(equalTo: controlContainer.trailingAnchor),
                control.bottomAnchor.constraint(equalTo: controlContainer.bottomAnchor)
            ])
            currentControl = control
        }
    }
}


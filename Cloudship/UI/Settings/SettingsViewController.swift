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
        let sc = UISegmentedControl(items: ["Tmrw", "NOAA", "O-Meteo", "Pirate", "Apple"])
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11)], for: .normal)
        let active = WeatherDataSourceManager.shared.activeSource
        if active is NOAADataSource                { sc.selectedSegmentIndex = 1 }
        else if active is OpenMeteoDataSource      { sc.selectedSegmentIndex = 2 }
        else if active is PirateWeatherDataSource  { sc.selectedSegmentIndex = 3 }
        else if active is AppleWeatherDataSource   { sc.selectedSegmentIndex = 4 }
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
        case .about:          return 3
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
            return "NOAA: US-only. Open-Meteo: global. \nTomorrow.io, Pirate Weather, and Apple Weather require Premium \n Nearest Station and Consensus Mode override the source selector above."
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
        let premiumIndices: Set<Int> = [0, 3, 4]  // Tomorrow.io, Pirate, Apple
        if premiumIndices.contains(sender.selectedSegmentIndex)
            && !SubscriptionManager.shared.isPremiumCached {
            // Revert to current selection
            let active = WeatherDataSourceManager.shared.activeSource
            if active is NOAADataSource              { sender.selectedSegmentIndex = 1 }
            else if active is OpenMeteoDataSource    { sender.selectedSegmentIndex = 2 }
            else if active is PirateWeatherDataSource { sender.selectedSegmentIndex = 3 }
            else if active is AppleWeatherDataSource  { sender.selectedSegmentIndex = 4 }
            else                                      { sender.selectedSegmentIndex = 0 }
            presentPaywall()
            return
        }

        switch sender.selectedSegmentIndex {
        case 1:  WeatherDataSourceManager.shared.activeSource = NOAADataSource()
        case 2:  WeatherDataSourceManager.shared.activeSource = OpenMeteoDataSource()
        case 3:  WeatherDataSourceManager.shared.activeSource = PirateWeatherDataSource()
        case 4:  WeatherDataSourceManager.shared.activeSource = AppleWeatherDataSource()
        default: WeatherDataSourceManager.shared.activeSource = TomorrowIODataSource()
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
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        var config = cell.defaultContentConfiguration()
        config.text = "Nearest Active Station"
        config.secondaryText = nearestStationSubtitle
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.font = .systemFont(ofSize: 12)
        cell.contentConfiguration = config
    }

    /// Updates the nearest-station cell's subtitle in place (no row reload).
    /// Called when settingsChanged fires so the km/mi label tracks the unit preference.
    @objc private func reloadNearestStationRow() {
        guard UserDefaults.standard.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey) else { return }
        let indexPath = IndexPath(row: 1, section: Section.dataSource.rawValue)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        var config = cell.defaultContentConfiguration()
        config.text = "Nearest Active Station"
        config.secondaryText = nearestStationSubtitle
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.font = .systemFont(ofSize: 12)
        cell.contentConfiguration = config
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
            self?.tableView.reloadSections(IndexSet(integer: Section.dataSource.rawValue), with: .none)
            self?.tableView.reloadSections(IndexSet(integer: Section.subscription.rawValue), with: .none)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                toast.dismiss(animated: true)
            }

            // Reload to update version label and subscription section
            tableView.reloadData()
        }
    }
    #endif

    private func presentPaywall() {
        let paywall = PaywallViewController()
        paywall.modalPresentationStyle = .pageSheet
        if let sheet = paywall.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(paywall, animated: true)
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
        if sender.isOn && !wasEnabled {
            let timeRow = IndexPath(row: 4, section: Section.notifications.rawValue)
            tableView.insertRows(at: [timeRow], with: .automatic)
        } else if !sender.isOn && wasEnabled {
            let timeRow = IndexPath(row: 4, section: Section.notifications.rawValue)
            tableView.deleteRows(at: [timeRow], with: .automatic)
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
        if sender.isOn && !wasEnabled {
            let timeRow = IndexPath(row: timeRowIndex, section: Section.notifications.rawValue)
            tableView.insertRows(at: [timeRow], with: .automatic)
        } else if !sender.isOn && wasEnabled {
            let timeRow = IndexPath(row: timeRowIndex, section: Section.notifications.rawValue)
            tableView.deleteRows(at: [timeRow], with: .automatic)
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
            self?.tableView.reloadSections(IndexSet(integer: Section.notifications.rawValue), with: .none)
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
        NotificationCenter.default.post(name: Notification.Name("settingsChanged"), object: nil)
    }

    private func triggerRefetch() {
        // Ask the main forecast VC to re-fetch via notification or direct call
        NotificationCenter.default.post(name: Notification.Name("settingsChanged"), object: nil)
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

// MARK: - Control cell

private class ControlCell: UITableViewCell {

    static let reuseID = "ControlCell"

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private var embeddedControl: UIView?
    private var controlConstraints: [NSLayoutConstraint] = []

    func configure(label: String, control: UIView) {
        nameLabel.text = label
        selectionStyle = .none
        control.translatesAutoresizingMaskIntoConstraints = false

        // Remove old control and constraints
        NSLayoutConstraint.deactivate(controlConstraints)
        embeddedControl?.removeFromSuperview()
        nameLabel.removeFromSuperview()

        contentView.addSubview(nameLabel)
        contentView.addSubview(control)
        embeddedControl = control

        // Stack label above control so nothing gets truncated
        controlConstraints = [
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            control.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            control.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            control.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            control.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(controlConstraints)
    }
}

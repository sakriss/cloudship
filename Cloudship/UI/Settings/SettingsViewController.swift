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

    private lazy var unitsControl: UISegmentedControl = {
        let isMetric = TemperatureFormatter.isMetric
        let sc = UISegmentedControl(items: ["°F (Imperial)", "°C (Metric)"])
        sc.selectedSegmentIndex = isMetric ? 1 : 0
        sc.addTarget(self, action: #selector(unitsChanged(_:)), for: .valueChanged)
        return sc
    }()

    private lazy var appearanceControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["System", "Light", "Dark"])
        sc.selectedSegmentIndex = savedAppearanceIndex()
        sc.addTarget(self, action: #selector(appearanceChanged(_:)), for: .valueChanged)
        return sc
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(ControlCell.self, forCellReuseIdentifier: "ControlCell_source")
        tableView.register(ControlCell.self, forCellReuseIdentifier: "ControlCell_units")
        tableView.register(ControlCell.self, forCellReuseIdentifier: "ControlCell_appearance")
    }

    // MARK: - UITableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .dataSource:     return 1
        case .units:          return 1
        case .appearance:     return 1
        case .notifications:  return 2
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
            return "NOAA: US-only. Open-Meteo: global. Tomorrow.io, Pirate Weather, and Apple Weather require Premium."
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {

        case .dataSource:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCell_source", for: indexPath) as! ControlCell
            cell.configure(label: "Weather Source", control: sourceControl)
            return cell

        case .units:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCell_units", for: indexPath) as! ControlCell
            cell.configure(label: "Temperature", control: unitsControl)
            return cell

        case .appearance:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCell_appearance", for: indexPath) as! ControlCell
            cell.configure(label: "Theme", control: appearanceControl)
            return cell

        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                config.text = "Rain Alerts"
                config.secondaryText = "Get notified when rain is starting or stopping"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = rainAlertsSwitch
                cell.accessoryType = .none
                cell.selectionStyle = .none
            } else {
                config.text = "Manage Locations"
                config.secondaryText = "Set up rain alerts for specific locations"
                config.secondaryTextProperties.color = .secondaryLabel
                config.secondaryTextProperties.font = .systemFont(ofSize: 12)
                cell.contentConfiguration = config
                cell.accessoryView = nil
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

        if Section(rawValue: indexPath.section) == .notifications && indexPath.row == 1 {
            let vc = ManageLocationsViewController(style: .grouped)
            navigationController?.pushViewController(vc, animated: true)
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

    @objc private func appearanceChanged(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "AppearanceIndex")
        let style: UIUserInterfaceStyle = [.unspecified, .light, .dark][sender.selectedSegmentIndex]
        view.window?.overrideUserInterfaceStyle = style
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

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
        case about
    }

    // MARK: - Cached controls

    private lazy var sourceControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Tomorrow.io", "NOAA", "Open-Meteo"])
        let active = WeatherDataSourceManager.shared.activeSource
        if active is NOAADataSource           { sc.selectedSegmentIndex = 1 }
        else if active is OpenMeteoDataSource { sc.selectedSegmentIndex = 2 }
        else                                  { sc.selectedSegmentIndex = 0 }
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
        tableView.register(ControlCell.self, forCellReuseIdentifier: ControlCell.reuseID)
    }

    // MARK: - UITableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .dataSource:   return 1
        case .units:        return 1
        case .appearance:   return 1
        case .about:        return 3
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .dataSource:  return "Data Source"
        case .units:       return "Units"
        case .appearance:  return "Appearance"
        case .about:       return "About"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if Section(rawValue: section) == .dataSource {
            return "NOAA: Free, US-only. Open-Meteo: Free, global. Tomorrow.io: Global with API key."
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {

        case .dataSource:
            let cell = tableView.dequeueReusableCell(withIdentifier: ControlCell.reuseID, for: indexPath) as! ControlCell
            cell.configure(label: "Weather Source", control: sourceControl)
            return cell

        case .units:
            let cell = tableView.dequeueReusableCell(withIdentifier: ControlCell.reuseID, for: indexPath) as! ControlCell
            cell.configure(label: "Temperature", control: unitsControl)
            return cell

        case .appearance:
            let cell = tableView.dequeueReusableCell(withIdentifier: ControlCell.reuseID, for: indexPath) as! ControlCell
            cell.configure(label: "Theme", control: appearanceControl)
            return cell

        case .about:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            switch indexPath.row {
            case 0:
                config.text = "Version"
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
                let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
                config.secondaryText = "\(version) (\(build))"
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
        guard Section(rawValue: indexPath.section) == .about else { return }
        switch indexPath.row {
        case 1: sendFeedbackEmail()
        case 2: openAppStore()
        default: break
        }
    }

    // MARK: - Actions

    @objc private func sourceChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:  WeatherDataSourceManager.shared.activeSource = NOAADataSource()
        case 2:  WeatherDataSourceManager.shared.activeSource = OpenMeteoDataSource()
        default: WeatherDataSourceManager.shared.activeSource = TomorrowIODataSource()
        }
        triggerRefetch()
    }

    @objc private func unitsChanged(_ sender: UISegmentedControl) {
        let newUnits = sender.selectedSegmentIndex == 0 ? "imperial" : "metric"
        UserDefaults.standard.set(newUnits, forKey: "Units")
        triggerRefetch()
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

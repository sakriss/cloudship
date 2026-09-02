//
//  ManageLocationsViewController.swift
//  Cloudship
//
//  UITableViewController listing saved locations with per-location
//  notification settings (rain alerts, daily summary).
//

import UIKit
import CoreLocation

class ManageLocationsViewController: UITableViewController {

    private var locations: [SavedLocation] = []
    private let geocoder = CLGeocoder()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Locations"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.reuseID)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addLocation)
        )

        reload()
    }

    private func reload() {
        locations = SavedLocationStore.shared.locations
        tableView.reloadData()
    }

    // MARK: - Add location

    @objc private func addLocation() {
        let alert = UIAlertController(title: "Add Location",
                                       message: "Enter a city name",
                                       preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g. Brooklyn, NY"
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self?.geocodeAndAdd(text)
        })
        present(alert, animated: true)
    }

    private func geocodeAndAdd(_ query: String) {
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            guard let pm = placemarks?.first,
                  let coord = pm.location?.coordinate else {
                DispatchQueue.main.async {
                    let errorAlert = UIAlertController(title: "Not Found",
                                                        message: "Couldn't find that location. Try again.",
                                                        preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(errorAlert, animated: true)
                }
                return
            }

            let name = [pm.locality, pm.administrativeArea].compactMap { $0 }.joined(separator: ", ")
            let location = SavedLocation(name: name.isEmpty ? query : name,
                                          lat: coord.latitude,
                                          lon: coord.longitude)

            DispatchQueue.main.async {
                let added = SavedLocationStore.shared.add(location)
                if !added {
                    let maxAlert = UIAlertController(title: "Limit Reached",
                                                      message: "Maximum 10 locations or location already exists.",
                                                      preferredStyle: .alert)
                    maxAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(maxAlert, animated: true)
                }
                self?.reload()
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.reuseID, for: indexPath) as! LocationCell
        let loc = locations[indexPath.row]
        cell.configure(with: loc) { [weak self] updated in
            SavedLocationStore.shared.update(at: indexPath.row, updated)
            self?.locations[indexPath.row] = updated
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                             forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SavedLocationStore.shared.remove(at: indexPath.row)
            locations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if locations.isEmpty {
            return "Add locations to receive rain alerts for places you care about."
        }
        return "Swipe left to delete. Up to 5 locations can have rain alerts enabled."
    }
}

// MARK: - Location Cell

private class LocationCell: UITableViewCell {

    static let reuseID = "LocationCell"

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 16, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rainAlertLabel: UILabel = {
        let l = UILabel()
        l.text = "Rain Alerts"
        l.font = .appFont(size: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rainAlertSwitch: UISwitch = {
        let sw = UISwitch()
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        return sw
    }()

    private var onChange: ((SavedLocation) -> Void)?
    private var location: SavedLocation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(nameLabel)
        contentView.addSubview(rainAlertLabel)
        contentView.addSubview(rainAlertSwitch)

        rainAlertSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            rainAlertLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            rainAlertLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rainAlertLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            rainAlertSwitch.centerYAnchor.constraint(equalTo: rainAlertLabel.centerYAnchor),
            rainAlertSwitch.leadingAnchor.constraint(equalTo: rainAlertLabel.trailingAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with location: SavedLocation, onChange: @escaping (SavedLocation) -> Void) {
        self.location = location
        self.onChange = onChange
        nameLabel.text = location.name
        rainAlertSwitch.isOn = location.rainAlertsEnabled

        // Gate rain alerts behind premium
        let isPremium = SubscriptionManager.shared.isPremiumCached
        rainAlertSwitch.isEnabled = isPremium
        if !isPremium {
            rainAlertSwitch.isOn = false
            rainAlertLabel.text = "Rain Alerts (Premium)"
        } else {
            rainAlertLabel.text = "Rain Alerts"
        }
    }

    @objc private func switchChanged() {
        guard var loc = location else { return }
        loc.rainAlertsEnabled = rainAlertSwitch.isOn
        location = loc
        onChange?(loc)
    }
}

//
//  AlertDetailViewController.swift
//  Cloudship
//
//  Pushed on the nav stack when the user taps an alert banner.
//  Shows full details for all active alerts, one section per alert.
//

import UIKit

class AlertDetailViewController: UITableViewController {

    // MARK: - Data

    private let alerts: [WeatherAlert]

    // MARK: - Init

    init(alerts: [WeatherAlert]) {
        self.alerts = alerts
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(alerts:)")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = alerts.count == 1 ? "Weather Alert" : "Weather Alerts (\(alerts.count))"
        navigationItem.largeTitleDisplayMode = .never

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "detail")
        tableView.register(AlertHeaderCell.self, forCellReuseIdentifier: "header")
        tableView.register(AlertTextCell.self, forCellReuseIdentifier: "text")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
    }

    // MARK: - UITableViewDataSource

    // Each alert is its own section.
    // Row 0: header cell (severity badge, event, onset/expires)
    // Row 1: description text cell
    // Row 2 (optional): instruction text cell

    override func numberOfSections(in tableView: UITableView) -> Int {
        alerts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let alert = alerts[section]
        return alert.instruction != nil ? 3 : 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let alert = alerts[indexPath.section]

        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! AlertHeaderCell
            cell.configure(with: alert)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath) as! AlertTextCell
            cell.configure(label: "DESCRIPTION", body: alert.description)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath) as! AlertTextCell
            cell.configure(label: "INSTRUCTIONS", body: alert.instruction ?? "")
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - AlertHeaderCell

private class AlertHeaderCell: UITableViewCell {

    private let severityBadge: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 11, weight: .bold)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let eventLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 17, weight: .semibold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sourceLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let onsetLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let areaLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        selectionStyle = .none
        backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [severityBadge, eventLabel, sourceLabel, onsetLabel, areaLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            severityBadge.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    func configure(with alert: WeatherAlert) {
        eventLabel.text = alert.event
        sourceLabel.text = "Source: \(alert.source)"

        // Severity badge
        severityBadge.text = "  \(alert.severity.emoji) \(alert.severity.rawValue)  "
        switch alert.severity {
        case .extreme:
            severityBadge.backgroundColor = UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
            severityBadge.textColor = .white
        case .severe:
            severityBadge.backgroundColor = UIColor(red: 0.85, green: 0.35, blue: 0.08, alpha: 1)
            severityBadge.textColor = .white
        case .moderate:
            severityBadge.backgroundColor = UIColor(red: 0.80, green: 0.60, blue: 0.05, alpha: 1)
            severityBadge.textColor = .white
        case .minor:
            severityBadge.backgroundColor = UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1)
            severityBadge.textColor = .white
        case .unknown:
            severityBadge.backgroundColor = .secondarySystemFill
            severityBadge.textColor = .secondaryLabel
        }

        // Onset / expires
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        var timeText = ""
        if let onset = alert.onset {
            timeText += "Begins: \(df.string(from: onset))\n"
        }
        if let expires = alert.expires {
            timeText += "Expires: \(df.string(from: expires))"
        }
        onsetLabel.text = timeText.trimmingCharacters(in: .newlines)
        onsetLabel.isHidden = timeText.isEmpty

        // Area
        if let area = alert.areaDesc, !area.isEmpty {
            areaLabel.text = "📍 \(area)"
            areaLabel.isHidden = false
        } else {
            areaLabel.isHidden = true
        }
    }
}

// MARK: - AlertTextCell

private class AlertTextCell: UITableViewCell {

    private let sectionLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 11, weight: .semibold)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .appFont(size: 14, weight: .regular)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        selectionStyle = .none
        backgroundColor = .clear

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(divider)
        contentView.addSubview(sectionLabel)
        contentView.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: contentView.topAnchor),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            sectionLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            sectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(label: String, body: String) {
        sectionLabel.text = label
        bodyLabel.text = body
    }
}

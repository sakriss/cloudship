//
//  ConsensusBreakdownViewController.swift
//  Cloudship
//
//  Bottom sheet showing the per-source temperature and precipitation breakdown
//  when Consensus Mode is active.
//

import UIKit

final class ConsensusBreakdownViewController: UIViewController {

    // MARK: - Init

    private let breakdown: ConsensusBreakdown

    init(breakdown: ConsensusBreakdown) {
        self.breakdown = breakdown
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Consensus Forecast"
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Averaging \(breakdown.sourcesUsed) source\(breakdown.sourcesUsed == 1 ? "" : "s")"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.dataSource = self
        tv.register(SourceReadingCell.self, forCellReuseIdentifier: "SourceReadingCell")
        tv.register(SummaryRowCell.self, forCellReuseIdentifier: "SummaryRowCell")
        tv.isScrollEnabled = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemGroupedBackground
        return tv
    }()

    private lazy var footerLabel: UILabel = {
        let l = UILabel()
        l.text = "Multiple sources reduce the impact of single-provider errors. Outlier sources (\u{26A0}) are down-weighted automatically."
        l.font = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
        view.addSubview(footerLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: tableViewHeight),

            footerLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 12),
            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            footerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private var tableViewHeight: CGFloat {
        // header row (44) + one row per reading (44) + summary row (44)
        CGFloat(44 + breakdown.readings.count * 44 + 44)
    }
}

// MARK: - UITableViewDataSource

extension ConsensusBreakdownViewController: UITableViewDataSource {

    // Section 0: per-source readings
    // Section 1: consensus average row

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? breakdown.readings.count : 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Sources" : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryRowCell", for: indexPath) as! SummaryRowCell
            cell.configure(
                avgTemp: breakdown.averageTemp,
                avgPrecip: breakdown.averagePrecipChance
            )
            return cell
        }
        let reading = breakdown.readings[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SourceReadingCell", for: indexPath) as! SourceReadingCell
        cell.configure(reading: reading)
        return cell
    }
}

// MARK: - SourceReadingCell

private final class SourceReadingCell: UITableViewCell {

    private let sourceNameLabel = UILabel()
    private let tempLabel       = UILabel()
    private let precipLabel     = UILabel()
    private let outlierBadge    = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildLayout() {
        [sourceNameLabel, outlierBadge, tempLabel, precipLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .systemFont(ofSize: 14)
        }

        outlierBadge.text = "⚠"
        outlierBadge.textColor = .systemOrange
        outlierBadge.font = .systemFont(ofSize: 13)

        tempLabel.textAlignment   = .right
        precipLabel.textAlignment = .right
        precipLabel.textColor     = .secondaryLabel

        contentView.addSubview(sourceNameLabel)
        contentView.addSubview(outlierBadge)
        contentView.addSubview(tempLabel)
        contentView.addSubview(precipLabel)

        NSLayoutConstraint.activate([
            sourceNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sourceNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            outlierBadge.leadingAnchor.constraint(equalTo: sourceNameLabel.trailingAnchor, constant: 4),
            outlierBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            precipLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            precipLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            precipLabel.widthAnchor.constraint(equalToConstant: 52),

            tempLabel.trailingAnchor.constraint(equalTo: precipLabel.leadingAnchor, constant: -8),
            tempLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tempLabel.widthAnchor.constraint(equalToConstant: 52)
        ])
    }

    func configure(reading: ConsensusBreakdown.SourceReading) {
        sourceNameLabel.text = reading.sourceName
        sourceNameLabel.textColor = reading.isOutlier ? .secondaryLabel : .label
        outlierBadge.isHidden = !reading.isOutlier

        if let t = reading.temperature {
            let formatted = TemperatureFormatter.format(t)
            tempLabel.text = formatted
            tempLabel.textColor = reading.isOutlier ? .secondaryLabel : .label
        } else {
            tempLabel.text = "—"
            tempLabel.textColor = .tertiaryLabel
        }

        if let p = reading.precipChance {
            precipLabel.text = "\(Int(p.rounded()))%"
        } else {
            precipLabel.text = "—"
        }
    }
}

// MARK: - SummaryRowCell

private final class SummaryRowCell: UITableViewCell {

    private let nameLabel   = UILabel()
    private let tempLabel   = UILabel()
    private let precipLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildLayout() {
        [nameLabel, tempLabel, precipLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .systemFont(ofSize: 14, weight: .semibold)
        }

        nameLabel.text     = "Consensus"
        tempLabel.textAlignment   = .right
        precipLabel.textAlignment = .right
        precipLabel.textColor     = .secondaryLabel

        contentView.addSubview(nameLabel)
        contentView.addSubview(tempLabel)
        contentView.addSubview(precipLabel)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            precipLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            precipLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            precipLabel.widthAnchor.constraint(equalToConstant: 52),

            tempLabel.trailingAnchor.constraint(equalTo: precipLabel.leadingAnchor, constant: -8),
            tempLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tempLabel.widthAnchor.constraint(equalToConstant: 52)
        ])
    }

    func configure(avgTemp: Double?, avgPrecip: Double?) {
        tempLabel.text   = avgTemp.map   { TemperatureFormatter.format($0) } ?? "—"
        precipLabel.text = avgPrecip.map { "\(Int($0.rounded()))%" }         ?? "—"
    }
}

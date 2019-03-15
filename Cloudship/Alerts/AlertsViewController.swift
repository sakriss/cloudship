//
//  AlertsViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 6/1/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class AlertsViewController: UIViewController {

    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var alertsTableView: UITableView!
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        self.alertsTableView.rowHeight = UITableViewAutomaticDimension
        self.alertsTableView.estimatedRowHeight = 150
        
    }
}

//--------------------------------------------------------------------------
// MARK: - TableView Delegate
//--------------------------------------------------------------------------
//extension AlertsViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return alertsTableView.bounds.size.height
//    }
//}

//--------------------------------------------------------------------------
// MARK: - TableView Data Source
//--------------------------------------------------------------------------
extension AlertsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (WeatherController.shared.weather?.alerts?.count)!
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlertsTableViewCell", for: indexPath) as? AlertsTableViewCell else {
            return UITableViewCell()
        }
        
        let dataPoint = WeatherController.shared.weather
        
        if let alertsTitle = dataPoint?.alerts?[indexPath.row].title {
            cell.alertTitleLabel.text = ("\u{26A0} ") + String(alertsTitle.uppercased()) + (" \u{26A0}")

        }
        
        if let alertsSeverity = dataPoint?.alerts?[indexPath.row].severity {
                cell.alertSeverityLabel.text = String(alertsSeverity.uppercased())
        }
        
        if let alertsDescription = dataPoint?.alerts?[indexPath.row].description {
                cell.alertDescriptionLabel.text = String(alertsDescription)
        }

        return cell
    }
}

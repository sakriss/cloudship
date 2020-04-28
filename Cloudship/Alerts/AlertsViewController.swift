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

        self.alertsTableView.rowHeight = UITableView.automaticDimension
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
        return (WeatherController.shared.weatherbitWeatherAlerts?.alerts?.count)!
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlertsTableViewCell", for: indexPath) as? AlertsTableViewCell else {
            return UITableViewCell()
        }
        
        if indexPath.row % 2 == 0 {
            cell.contentView.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 1)
            cell.alertTitleLabel.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 1)
            cell.alertDescriptionLabel.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 1)
            cell.alertSeverityLabel.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 1)
            
        } else {
            cell.contentView.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
            cell.alertTitleLabel.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
            cell.alertDescriptionLabel.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
            cell.alertSeverityLabel.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
        }
        
        let dataPoint = WeatherController.shared.weatherbitWeatherAlerts
        
        if let alertsTitle = dataPoint?.alerts?[indexPath.row].title {
            cell.alertTitleLabel.text = ("\u{26A0} ") + String(alertsTitle.uppercased()) + (" \u{26A0}")

        }
        
        if let alertsSeverity = dataPoint?.alerts?[indexPath.row].severity {
            cell.alertSeverityLabel.text = String(alertsSeverity.uppercased())
        }
        
        if let alertsDescription = dataPoint?.alerts?[indexPath.row].descriptionField {
            let formattedDescription = alertsDescription.replacingOccurrences(of: "*", with: "\n\n*")
            cell.alertDescriptionLabel.text = String(formattedDescription)
        }

        return cell
    }
}

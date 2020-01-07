//
//  AlertsViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 6/1/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import SafariServices

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
extension AlertsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (WeatherController.shared.weather?.alerts?.count)!
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlertsTableViewCell", for: indexPath) as? AlertsTableViewCell else {
            return UITableViewCell()
        }
        
        let dataPoint = WeatherController.shared.weather
        cell.delegate = self as? AlertsCellDelegate
        guard let url = dataPoint?.alerts?[indexPath.row] else { return cell }
        cell.setURL(url: url)
        
        if let alertsTitle = dataPoint?.alerts?[indexPath.row].title {
            cell.alertTitleLabel.text = ("\u{1F6A8} ") + String(alertsTitle.uppercased()) + (" \u{1F6A8}")

        }
        
        if let alertsDescription = dataPoint?.alerts?[indexPath.row].description {
            let formattedDescription = alertsDescription.replacingOccurrences(of: "*", with: "\n\n*")
            cell.alertDescriptionLabel.text = String(formattedDescription)
        }
        
        cell.alertsMoreInfoButton.layer.cornerRadius = 7
        cell.alertsMoreInfoButton.layer.borderColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 0.25).cgColor
        cell.alertsMoreInfoButton.layer.borderWidth = 1.0
        cell.alertsMoreInfoButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        
        let alertsEffectiveTime = Date(timeIntervalSince1970: (dataPoint?.alerts?[indexPath.row].time)!)
        let effectiveString = "\(alertsEffectiveTime)" // the date string to be parsed
        let effectiveDateFormatterGet = DateFormatter()
        effectiveDateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        let effectiveDateFormatterPrint = DateFormatter()
        effectiveDateFormatterPrint.dateFormat = "EEEE, MMMM d - h:mm a"
        effectiveDateFormatterPrint.timeZone = TimeZone(identifier: (dataPoint?.timezone)!)

        if let date = effectiveDateFormatterGet.date(from: effectiveString) {
            print(effectiveDateFormatterPrint.string(from: date))
            cell.alertEffectiveTime.text = "Effective: " + effectiveDateFormatterPrint.string(from: date)
        } else {
           print("There was an error decoding the date")
        }
        
        let expiredTime = Date(timeIntervalSince1970: (dataPoint?.alerts?[indexPath.row].expires)!)
        let expiredString = "\(expiredTime)" // the date string to be parsed
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "EEEE, MMMM d - h:mm a"
        dateFormatterPrint.timeZone = TimeZone(identifier: (dataPoint?.timezone)!)

        if let date = dateFormatterGet.date(from: expiredString) {
            print(dateFormatterPrint.string(from: date))
            cell.alertExpiresTime.text = "Expires: " + dateFormatterPrint.string(from: date)
        } else {
           print("There was an error decoding the date")
        }

        return cell
    }
}

//--------------------------------------------------------------------------
// MARK: - Alerts Cell Delegate
//--------------------------------------------------------------------------
extension AlertsViewController: AlertsCellDelegate {
    func didTapURLButton(url: String) {
        let alertsURL = URL(string: url)!
        let safariVC = SFSafariViewController(url: alertsURL)
        present(safariVC, animated: true, completion: nil)
        print("Did tap from view controller")
    }
}

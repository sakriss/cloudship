//
//  HourlyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class HourlyViewController: UIViewController {

    @IBOutlet weak var hourlyTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hourlyTableView.rowHeight = UITableViewAutomaticDimension
        self.hourlyTableView.estimatedRowHeight = 80
    }

}

extension HourlyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (WeatherController.shared.weather?.hourly?.data?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyTableViewCell", for: indexPath) as? HourlyTableViewCell else {
            return UITableViewCell()
        }
        let dataPoint = WeatherController.shared.weather
        
//        if let day = dataPoint?.hourly?.data?[indexPath.row].time {
//            DispatchQueue.main.async {
//                cell.dayOfWeekLabel.text = String(day)
//            }
//        }
        
        //        if let hour = dataPoint?.hourly?.data?[indexPath.row].time {
        //            DispatchQueue.main.async {
        //                cell.dayOfWeekLabel.text = String(day)
        //            }
        //        }
        
        if let hourlyTemp = dataPoint?.hourly?.data?[indexPath.row].temperature {
            let newHighTemp = String(format: "%.0f", hourlyTemp)
            DispatchQueue.main.async {
                cell.hourlyTempLabel.text = newHighTemp + "\u{00B0}"
            }
        }
        
        if let hourlyCondition = dataPoint?.hourly?.data?[indexPath.row].summary {
            DispatchQueue.main.async {
                cell.hourlyConditionLabel.text = String(hourlyCondition)
            }
        }
        
        if let precipChance = dataPoint?.hourly?.data?[indexPath.row].precipProbability {
            DispatchQueue.main.async {
                cell.hourlyPrecipLabel.text = String(format: "%.2f%%", precipChance)
            }
        }
        
        if let windData = dataPoint?.hourly?.data?[indexPath.row].windSpeed {
            DispatchQueue.main.async {
                cell.hourlyWindLabel.text = String(windData)
            }
        }
        
        return cell
    }
    
    
}

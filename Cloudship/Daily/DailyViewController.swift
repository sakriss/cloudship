//
//  DailyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class DailyViewController: UIViewController {
    
    @IBOutlet weak var dailyForcastTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dailyForcastTableView.rowHeight = UITableViewAutomaticDimension
        self.dailyForcastTableView.estimatedRowHeight = 120
    }
    
}

extension DailyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (WeatherController.shared.weather?.daily?.data?.count)!
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DailyTableViewCell", for: indexPath) as? DailyTableViewCell else {
            return UITableViewCell()
        }
        
        let dataPoint = WeatherController.shared.weather
        
        let dailyTime = NSDate(timeIntervalSince1970: (dataPoint?.daily?.data?[indexPath.row].time)!)
        
        let dateString = "\(dailyTime)" // the date string to be parsed
        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US_POSIX")
        df1.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        if let date = df1.date(from: dateString) {
            let df2 = DateFormatter()
            df2.dateStyle = .full
            let string = df2.string(from: date)
            DispatchQueue.main.async {
                cell.dayOfWeekLabel.text = string
            }
        } else {
            print("Unable to parse date string")
        }
        
        if let dailySummary = dataPoint?.daily?.data?[indexPath.row].summary {
            DispatchQueue.main.async {
                cell.dailySummaryLabel.text = String(dailySummary)
            }
        }
        
        if let highTemp = dataPoint?.daily?.data?[indexPath.row].temperatureMax, let lowTemp = dataPoint?.daily?.data?[indexPath.row].temperatureLow {
            let newHighTemp = String(format: "%.0f", highTemp)
            let newLowTemp = String(format: "%.0f", lowTemp)
            DispatchQueue.main.async {
                //cell.dailyHighTempLabel.text = String(format: "%.0f", highTemp)
                cell.dailyHighTempLabel.text = newHighTemp + "\u{00B0}/" + newLowTemp + "\u{00B0}"
            }
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent

        if let precipChance = dataPoint?.daily?.data?[indexPath.row].precipProbability {
                cell.dailyPercipPercent.text = percentFormatter.string(from: precipChance as NSNumber)
        }
        return cell
    }
    
    
}

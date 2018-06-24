//
//  DailyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class DailyViewController: UIViewController {
    
    var selectedRowIndex: NSIndexPath = NSIndexPath(row: -1, section: 0)
    
    @IBOutlet weak var dailyForcastTableView: UITableView!
    @IBOutlet weak var dailySummaryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dailySummaryLabel.text = WeatherController.shared.weather?.daily?.summary
        
        self.dailyForcastTableView.rowHeight = UITableViewAutomaticDimension
        self.dailyForcastTableView.estimatedRowHeight = 110
    }
    
}

extension DailyViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRowIndex = indexPath as NSIndexPath
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = tableView.cellForRow(at: indexPath)
        let cellHeight = row?.bounds.height
        
        if indexPath.row == selectedRowIndex.row {
            if cellHeight == 110 {
                return 180
            }
        }
        return 110
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
            let format = "EEEE, MMMM d"
            let df2 = DateFormatter()
            df2.dateFormat = format
            //df2.dateStyle = .full
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
                //cell.dailyHighTempLabel.text = String(format: "%.0f", highTemp)
                cell.dailyHighTempLabel.text = newHighTemp + "\u{00B0}/" + newLowTemp + "\u{00B0}"
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent

        if let precipChance = dataPoint?.daily?.data?[indexPath.row].precipProbability {
                cell.dailyPercipPercent.text = percentFormatter.string(from: precipChance as NSNumber)
        }
        return cell
    }
    
    
}

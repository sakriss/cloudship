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
        self.dailyForcastTableView.estimatedRowHeight = 150
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
        
        let time = NSDate(timeIntervalSince1970: (dataPoint?.daily?.data?[indexPath.row].time)!)
            
            let dateString = "\(time)" // the date string to be parsed
            let df1 = DateFormatter()
            df1.locale = Locale(identifier: "en_US_POSIX")
            df1.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
            if let date = df1.date(from: dateString) {
                print(date)
                let df2 = DateFormatter()
                df2.dateStyle = .full
//                df2.timeStyle = .short
                let string = df2.string(from: date)
                DispatchQueue.main.async {
                    cell.dayOfWeekLabel.text = string
                }
            } else {
                print("Unable to parse date string")
            }
        
        if let highTemp = dataPoint?.daily?.data?[indexPath.row].temperatureMax {
            DispatchQueue.main.async {
                cell.dailyHighTempLabel.text = String(highTemp)
            }
        }
        
        if let lowTemp = dataPoint?.daily?.data?[indexPath.row].temperatureLow {
            DispatchQueue.main.async {
                cell.dailyLowTempLabel.text = String(lowTemp)
            }
        }
        
        if let precipChance = dataPoint?.daily?.data?[indexPath.row].precipProbability {
            DispatchQueue.main.async {
                cell.dailyPercipPercent.text = String(precipChance)
            }
        }
        
        cell.backgroundColor = UIColor.green
        return cell
    }
    
    
}

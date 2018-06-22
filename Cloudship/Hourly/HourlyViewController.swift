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
        
        let time = NSDate(timeIntervalSince1970: (dataPoint?.hourly?.data?[indexPath.row].time)!)
        let dateString = "\(time)" // the date string to be parsed
        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US")
        df1.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        if let date = df1.date(from: dateString) {
            let format = "EEEE"
            let df2 = DateFormatter()
            df2.dateFormat = format
            let string = df2.string(from: date)
                cell.dayOfWeekLabel.text = string

        } else {
            print("Unable to parse date string")
        }
        
        let hourlyTime = NSDate(timeIntervalSince1970: (dataPoint?.hourly?.data?[indexPath.row].time)!)
        let dailyHourString = "\(hourlyTime)" // the date string to be parsed
        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US")
        df3.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        if let hour = df3.date(from: dailyHourString) {
            let format = "ha"
            let df4 = DateFormatter()
            df4.dateFormat = format
            df4.amSymbol = "AM"
            df4.pmSymbol = "PM"
            let string = df4.string(from: hour)
                cell.hourlyHourLabel.text = string
        } else {
            print("Unable to parse date string")
        }
        
        if let hourlyTemp = dataPoint?.hourly?.data?[indexPath.row].temperature {
            let newHighTemp = String(format: "%.0f", hourlyTemp)
                cell.hourlyTempLabel.text = newHighTemp + "\u{00B0}"
        }
        
        let conditionIcon = dataPoint?.hourly?.data?[indexPath.row].icon
        switch conditionIcon {
        case "partly-cloudy-day":
                cell.conditionIconImage.image = UIImage(named: "mostlycloudy.png")

        case "partly-cloudy-night":
                cell.conditionIconImage.image = UIImage(named: "cloudynight.png")

        case "cloudy":
                cell.conditionIconImage.image = UIImage(named: "cloudy.png")

        case "clear-day":
                cell.conditionIconImage.image = UIImage(named: "sunny.png")

        case "clear-night":
                cell.conditionIconImage.image = UIImage(named: "clearnight.png")
            
        case "rain":
                cell.conditionIconImage.image = UIImage(named: "rain.png")
            
        case "snow":
                cell.conditionIconImage.image = UIImage(named: "snow.png")
            
        case "sleet":
                cell.conditionIconImage.image = UIImage(named: "sleet.png")
            
        case "wind":
                cell.conditionIconImage.image = UIImage(named: "wind.png")
            
        case "fog":
                cell.conditionIconImage.image = UIImage(named: "fog.png")
            
        default:
                cell.conditionIconImage.image = UIImage(named: "default.png")

        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        
        if let precipChance = dataPoint?.hourly?.data?[indexPath.row].precipProbability {
            cell.hourlyPrecipLabel.text = percentFormatter.string(from: precipChance as NSNumber)
        }
        
        if let windData = dataPoint?.hourly?.data?[indexPath.row].windSpeed {
            cell.hourlyWindLabel.text = String(format: "%.1f", windData)
        }
        
        return cell
    }
    
    
}

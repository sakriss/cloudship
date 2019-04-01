//
//  DailyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class DailyViewController: UIViewController {

    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var dailyForcastTableView: UITableView!
    @IBOutlet weak var dailySummaryLabel: UILabel!
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    var selectedRowIndex: NSIndexPath = NSIndexPath(row: -1, section: 0)
    let dataPoint = WeatherController.shared.weather?.daily
    var isExpanded = false
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        if let dailySummary = dataPoint?.summary {
            dailySummaryLabel.text = dailySummary
        }
        
        self.dailyForcastTableView.rowHeight = UITableView.automaticDimension
        self.dailyForcastTableView.estimatedRowHeight = 115
    }
    
}

//--------------------------------------------------------------------------
// MARK: - Tableview Delegate
//--------------------------------------------------------------------------

extension DailyViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRowIndex = indexPath as NSIndexPath
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = tableView.cellForRow(at: indexPath)
        let cellHeight = row?.bounds.height
        let cell = tableView.cellForRow(at: indexPath) as? DailyTableViewCell
        
        if indexPath.row == selectedRowIndex.row {
            if cellHeight == 115 {
                
                cell?.dailyViewMoreLabel.text = "-"
                return 185
            }
            
        }
        cell?.dailyViewMoreLabel.text = "+"
        
        return 115
    }
}

//--------------------------------------------------------------------------
// MARK: - TableView Data Source
//--------------------------------------------------------------------------

extension DailyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (dataPoint?.data?.count)!
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DailyTableViewCell", for: indexPath) as? DailyTableViewCell else {
            return UITableViewCell()
        }
        var units = ""
        if let unitsSaved = UserDefaults.standard.string(forKey: "Units") {
            if unitsSaved == "units=us" {
                units = " mph"
            }
            if unitsSaved == "units=si" {
                units = " m/s"
            }
        }

        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 1)

        } else {
            cell.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
        }
        
        
        let dataPoint = WeatherController.shared.weather
        
        let dailyTime = Date(timeIntervalSince1970: (dataPoint?.daily?.data?[indexPath.row].time)!)
        
        let dateString = "\(dailyTime)" // the date string to be parsed
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "EEEE, MMMM d"
        dateFormatterPrint.locale = Locale(identifier: "en_US_POSIX")
        dateFormatterPrint.timeZone = TimeZone(identifier: (dataPoint?.timezone)!)
        
        let date: Date? = dateFormatterGet.date(from: dateString)
        print(dateFormatterPrint.string(from: date!))
        DispatchQueue.main.async {
            cell.dayOfWeekLabel.text = dateFormatterPrint.string(from: date!)
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
                cell.dailyHighTempLabel.text = newLowTemp + "\u{00B0}/" + newHighTemp + "\u{00B0}"
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent

        if let precipChance = dataPoint?.daily?.data?[indexPath.row].precipProbability {
                cell.dailyPercipPercent.text = percentFormatter.string(from: precipChance as NSNumber)
        }
        
        if let dailyHumidity = dataPoint?.daily?.data?[indexPath.row].humidity {
            cell.dailyHumidityLabel.text = percentFormatter.string(from: dailyHumidity as NSNumber)
        }
        
        if let dailyWindSpeed = dataPoint?.daily?.data?[indexPath.row].windSpeed {
            let newDailyWindSpeed = String(format: "%.0f", dailyWindSpeed)
            cell.dailyWindSpeedLabel.text = newDailyWindSpeed + units
        }
        
        if let windBearingIcon = dataPoint?.hourly?.data?[indexPath.row].windBearing {
            
            switch windBearingIcon {
            case 0:
                cell.dailyWindLabel.text = "South"
            case 1...89:
                cell.dailyWindLabel.text = "Southwest"
            case 90:
                cell.dailyWindLabel.text = "West"
            case 91...179:
                cell.dailyWindLabel.text = "Northwest"
            case 180:
                cell.dailyWindLabel.text = "North"
            case 181...224:
                cell.dailyWindLabel.text = "Northeast"
            case 225:
                cell.dailyWindLabel.text = "East"
            case 226...359:
                cell.dailyWindLabel.text = "Southeast"
            case 360:
                cell.dailyWindLabel.text = "North"
            default:
                cell.dailyWindLabel.text = "N/A"
            }
        }
        
        let dailySunriseTime = NSDate(timeIntervalSince1970: (dataPoint?.daily?.data?[indexPath.row].sunriseTime)!)
            
            let dailySunriseString = "\(dailySunriseTime)" // the date string to be parsed
            let df3 = DateFormatter()
            df3.locale = Locale(identifier: "en_US")
            df3.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
            if let hour = df3.date(from: dailySunriseString) {
                let format = "h:mma"
                let df4 = DateFormatter()
                df4.dateFormat = format
                df4.amSymbol = "AM"
                df4.pmSymbol = "PM"
                let string = df4.string(from: hour)
                cell.dailySunriseLabel.text = string
            } else {
                print("Unable to parse date string")
            }
            
        let dailySunsetTime = NSDate(timeIntervalSince1970: (dataPoint?.daily?.data?[indexPath.row].sunsetTime)!)
        
        let dailySunsetString = "\(dailySunsetTime)" // the date string to be parsed
        let df5 = DateFormatter()
        df5.locale = Locale(identifier: "en_US")
        df5.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        if let hour = df5.date(from: dailySunsetString) {
            let format = "h:mma"
            let df6 = DateFormatter()
            df6.dateFormat = format
            df6.amSymbol = "AM"
            df6.pmSymbol = "PM"
            let string = df6.string(from: hour)
            cell.dailySunsetLabel.text = string
        } else {
            print("Unable to parse date string")
        }
        
        if let dailyCloudCover = dataPoint?.daily?.data?[indexPath.row].cloudCover {
            cell.dailyCloudCoverLabel.text = percentFormatter.string(from: dailyCloudCover as NSNumber)
        }
        
        return cell
    }
    
}

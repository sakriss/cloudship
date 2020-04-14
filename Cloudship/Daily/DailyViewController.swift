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
    let dataPointDaily = WeatherController.shared.climacellDailyWeather
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
        return (dataPointDaily?.count)!
        
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
        
        let dailyTime = (dataPointDaily?[indexPath.row].observation_time?.value)!
        
//        let dateString = "\(dailyTime)" // the date string to be parsed
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.locale = Locale(identifier: "en_US")
        dateFormatterGet.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        
//        dateFormatterGet.timeZone = TimeZone(identifier: (dataPoint?.timezone)!)

        if let date = dateFormatterGet.date(from: dailyTime) {
        let format = "EEEE, MMMM d"
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = format
        let string = dateFormatterPrint.string(from: date)
            cell.dayOfWeekLabel.text = string
        } else {
            print("Unable to parse date string")
        }
        
        if let dailySummary = dataPointDaily?[indexPath.row].weather_code?.value {
            let dailySummaryModified = dailySummary.replacingOccurrences(of: "_", with: " ")
            cell.dailySummaryLabel.text = String(dailySummaryModified.capitalized)
            
        }
        
        if let highTemp = dataPointDaily?[indexPath.row].temp?[1].max?.value, let lowTemp = dataPointDaily?[indexPath.row].temp?[0].min?.value {
            let newHighTemp = String(format: "%.0f", highTemp)
            let newLowTemp = String(format: "%.0f", lowTemp)
                //cell.dailyHighTempLabel.text = String(format: "%.0f", highTemp)
                cell.dailyHighTempLabel.text = newLowTemp + "\u{00B0}/" + newHighTemp + "\u{00B0}"
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent

        if let precipChance = dataPointDaily?[indexPath.row].precipitation_probability?.value {
            let newPrecip = String(format: "%.0f", precipChance)
                cell.dailyPercipPercent.text = newPrecip + "%"
        }
        
        if let dailyHumidity = dataPointDaily?[indexPath.row].humidity?[1].max?.value {
            let newHumidity = String(format: "%.0f", dailyHumidity)
            cell.dailyHumidityLabel.text = newHumidity + "%"
        }
        
        if let dailyWindSpeed = dataPointDaily?[indexPath.row].wind_speed?[1].max?.value {
            let newDailyWindSpeed = String(format: "%.0f", dailyWindSpeed)
            cell.dailyWindSpeedLabel.text = newDailyWindSpeed + units
        }
        
        if let windBearingIcon = dataPointDaily?[indexPath.row].wind_direction?[1].max?.value {
            
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
        
        let dailySunriseTime = (dataPointDaily?[indexPath.row].sunrise?.value)!
            
//            let dailySunriseString = "\(dailySunriseTime)" // the date string to be parsed
            let df3 = DateFormatter()
            df3.locale = Locale(identifier: "en_US")
        df3.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
            df3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
//                              2020-04-13 T 12:24:35.826 Z
            if let hour = df3.date(from: dailySunriseTime) {
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
            
        let dailySunsetTime = (dataPointDaily?[indexPath.row].sunset?.value)!
        
//        let dailySunsetString = "\(dailySunsetTime)" // the date string to be parsed
        let df5 = DateFormatter()
        df5.locale = Locale(identifier: "en_US")
        df5.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
        df5.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let hour = df5.date(from: dailySunsetTime) {
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

//
//  HourlyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class HourlyViewController: UIViewController {
    
    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var hourlyTableView: UITableView!
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    let dataPointHourly = WeatherController.shared.weatherbitWeatherHourly
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hourlyTableView.rowHeight = UITableView.automaticDimension
        self.hourlyTableView.estimatedRowHeight = 80
    }

}

//--------------------------------------------------------------------------
// MARK: - TableView Datasource
//--------------------------------------------------------------------------

extension HourlyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (dataPointHourly?.data?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyTableViewCell", for: indexPath) as? HourlyTableViewCell else {
            return UITableViewCell()
        }
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 1)
            
        } else {
            cell.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
        }
        
//        let dataPoint = WeatherController.shared.weather
        
        let time = (dataPointHourly?.data?[indexPath.row].timestampLocal)!
        let dateString = "\(time)" // the date string to be parsed
        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US")
        df1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = df1.date(from: dateString) {
            let format = "EEEE"
            let df2 = DateFormatter()
            df2.dateFormat = format
            let string = df2.string(from: date)
                cell.dayOfWeekLabel.text = string

        } else {
            print("Unable to parse date string")
        }
        
        let hourlyTime = (dataPointHourly?.data?[indexPath.row].timestampLocal)!
        let dailyHourString = "\(hourlyTime)" // the date string to be parsed
        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US")
        df3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
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
        
        if let hourlyTemp = dataPointHourly?.data?[indexPath.row].temp {
            let newHighTemp = String(format: "%.0f", hourlyTemp)
                cell.hourlyTempLabel.text = newHighTemp + "\u{00B0}"
        }
        
        let conditionIcon = dataPointHourly?.data?[indexPath.row].weather?.icon
        let conditionIconString = String(conditionIcon!)
        switch conditionIconString {
        case "t01d", "t02d","t03d":
            cell.conditionIconImage.image = UIImage(named: "t01d")
        case "t01n","t02n", "t03n":
            cell.conditionIconImage.image = UIImage(named: "t01d")
        case "t04d","t05d":
            cell.conditionIconImage.image = UIImage(named: "t04d")
        case "t04n","t05n":
            cell.conditionIconImage.image = UIImage(named: "t04n")
        case "d01d","d02d", "d03d":
            cell.conditionIconImage.image = UIImage(named: "d01d")
        case "d01n","d02n", "d03n":
            cell.conditionIconImage.image = UIImage(named: "d01n")
        case "r01d","r02d", "r03d":
            cell.conditionIconImage.image = UIImage(named: "r01d")
        case "r01n","r02n", "r03n":
            cell.conditionIconImage.image = UIImage(named: "r01n")
        case "f01d","r04d","r05d","r06d":
            cell.conditionIconImage.image = UIImage(named: "f01d")
        case "f01n","r04n","r05n","r06n":
            cell.conditionIconImage.image = UIImage(named: "f01n")
        case "s01d","s02d","s03d","s04d","s05d":
            cell.conditionIconImage.image = UIImage(named: "s01d")
         case "s01n","s02n","s03n","s04n","s05n":
            cell.conditionIconImage.image = UIImage(named: "s01n")
         case "a01d","a02d","a03d","a04d","a05d", "a06d":
            cell.conditionIconImage.image = UIImage(named: "a01d")
        case "a01n","a02n","a03n","a04n","a05n", "a06n":
            cell.conditionIconImage.image = UIImage(named: "a01n")
        case "c01d","c02d","c03d","c04d":
            cell.conditionIconImage.image = UIImage(named: "c01d")
        case "c01n","c02n","c03n","c04n":
            cell.conditionIconImage.image = UIImage(named: "c01n")
        default:
            cell.conditionIconImage.image = UIImage(named: "c01d")
        }
//        let conditionIcon = dataPoint?.hourly?.data?[indexPath.row].icon
//        switch conditionIcon {
//        case "partly-cloudy-day":
//                cell.conditionIconImage.image = UIImage(named: "mostlycloudy.png")
//
//        case "partly-cloudy-night":
//                cell.conditionIconImage.image = UIImage(named: "cloudynight.png")
//
//        case "cloudy":
//                cell.conditionIconImage.image = UIImage(named: "cloudy.png")
//
//        case "clear-day":
//                cell.conditionIconImage.image = UIImage(named: "sunny.png")
//
//        case "clear-night":
//                cell.conditionIconImage.image = UIImage(named: "clearnight.png")
//
//        case "rain":
//                cell.conditionIconImage.image = UIImage(named: "rain.png")
//
//        case "snow":
//                cell.conditionIconImage.image = UIImage(named: "snow.png")
//
//        case "sleet":
//                cell.conditionIconImage.image = UIImage(named: "sleet.png")
//
//        case "wind":
//                cell.conditionIconImage.image = UIImage(named: "wind.png")
//
//        case "fog":
//                cell.conditionIconImage.image = UIImage(named: "fog.png")
//
//        default:
//                cell.conditionIconImage.image = UIImage(named: "default.png")
//
//        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        
        if let precipChance = dataPointHourly?.data?[indexPath.row].precip {
            cell.hourlyPrecipLabel.text = percentFormatter.string(from: precipChance as NSNumber)
        }
        
        if let windBearingIcon = dataPointHourly?.data?[indexPath.row].windDir {
            
            switch windBearingIcon {
            case 0:
                cell.windBearingIcon.image = UIImage(named: "south.png")
            case 1...89:
                cell.windBearingIcon.image = UIImage(named: "southwest.png")
            case 90:
                cell.windBearingIcon.image = UIImage(named: "west.png")
            case 91...179:
                cell.windBearingIcon.image = UIImage(named: "northwest.png")
            case 180:
                cell.windBearingIcon.image = UIImage(named: "north.png")
            case 181...224:
                cell.windBearingIcon.image = UIImage(named: "northeast.png")
            case 225:
                cell.windBearingIcon.image = UIImage(named: "east.png")
            case 226...359:
                cell.windBearingIcon.image = UIImage(named: "southeast.png")
            case 360:
                cell.windBearingIcon.image = UIImage(named: "north.png")
            default:
                cell.windBearingIcon.image = UIImage(named: "north.png")
            }
        }
        
        if let windData = dataPointHourly?.data?[indexPath.row].windSpd {
            cell.hourlyWindLabel.text = String(format: "%.1f", windData)
        }
        
        return cell
    }
    
    
}

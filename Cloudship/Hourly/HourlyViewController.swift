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
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hourlyTableView.rowHeight = UITableView.automaticDimension
        self.hourlyTableView.estimatedRowHeight = 80
    }
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    let dataPointHourly = WeatherController.shared.climacellHourlyWeather

}

//--------------------------------------------------------------------------
// MARK: - TableView Datasource
//--------------------------------------------------------------------------

extension HourlyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (dataPointHourly?.count)!
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
        
        let dataPoint = WeatherController.shared.weather
        
        let time = (dataPointHourly?[indexPath.row].observation_time?.value)!
//        let dateString = "\(time)" // the date string to be parsed
        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US")
        df1.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
        df1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = df1.date(from: time) {
            let format = "EEEE"
            let df2 = DateFormatter()
            df2.dateFormat = format
            let string = df2.string(from: date)
                cell.dayOfWeekLabel.text = string

        } else {
            print("Unable to parse date string")
        }
        
        let hourlyTime = (dataPointHourly?[indexPath.row].observation_time?.value)!
//        let dailyHourString = "\(hourlyTime)" // the date string to be parsed
        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US")
        df3.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
        df3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let hour = df3.date(from: hourlyTime) {
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
        
        if let hourlyTemp = dataPointHourly?[indexPath.row].temp?.value {
            let newHighTemp = String(format: "%.0f", hourlyTemp)
                cell.hourlyTempLabel.text = newHighTemp + "\u{00B0}"
        }
        
        let conditionIcon = dataPointHourly?[indexPath.row].weather_code?.value
        switch conditionIcon {
        case "partly_cloudy":
            cell.conditionIconImage.image = UIImage(named: "mostlycloudy.png")
            
        case "mostly_cloudy":
            cell.conditionIconImage.image = UIImage(named: "mostlycloudy.png")
            
        case "cloudy":
            cell.conditionIconImage.image = UIImage(named: "cloudy.png")
            
        case "clear":
            cell.conditionIconImage.image = UIImage(named: "sunny.png")
        
        case "mostly_clear":
        cell.conditionIconImage.image = UIImage(named: "sunny.png")
            
        case "clear-night":
            cell.conditionIconImage.image = UIImage(named: "clearnight.png")
            
        case "rain":
            cell.conditionIconImage.image = UIImage(named: "rain.png")
            
        case "rain_light":
            cell.conditionIconImage.image = UIImage(named: "rain.png")
            
        case "rain_heavy":
            cell.conditionIconImage.image = UIImage(named: "rain.png")
            
        case "drizzle":
            cell.conditionIconImage.image = UIImage(named: "rain.png")
            
        case "snow_light":
            cell.conditionIconImage.image = UIImage(named: "snow.png")
            
        case "snow":
            cell.conditionIconImage.image = UIImage(named: "snow.png")
            
        case "snow_heavy":
            cell.conditionIconImage.image = UIImage(named: "snow.png")
            
        case "flurries":
        cell.conditionIconImage.image = UIImage(named: "snow.png")
            
        case "freezing_rain":
            cell.conditionIconImage.image = UIImage(named: "sleet.png")
            
        case "wind":
            cell.conditionIconImage.image = UIImage(named: "wind.png")
            
        case "fog":
            cell.conditionIconImage.image = UIImage(named: "fog.png")
        
        case "fog_light":
        cell.conditionIconImage.image = UIImage(named: "fog.png")
            
        default:
            cell.conditionIconImage.image = UIImage(named: "default.png")
            
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        
        if let precipChance = dataPointHourly?[indexPath.row].precipitation_probability?.value {
            cell.hourlyPrecipLabel.text = String(format: "%.0f", precipChance) + "%"
        }
        
        if let windBearingIcon = dataPointHourly?[indexPath.row].wind_direction?.value {
            
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
        
        if let windData = dataPointHourly?[indexPath.row].wind_speed?.value {
            cell.hourlyWindLabel.text = String(format: "%.1f", windData)
        }
        
        return cell
    }
    
    
}

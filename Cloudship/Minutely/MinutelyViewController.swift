//
//  MinutelyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/21/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class MinutelyViewController: UIViewController {
    
    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var minutelyTableView: UITableView!
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.minutelyTableView.rowHeight = UITableView.automaticDimension
        self.minutelyTableView.estimatedRowHeight = 80
    }
    

}

//--------------------------------------------------------------------------
// MARK: - TableView Data Source
//--------------------------------------------------------------------------
extension MinutelyViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (WeatherController.shared.weather?.minutely?.data?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MinutelyTableViewCell", for: indexPath) as? MinutelyTableViewCell else {
            return UITableViewCell()
        }
        
        let dataPoint = WeatherController.shared.weather
        
        let minutelyTime = NSDate(timeIntervalSince1970: (dataPoint?.hourly?.data?[indexPath.row].time)!)
        let minutelyMinuteString = "\(minutelyTime)" // the date string to be parsed
        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US")
        df3.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        if let hour = df3.date(from: minutelyMinuteString) {
            let format = "ha"
            let df4 = DateFormatter()
            df4.dateFormat = format
            df4.amSymbol = "AM"
            df4.pmSymbol = "PM"
            let string = df4.string(from: hour)
            DispatchQueue.main.async {
                cell.minutelyMinuteLabel.text = string
            }
        } else {
            print("Unable to parse date string")
        }
        
        return cell
    }
    

}

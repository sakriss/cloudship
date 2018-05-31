//
//  MinutelyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/21/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class MinutelyViewController: UIViewController {
    
    @IBOutlet weak var minutelyTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.minutelyTableView.rowHeight = UITableViewAutomaticDimension
        self.minutelyTableView.estimatedRowHeight = 80
    }
    

}

extension MinutelyViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (WeatherController.shared.weather?.minutely?.data?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MinutelyTableViewCell", for: indexPath) as? MinutelyTableViewCell else {
            return UITableViewCell()
        }
        
        let dataPoint = WeatherController.shared.weather
        
        
        return cell
    }
    

}

//
//  ViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var currentTempLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataFetched) , name: WeatherController.weatherDataParseComplete, object: nil)
        WeatherController.shared.fetchWeatherInfo()

    }
    
    @objc func weatherDataFetched () {
        //do something amazing
        print("We should be getting the weather array back here, please!!!!!!")
        print(WeatherController.shared.weatherArray)
        
        print("Here is your current temp")
        print(WeatherController.shared.weather?.currently?.temperature)
        DispatchQueue.main.async {
            self.currentTempLabel.text = String(describing: WeatherController.shared.weather?.currently?.temperature)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


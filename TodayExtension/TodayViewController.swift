//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Scott Kriss on 9/14/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var conditionIcon: UIImageView!
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    
    private let sharedDefaults = UserDefaults(suiteName: "group.happygiraffe.Cloudship-test")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentTemp = sharedDefaults?.string(forKey: "currentTemp") {
            currentTempLabel.text = currentTemp
        }
        
        if let currentSummary = sharedDefaults?.string(forKey: "currentSummary"){
            summaryLabel.text = currentSummary
        }
        
            let conditionIcon = sharedDefaults?.string(forKey: "currentIcon")
            switch conditionIcon {
            case "partly-cloudy-day":
                self.conditionIcon.image = UIImage(named: "mostlycloudy.png")
                
            case "partly-cloudy-night":
                self.conditionIcon.image = UIImage(named: "cloudynight.png")

            case "cloudy":
                self.conditionIcon.image = UIImage(named: "cloudy.png")
                
            case "clear-day":
                self.conditionIcon.image = UIImage(named: "sunny.png")
                
            case "clear-night":
                self.conditionIcon.image = UIImage(named: "clearnight.png")
                
            case "rain":
                self.conditionIcon.image = UIImage(named: "rain.png")
                
            case "snow":
                self.conditionIcon.image = UIImage(named: "snow.png")
                
            case "sleet":
                self.conditionIcon.image = UIImage(named: "sleet.png")
                
            case "wind":
                self.conditionIcon.image = UIImage(named: "wind.png")
                
            case "fog":
                self.conditionIcon.image = UIImage(named: "fog.png")
                
            default:
               self.conditionIcon.image = UIImage(named: "default.png")
                
            }
//            conditionIcon.image = UIImage(named: currentIconName)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        if let currentTemp = sharedDefaults?.string(forKey: "currentTemp") {
            currentTempLabel.text = currentTemp
        }
        
        let conditionIcon = sharedDefaults?.string(forKey: "currentIcon")
        switch conditionIcon {
        case "partly-cloudy-day":
            self.conditionIcon.image = UIImage(named: "mostlycloudy.png")
            
        case "partly-cloudy-night":
            self.conditionIcon.image = UIImage(named: "cloudynight.png")
            
        case "cloudy":
            self.conditionIcon.image = UIImage(named: "cloudy.png")
            
        case "clear-day":
            self.conditionIcon.image = UIImage(named: "sunny.png")
            
        case "clear-night":
            self.conditionIcon.image = UIImage(named: "clearnight.png")
            
        case "rain":
            self.conditionIcon.image = UIImage(named: "rain.png")
            
        case "snow":
            self.conditionIcon.image = UIImage(named: "snow.png")
            
        case "sleet":
            self.conditionIcon.image = UIImage(named: "sleet.png")
            
        case "wind":
            self.conditionIcon.image = UIImage(named: "wind.png")
            
        case "fog":
            self.conditionIcon.image = UIImage(named: "fog.png")
            
        default:
            self.conditionIcon.image = UIImage(named: "default.png")
            
        }
        
//        if let currentIcon = sharedDefaults?.string(forKey: "currentIcon") {
//            let currentIconName = currentIcon + ".png"
//            conditionIcon.image = UIImage(named: currentIconName)
//        }
        
        
        completionHandler(NCUpdateResult.newData)
    }
    
}

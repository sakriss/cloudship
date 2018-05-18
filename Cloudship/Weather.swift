//
//  Weather.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class Weather: Codable {
    private(set) var latitude: Double? = 0.0
    private(set) var longitude: Double? = 0.0
    private(set) var timezone: String? = ""
    private(set) var offset: Double? = 0.0
    
    private(set) var currently: Currently?
    private(set) var minutely: Minutely?
    private(set) var hourly: Hourly?
    private(set) var daily: Daily?
    //private(set) var flags: Flags?
    

}

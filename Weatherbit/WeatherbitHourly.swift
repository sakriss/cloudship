//
//  WeatherbitHourly.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitHourly: Codable {
    let cityName : String?
    let countryCode : String?
    let data : [WeatherbitHourlyData]?
    let lat : Double?
    let lon : Double?
    let stateCode : String?
    let timezone : String?
}

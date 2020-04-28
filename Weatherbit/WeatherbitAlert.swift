//
//  WeatherbitAlert.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/22/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitAlert: Codable {
    
    let alerts : [WeatherbitAlertsData]?
    let cityName : String?
    let countryCode : String?
    let lat : Double?
    let lon : Double?
    let stateCode : String?
    let timezone : String?
    
    enum CodingKeys: String, CodingKey {
        case alerts = "alerts"
        case cityName = "city_name"
        case countryCode = "country_code"
        case lat = "lat"
        case lon = "lon"
        case stateCode = "state_code"
        case timezone = "timezone"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        alerts = try values.decodeIfPresent([WeatherbitAlertsData].self, forKey: .alerts)
        cityName = try values.decodeIfPresent(String.self, forKey: .cityName)
        countryCode = try values.decodeIfPresent(String.self, forKey: .countryCode)
        lat = try values.decodeIfPresent(Double.self, forKey: .lat)
        lon = try values.decodeIfPresent(Double.self, forKey: .lon)
        stateCode = try values.decodeIfPresent(String.self, forKey: .stateCode)
        timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
    }
    
}

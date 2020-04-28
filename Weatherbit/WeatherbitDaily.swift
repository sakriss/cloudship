//
//  WeatherbitDaily.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitDaily: Codable {
    let cityName : String?
    let countryCode : String?
    let data : [WeatherbitDailyData]?
    let lat : Double?
    let lon : Double?
    let stateCode : String?
    let timezone : String?
    
    enum CodingKeys: String, CodingKey {
                case cityName = "city_name"
                case countryCode = "country_code"
                case data = "data"
                case lat = "lat"
                case lon = "lon"
                case stateCode = "state_code"
                case timezone = "timezone"
        }
    
//    required init(from decoder: Decoder) throws {
//                let values = try decoder.container(keyedBy: CodingKeys.self)
//                cityName = try values.decodeIfPresent(String.self, forKey: .cityName)
//                countryCode = try values.decodeIfPresent(String.self, forKey: .countryCode)
//                data = try values.decodeIfPresent([WeatherbitDailyData].self, forKey: .data)
//                lat = try values.decodeIfPresent(Double.self, forKey: .lat)
//                lon = try values.decodeIfPresent(Double.self, forKey: .lon)
//                stateCode = try values.decodeIfPresent(String.self, forKey: .stateCode)
//                timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
//        }
}

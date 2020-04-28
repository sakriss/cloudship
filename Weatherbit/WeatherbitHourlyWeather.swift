//
//  WeatherbitHourlyWeather.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/27/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitHourlyWeather: Codable {
    let code : Int?
    let descriptionField : String?
    let icon : String?
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case descriptionField = "description"
        case icon = "icon"
    }
    
//    required init(from decoder: Decoder) throws {
//        
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        code = try values.decodeIfPresent(Int.self, forKey: .code)
//        descriptionField = try values.decodeIfPresent(String.self, forKey: .descriptionField)
//        icon = try values.decodeIfPresent(String.self, forKey: .icon)
//    }
}

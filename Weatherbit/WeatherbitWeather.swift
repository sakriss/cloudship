//
//  WeatherbitWeather.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitWeather: Codable {
    let code : String?
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
//        code = try values.decodeIfPresent(String.self, forKey: .code)
//        descriptionField = try values.decodeIfPresent(String.self, forKey: .descriptionField)
//        icon = try values.decodeIfPresent(String.self, forKey: .icon)
//    }

        //            if let stringProperty = try values.decodeIfPresent(String.self, forKey: .descriptionField) {
        //                self = .stringProperty
        //            } else if let doubleProperty = try values.decodeIfPresent(DoubleValue.self, forKey: .descriptionField) {
        //                descriptionField = doubleProperty
        //            } else {
        //                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath, debugDescription: "Not a JSON"))
        //            }
    
    
//    enum DescriptionField: Codable {
//        case string(String)
//        case double(DoubleThingy)
//
//        init(from decoder: Decoder) throws {
//            let container = try decoder.singleValueContainer()
//            if let x = try? container.decode(String.self) {
//                self = .string(x)
//                return
//            }
//            if let x = try? container.decode(DoubleThingy.self) {
//                self = .double(x)
//                return
//            }
//            throw DecodingError.typeMismatch(DescriptionField.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Description"))
//        }
//
//        func encode(to encoder: Encoder) throws {
//            var container = encoder.singleValueContainer()
//            switch self {
//            case .string(let x):
//                try container.encode(x)
//            case .double(let x):
//                try container.encode(x)
//            }
//        }
//
//        struct DoubleThingy: Codable{
//            let descriptionField: Double?
//        }
//    }
}

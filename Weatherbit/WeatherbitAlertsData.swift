//
//  WeatherbitAlertsData.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/22/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitAlertsData: Codable {
    
    let descriptionField : String?
    let effectiveLocal : String?
    let effectiveUtc : String?
    let expiresLocal : String?
    let expiresUtc : String?
    let regions : [String]?
    let severity : String?
    let title : String?
    let uri : String?
    
    enum CodingKeys: String, CodingKey {
        case descriptionField = "description"
        case effectiveLocal = "effective_local"
        case effectiveUtc = "effective_utc"
        case expiresLocal = "expires_local"
        case expiresUtc = "expires_utc"
        case regions = "regions"
        case severity = "severity"
        case title = "title"
        case uri = "uri"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        descriptionField = try values.decodeIfPresent(String.self, forKey: .descriptionField)
        effectiveLocal = try values.decodeIfPresent(String.self, forKey: .effectiveLocal)
        effectiveUtc = try values.decodeIfPresent(String.self, forKey: .effectiveUtc)
        expiresLocal = try values.decodeIfPresent(String.self, forKey: .expiresLocal)
        expiresUtc = try values.decodeIfPresent(String.self, forKey: .expiresUtc)
        regions = try values.decodeIfPresent([String].self, forKey: .regions)
        severity = try values.decodeIfPresent(String.self, forKey: .severity)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        uri = try values.decodeIfPresent(String.self, forKey: .uri)
    }
}

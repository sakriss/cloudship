//
//  Configuration.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/31/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import Foundation

//setting the URL for the API
struct API {
    
    static let APIKey = "f7bc7a2bca5a3df8d3492ec37f730f60"
    static let BaseURL = URL(string: "https://api.darksky.net/forecast/")!
    
    static var AuthenticatedBaseURL: URL {
        return BaseURL.appendingPathComponent(APIKey)
    }
}

// Setting default location for testing
struct Defaults {
    
    static let Latitude: Double = 47.3452
    static let Longitude: Double = -122.3124
    
}

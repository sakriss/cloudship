//
//  HourlyData.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class HourlyData: Codable {
    private(set) var time: Date?
    private(set) var summary: String?
    private(set) var icon: String?
    private(set) var precipIntensity: Double?
    private(set) var precipProbability: Double?
    private(set) var precipType: String?
    private(set) var temperature: Double?
    private(set) var apparentTemperature: Double?
    private(set) var dewPoint: Double?
    private(set) var humidity: Double?
    private(set) var pressure: Double?
    private(set) var windSpeed: Double?
    private(set) var windGust: Double?
    private(set) var windBearing: Double?
    private(set) var cloudCover: Double?
    private(set) var uvIndex: Double?
    private(set) var visibility: Double?
    private(set) var ozone: Double?
    
    
}

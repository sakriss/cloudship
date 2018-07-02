//
//  DailyData.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class DailyData: Codable {
    private(set) var time: Double?
    private(set) var summary: String?
    private(set) var icon: String?
    private(set) var sunriseTime: Double?
    private(set) var sunsetTime: Double?
    private(set) var moonPhase: Double?
    private(set) var precipIntensity: Double?
    private(set) var precipIntensityMax: Double?
    private(set) var precipIntensityMaxTime: Date?
    private(set) var precipProbability: Double?
    private(set) var precipType: String?
    private(set) var temperatureHigh: Double?
    private(set) var temperatureHighTime: Date?
    private(set) var temperatureLow: Double?
    private(set) var temperatureLowTime: Date?
    private(set) var apparentTemperatureHigh: Double?
    private(set) var apparentTemperatureHighTime: Date?
    private(set) var apparentTemperatureLow: Double?
    private(set) var apparentTemperatureLowTime: Date?
    private(set) var dewPoint: Double?
    private(set) var humidity: Double?
    private(set) var pressure: Double?
    private(set) var windSpeed: Double?
    private(set) var windGust: Double?
    private(set) var windGustTime: Date?
    private(set) var windBearing: Double?
    private(set) var cloudCover: Double?
    private(set) var uvIndex: Double?
    private(set) var uvIndexTime: Date?
    private(set) var visibility: Double?
    private(set) var ozone: Double?
    private(set) var temperatureMin: Double?
    private(set) var temperatureMinTime: Date?
    private(set) var temperatureMax: Double?
    private(set) var temperatureMaxTime: Date?
    private(set) var apparentTemperatureMin: Double?
    private(set) var apparentTemperatureMinTime: Date?
    private(set) var apparentTemperatureMax: Double?
    private(set) var apparentTemperatureMaxTime: Date?
    
}

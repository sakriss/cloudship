//
//  ClimacellV4.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/21.
//  Copyright © 2021 Scott Kriss. All rights reserved.
//

import Foundation

import UIKit

// MARK: - ClimacellV4
class ClimacellV4: Codable {
    let data: DataClass?

    init(data: DataClass?) {
        self.data = data
    }
}

// MARK: - DataClass
class DataClass: Codable {
    let timelines: [Timeline]?

    init(timelines: [Timeline]?) {
        self.timelines = timelines
    }
}

// MARK: - Timeline
class Timeline: Codable {
    let timestep: String?
    let startTime, endTime: String?
    let intervals: [Interval]?

    init(timestep: String?, startTime: String?, endTime: String?, intervals: [Interval]?) {
        self.timestep = timestep
        self.startTime = startTime
        self.endTime = endTime
        self.intervals = intervals
    }
}

// MARK: - Interval
class Interval: Codable {
    let startTime: String?
    let values: Values?

    init(startTime: String?, values: Values?) {
        self.startTime = startTime
        self.values = values
    }
}

// MARK: - Values
class Values: Codable {
    let precipitationIntensity: Double?
    let temperature, humidity, windSpeed, windDirection: Double?
    let precipitationProbability, precipitationType: Double?
    let sunriseTime, sunsetTime: String?
    let cloudCover: Double?
    let weatherCode: Int?

    init(precipitationIntensity: Double?, temperature: Double?, humidity: Double?, windSpeed: Double?, windDirection: Double?, precipitationProbability: Double?, precipitationType: Double?, sunriseTime: String?, sunsetTime: String?, cloudCover: Double?, weatherCode: Int?) {
        self.precipitationIntensity = precipitationIntensity
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.precipitationProbability = precipitationProbability
        self.precipitationType = precipitationType
        self.sunriseTime = sunriseTime
        self.sunsetTime = sunsetTime
        self.cloudCover = cloudCover
        self.weatherCode = weatherCode
    }
}

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
//struct ClimacellV4: Codable {
//    let data: DataClass?
//}
//
//// MARK: - DataClass
//struct DataClass: Codable {
//    let timelines: [Timeline]?
//}
//
//// MARK: - Timeline
//struct Timeline: Codable {
//    let timestep: String?
//    let startTime, endTime: String?
//    let intervals: [Interval]?
//}
//
//// MARK: - Interval
//struct Interval: Codable {
//    let startTime: String?
//    let values: Values?
//}
//
//// MARK: - Values
//struct Values: Codable {
//    let precipitationIntensity: Double?
//    let temperature,temperatureMax, temperatureMin, humidity, windSpeed, windDirection: Double?
//    let precipitationProbability, precipitationType: Double?
//    let sunriseTime, sunsetTime: String?
//    let cloudCover: Double?
//    let weatherCode: Int?
//}

struct ClimacellV4: Codable {
    let realtime: RealtimeWeather?
    let forecast: ForecastResponse? // Add the forecast property here

    struct RealtimeWeather: Codable {
        let time: String
        let values: RealtimeValues
        let location: Location
    }

    struct ForecastResponse: Codable {
        let time: String
        let values: ForecastValues
        let location: Location
    }

    struct RealtimeValues: Codable {
        let cloudBase: Double?
        let cloudCeiling: Double?
        let cloudCover: Int?
        let dewPoint: Double?
        let freezingRainIntensity: Double?
        let humidity: Int?
        let precipitationProbability: Int?
        let pressureSurfaceLevel: Double?
        let rainIntensity: Double?
        let sleetIntensity: Double?
        let snowIntensity: Double?
        let temperature: Double?
        let temperatureApparent: Double?
        let uvHealthConcern: Int?
        let uvIndex: Int?
        let visibility: Double?
        let weatherCode: Int?
        let windDirection: Double?
        let windGust: Double?
        let windSpeed: Double?
    }

    struct ForecastValues: Codable {
        let cloudBase: Double
        let cloudCeiling: Double
        let cloudCover: Int
        let dewPoint: Double
        let freezingRainIntensity: Double
        let humidity: Int
        let precipitationProbability: Int
        let pressureSurfaceLevel: Double
        let rainIntensity: Double
        let sleetIntensity: Double
        let snowIntensity: Double
        let temperature: Double
        let temperatureApparent: Double
        let uvHealthConcern: Int
        let uvIndex: Int
        let visibility: Double
        let weatherCode: Int
        let windDirection: Double
        let windGust: Double
        let windSpeed: Double
    }

    struct Location: Codable {
        let lat: Double
        let lon: Double
    }
}

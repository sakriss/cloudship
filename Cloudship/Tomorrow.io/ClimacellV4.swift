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

// Realtime endpoint: { "data": { "time": ..., "values": ... }, "location": { ... } }
struct ClimacellV4: Codable {
    let data: RealtimeWeather?
    let location: Location?

    // Convenience accessor so existing ViewController code keeps working
    var realtime: RealtimeWeather? { data }

    struct RealtimeWeather: Codable {
        let time: String
        let values: RealtimeValues
    }

    // Forecast endpoint: { "timelines": { "hourly": [...], "daily": [...] }, "location": { ... } }
    struct ForecastResponse: Codable {
        let timelines: ForecastTimelines?
        let location: Location?
    }

    struct ForecastTimelines: Codable {
        let minutely: [ForecastEntry]?
        let hourly: [ForecastEntry]?
        let daily: [ForecastEntry]?
    }

    struct ForecastEntry: Codable {
        let time: String?
        let values: ForecastValues?
    }

    struct RealtimeValues: Codable {
        let cloudBase: Double?
        let cloudCeiling: Double?
        let cloudCover: Double?
        let dewPoint: Double?
        let freezingRainIntensity: Double?
        let humidity: Double?
        let precipitationProbability: Double?
        let pressureSurfaceLevel: Double?
        let rainIntensity: Double?
        let sleetIntensity: Double?
        let snowIntensity: Double?
        let temperature: Double?
        let temperatureApparent: Double?
        let uvHealthConcern: Double?
        let uvIndex: Double?
        let visibility: Double?
        let weatherCode: Int?
        let windDirection: Double?
        let windGust: Double?
        let windSpeed: Double?
        // Air quality (may be absent for some locations/plans)
        let epaIndex: Int?
        let epaHealthConcern: Int?
        // Pollen (realtime)
        let treeIndex: Int?
        let grassIndex: Int?
        let weedIndex: Int?
    }

    struct ForecastValues: Codable {
        let cloudBase: Double?
        let cloudCeiling: Double?
        let cloudCover: Double?
        let dewPoint: Double?
        let freezingRainIntensity: Double?
        let humidity: Double?
        let precipitationProbability: Double?          // hourly
        let precipitationProbabilityAvg: Double?       // daily
        let rainAccumulationSum: Double?               // daily total rain
        let pressureSurfaceLevel: Double?
        let rainIntensity: Double?
        let sleetIntensity: Double?
        let snowIntensity: Double?
        let temperature: Double?
        let temperatureApparent: Double?
        let temperatureApparentMin: Double?
        let temperatureApparentMax: Double?
        let temperatureMax: Double?
        let temperatureMin: Double?
        let uvHealthConcern: Double?
        let uvIndex: Double?
        let visibility: Double?
        let weatherCode: Int?          // hourly
        let weatherCodeAvg: Int?       // daily average
        let weatherCodeMax: Int?       // daily max (most severe)
        let weatherCodeDay: Int?       // reserved / future
        let weatherCodeNight: Int?     // reserved / future
        let windDirection: Double?
        let windGust: Double?
        let windSpeed: Double?
        // Sun / Moon (daily timeline)
        let sunriseTime: String?
        let sunsetTime: String?
        let moonPhase: Double?
        // Pollen (daily)
        let treeIndex: Int?
        let grassIndex: Int?
        let weedIndex: Int?
    }

    struct Location: Codable {
        let lat: Double
        let lon: Double
    }
}

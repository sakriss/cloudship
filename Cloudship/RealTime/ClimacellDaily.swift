////
////  Climacell.swift
////  Cloudship
////
////  Created by Scott Kriss on 4/10/20.
////  Copyright © 2020 Scott Kriss. All rights reserved.
////
//
//import Foundation
//
//class ClimaWeatherDailyElement: Codable {
//    
//    let temp: [Temp]
//    let humidity: [Humidity]
//    let precipitationProbability: PrecipitationProbability
//    let humidity, windSpeed, windDirection: [Humidity]
//    let sunrise, sunset, weatherCode, observationTime: ObservationTime
//    let lat, lon: Double
//    
//    enum CodingKeys: String, CodingKey {
//        case temp
//        case precipitationProbability
//        case humidity
//        case windSpeed
//        case windDirection
//        case sunrise, sunset
//        case weatherCode
//        case observationTime
//        case lat, lon
//    }
//    
//    init(temp: [Humidity], precipitationProbability: PrecipitationProbability, humidity: [Humidity], windSpeed: [Humidity], windDirection: [Humidity], sunrise: ObservationTime, sunset: ObservationTime, weatherCode: ObservationTime, observationTime: ObservationTime, lat: Double, lon: Double) {
//        self.temp = temp
//        self.precipitationProbability = precipitationProbability
//        self.humidity = humidity
//        self.windSpeed = windSpeed
//        self.windDirection = windDirection
//        self.sunrise = sunrise
//        self.sunset = sunset
//        self.weatherCode = weatherCode
//        self.observationTime = observationTime
//        self.lat = lat
//        self.lon = lon
//    }
//}
//
//// MARK: - Temp
//class Temp: Codable {
//    let max : Max?
//    let min : Min?
//    let observationTime : String?
//
//    enum CodingKeys: String, CodingKey {
//            case observationTime
//            case min, max
//        }
//
//        init(observationTime: ObservationTime, min: Max?, max: Max?) {
//            self.observationTime = observationTime
//            self.min = min
//            self.max = max
//        }
//}
//
//// MARK: - Humidity
//class Humidity: Codable {
//    let observationTime: Date
//    let min, max: PrecipitationProbability?
//    
//    enum CodingKeys: String, CodingKey {
//        case observationTime
//        case min, max
//    }
//    
//    init(observationTime: Date, min: PrecipitationProbability?, max: PrecipitationProbability?) {
//        self.observationTime = observationTime
//        self.min = min
//        self.max = max
//    }
//}
//
//// MARK: - PrecipitationProbability
//class PrecipitationProbability: Codable {
//    let value: Double
//    let units: Units
//    
//    init(value: Double, units: Units) {
//        self.value = value
//        self.units = units
//    }
//}
//
//enum Units: String, Codable {
//    case degrees = "degrees"
//    case empty = "%"
//    case f = "F"
//    case mph = "mph"
//}
//
//// MARK: - ObservationTime
//class ObservationTime: Codable {
//    let value: String
//    
//    init(value: String) {
//        self.value = value
//    }
//}
//class Min: Codable {
//    let units : String?
//    let value : Double?
//    
//    enum CodingKeys: String, CodingKey {
//        case units = "units"
//        case value = "value"
//    }
//    
//    init(units: String, value: Double)  {
//        self.units = units
//        self.value = value
//    }
//}
//
//class Max: Codable {
//    let units : String?
//    let value : Double?
//    
//    enum CodingKeys: String, CodingKey {
//        case units = "units"
//        case value = "value"
//    }
//    
//    init(units: String, value: Double)  {
//        self.units = units
//        self.value = value
//    }
//}
////    let lon, lat: Double
////    let temp: Temp
////    let observationTime: ObservationTime
////
////    enum CodingKeys: String, CodingKey {
////        case lon, lat, temp
////        case observationTime = "observation_time"
////    }
////
////    init(lon: Double, lat: Double, temp: Temp, observationTime: ObservationTime) {
////        self.lon = lon
////        self.lat = lat
////        self.temp = temp
////        self.observationTime = observationTime
////    }
////}
////
////// MARK: - ObservationTime
////class ObservationTime: Codable {
////    let value: String
////
////    init(value: String) {
////        self.value = value
////    }
////}
////
////// MARK: - Temp
////class Temp: Codable {
////    let value: Double
////    let units: String
////
////    init(value: Double, units: String) {
////        self.value = value
////        self.units = units
////    }
////}
//
////enum Units: Codable {
////    let units: String
//////    case f = "F"
////}
//
//typealias Welcome = [ClimaWeatherDailyElement]

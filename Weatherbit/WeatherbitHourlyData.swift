//
//  WeatherbitHourlyData.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitHourlyData: Codable {
    
    let appTemp : Double?
    let clouds : Double?
    let cloudsHi : Double?
    let cloudsLow : Double?
    let cloudsMid : Double?
    let datetime : String?
    let dewpt : Double?
    let dhi : Double?
    let dni : Double?
    let ghi : Double?
    let ozone : Double?
    let pod : String?
    let pop : Double?
    let precip : Double?
    let pres : Double?
    let rh : Double?
    let slp : Double?
    let snow : Double?
    let snowDepth : Double?
    let solarRad : Double?
    let temp : Double?
    let timestampLocal : String?
    let timestampUtc : String?
    let ts : Double?
    let uv : Double?
    let vis : Double?
    let weather : WeatherbitHourlyWeather?
    let windCdir : String?
    let windCdirFull : String?
    let windDir : Double?
    let windGustSpd : Double?
    let windSpd : Double?
    
    enum CodingKeys: String, CodingKey {
        case appTemp = "app_temp"
        case clouds = "clouds"
        case cloudsHi = "clouds_hi"
        case cloudsLow = "clouds_low"
        case cloudsMid = "clouds_mid"
        case datetime = "datetime"
        case dewpt = "dewpt"
        case dhi = "dhi"
        case dni = "dni"
        case ghi = "ghi"
        case ozone = "ozone"
        case pod = "pod"
        case pop = "pop"
        case precip = "precip"
        case pres = "pres"
        case rh = "rh"
        case slp = "slp"
        case snow = "snow"
        case snowDepth = "snow_depth"
        case solarRad = "solar_rad"
        case temp = "temp"
        case timestampLocal = "timestamp_local"
        case timestampUtc = "timestamp_utc"
        case ts = "ts"
        case uv = "uv"
        case vis = "vis"
        case weather = "weather"
        case windCdir = "wind_cdir"
        case windCdirFull = "wind_cdir_full"
        case windDir = "wind_dir"
        case windGustSpd = "wind_gust_spd"
        case windSpd = "wind_spd"
    }
    
//    required init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        appTemp = try values.decodeIfPresent(Double.self, forKey: .appTemp)
//        clouds = try values.decodeIfPresent(Double.self, forKey: .clouds)
//        cloudsHi = try values.decodeIfPresent(Double.self, forKey: .cloudsHi)
//        cloudsLow = try values.decodeIfPresent(Double.self, forKey: .cloudsLow)
//        cloudsMid = try values.decodeIfPresent(Double.self, forKey: .cloudsMid)
//        datetime = try values.decodeIfPresent(String.self, forKey: .datetime)
//        dewpt = try values.decodeIfPresent(Double.self, forKey: .dewpt)
//        dhi = try values.decodeIfPresent(Double.self, forKey: .dhi)
//        dni = try values.decodeIfPresent(Double.self, forKey: .dni)
//        ghi = try values.decodeIfPresent(Double.self, forKey: .ghi)
//        ozone = try values.decodeIfPresent(Double.self, forKey: .ozone)
//        pod = try values.decodeIfPresent(String.self, forKey: .pod)
//        pop = try values.decodeIfPresent(Double.self, forKey: .pop)
//        precip = try values.decodeIfPresent(Double.self, forKey: .precip)
//        pres = try values.decodeIfPresent(Double.self, forKey: .pres)
//        rh = try values.decodeIfPresent(Double.self, forKey: .rh)
//        slp = try values.decodeIfPresent(Double.self, forKey: .slp)
//        snow = try values.decodeIfPresent(Double.self, forKey: .snow)
//        snowDepth = try values.decodeIfPresent(Double.self, forKey: .snowDepth)
//        solarRad = try values.decodeIfPresent(Double.self, forKey: .solarRad)
//        temp = try values.decodeIfPresent(Double.self, forKey: .temp)
//        timestampLocal = try values.decodeIfPresent(String.self, forKey: .timestampLocal)
//        timestampUtc = try values.decodeIfPresent(String.self, forKey: .timestampUtc)
//        ts = try values.decodeIfPresent(Double.self, forKey: .ts)
//        uv = try values.decodeIfPresent(Double.self, forKey: .uv)
//        vis = try values.decodeIfPresent(Double.self, forKey: .vis)
//        weather = try WeatherbitHourlyWeather(from: decoder)
//        windCdir = try values.decodeIfPresent(String.self, forKey: .windCdir)
//        windCdirFull = try values.decodeIfPresent(String.self, forKey: .windCdirFull)
//        windDir = try values.decodeIfPresent(Double.self, forKey: .windDir)
//        windGustSpd = try values.decodeIfPresent(Double.self, forKey: .windGustSpd)
//        windSpd = try values.decodeIfPresent(Double.self, forKey: .windSpd)
//    }
    
}

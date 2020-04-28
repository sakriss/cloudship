//
//  WeatherbitDailyData.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitDailyData: Codable {
    let appMaxTemp : Double?
    let appMinTemp : Double?
    let clouds : Double?
    let cloudsHi : Double?
    let cloudsLow : Double?
    let cloudsMid : Double?
    let datetime : String?
    let dewpt : Double?
    let highTemp : Double?
    let lowTemp : Double?
    let maxDhi : String?
    let maxTemp : Double?
    let minTemp : Double?
    let moonPhase : Double?
    let moonPhaseLunation : Double?
    let moonriseTs : Double?
    let moonsetTs : Double?
    let ozone : Double?
    let pop : Double?
    let precip : Double?
    let pres : Double?
    let rh : Double?
    let slp : Double?
    let snow : Double?
    let snowDepth : Double?
    let sunriseTs : Double?
    let sunsetTs : Double?
    let temp : Double?
    let ts : Double?
    let uv : Double?
    let validDate : String?
    let vis : Double?
    let weather : WeatherbitDailyWeather?
    let windCdir : String?
    let windCdirFull : String?
    let windDir : Double?
    let windGustSpd : Double?
    let windSpd : Double?
    
    enum CodingKeys: String, CodingKey {
        case appMaxTemp = "app_max_temp"
        case appMinTemp = "app_min_temp"
        case clouds = "clouds"
        case cloudsHi = "clouds_hi"
        case cloudsLow = "clouds_low"
        case cloudsMid = "clouds_mid"
        case datetime = "datetime"
        case dewpt = "dewpt"
        case highTemp = "high_temp"
        case lowTemp = "low_temp"
        case maxDhi = "max_dhi"
        case maxTemp = "max_temp"
        case minTemp = "min_temp"
        case moonPhase = "moon_phase"
        case moonPhaseLunation = "moon_phase_lunation"
        case moonriseTs = "moonrise_ts"
        case moonsetTs = "moonset_ts"
        case ozone = "ozone"
        case pop = "pop"
        case precip = "precip"
        case pres = "pres"
        case rh = "rh"
        case slp = "slp"
        case snow = "snow"
        case snowDepth = "snow_depth"
        case sunriseTs = "sunrise_ts"
        case sunsetTs = "sunset_ts"
        case temp = "temp"
        case ts = "ts"
        case uv = "uv"
        case validDate = "valid_date"
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
//        appMaxTemp = try values.decodeIfPresent(Double.self, forKey: .appMaxTemp)
//        appMinTemp = try values.decodeIfPresent(Double.self, forKey: .appMinTemp)
//        clouds = try values.decodeIfPresent(Double.self, forKey: .clouds)
//        cloudsHi = try values.decodeIfPresent(Double.self, forKey: .cloudsHi)
//        cloudsLow = try values.decodeIfPresent(Double.self, forKey: .cloudsLow)
//        cloudsMid = try values.decodeIfPresent(Double.self, forKey: .cloudsMid)
//        datetime = try values.decodeIfPresent(String.self, forKey: .datetime)
//        dewpt = try values.decodeIfPresent(Double.self, forKey: .dewpt)
//        highTemp = try values.decodeIfPresent(Double.self, forKey: .highTemp)
//        lowTemp = try values.decodeIfPresent(Double.self, forKey: .lowTemp)
//        maxDhi = try values.decodeIfPresent(String.self, forKey: .maxDhi)
//        maxTemp = try values.decodeIfPresent(Double.self, forKey: .maxTemp)
//        minTemp = try values.decodeIfPresent(Double.self, forKey: .minTemp)
//        moonPhase = try values.decodeIfPresent(Double.self, forKey: .moonPhase)
//        moonPhaseLunation = try values.decodeIfPresent(Double.self, forKey: .moonPhaseLunation)
//        moonriseTs = try values.decodeIfPresent(Double.self, forKey: .moonriseTs)
//        moonsetTs = try values.decodeIfPresent(Double.self, forKey: .moonsetTs)
//        ozone = try values.decodeIfPresent(Double.self, forKey: .ozone)
//        pop = try values.decodeIfPresent(Double.self, forKey: .pop)
//        precip = try values.decodeIfPresent(Double.self, forKey: .precip)
//        pres = try values.decodeIfPresent(Double.self, forKey: .pres)
//        rh = try values.decodeIfPresent(Double.self, forKey: .rh)
//        slp = try values.decodeIfPresent(Double.self, forKey: .slp)
//        snow = try values.decodeIfPresent(Double.self, forKey: .snow)
//        snowDepth = try values.decodeIfPresent(Double.self, forKey: .snowDepth)
//        sunriseTs = try values.decodeIfPresent(Double.self, forKey: .sunriseTs)
//        sunsetTs = try values.decodeIfPresent(Double.self, forKey: .sunsetTs)
//        temp = try values.decodeIfPresent(Double.self, forKey: .temp)
//        ts = try values.decodeIfPresent(Double.self, forKey: .ts)
//        uv = try values.decodeIfPresent(Double.self, forKey: .uv)
//        validDate = try values.decodeIfPresent(String.self, forKey: .validDate)
//        vis = try values.decodeIfPresent(Double.self, forKey: .vis)
//        weather = try WeatherbitDailyWeather(from: decoder)
//        windCdir = try values.decodeIfPresent(String.self, forKey: .windCdir)
//        windCdirFull = try values.decodeIfPresent(String.self, forKey: .windCdirFull)
//        windDir = try values.decodeIfPresent(Double.self, forKey: .windDir)
//        windGustSpd = try values.decodeIfPresent(Double.self, forKey: .windGustSpd)
//        windSpd = try values.decodeIfPresent(Double.self, forKey: .windSpd)
//    }
    
}

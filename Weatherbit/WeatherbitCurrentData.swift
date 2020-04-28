//
//  WeatherbitData.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/14/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WeatherbitCurrentData: Codable {
    let app_temp : Double?
    let aqi : Double?
    let city_name : String?
    let clouds : Double?
    let country_code : String?
    let datetime : String?
    let dewpt : Double?
    let dhi : Double?
    let dni : Double?
    let elev_angle : Double?
    let ghi : Double?
    let h_angle : Double?
    let last_ob_time : String?
    let lat : Double?
    let lon : Double?
    let ob_time : String?
    let pod : String?
    let precip : Double?
    let pres : Double?
    let rh : Double?
    let slp : Double?
    let snow : Double?
    let solar_rad : Double?
    let state_code : String?
    let station : String?
    let sunrise : String?
    let sunset : String?
    let temp : Double?
    let timezone : String?
    let ts : Double?
    let uv : Double?
    let vis : Double?
    let weather : WeatherbitWeather?
    let wind_cdir : String?
    let wind_cdir_full : String?
    let wind_dir : Double?
    let wind_spd : Double?
    
}

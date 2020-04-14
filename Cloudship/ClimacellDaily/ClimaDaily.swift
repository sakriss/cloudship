//
//  ClimaDaily.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/13/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class ClimaDaily: Codable {
    let humidity : [Humidity]?
    let lat : Double?
    let lon : Double?
    let observation_time : ObservationTime?
    let precipitation_probability : PrecipitationProbability?
    let sunrise : Sunrise?
    let sunset : Sunset?
    let temp : [DailyTemp]?
    let weather_code : WeatherCode?
    let wind_direction : [WindDirectionDaily]?
    let wind_speed : [WindSpeedDaily]?
}

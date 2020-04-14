//
//  ClimaHourly.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/13/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class ClimaHourly: Codable {
    let lat : Double?
    let lon : Double?
    let observation_time : ObservationTime?
    let precipitation_probability : PrecipitationProbability?
    let temp : Temp?
    let weather_code : WeatherCode?
    let wind_direction : WindDirection?
    let wind_speed : WindSpeed?
}

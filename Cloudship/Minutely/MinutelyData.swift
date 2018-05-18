//
//  MinutelyData.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class MinutelyData: Codable {
    private(set) var time: Date?
    private(set) var precipIntensity: Double?
    private(set) var precipProbability: Double?
    private(set) var precipIntensityError: Double?
    private(set) var precipType: String?
}

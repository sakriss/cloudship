//
//  Minutely.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class Minutely: Codable {
    private(set) var summary: String? = ""
    private(set) var icon: String? = ""
    private(set) var  data: [MinutelyData]? = []
}

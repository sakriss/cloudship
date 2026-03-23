//
//  Alerts.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/18/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class Alerts: Codable {
    private(set) var description: String = ""
    private(set) var expires: Date?
    private(set) var regions: [String] = []
    private(set) var severity: String = ""
    private(set) var time: Date?
    private(set) var title: String = ""
    private(set) var uri: String = ""
}

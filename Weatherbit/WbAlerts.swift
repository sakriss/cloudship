//
//  WbAlerts.swift
//  Cloudship
//
//  Created by Scott Kriss on 4/22/20.
//  Copyright © 2020 Scott Kriss. All rights reserved.
//

import UIKit

class WbAlerts: Codable {
    let countryCode: String
    let lon: Double
    let timezone: String
    let lat: Double
    let alerts: [Alert]
    let cityName, stateCode: String
    
    enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case lon, timezone, lat, alerts
        case cityName = "city_name"
        case stateCode = "state_code"
    }
    
    init(countryCode: String, lon: Double, timezone: String, lat: Double, alerts: [Alert], cityName: String, stateCode: String) {
        self.countryCode = countryCode
        self.lon = lon
        self.timezone = timezone
        self.lat = lat
        self.alerts = alerts
        self.cityName = cityName
        self.stateCode = stateCode
    }
}

// MARK: - Alert
class Alert: Codable {
    let regions: [String]
    let expiresUTC, effectiveLocal: String
    let uri: String
    let alertDescription, effectiveUTC, severity, title: String
    let expiresLocal: String
    
    enum CodingKeys: String, CodingKey {
        case regions
        case expiresUTC = "expires_utc"
        case effectiveLocal = "effective_local"
        case uri
        case alertDescription = "description"
        case effectiveUTC = "effective_utc"
        case severity, title
        case expiresLocal = "expires_local"
    }
    
    init(regions: [String], expiresUTC: String, effectiveLocal: String, uri: String, alertDescription: String, effectiveUTC: String, severity: String, title: String, expiresLocal: String) {
        self.regions = regions
        self.expiresUTC = expiresUTC
        self.effectiveLocal = effectiveLocal
        self.uri = uri
        self.alertDescription = alertDescription
        self.effectiveUTC = effectiveUTC
        self.severity = severity
        self.title = title
        self.expiresLocal = expiresLocal
    }
}

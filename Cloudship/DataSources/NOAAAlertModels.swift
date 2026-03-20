//
//  NOAAAlertModels.swift
//  Cloudship
//
//  Codable structs for NOAA api.weather.gov /alerts endpoint.
//

import Foundation

struct NOAAAlertCollection: Codable {
    let features: [NOAAAlertFeature]?
}

struct NOAAAlertFeature: Codable {
    let properties: NOAAAlertProperties?
}

struct NOAAAlertProperties: Codable {
    let event: String?
    let headline: String?
    let description: String?
    let instruction: String?
    let severity: String?       // "Extreme", "Severe", "Moderate", "Minor", "Unknown"
    let onset: String?
    let expires: String?
    let ends: String?
    let areaDesc: String?
    let status: String?         // "Actual", "Exercise", "Test", etc.
    let messageType: String?    // "Alert", "Update", "Cancel"
}

//
//  WeatherColors.swift
//  Cloudship
//
//  Centralized color constants for weather visualizations.
//

import UIKit

enum WeatherColors {

    // MARK: - Precipitation

    /// Light rain / drizzle (< 0.1 mm/hr)
    static let precipitationVeryLight = UIColor(red: 0.55, green: 0.78, blue: 0.94, alpha: 0.7)
    /// Light rain (0.1–0.5 mm/hr)
    static let precipitationLight = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 0.85)
    /// Heavy rain (0.5–2.0 mm/hr)
    static let precipitationHeavy = UIColor(red: 0.15, green: 0.45, blue: 0.78, alpha: 0.9)
    /// Very heavy rain (> 2.0 mm/hr)
    static let precipitationExtreme = UIColor(red: 0.45, green: 0.25, blue: 0.80, alpha: 0.95)

    /// General precipitation accent (precip chance labels, etc.)
    static let precipitation = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)

    // MARK: - Temperature

    /// Cool end of temperature gradient
    static let temperatureCool = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
    /// Warm end of temperature gradient
    static let temperatureWarm = UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1)

    // MARK: - Sun

    /// Sun arc / sun position dot
    static let sunGlow = UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0)

    // MARK: - Wind

    /// Wind-related text and indicators
    static let wind = UIColor.secondaryLabel
}

//
//  DateFormatHelper.swift
//  Cloudship
//

import Foundation

enum DateFormatHelper {

    // "2026-03-19T22:15:00Z"  (Tomorrow.io, NOAA UTC)
    private static let iso8601UTC: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return f
    }()

    // "2026-03-19T22:15:00.000Z"  (Tomorrow.io with fractional seconds)
    private static let iso8601Fractional: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return f
    }()

    // "2026-03-19T15:00:00-07:00"  (NOAA local time with colon in offset)
    private static let iso8601ColonTZ: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f
    }()

    // ISO8601DateFormatter with all common options as a last resort
    private static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601NoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parse an ISO 8601 string to Date. Handles:
    /// - Tomorrow.io: "2026-03-19T22:15:00Z"
    /// - NOAA local:  "2026-03-19T15:00:00-07:00"  (colon timezone offset)
    /// - Fractional:  "2026-03-19T22:15:00.000Z"
    static func date(from string: String?) -> Date? {
        guard let string = string else { return nil }
        return iso8601UTC.date(from: string)
            ?? iso8601ColonTZ.date(from: string)
            ?? iso8601Fractional.date(from: string)
            ?? iso8601NoFractional.date(from: string)
            ?? iso8601Full.date(from: string)
    }

    /// Format a Date as an hour string, e.g. "2 PM", "11 AM". Uses device timezone.
    static func hourString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "h a"   // "2 PM"
        return f.string(from: date)
    }

    /// Format a Date as a short day name, e.g. "Mon", "Tue".
    static func dayString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    /// Returns true if the given date is "today".
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Returns the display label for hourly strips: "Now" if within 30 minutes, else hour string.
    static func hourLabel(from date: Date) -> String {
        if abs(date.timeIntervalSinceNow) < 1800 { return "Now" }
        return hourString(from: date)
    }

    /// Display label for daily rows: "Today" for today, short day name otherwise.
    static func dailyLabel(from date: Date) -> String {
        isToday(date) ? "Today" : dayString(from: date)
    }
}

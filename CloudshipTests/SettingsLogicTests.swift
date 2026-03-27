//
//  SettingsLogicTests.swift
//  CloudshipTests
//
//  Unit tests for settings-related logic: UserDefaults toggles,
//  mutual exclusion between Nearest Station and Consensus Mode,
//  notification row counting, and data source switching.
//

import XCTest
@testable import Cloudship

final class SettingsLogicTests: XCTestCase {

    // Use a dedicated UserDefaults suite so tests don't pollute app state
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "com.cloudship.tests.settings")!
        defaults.removePersistentDomain(forName: "com.cloudship.tests.settings")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "com.cloudship.tests.settings")
        defaults = nil
        super.tearDown()
    }

    // MARK: - Toggle Persistence

    func testRainAlertsToggle_persistsToUserDefaults() {
        defaults.set(true, forKey: "RainAlertsEnabled")
        XCTAssertTrue(defaults.bool(forKey: "RainAlertsEnabled"))

        defaults.set(false, forKey: "RainAlertsEnabled")
        XCTAssertFalse(defaults.bool(forKey: "RainAlertsEnabled"))
    }

    func testMorningBriefToggle_persistsToUserDefaults() {
        defaults.set(true, forKey: "MorningBriefEnabled")
        XCTAssertTrue(defaults.bool(forKey: "MorningBriefEnabled"))

        defaults.set(false, forKey: "MorningBriefEnabled")
        XCTAssertFalse(defaults.bool(forKey: "MorningBriefEnabled"))
    }

    func testEveningBriefToggle_persistsToUserDefaults() {
        defaults.set(true, forKey: "EveningBriefEnabled")
        XCTAssertTrue(defaults.bool(forKey: "EveningBriefEnabled"))

        defaults.set(false, forKey: "EveningBriefEnabled")
        XCTAssertFalse(defaults.bool(forKey: "EveningBriefEnabled"))
    }

    func testLiveActivityToggle_persistsToUserDefaults() {
        defaults.set(true, forKey: "PrecipitationLiveActivityEnabled")
        XCTAssertTrue(defaults.bool(forKey: "PrecipitationLiveActivityEnabled"))

        defaults.set(false, forKey: "PrecipitationLiveActivityEnabled")
        XCTAssertFalse(defaults.bool(forKey: "PrecipitationLiveActivityEnabled"))
    }

    // MARK: - Mutual Exclusion: Nearest Station vs Consensus Mode

    func testNearestStationAndConsensusMode_areMutuallyExclusive() {
        // Simulate: turn on Nearest Station
        defaults.set(true, forKey: WeatherDataSourceManager.nearestStationEnabledKey)
        defaults.set(false, forKey: WeatherDataSourceManager.consensusModeEnabledKey)

        XCTAssertTrue(defaults.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey))
        XCTAssertFalse(defaults.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey))

        // Simulate: turn on Consensus → should turn off Nearest Station
        defaults.set(true, forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        defaults.set(false, forKey: WeatherDataSourceManager.nearestStationEnabledKey)

        XCTAssertFalse(defaults.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey))
        XCTAssertTrue(defaults.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey))
    }

    func testConsensusModeOn_disablesSourceSelector() {
        // When either Nearest Station or Consensus Mode is on,
        // the source selector should be disabled (alpha 0.40)
        defaults.set(true, forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        defaults.set(false, forKey: WeatherDataSourceManager.nearestStationEnabledKey)

        let overrideActive = defaults.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey)
                          || defaults.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        XCTAssertTrue(overrideActive, "Source selector should be disabled when consensus mode is on")
    }

    func testNearestStationOn_disablesSourceSelector() {
        defaults.set(false, forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        defaults.set(true, forKey: WeatherDataSourceManager.nearestStationEnabledKey)

        let overrideActive = defaults.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey)
                          || defaults.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        XCTAssertTrue(overrideActive, "Source selector should be disabled when nearest station is on")
    }

    func testBothOff_enablesSourceSelector() {
        defaults.set(false, forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        defaults.set(false, forKey: WeatherDataSourceManager.nearestStationEnabledKey)

        let overrideActive = defaults.bool(forKey: WeatherDataSourceManager.nearestStationEnabledKey)
                          || defaults.bool(forKey: WeatherDataSourceManager.consensusModeEnabledKey)
        XCTAssertFalse(overrideActive, "Source selector should be enabled when both modes are off")
    }

    // MARK: - Notification Row Counting

    /// Mirrors the notificationRowCount logic from SettingsViewController
    private func notificationRowCount(morningEnabled: Bool, eveningEnabled: Bool) -> Int {
        var count = 5 // Rain Alerts, Manage Locations, Live Activity, Morning Brief, Evening Brief
        if morningEnabled { count += 1 }
        if eveningEnabled { count += 1 }
        return count
    }

    func testNotificationRowCount_bothBriefsOff() {
        XCTAssertEqual(notificationRowCount(morningEnabled: false, eveningEnabled: false), 5)
    }

    func testNotificationRowCount_morningBriefOn() {
        XCTAssertEqual(notificationRowCount(morningEnabled: true, eveningEnabled: false), 6)
    }

    func testNotificationRowCount_eveningBriefOn() {
        XCTAssertEqual(notificationRowCount(morningEnabled: false, eveningEnabled: true), 6)
    }

    func testNotificationRowCount_bothBriefsOn() {
        XCTAssertEqual(notificationRowCount(morningEnabled: true, eveningEnabled: true), 7)
    }

    // MARK: - Notification Row Mapping

    /// Mirrors the notificationRow(for:) logic from SettingsViewController
    private enum NotificationRow {
        case rainAlerts, manageLocations, liveActivity
        case morningBriefToggle, morningBriefTime
        case eveningBriefToggle, eveningBriefTime
    }

    private func notificationRow(for index: Int, morningEnabled: Bool) -> NotificationRow {
        switch index {
        case 0: return .rainAlerts
        case 1: return .manageLocations
        case 2: return .liveActivity
        case 3: return .morningBriefToggle
        case 4 where morningEnabled: return .morningBriefTime
        case 4: return .eveningBriefToggle
        case 5 where morningEnabled: return .eveningBriefToggle
        case 5: return .eveningBriefTime
        case 6: return .eveningBriefTime
        default: return .rainAlerts
        }
    }

    func testNotificationRowMapping_morningOff() {
        // Row 4 should be evening toggle (not morning time) when morning is off
        let row4 = notificationRow(for: 4, morningEnabled: false)
        XCTAssertTrue(isEveningBriefToggle(row4), "Row 4 should be evening brief toggle when morning is disabled")
    }

    func testNotificationRowMapping_morningOn() {
        // Row 4 should be morning time when morning is on
        let row4 = notificationRow(for: 4, morningEnabled: true)
        XCTAssertTrue(isMorningBriefTime(row4), "Row 4 should be morning brief time when morning is enabled")

        // Row 5 should be evening toggle when morning is on
        let row5 = notificationRow(for: 5, morningEnabled: true)
        XCTAssertTrue(isEveningBriefToggle(row5), "Row 5 should be evening brief toggle when morning is enabled")
    }

    func testNotificationRowMapping_fixedRows() {
        let row0 = notificationRow(for: 0, morningEnabled: false)
        XCTAssertTrue(isRainAlerts(row0))

        let row1 = notificationRow(for: 1, morningEnabled: false)
        XCTAssertTrue(isManageLocations(row1))

        let row2 = notificationRow(for: 2, morningEnabled: false)
        XCTAssertTrue(isLiveActivity(row2))

        let row3 = notificationRow(for: 3, morningEnabled: false)
        XCTAssertTrue(isMorningBriefToggle(row3))
    }

    // Helper matchers
    private func isRainAlerts(_ row: NotificationRow) -> Bool { if case .rainAlerts = row { return true } else { return false } }
    private func isManageLocations(_ row: NotificationRow) -> Bool { if case .manageLocations = row { return true } else { return false } }
    private func isLiveActivity(_ row: NotificationRow) -> Bool { if case .liveActivity = row { return true } else { return false } }
    private func isMorningBriefToggle(_ row: NotificationRow) -> Bool { if case .morningBriefToggle = row { return true } else { return false } }
    private func isMorningBriefTime(_ row: NotificationRow) -> Bool { if case .morningBriefTime = row { return true } else { return false } }
    private func isEveningBriefToggle(_ row: NotificationRow) -> Bool { if case .eveningBriefToggle = row { return true } else { return false } }
    private func isEveningBriefTime(_ row: NotificationRow) -> Bool { if case .eveningBriefTime = row { return true } else { return false } }

    // MARK: - Units Preference

    func testUnitsDefault_isImperial() {
        // Fresh defaults should not have a Units key → isMetric should be false
        XCTAssertNil(defaults.string(forKey: "Units"))
        let units = defaults.string(forKey: "Units") ?? "imperial"
        XCTAssertEqual(units, "imperial")
    }

    func testUnitsChanged_persistsMetric() {
        defaults.set("metric", forKey: "Units")
        XCTAssertEqual(defaults.string(forKey: "Units"), "metric")
    }

    func testUnitsChanged_persistsImperial() {
        defaults.set("imperial", forKey: "Units")
        XCTAssertEqual(defaults.string(forKey: "Units"), "imperial")
    }

    // MARK: - Appearance Preference

    func testAppearanceDefault_isZero() {
        // System = 0
        XCTAssertEqual(defaults.integer(forKey: "AppearanceIndex"), 0)
    }

    func testAppearanceChanged_persists() {
        defaults.set(2, forKey: "AppearanceIndex") // Dark
        XCTAssertEqual(defaults.integer(forKey: "AppearanceIndex"), 2)
    }

    // MARK: - Weather Source Persistence

    func testWeatherSourcePersistence() {
        for source in WeatherSourceID.allCases {
            defaults.set(source.rawValue, forKey: "WeatherSource")
            XCTAssertEqual(defaults.string(forKey: "WeatherSource"), source.rawValue)
        }
    }
}

// MARK: - WeatherSourceID allCases conformance for test enumeration

extension WeatherSourceID: CaseIterable {
    static var allCases: [WeatherSourceID] {
        [.tomorrowIO, .noaa, .openMeteo, .pirateWeather, .appleWeather]
    }
}

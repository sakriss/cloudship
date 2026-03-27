//
//  TemperatureFormatterTests.swift
//  CloudshipTests
//
//  Unit tests for TemperatureFormatter formatting and unit detection.
//

import XCTest
@testable import Cloudship

final class TemperatureFormatterTests: XCTestCase {

    private let defaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        // Reset to a known state before each test
        defaults.removeObject(forKey: "Units")
    }

    override func tearDown() {
        defaults.removeObject(forKey: "Units")
        super.tearDown()
    }

    // MARK: - format(_:showUnit:)

    func testFormat_nilValue_returnsDash() {
        XCTAssertEqual(TemperatureFormatter.format(nil), "—")
    }

    func testFormat_nilValue_showUnit_returnsDash() {
        XCTAssertEqual(TemperatureFormatter.format(nil, showUnit: true), "—")
    }

    func testFormat_roundsToInteger() {
        XCTAssertEqual(TemperatureFormatter.format(72.4), "72°")
        XCTAssertEqual(TemperatureFormatter.format(72.5), "73°")
        XCTAssertEqual(TemperatureFormatter.format(72.6), "73°")
    }

    func testFormat_showUnit_imperial() {
        defaults.set("imperial", forKey: "Units")
        XCTAssertEqual(TemperatureFormatter.format(72.0, showUnit: true), "72°F")
    }

    func testFormat_showUnit_metric() {
        defaults.set("metric", forKey: "Units")
        XCTAssertEqual(TemperatureFormatter.format(22.0, showUnit: true), "22°C")
    }

    func testFormat_negativeTemperature() {
        XCTAssertEqual(TemperatureFormatter.format(-5.0), "-5°")
    }

    func testFormat_zero() {
        XCTAssertEqual(TemperatureFormatter.format(0.0), "0°")
    }

    // MARK: - isMetric

    func testIsMetric_defaultsToFalse() {
        // No "Units" key set → should default to imperial
        XCTAssertFalse(TemperatureFormatter.isMetric)
    }

    func testIsMetric_whenMetric() {
        defaults.set("metric", forKey: "Units")
        XCTAssertTrue(TemperatureFormatter.isMetric)
    }

    func testIsMetric_whenImperial() {
        defaults.set("imperial", forKey: "Units")
        XCTAssertFalse(TemperatureFormatter.isMetric)
    }

    // MARK: - apiUnits

    func testApiUnits_imperial() {
        defaults.set("imperial", forKey: "Units")
        XCTAssertEqual(TemperatureFormatter.apiUnits, "imperial")
    }

    func testApiUnits_metric() {
        defaults.set("metric", forKey: "Units")
        XCTAssertEqual(TemperatureFormatter.apiUnits, "metric")
    }
}

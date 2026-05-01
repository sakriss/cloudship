//
//  AlertBannerUITests.swift
//  CloudshipUITests
//
//  Tests for the AlertBannerCardView timeline card.
//
//  Note: the card uses isAccessibilityElement = true + .button trait, so XCUI
//  exposes it under app.buttons[]. Sub-views (timeline rows, badge) are inside
//  that leaf element and verified via the card's combined accessibilityLabel.
//

import XCTest

final class AlertBannerUITests: XCTestCase {

    private var app: XCUIApplication!

    // Launch args shared by all tests in this suite
    private let baseArgs: [String] = [
        "-UITesting",
        "-CloudshipUITestResetLaunchExperience",
        "-CloudshipUITestCompletedOnboarding",
        "-CloudshipUITestSeedLastForecast",
        "-CloudshipUITestUseMockWeather"
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - No Alerts

    func testAlertBannerHiddenWhenNoAlerts() {
        app = XCUIApplication()
        app.launchArguments = baseArgs  // no -CloudshipUITestInjectAlerts
        app.launch()

        // Wait for the main forecast to render
        XCTAssertTrue(app.otherElements["forecastHeaderCard"].waitForExistence(timeout: 12),
                      "Forecast should load within 12 seconds")

        // Alert banner must not be visible — either absent or not hittable
        let banner = app.buttons["alertBannerCard"]
        let appeared = banner.waitForExistence(timeout: 3)
        if appeared {
            XCTAssertFalse(banner.isHittable, "Alert banner should be hidden when there are no alerts")
        }
    }

    // MARK: - Alerts Present

    func testAlertBannerVisibleWhenAlertsPresent() {
        app = makeAppWithAlerts()
        app.launch()

        // Wait for the main forecast to render first
        XCTAssertTrue(app.otherElements["forecastHeaderCard"].waitForExistence(timeout: 12),
                      "Forecast should load within 12 seconds")

        let banner = app.buttons["alertBannerCard"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5),
                      "Alert banner should appear when alerts are active")
        XCTAssertTrue(banner.isHittable, "Alert banner should be tappable")
    }

    func testAlertBannerShowsTopAlertEventName() {
        app = makeAppWithAlerts()
        app.launch()

        XCTAssertTrue(app.otherElements["forecastHeaderCard"].waitForExistence(timeout: 12))

        let banner = app.buttons["alertBannerCard"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.label.contains("Heat Advisory"),
                      "Banner label '\(banner.label)' should contain 'Heat Advisory'")
    }

    func testAlertBannerLabelMentionsMultipleAlerts() {
        // When > 1 alert is active, the accessibility label includes the count
        app = makeAppWithAlerts()
        app.launch()

        XCTAssertTrue(app.otherElements["forecastHeaderCard"].waitForExistence(timeout: 12))

        let banner = app.buttons["alertBannerCard"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.label.contains("2 total alerts"),
                      "Banner label '\(banner.label)' should mention '2 total alerts'")
    }

    func testAlertBannerLabelIncludesArea() {
        app = makeAppWithAlerts()
        app.launch()

        XCTAssertTrue(app.otherElements["forecastHeaderCard"].waitForExistence(timeout: 12))

        let banner = app.buttons["alertBannerCard"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.label.contains("King County"),
                      "Banner label '\(banner.label)' should contain the area description 'King County'")
    }

    func testTappingAlertBannerPushesDetailScreen() {
        app = makeAppWithAlerts()
        app.launch()

        XCTAssertTrue(app.otherElements["forecastHeaderCard"].waitForExistence(timeout: 12))

        let banner = app.buttons["alertBannerCard"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        banner.tap()

        // AlertDetailViewController title is "Weather Alerts (N)" for N > 1
        let detailNav = app.navigationBars["Weather Alerts (2)"]
        XCTAssertTrue(detailNav.waitForExistence(timeout: 5),
                      "Tapping the alert card should push the detail view controller")
    }

    // MARK: - Helpers

    private func makeAppWithAlerts() -> XCUIApplication {
        let a = XCUIApplication()
        a.launchArguments = baseArgs + ["-CloudshipUITestInjectAlerts"]
        return a
    }
}

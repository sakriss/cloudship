//
//  ForecastLaunchUITests.swift
//  CloudshipUITests
//

import XCTest

final class ForecastLaunchUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testInitialLaunchDisplaysSeededForecastResponse() {
        app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            "-CloudshipUITestResetLaunchExperience",
            "-CloudshipUITestCompletedOnboarding",
            "-CloudshipUITestSeedLastForecast",
            "-CloudshipUITestUseMockWeather"
        ]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Forecast"].waitForExistence(timeout: 8))

        let header = app.otherElements["forecastHeaderCard"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))

        let renderedForecast = NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Seattle", "72")
        expectation(for: renderedForecast, evaluatedWith: header)
        waitForExpectations(timeout: 10)

        XCTAssertFalse(app.alerts["Unable to Load Weather"].exists)
    }

    func testMonospacedTypographyLayoutSmoke() {
        app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            "-CloudshipUITestCompletedOnboarding",
            "-CloudshipUITestSeedLastForecast",
            "-CloudshipUITestUseMockWeather",
            "-AppFontStyle", "3"
        ]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Forecast"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Radar"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        attachScreenshot(named: "Monospaced_Forecast")

        app.buttons["Search Cities"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        attachScreenshot(named: "Monospaced_Search")
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.88)).tap()
        }
        XCTAssertFalse(app.searchFields.firstMatch.waitForExistence(timeout: 2))

        app.tabBars.buttons["Settings"].tap()
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        attachScreenshot(named: "Monospaced_Settings")

        app.tabBars.buttons["Forecast"].tap()
        app.swipeUp()
        attachScreenshot(named: "Monospaced_Forecast_Middle")
        app.swipeUp()
        attachScreenshot(named: "Monospaced_Forecast_Scrolled")

        app.tabBars.buttons["Radar"].tap()
        XCTAssertTrue(app.tabBars.buttons["Radar"].isSelected)
        attachScreenshot(named: "Monospaced_Radar")
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

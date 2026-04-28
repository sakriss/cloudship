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
}

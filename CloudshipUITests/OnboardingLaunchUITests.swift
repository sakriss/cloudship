//
//  OnboardingLaunchUITests.swift
//  CloudshipUITests
//

import XCTest

final class OnboardingLaunchUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFirstInstallOnboardingCompletesIntoForecast() {
        app = launchApp(arguments: [
            "-CloudshipUITestResetLaunchExperience"
        ])

        XCTAssertTrue(app.staticTexts["Cloudship"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.otherElements["cloudbreakUpdateIcon"].exists)

        app.buttons["Get Started"].tap()
        XCTAssertTrue(app.staticTexts["Forecasts where you are"].waitForExistence(timeout: 3))

        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Know when rain changes"].waitForExistence(timeout: 3))

        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Make it yours"].waitForExistence(timeout: 3))

        app.buttons["Start Forecasting"].tap()
        XCTAssertTrue(app.tabBars.buttons["Forecast"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Cloudship"].exists)
    }

    func testUpdateScreenAppearsOnceAndDismisses() {
        app = launchApp(arguments: [
            "-CloudshipUITestResetLaunchExperience",
            "-CloudshipUITestUpdatedFromPreviousVersion"
        ])

        XCTAssertTrue(app.staticTexts["What's New in Cloudship"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["cloudbreakUpdateIcon"].exists)

        app.buttons["Continue"].tap()
        XCTAssertTrue(app.tabBars.buttons["Forecast"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["What's New in Cloudship"].waitForExistence(timeout: 2))

        app.terminate()
        app = launchApp(arguments: [])

        XCTAssertTrue(app.tabBars.buttons["Forecast"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["What's New in Cloudship"].waitForExistence(timeout: 2))
    }

    private func launchApp(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"] + arguments
        app.launch()
        return app
    }
}

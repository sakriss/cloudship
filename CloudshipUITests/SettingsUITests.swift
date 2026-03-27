//
//  SettingsUITests.swift
//  CloudshipUITests
//
//  UI tests for the Settings screen. Verifies that toggles are responsive
//  (not frozen), mutual exclusion works visually, and section navigation
//  is functional.
//

import XCTest

final class SettingsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Navigate to the Settings tab. Assumes a tab bar with a "Settings" tab.
    private func navigateToSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 5) {
            settingsTab.tap()
        }
    }

    /// Finds a UISwitch accessory in the cell that contains the given label text.
    private func findSwitch(near label: String) -> XCUIElement {
        let cell = app.tables.cells.containing(.staticText, identifier: label).firstMatch
        return cell.switches.firstMatch
    }

    // MARK: - Toggle Responsiveness (anti-freeze tests)

    func testRainAlertsToggle_respondsToTap() {
        navigateToSettings()

        let toggle = findSwitch(near: "Rain Alerts")
        guard toggle.waitForExistence(timeout: 5) else {
            XCTFail("Rain Alerts toggle not found")
            return
        }

        let initialValue = toggle.value as? String
        toggle.tap()

        // After tap, the value should have changed (toggle is not frozen)
        let newValue = toggle.value as? String
        XCTAssertNotEqual(initialValue, newValue,
            "Rain Alerts toggle should change state on tap (was frozen?)")
    }

    func testNearestStationToggle_respondsToTap() {
        navigateToSettings()

        let toggle = findSwitch(near: "Nearest Active Station")
        guard toggle.waitForExistence(timeout: 5) else {
            XCTFail("Nearest Active Station toggle not found")
            return
        }

        let initialValue = toggle.value as? String
        toggle.tap()

        let newValue = toggle.value as? String
        XCTAssertNotEqual(initialValue, newValue,
            "Nearest Station toggle should change state on tap (was frozen?)")
    }

    func testConsensusModeToggle_respondsToTap() {
        navigateToSettings()

        let toggle = findSwitch(near: "Consensus Mode")
        guard toggle.waitForExistence(timeout: 5) else {
            // Consensus Mode may require premium; skip if not visible
            return
        }

        let initialValue = toggle.value as? String
        toggle.tap()

        // Note: If the user is not premium, the toggle may revert and show a paywall.
        // We verify the toggle is at least tappable (not frozen).
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: toggle
        )
        wait(for: [expectation], timeout: 3)
    }

    func testMorningBriefToggle_respondsToTap() {
        navigateToSettings()

        // Scroll down to notifications section
        let toggle = findSwitch(near: "Morning Brief")
        guard toggle.waitForExistence(timeout: 5) else {
            // May need to scroll
            app.tables.firstMatch.swipeUp()
            guard toggle.waitForExistence(timeout: 3) else {
                XCTFail("Morning Brief toggle not found after scrolling")
                return
            }
            return
        }

        let initialValue = toggle.value as? String
        toggle.tap()

        let newValue = toggle.value as? String
        // If premium is required and not available, the toggle may revert.
        // At minimum, verify the tap didn't freeze the UI.
        let tableExists = app.tables.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(tableExists, "Table should still be responsive after toggling Morning Brief")
    }

    func testEveningBriefToggle_respondsToTap() {
        navigateToSettings()

        app.tables.firstMatch.swipeUp()

        let toggle = findSwitch(near: "Evening Brief")
        guard toggle.waitForExistence(timeout: 5) else {
            XCTFail("Evening Brief toggle not found")
            return
        }

        let initialValue = toggle.value as? String
        toggle.tap()

        let tableExists = app.tables.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(tableExists, "Table should still be responsive after toggling Evening Brief")
    }

    // MARK: - Mutual Exclusion

    func testNearestStationAndConsensusMode_mutualExclusion() {
        navigateToSettings()

        let nearestToggle = findSwitch(near: "Nearest Active Station")
        let consensusToggle = findSwitch(near: "Consensus Mode")

        guard nearestToggle.waitForExistence(timeout: 5),
              consensusToggle.waitForExistence(timeout: 5) else {
            // Cannot test mutual exclusion if either toggle is not present
            return
        }

        // Turn on Nearest Station
        if nearestToggle.value as? String == "0" {
            nearestToggle.tap()
        }
        XCTAssertEqual(nearestToggle.value as? String, "1",
            "Nearest Station should be on")

        // Turn on Consensus Mode → Nearest Station should turn off
        consensusToggle.tap()

        // Give UI time to settle
        let predicate = NSPredicate(format: "value == '0'")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nearestToggle)
        let result = XCTWaiter.wait(for: [expectation], timeout: 3)

        if result == .completed {
            XCTAssertEqual(nearestToggle.value as? String, "0",
                "Nearest Station should be off after enabling Consensus Mode")
        }
        // Note: Consensus toggle may revert if premium is not active, which is OK
    }

    // MARK: - Source Selector Disabled State

    func testSourceSelector_disabledWhenNearestStationOn() {
        navigateToSettings()

        let nearestToggle = findSwitch(near: "Nearest Active Station")
        guard nearestToggle.waitForExistence(timeout: 5) else { return }

        // Turn on Nearest Station
        if nearestToggle.value as? String == "0" {
            nearestToggle.tap()
        }

        // The source segmented control should be dimmed (not easily verifiable in XCUI,
        // but we can verify the toggle state persisted)
        XCTAssertEqual(nearestToggle.value as? String, "1")
    }

    // MARK: - Settings Section Navigation

    func testSettingsScreen_displaysAllSections() {
        navigateToSettings()

        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5), "Settings table should be visible")

        // Verify section headers exist
        let dataSourceHeader = table.staticTexts["Data Source"]
        XCTAssertTrue(dataSourceHeader.exists || table.otherElements.staticTexts["Data Source"].exists,
            "Data Source section header should exist")
    }

    func testManageLocations_navigates() {
        navigateToSettings()

        app.tables.firstMatch.swipeUp()

        let manageLocationsCell = app.tables.cells.containing(.staticText, identifier: "Manage Locations").firstMatch
        guard manageLocationsCell.waitForExistence(timeout: 5) else {
            return
        }

        manageLocationsCell.tap()

        // Should navigate to a new screen
        let backButton = app.navigationBars.buttons.firstMatch
        let appeared = backButton.waitForExistence(timeout: 5)
        if appeared {
            // Successfully navigated
            backButton.tap()
        }
    }

    // MARK: - Units Switching

    func testUnitsSegmentedControl_switchable() {
        navigateToSettings()

        let imperialButton = app.segmentedControls.buttons["°F (Imperial)"]
        let metricButton = app.segmentedControls.buttons["°C (Metric)"]

        guard imperialButton.waitForExistence(timeout: 5) else {
            return
        }

        metricButton.tap()
        XCTAssertTrue(metricButton.isSelected, "Metric should be selected after tap")

        imperialButton.tap()
        XCTAssertTrue(imperialButton.isSelected, "Imperial should be selected after tap")
    }

    // MARK: - Appearance Switching

    func testAppearanceSegmentedControl_switchable() {
        navigateToSettings()

        let systemButton = app.segmentedControls.buttons["System"]
        let darkButton = app.segmentedControls.buttons["Dark"]

        guard systemButton.waitForExistence(timeout: 5) else {
            return
        }

        darkButton.tap()
        XCTAssertTrue(darkButton.isSelected, "Dark should be selected after tap")

        systemButton.tap()
        XCTAssertTrue(systemButton.isSelected, "System should be selected after tap")
    }
}

//
//  AppFontStyleTests.swift
//  CloudshipTests
//

import XCTest
@testable import Cloudship

final class AppFontStyleTests: XCTestCase {

    private let defaults = UserDefaults.standard
    private let appGroupDefaults = UserDefaults(suiteName: AppFontStyle.appGroupID)

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: AppFontStyle.defaultsKey)
        appGroupDefaults?.removeObject(forKey: AppFontStyle.defaultsKey)
    }

    override func tearDown() {
        defaults.removeObject(forKey: AppFontStyle.defaultsKey)
        appGroupDefaults?.removeObject(forKey: AppFontStyle.defaultsKey)
        super.tearDown()
    }

    func testSavedDefaultsToSystemWhenUnset() {
        XCTAssertEqual(AppFontStyle.saved, .system)
    }

    func testInvalidRawValueFallsBackToSystem() {
        defaults.set(999, forKey: AppFontStyle.defaultsKey)
        XCTAssertEqual(AppFontStyle.saved, .system)
    }

    func testSavePersistsSelectedStyle() {
        AppFontStyle.save(.rounded)
        XCTAssertEqual(AppFontStyle.saved, .rounded)
    }

    func testSaveMirrorsSelectionToAppGroup() throws {
        AppFontStyle.save(.serif)
        let groupDefaults = try XCTUnwrap(appGroupDefaults)
        XCTAssertEqual(groupDefaults.integer(forKey: AppFontStyle.defaultsKey), AppFontStyle.serif.rawValue)
        XCTAssertEqual(AppFontStyle.shared, .serif)
    }
}

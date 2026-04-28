//
//  AppLaunchExperienceTests.swift
//  CloudshipTests
//

import XCTest
@testable import Cloudship

final class AppLaunchExperienceTests: XCTestCase {

    private var defaults: UserDefaults!
    private let version = AppVersion(marketingVersion: "2.0", build: "42")

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "com.cloudship.tests.launchExperience")!
        defaults.removePersistentDomain(forName: "com.cloudship.tests.launchExperience")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "com.cloudship.tests.launchExperience")
        defaults = nil
        super.tearDown()
    }

    func testFreshInstall_showsOnboarding() {
        let state = makeState()

        XCTAssertEqual(state.launchDecision(), .onboarding)
    }

    func testCompletedOnboardingAndCurrentVersion_showsMain() {
        defaults.set(true, forKey: AppLaunchExperienceState.hasCompletedOnboardingKey)
        defaults.set(version.marketingVersion, forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey)
        defaults.set(version.build, forKey: AppLaunchExperienceState.lastSeenBuildKey)

        let state = makeState()

        XCTAssertEqual(state.launchDecision(), .main)
    }

    func testCompletedOnboardingAndNewVersionWithNotes_showsWhatsNew() {
        defaults.set(true, forKey: AppLaunchExperienceState.hasCompletedOnboardingKey)
        defaults.set("1.9", forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey)
        defaults.set("41", forKey: AppLaunchExperienceState.lastSeenBuildKey)
        let notes = ReleaseNotes(version: version, title: "New", subtitle: "Better weather", bullets: ["One"])
        let state = makeState(notes: notes)

        XCTAssertEqual(state.launchDecision(), .whatsNew(notes))
    }

    func testCompletedOnboardingAndNewVersionWithoutNotes_marksSeenAndShowsMain() {
        defaults.set(true, forKey: AppLaunchExperienceState.hasCompletedOnboardingKey)
        defaults.set("1.9", forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey)
        defaults.set("41", forKey: AppLaunchExperienceState.lastSeenBuildKey)
        let state = makeState(notes: nil)

        XCTAssertEqual(state.launchDecision(), .main)
        XCTAssertEqual(defaults.string(forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey), version.marketingVersion)
        XCTAssertEqual(defaults.string(forKey: AppLaunchExperienceState.lastSeenBuildKey), version.build)
    }

    func testLegacyInstallSkipsOnboardingAndCanShowWhatsNew() {
        defaults.set("imperial", forKey: "Units")
        let notes = ReleaseNotes(version: version, title: "New", subtitle: "Better weather", bullets: ["One"])
        let state = makeState(notes: notes)

        XCTAssertEqual(state.launchDecision(), .whatsNew(notes))
        XCTAssertTrue(defaults.bool(forKey: AppLaunchExperienceState.hasCompletedOnboardingKey))
    }

    func testCompleteOnboardingMarksCurrentVersionSeen() {
        let state = makeState()

        state.completeOnboarding()

        XCTAssertTrue(defaults.bool(forKey: AppLaunchExperienceState.hasCompletedOnboardingKey))
        XCTAssertEqual(defaults.string(forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey), version.marketingVersion)
        XCTAssertEqual(defaults.string(forKey: AppLaunchExperienceState.lastSeenBuildKey), version.build)
    }

    private func makeState(notes: ReleaseNotes? = nil) -> AppLaunchExperienceState {
        AppLaunchExperienceState(
            defaults: defaults,
            currentVersion: version,
            releaseNotesProvider: { _ in notes }
        )
    }
}

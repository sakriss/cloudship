//
//  AppLaunchExperience.swift
//  Cloudship
//
//  Launch routing for first-run onboarding and version update notes.
//

import Foundation

struct AppVersion: Equatable {
    let marketingVersion: String
    let build: String

    static func current(bundle: Bundle = .main) -> AppVersion {
        let info = bundle.infoDictionary
        return AppVersion(
            marketingVersion: info?["CFBundleShortVersionString"] as? String ?? "0",
            build: info?["CFBundleVersion"] as? String ?? "0"
        )
    }
}

struct ReleaseNotes: Equatable {
    let version: AppVersion
    let title: String
    let subtitle: String
    let bullets: [String]

    static func notes(for version: AppVersion) -> ReleaseNotes? {
        switch version.marketingVersion {
        case "0.5":
            return ReleaseNotes(
                version: version,
                title: "What's New in Cloudship",
                subtitle: "A brighter weather read, tuned for the forecast you check every day.",
                bullets: [
                    "Refined forecast cards for faster daily scanning.",
                    "Smarter precipitation tools for rain alerts and live tracking.",
                    "More flexible weather sources, including premium consensus options."
                ]
            )
        default:
            return nil
        }
    }
}

enum AppLaunchExperienceDecision: Equatable {
    case onboarding
    case main
    case whatsNew(ReleaseNotes)
}

final class AppLaunchExperienceState {
    static let hasCompletedOnboardingKey = "CloudshipHasCompletedOnboarding"
    static let lastSeenMarketingVersionKey = "CloudshipLastSeenMarketingVersion"
    static let lastSeenBuildKey = "CloudshipLastSeenBuild"

    private let defaults: UserDefaults
    private let currentVersion: AppVersion
    private let releaseNotesProvider: (AppVersion) -> ReleaseNotes?

    init(defaults: UserDefaults = .standard,
         currentVersion: AppVersion = .current(),
         releaseNotesProvider: @escaping (AppVersion) -> ReleaseNotes? = ReleaseNotes.notes(for:)) {
        self.defaults = defaults
        self.currentVersion = currentVersion
        self.releaseNotesProvider = releaseNotesProvider
    }

    func launchDecision() -> AppLaunchExperienceDecision {
        if shouldShowOnboarding {
            return .onboarding
        }

        guard hasSeenCurrentVersion == false else {
            return .main
        }

        if let notes = releaseNotesProvider(currentVersion) {
            return .whatsNew(notes)
        }

        markCurrentVersionSeen()
        return .main
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Self.hasCompletedOnboardingKey)
        markCurrentVersionSeen()
    }

    func markCurrentVersionSeen() {
        defaults.set(currentVersion.marketingVersion, forKey: Self.lastSeenMarketingVersionKey)
        defaults.set(currentVersion.build, forKey: Self.lastSeenBuildKey)
    }

    private var shouldShowOnboarding: Bool {
        if defaults.bool(forKey: Self.hasCompletedOnboardingKey) {
            return false
        }

        if defaults.object(forKey: Self.hasCompletedOnboardingKey) != nil {
            return true
        }

        if hasLegacyInstallMarker {
            defaults.set(true, forKey: Self.hasCompletedOnboardingKey)
            return false
        }

        return true
    }

    private var hasSeenCurrentVersion: Bool {
        let seenVersion = defaults.string(forKey: Self.lastSeenMarketingVersionKey)
        let seenBuild = defaults.string(forKey: Self.lastSeenBuildKey)
        return seenVersion == currentVersion.marketingVersion && seenBuild == currentVersion.build
    }

    private var hasLegacyInstallMarker: Bool {
        let legacyKeys = [
            "Units",
            "AppearanceIndex",
            "RainAlertsEnabled",
            "MorningBriefEnabled",
            "EveningBriefEnabled",
            "PrecipitationLiveActivityEnabled",
            "cardOrder_v2",
            "WeatherSource",
            "isPremiumCached",
            "recentSearches_v1"
        ]
        return legacyKeys.contains { defaults.object(forKey: $0) != nil }
    }
}

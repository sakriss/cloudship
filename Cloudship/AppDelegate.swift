//
//  AppDelegate.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var launchCoordinator: AppLaunchExperienceCoordinator?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        configureLaunchExperienceForUITestingIfNeeded()

        // Programmatic window setup. Launch routing checks install/update state
        // before defaults migration writes any first-run keys.
        window = UIWindow(frame: UIScreen.main.bounds)
        launchCoordinator = AppLaunchExperienceCoordinator()
        if let window {
            launchCoordinator?.start(in: window)
        }

        // Migrate legacy units key format ("units=us" to "imperial", "units=si" to "metric")
        if let existing = UserDefaults.standard.string(forKey: "Units") {
            if existing == "units=us" {
                UserDefaults.standard.set("imperial", forKey: "Units")
            } else if existing == "units=si" {
                UserDefaults.standard.set("metric", forKey: "Units")
            }
        } else {
            UserDefaults.standard.set("imperial", forKey: "Units")
        }

        // Start subscription manager
        SubscriptionManager.shared.start()

        // Register background tasks for precipitation notifications
        BackgroundTaskManager.shared.registerTasks()

        return true
    }

    private func configureLaunchExperienceForUITestingIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-UITesting") else { return }

        if !arguments.contains("-CloudshipUITestPremium") {
            UserDefaults.standard.set(false, forKey: "isPremiumCached")
            UserDefaults.standard.set(false, forKey: "DemoModeEnabled")
        }

        if arguments.contains("-CloudshipUITestPremium") {
            UserDefaults.standard.set(true, forKey: "isPremiumCached")
            UserDefaults.standard.set(true, forKey: "DemoModeEnabled")
        }

        if arguments.contains("-CloudshipUITestForceFree") {
            UserDefaults.standard.set(false, forKey: "isPremiumCached")
            UserDefaults.standard.set(false, forKey: "DemoModeEnabled")
        }

        if arguments.contains("-CloudshipUITestUseMockWeather") {
            UserDefaults.standard.set(false, forKey: "NearestStationEnabled")
            UserDefaults.standard.set(false, forKey: "ConsensusModeEnabled")
        }

        if arguments.contains("-CloudshipUITestResetLaunchExperience") {
            let keys = [
                AppLaunchExperienceState.hasCompletedOnboardingKey,
                AppLaunchExperienceState.lastSeenMarketingVersionKey,
                AppLaunchExperienceState.lastSeenBuildKey
            ]
            keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
            UserDefaults.standard.set(false, forKey: AppLaunchExperienceState.hasCompletedOnboardingKey)
        }

        if arguments.contains("-CloudshipUITestUpdatedFromPreviousVersion") {
            UserDefaults.standard.set(true, forKey: AppLaunchExperienceState.hasCompletedOnboardingKey)
            UserDefaults.standard.set("0.0", forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey)
            UserDefaults.standard.set("0", forKey: AppLaunchExperienceState.lastSeenBuildKey)
        }

        if arguments.contains("-CloudshipUITestCompletedOnboarding") {
            UserDefaults.standard.set(true, forKey: AppLaunchExperienceState.hasCompletedOnboardingKey)
            UserDefaults.standard.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                                      forKey: AppLaunchExperienceState.lastSeenMarketingVersionKey)
            UserDefaults.standard.set(Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
                                      forKey: AppLaunchExperienceState.lastSeenBuildKey)
        }

        if arguments.contains("-CloudshipUITestSeedLastForecast") {
            let seattle = CLLocation(latitude: 47.6062, longitude: -122.3321)
            LastForecastLocationStore.shared.save(name: "Seattle", location: seattle)
            UserDefaults.standard.set("imperial", forKey: "Units")
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule next background precipitation check
        BackgroundTaskManager.shared.scheduleNextRefresh()

        let appState = UIApplication.shared.applicationState
        if appState == .background {
            print("App in Background")
        } else if appState == .active {
            print("App in Foreground or Active")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

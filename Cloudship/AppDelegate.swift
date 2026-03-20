//
//  AppDelegate.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Migrate legacy units key format ("units=us" → "imperial", "units=si" → "metric")
        if let existing = UserDefaults.standard.string(forKey: "Units") {
            if existing == "units=us" {
                UserDefaults.standard.set("imperial", forKey: "Units")
            } else if existing == "units=si" {
                UserDefaults.standard.set("metric", forKey: "Units")
            }
        } else {
            UserDefaults.standard.set("imperial", forKey: "Units")
        }

        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Programmatic window setup — no storyboard
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainTabBarController()

        // Restore appearance override if saved
        let appearanceIdx = UserDefaults.standard.integer(forKey: "AppearanceIndex")
        let styles: [UIUserInterfaceStyle] = [.unspecified, .light, .dark]
        window?.overrideUserInterfaceStyle = appearanceIdx < styles.count ? styles[appearanceIdx] : .unspecified

        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let appState = UIApplication.shared.applicationState
        if appState == .background {
            print("App in Background")
        }else if appState == .active {
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


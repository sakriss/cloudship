//
//  MainTabBarController.swift
//  Cloudship
//
//  Sets up the three-tab structure: Forecast | Radar | Settings.
//  Created programmatically — no storyboard required.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        styleTabBar()
    }

    // MARK: - Tab setup

    private func setupTabs() {
        let forecast = makeTab(
            rootVC: MainForecastViewController(),
            title: "Forecast",
            image: UIImage(systemName: "sun.max.fill"),
            selectedImage: UIImage(systemName: "sun.max.fill")
        )

        let radar = makeTab(
            rootVC: RadarViewController(),
            title: "Radar",
            image: UIImage(systemName: "antenna.radiowaves.left.and.right"),
            selectedImage: UIImage(systemName: "antenna.radiowaves.left.and.right.fill")
        )

        let settings = makeTab(
            rootVC: SettingsViewController(style: .insetGrouped),
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [forecast, radar, settings]
    }

    private func makeTab(rootVC: UIViewController,
                         title: String,
                         image: UIImage?,
                         selectedImage: UIImage?) -> UINavigationController {
        rootVC.title = title
        let nav = UINavigationController(rootViewController: rootVC)
        nav.tabBarItem = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
        return nav
    }

    // MARK: - Style

    private func styleTabBar() {
        // Use the default system appearance — adapts to light/dark automatically
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = UIColor(red: 0.27, green: 0.65, blue: 0.89, alpha: 1)
    }
}

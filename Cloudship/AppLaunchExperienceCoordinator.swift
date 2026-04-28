//
//  AppLaunchExperienceCoordinator.swift
//  Cloudship
//

import UIKit

final class AppLaunchExperienceCoordinator {

    private let state: AppLaunchExperienceState

    init(state: AppLaunchExperienceState = AppLaunchExperienceState()) {
        self.state = state
    }

    func start(in window: UIWindow) {
        switch state.launchDecision() {
        case .onboarding:
            showOnboarding(in: window)
        case .main:
            showMainApp(in: window, notes: nil)
        case .whatsNew(let notes):
            showMainApp(in: window, notes: notes)
        }
    }

    private func showOnboarding(in window: UIWindow) {
        let onboarding = OnboardingViewController()
        onboarding.onComplete = { [weak self, weak window] in
            guard let self, let window else { return }
            self.state.completeOnboarding()
            self.showMainApp(in: window, notes: nil)
        }

        window.rootViewController = onboarding
        applySavedAppearance(to: window)
        window.makeKeyAndVisible()
    }

    private func showMainApp(in window: UIWindow, notes: ReleaseNotes?) {
        let tabBarController = MainTabBarController()
        window.rootViewController = tabBarController
        applySavedAppearance(to: window)
        window.makeKeyAndVisible()

        guard let notes else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self, weak tabBarController] in
            guard let self, let presenter = tabBarController else { return }
            let whatsNew = WhatsNewViewController(notes: notes)
            whatsNew.onDismiss = { [weak self] in
                self?.state.markCurrentVersionSeen()
            }
            presenter.present(whatsNew, animated: true)
        }
    }

    private func applySavedAppearance(to window: UIWindow) {
        let appearanceIdx = UserDefaults.standard.integer(forKey: "AppearanceIndex")
        let styles: [UIUserInterfaceStyle] = [.unspecified, .light, .dark, .unspecified]
        window.overrideUserInterfaceStyle = appearanceIdx < styles.count ? styles[appearanceIdx] : .unspecified
    }
}

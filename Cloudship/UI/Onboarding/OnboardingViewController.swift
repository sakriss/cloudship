//
//  OnboardingViewController.swift
//  Cloudship
//

import CoreLocation
import UIKit
import UserNotifications

final class OnboardingViewController: UIViewController {

    var onComplete: (() -> Void)?

    private enum Step: Int, CaseIterable {
        case welcome
        case confidence
        case location
        case notifications
        case preferences

        var title: String {
            switch self {
            case .welcome: return "Know what to do today"
            case .confidence: return "More confidence, less guesswork"
            case .location: return "Forecasts where you are"
            case .notifications: return "Know when rain changes"
            case .preferences: return "Make it yours"
            }
        }

        var message: String {
            switch self {
            case .welcome:
                return "Cloudship turns the forecast into one clear daily call, then keeps the deeper details close when you need them."
            case .confidence:
                return "Compare forecasts, watch rain changes, and see which activities fit the day. Cloudship is built for decisions, not data overload."
            case .location:
                return "Allow location to make the daily call, radar, and nearby alerts accurate for where you actually are."
            case .notifications:
                return "Enable notifications for useful changes, such as rain starting or stopping. Cloudship will not send routine noise."
            case .preferences:
                return "Choose your default temperature units. You can change this later in Settings."
            }
        }

        var buttonTitle: String {
            switch self {
            case .welcome: return "Get Started"
            case .confidence: return "Continue"
            case .location: return "Allow Location"
            case .notifications: return "Enable Notifications"
            case .preferences: return "Start Forecasting"
            }
        }
    }

    private let locationManager = CLLocationManager()
    private var currentStep: Step = .welcome {
        didSet { updateContent() }
    }

    private let iconView = CloudbreakUpdateIconView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let unitsControl = UISegmentedControl(items: ["Fahrenheit", "Celsius"])
    private let pageControl = UIPageControl()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        updateContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        iconView.playIfNeeded()
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        let background = CAGradientLayer()
        background.colors = [
            UIColor(red: 0.94, green: 0.98, blue: 1.00, alpha: 1).cgColor,
            UIColor.systemBackground.cgColor
        ]
        background.startPoint = CGPoint(x: 0.5, y: 0)
        background.endPoint = CGPoint(x: 0.5, y: 1)
        background.frame = UIScreen.main.bounds
        view.layer.insertSublayer(background, at: 0)

        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        unitsControl.selectedSegmentIndex = TemperatureFormatter.isMetric ? 1 : 0
        unitsControl.addTarget(self, action: #selector(unitsChanged(_:)), for: .valueChanged)

        pageControl.numberOfPages = Step.allCases.count
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.pageIndicatorTintColor = .systemBlue.withAlphaComponent(0.25)

        primaryButton.configuration = .filled()
        primaryButton.configuration?.cornerStyle = .large
        primaryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        secondaryButton.configuration = .plain()
        secondaryButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, unitsControl])
        textStack.axis = .vertical
        textStack.spacing = 18
        textStack.alignment = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = UIStackView(arrangedSubviews: [primaryButton, secondaryButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = UIStackView(arrangedSubviews: [iconView, textStack, pageControl, buttonStack])
        contentStack.axis = .vertical
        contentStack.spacing = 26
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 168),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.centerXAnchor.constraint(equalTo: contentStack.centerXAnchor),

            contentStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -12),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            secondaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    private func updateContent() {
        titleLabel.text = currentStep.title
        messageLabel.text = currentStep.message
        pageControl.currentPage = currentStep.rawValue
        unitsControl.isHidden = currentStep != .preferences

        primaryButton.configuration?.title = currentStep.buttonTitle
        secondaryButton.configuration?.title = currentStep == .welcome ? "Not Now" : "Skip"
        secondaryButton.isHidden = currentStep == .preferences

        UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
    }

    @objc private func primaryTapped() {
        switch currentStep {
        case .welcome, .confidence:
            advance()
        case .location:
            locationManager.requestWhenInUseAuthorization()
            advance()
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Notification auth error: \(error)")
                }
                print("Notification permission granted: \(granted)")
            }
            advance()
        case .preferences:
            finish()
        }
    }

    @objc private func skipTapped() {
        advance()
    }

    @objc private func unitsChanged(_ sender: UISegmentedControl) {
        let units = sender.selectedSegmentIndex == 0 ? "imperial" : "metric"
        UserDefaults.standard.set(units, forKey: "Units")
    }

    private func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else {
            finish()
            return
        }
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
        if UIAccessibility.isReduceMotionEnabled {
            currentStep = nextStep
        } else {
            UIView.transition(with: view, duration: 0.24, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.currentStep = nextStep
            }
        }
    }

    private func finish() {
        onComplete?()
    }
}

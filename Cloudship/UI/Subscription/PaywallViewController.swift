//
//  PaywallViewController.swift
//  Cloudship
//
//  Premium subscription paywall presented as a modal sheet.
//  Shows feature list, monthly/annual pricing, and restore option.
//

import UIKit
import StoreKit

class PaywallViewController: UIViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .close)
        return btn
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "AppIcon60x60")
            ?? UIImage(systemName: "cloud.sun.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 80),
            iv.heightAnchor.constraint(equalToConstant: 80)
        ])
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Cloudship Premium"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textAlignment = .center
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Unlock the full weather experience"
        lbl.font = .systemFont(ofSize: 16)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var monthlyButton = makePurchaseButton(title: "Monthly", subtitle: "")
    private lazy var annualButton  = makePurchaseButton(title: "Annual", subtitle: "")

    private let restoreButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Restore Purchases", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.secondaryLabel, for: .normal)
        return btn
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        return s
    }()

    // MARK: - State

    private var monthlyProduct: Product?
    private var annualProduct: Product?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupLayout()
        setupActions()
        loadProducts()
    }

    // MARK: - Layout

    private func setupLayout() {
        // Close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Content stack
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])

        // Icon + title
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(24, after: subtitleLabel)

        // Features
        let features: [(String, String)] = [
            ("sparkles", "Premium AI weather summaries & chat"),
            ("cloud.sun.rain.fill", "Tomorrow.io & AccuWeather premium sources"),
            ("bell.badge.fill", "Rain alerts for multiple locations"),
            ("drop.fill", "Precipitation Live Activity in Dynamic Island"),
        ]

        for (icon, text) in features {
            let row = makeFeatureRow(icon: icon, text: text)
            contentStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }

        contentStack.setCustomSpacing(28, after: contentStack.arrangedSubviews.last!)

        // Purchase buttons
        contentStack.addArrangedSubview(annualButton)
        annualButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

        contentStack.addArrangedSubview(monthlyButton)
        monthlyButton.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true

        contentStack.setCustomSpacing(20, after: monthlyButton)

        // Restore + spinner
        contentStack.addArrangedSubview(restoreButton)
        contentStack.addArrangedSubview(spinner)

        // Start with buttons disabled until products load
        monthlyButton.isEnabled = false
        annualButton.isEnabled = false
    }

    // MARK: - Actions

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        monthlyButton.addTarget(self, action: #selector(monthlyTapped), for: .touchUpInside)
        annualButton.addTarget(self, action: #selector(annualTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func monthlyTapped() {
        guard let product = monthlyProduct else { return }
        purchaseProduct(product)
    }

    @objc private func annualTapped() {
        guard let product = annualProduct else { return }
        purchaseProduct(product)
    }

    @objc private func restoreTapped() {
        spinner.startAnimating()
        restoreButton.isEnabled = false
        Task {
            await SubscriptionManager.shared.restorePurchases()
            spinner.stopAnimating()
            restoreButton.isEnabled = true
            if SubscriptionManager.shared.isPremium {
                showSuccess()
            } else {
                showAlert(title: "No Subscription Found",
                          message: "No active subscription was found for this Apple ID.")
            }
        }
    }

    // MARK: - Products

    private func loadProducts() {
        spinner.startAnimating()
        Task {
            await SubscriptionManager.shared.loadProducts()
            let products = SubscriptionManager.shared.products

            for product in products {
                if product.id == SubscriptionManager.monthlyID {
                    monthlyProduct = product
                    monthlyButton.isEnabled = true
                    updateButton(monthlyButton,
                                 title: "Monthly",
                                 subtitle: "\(product.displayPrice)/month")
                } else if product.id == SubscriptionManager.annualID {
                    annualProduct = product
                    annualButton.isEnabled = true
                    updateButton(annualButton,
                                 title: "Annual — Save 37%",
                                 subtitle: "\(product.displayPrice)/year")
                }
            }

            spinner.stopAnimating()

            if products.isEmpty {
                updateButton(monthlyButton, title: "Monthly", subtitle: "$1.99/month")
                updateButton(annualButton, title: "Annual — Save 37%", subtitle: "$14.99/year")
                monthlyButton.isEnabled = true
                annualButton.isEnabled = true
            }
        }
    }

    // MARK: - Purchase flow

    private func purchaseProduct(_ product: Product) {
        spinner.startAnimating()
        monthlyButton.isEnabled = false
        annualButton.isEnabled = false

        Task {
            do {
                let transaction = try await SubscriptionManager.shared.purchase(product)
                spinner.stopAnimating()
                monthlyButton.isEnabled = true
                annualButton.isEnabled = true

                if transaction != nil {
                    showSuccess()
                }
            } catch {
                spinner.stopAnimating()
                monthlyButton.isEnabled = true
                annualButton.isEnabled = true
                showAlert(title: "Purchase Failed", message: error.localizedDescription)
            }
        }
    }

    private func showSuccess() {
        let alert = UIAlertController(title: "Welcome to Premium!",
                                      message: "You now have access to all premium features.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func makeFeatureRow(icon: String, text: String) -> UIView {
        let container = UIView()

        let iconImage = UIImageView()
        iconImage.image = UIImage(systemName: icon)
        iconImage.tintColor = .systemBlue
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconImage)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconImage.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImage.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 28),
            iconImage.heightAnchor.constraint(equalToConstant: 28),

            label.leadingAnchor.constraint(equalTo: iconImage.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    private func makePurchaseButton(title: String, subtitle: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 14
        btn.clipsToBounds = true
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true

        var config = UIButton.Configuration.filled()
        config.title = title
        config.subtitle = subtitle
        config.titleAlignment = .center
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        btn.configuration = config

        return btn
    }

    private func updateButton(_ button: UIButton, title: String, subtitle: String) {
        var config = button.configuration ?? UIButton.Configuration.filled()
        config.title = title
        config.subtitle = subtitle
        button.configuration = config
    }
}

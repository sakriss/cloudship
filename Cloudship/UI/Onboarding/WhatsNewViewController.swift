//
//  WhatsNewViewController.swift
//  Cloudship
//

import UIKit

final class WhatsNewViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    var onDismiss: (() -> Void)?

    private let notes: ReleaseNotes
    private let iconView = CloudbreakUpdateIconView()
    private var didNotifyDismiss = false

    init(notes: ReleaseNotes) {
        self.notes = notes
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        iconView.playIfNeeded()
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = notes.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = notes.subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let bulletStack = UIStackView()
        bulletStack.axis = .vertical
        bulletStack.spacing = 14
        bulletStack.translatesAutoresizingMaskIntoConstraints = false
        notes.bullets.forEach { bulletStack.addArrangedSubview(makeBulletRow(text: $0)) }

        let continueButton = UIButton(type: .system)
        continueButton.configuration = .filled()
        continueButton.configuration?.cornerStyle = .large
        continueButton.configuration?.title = "Continue"
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            iconView,
            titleLabel,
            subtitleLabel,
            bulletStack,
            continueButton
        ])
        stack.axis = .vertical
        stack.spacing = 22
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 142),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.centerXAnchor.constraint(equalTo: stack.centerXAnchor),

            continueButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }

    private func makeBulletRow(text: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])

        return row
    }

    @objc private func continueTapped() {
        dismiss(animated: true) { [weak self] in
            self?.notifyDismissed()
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        notifyDismissed()
    }

    private func notifyDismissed() {
        guard !didNotifyDismiss else { return }
        didNotifyDismiss = true
        onDismiss?()
    }
}

//
//  CardView.swift
//  Cloudship
//
//  Base UIView subclass for all weather "block" cards.
//  Handles corner radius, shadow, adaptive background, and reorder handle.
//

import UIKit

class CardView: UIView {

    enum TextRole {
        case primary
        case secondary
        case tertiary
    }

    // MARK: - Configuration

    /// Inner padding applied by subclasses to their content.
    static let padding: CGFloat = 16

    /// Identifier used for persisting card order. Set by MainForecastViewController.
    var cardID: String = ""

    /// The drag handle view (≡ icon, top-right). Attach a UIPanGestureRecognizer to this.
    let reorderHandle: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bars = (0..<3).map { _ -> UIView in
            let bar = UIView()
            bar.backgroundColor = CardView.textColor(for: .tertiary)
            bar.layer.cornerRadius = 1.5
            bar.tag = 901
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.heightAnchor.constraint(equalToConstant: 3).isActive = true
            return bar
        }
        let stack = UIStackView(arrangedSubviews: bars)
        stack.axis = .vertical
        stack.spacing = 3
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.widthAnchor.constraint(equalToConstant: 28)
        ])
        return container
    }()

    /// Set to false to hide the reorder handle (e.g. header, alert banner).
    var showsReorderHandle: Bool = false {
        didSet { reorderHandle.isHidden = !showsReorderHandle }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = UIAccessibility.isReduceTransparencyEnabled
            ? .systemBackground
            : .secondarySystemBackground

        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.masksToBounds = false

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = UIAccessibility.isReduceTransparencyEnabled ? 0 : 0.08
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10

        // Reorder handle — top-right, with an intentionally generous touch target.
        addSubview(reorderHandle)
        NSLayoutConstraint.activate([
            reorderHandle.topAnchor.constraint(equalTo: topAnchor),
            reorderHandle.trailingAnchor.constraint(equalTo: trailingAnchor),
            reorderHandle.widthAnchor.constraint(equalToConstant: 52),
            reorderHandle.heightAnchor.constraint(equalToConstant: 52)
        ])
        updateChromeColors()
    }

    // MARK: - Tint & vintage styling

    /// Apply the user's chosen card tint. Call after configuring card content.
    func applyTint(_ style: CardTintStyle) {
        backgroundColor = UIAccessibility.isReduceTransparencyEnabled
            ? .systemBackground
            : style.cardBackgroundColor
    }

    /// Apply warm parchment/sepia styling for Time Machine historical mode.
    /// Overrides any user tint for the duration of the historical session.
    func applyVintageStyle() {
        backgroundColor = UIColor(red: 0.94, green: 0.87, blue: 0.70, alpha: 1)
        updateChromeColors()
    }

    /// Restore the card to the user's currently saved tint preference.
    func restoreTint() {
        applyTint(CardTintStyle.saved)
        updateChromeColors()
    }

    func updateChromeColors() {
        reorderHandle.subviews
            .flatMap(\.subviews)
            .filter { $0.tag == 901 }
            .forEach { $0.backgroundColor = Self.textColor(for: .tertiary) }
        layer.borderWidth = UIAccessibility.isDarkerSystemColorsEnabled ? 1 : 0
        layer.borderColor = UIColor.separator.cgColor
    }

    static func textColor(for role: TextRole) -> UIColor {
        if WeatherDataSourceManager.shared.isShowingHistorical {
            switch role {
            case .primary:
                return WeatherTheme.timeMachineTheme.textPrimary
            case .secondary:
                return WeatherTheme.timeMachineTheme.textSecondary
            case .tertiary:
                return WeatherTheme.timeMachineTheme.textSecondary.withAlphaComponent(0.78)
            }
        }

        switch role {
        case .primary:
            return .label
        case .secondary:
            return .secondaryLabel
        case .tertiary:
            return .tertiaryLabel
        }
    }

    // MARK: - Helpers

    /// Convenience: add a section title label pinned to top-left.
    func makeTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Self.textColor(for: .secondary)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}

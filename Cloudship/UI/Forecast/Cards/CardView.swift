//
//  CardView.swift
//  Cloudship
//
//  Base UIView subclass for all weather "block" cards.
//  Handles corner radius, shadow, adaptive background, and reorder handle.
//

import UIKit

class CardView: UIView {

    // MARK: - Configuration

    /// Inner padding applied by subclasses to their content.
    static let padding: CGFloat = 16

    /// Identifier used for persisting card order. Set by MainForecastViewController.
    var cardID: String = ""

    /// The drag handle view (≡ icon, top-right). Attach a UIPanGestureRecognizer to this.
    let reorderHandle: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 18),
            iv.heightAnchor.constraint(equalToConstant: 14)
        ])
        return container
    }()

    /// Set to false to hide the reorder handle (e.g. header, alert banner).
    var showsReorderHandle: Bool = true {
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
        backgroundColor = .secondarySystemBackground

        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.masksToBounds = false

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10

        // Reorder handle — top-right, 44×44 touch target
        addSubview(reorderHandle)
        NSLayoutConstraint.activate([
            reorderHandle.topAnchor.constraint(equalTo: topAnchor),
            reorderHandle.trailingAnchor.constraint(equalTo: trailingAnchor),
            reorderHandle.widthAnchor.constraint(equalToConstant: 44),
            reorderHandle.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Helpers

    /// Convenience: add a section title label pinned to top-left.
    func makeTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}

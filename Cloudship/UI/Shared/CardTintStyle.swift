//
//  CardTintStyle.swift
//  Cloudship
//
//  User-selectable tint options for weather cards.
//  Selected style is persisted in UserDefaults under "CardTintStyle".
//

import UIKit

enum CardTintStyle: Int, CaseIterable {

    case `default`  = 0
    case ocean      = 1
    case forest     = 2
    case sunset     = 3
    case lavender   = 4
    case rose       = 5
    case sand       = 6

    // MARK: - Persistence

    static var saved: CardTintStyle {
        CardTintStyle(rawValue: UserDefaults.standard.integer(forKey: "CardTintStyle")) ?? .default
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .default:  return "Default"
        case .ocean:    return "Ocean"
        case .forest:   return "Forest"
        case .sunset:   return "Sunset"
        case .lavender: return "Lavender"
        case .rose:     return "Rose"
        case .sand:     return "Sand"
        }
    }

    /// Solid color used for the swatch circle in Settings.
    var swatchColor: UIColor {
        switch self {
        case .default:  return .systemFill
        case .ocean:    return UIColor(red: 0.20, green: 0.45, blue: 0.75, alpha: 1)
        case .forest:   return UIColor(red: 0.18, green: 0.52, blue: 0.30, alpha: 1)
        case .sunset:   return UIColor(red: 0.88, green: 0.42, blue: 0.18, alpha: 1)
        case .lavender: return UIColor(red: 0.52, green: 0.35, blue: 0.78, alpha: 1)
        case .rose:     return UIColor(red: 0.82, green: 0.28, blue: 0.48, alpha: 1)
        case .sand:     return UIColor(red: 0.70, green: 0.58, blue: 0.38, alpha: 1)
        }
    }

    /// Adaptive card background: tint blended 18% into the system secondary background.
    /// Works correctly in both light and dark mode.
    var cardBackgroundColor: UIColor {
        guard self != .default else { return .secondarySystemBackground }

        let tint = swatchColor   // fixed, non-dynamic — safe to capture
        return UIColor { trait in
            let base = UIColor.secondarySystemBackground.resolvedColor(with: trait)
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0
            base.getRed(&r1, green: &g1, blue: &b1, alpha: &a)
            tint.getRed(&r2, green: &g2, blue: &b2, alpha: &a)
            let t: CGFloat = 0.18
            return UIColor(
                red:   r1 * (1 - t) + r2 * t,
                green: g1 * (1 - t) + g2 * t,
                blue:  b1 * (1 - t) + b2 * t,
                alpha: 1
            )
        }
    }
}

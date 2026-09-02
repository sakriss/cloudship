//
//  AppFontStyle.swift
//  Cloudship
//
//  Shared built-in typography preference for the app and widget extension.
//

import Foundation
import SwiftUI
import UIKit

enum AppFontStyle: Int, CaseIterable {
    case system = 0
    case rounded
    case serif
    case monospaced

    static let defaultsKey = "AppFontStyle"
    static let appGroupID = "group.happygiraffe.Cloudship-test"
    static let changedNotification = Notification.Name("appFontStyleChanged")

    var displayName: String {
        switch self {
        case .system: return "System"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .monospaced: return "Monospaced"
        }
    }

    static var saved: AppFontStyle {
        fontStyle(in: .standard)
    }

    static var shared: AppFontStyle {
        if let groupDefaults = UserDefaults(suiteName: appGroupID),
           groupDefaults.object(forKey: defaultsKey) != nil {
            return fontStyle(in: groupDefaults)
        }
        return saved
    }

    static func fontStyle(in defaults: UserDefaults) -> AppFontStyle {
        guard defaults.object(forKey: defaultsKey) != nil else { return .system }
        return AppFontStyle(rawValue: defaults.integer(forKey: defaultsKey)) ?? .system
    }

    static func save(_ style: AppFontStyle, defaults: UserDefaults = .standard) {
        defaults.set(style.rawValue, forKey: defaultsKey)
        mirrorToAppGroup(style)
    }

    static func mirrorToAppGroup(_ style: AppFontStyle) {
        UserDefaults(suiteName: appGroupID)?.set(style.rawValue, forKey: defaultsKey)
    }

    private var uiDesign: UIFontDescriptor.SystemDesign? {
        switch self {
        case .system: return nil
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }

    var swiftUIDesign: Font.Design {
        switch self {
        case .system: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }

    func font(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) -> UIFont {
        var descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        if let weight {
            var traits = descriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
            traits[.weight] = weight.rawValue
            descriptor = descriptor.addingAttributes([.traits: traits])
        }

        if let uiDesign,
           let designedDescriptor = descriptor.withDesign(uiDesign) {
            descriptor = designedDescriptor
        }

        return UIFont(descriptor: descriptor, size: 0)
    }

    func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let uiDesign,
              let descriptor = systemFont.fontDescriptor.withDesign(uiDesign) else {
            return systemFont
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    func scaledFont(size: CGFloat, weight: UIFont.Weight = .regular, textStyle: UIFont.TextStyle = .body) -> UIFont {
        UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font(size: size, weight: weight))
    }

    func font(matching sourceFont: UIFont) -> UIFont {
        let weight = UIFont.Weight(sourceFont.fontDescriptor.object(forKey: .traits)
            .flatMap { $0 as? [UIFontDescriptor.TraitKey: Any] }?[.weight] as? CGFloat ?? 0)
        let candidate = font(size: sourceFont.pointSize, weight: weight)
        return candidate.withSize(sourceFont.pointSize)
    }
}

extension UIFont.Weight {
    init(_ traitWeight: CGFloat) {
        switch traitWeight {
        case ...UIFont.Weight.ultraLight.rawValue: self = .ultraLight
        case ...UIFont.Weight.thin.rawValue: self = .thin
        case ...UIFont.Weight.light.rawValue: self = .light
        case ...UIFont.Weight.regular.rawValue: self = .regular
        case ...UIFont.Weight.medium.rawValue: self = .medium
        case ...UIFont.Weight.semibold.rawValue: self = .semibold
        case ...UIFont.Weight.bold.rawValue: self = .bold
        case ...UIFont.Weight.heavy.rawValue: self = .heavy
        default: self = .black
        }
    }
}

extension UIFont {
    static func appFont(forTextStyle textStyle: UIFont.TextStyle, weight: UIFont.Weight? = nil) -> UIFont {
        AppFontStyle.saved.font(forTextStyle: textStyle, weight: weight)
    }

    static func appFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        AppFontStyle.saved.font(size: size, weight: weight)
    }

    static func appScaledFont(size: CGFloat, weight: UIFont.Weight = .regular, textStyle: UIFont.TextStyle = .body) -> UIFont {
        AppFontStyle.saved.scaledFont(size: size, weight: weight, textStyle: textStyle)
    }
}

extension Font {
    static func app(_ textStyle: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        let base = Font.system(textStyle, design: AppFontStyle.shared.swiftUIDesign)
        if let weight {
            return base.weight(weight)
        }
        return base
    }

    static func app(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: AppFontStyle.shared.swiftUIDesign)
    }
}

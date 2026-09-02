//
//  AppTypography.swift
//  Cloudship
//
//  Applies the selected built-in font style to UIKit view hierarchies.
//

import UIKit

enum AppTypography {
    static func apply(to view: UIView, style: AppFontStyle = .saved) {
        restyle(view, style: style)
    }

    static func applyToVisibleWindows(style: AppFontStyle = .saved) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { apply(to: $0, style: style) }
    }

    static func configureNavigationAppearance(style: AppFontStyle = .saved) {
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        applyFont(to: standard, style: style)
        UINavigationBar.appearance().standardAppearance = standard
        UINavigationBar.appearance().compactAppearance = standard
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = standard
        }

        let fonts = tabBarFonts(for: style)
        UITabBarItem.appearance().setTitleTextAttributes([.font: fonts.normal], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: fonts.selected], for: .selected)
    }

    static func applyFont(to appearance: UINavigationBarAppearance, style: AppFontStyle = .saved) {
        appearance.titleTextAttributes[.font] = style.font(forTextStyle: .headline, weight: .semibold)
        appearance.largeTitleTextAttributes[.font] = style.font(forTextStyle: .largeTitle, weight: .bold)

        [appearance.buttonAppearance, appearance.doneButtonAppearance, appearance.backButtonAppearance]
            .forEach { buttonAppearance in
                buttonAppearance.normal.titleTextAttributes[.font] = style.font(forTextStyle: .body)
                buttonAppearance.highlighted.titleTextAttributes[.font] = style.font(forTextStyle: .body)
                buttonAppearance.disabled.titleTextAttributes[.font] = style.font(forTextStyle: .body)
            }
    }

    static func applyFont(to appearance: UITabBarAppearance, style: AppFontStyle = .saved) {
        let fonts = tabBarFonts(for: style)
        [appearance.stackedLayoutAppearance,
         appearance.inlineLayoutAppearance,
         appearance.compactInlineLayoutAppearance].forEach { itemAppearance in
            itemAppearance.normal.titleTextAttributes[.font] = fonts.normal
            itemAppearance.selected.titleTextAttributes[.font] = fonts.selected
        }
    }

    private static func restyle(_ view: UIView, style: AppFontStyle) {
        switch view {
        case let label as UILabel:
            label.font = style.font(matching: label.font)
        case let button as UIButton:
            button.titleLabel?.font = button.titleLabel?.font.map(style.font(matching:))
            if var configuration = button.configuration {
                let existingTransformer = configuration.titleTextAttributesTransformer
                configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                    var attributes = existingTransformer?(incoming) ?? incoming
                    let sourceFont = attributes.font ?? button.titleLabel?.font ?? style.font(forTextStyle: .body)
                    attributes.font = style.font(matching: sourceFont)
                    return attributes
                }
                button.configuration = configuration
                button.setNeedsUpdateConfiguration()
            }
        case let textField as UITextField:
            if let font = textField.font {
                textField.font = style.font(matching: font)
            }
        case let textView as UITextView:
            if let font = textView.font {
                textView.font = style.font(matching: font)
            }
        case let segmentedControl as UISegmentedControl:
            let normalFont = style.scaledFont(size: 13, weight: .regular, textStyle: .subheadline)
            let selectedFont = style.scaledFont(size: 13, weight: .semibold, textStyle: .subheadline)
            segmentedControl.setTitleTextAttributes([.font: normalFont], for: .normal)
            segmentedControl.setTitleTextAttributes([.font: selectedFont], for: .selected)
        case let navigationBar as UINavigationBar:
            applyFont(to: navigationBar.standardAppearance, style: style)
            navigationBar.compactAppearance.map { applyFont(to: $0, style: style) }
            navigationBar.scrollEdgeAppearance.map { applyFont(to: $0, style: style) }
        case let tabBar as UITabBar:
            applyFont(to: tabBar.standardAppearance, style: style)
            tabBar.scrollEdgeAppearance.map { applyFont(to: $0, style: style) }
        default:
            break
        }

        view.subviews.forEach { restyle($0, style: style) }
    }

    private static func tabBarFonts(for style: AppFontStyle) -> (normal: UIFont, selected: UIFont) {
        // UIKit gives tab titles a narrow fixed layout. Wider designs need a slightly
        // smaller optical size to keep Forecast and Settings from truncating.
        let size: CGFloat = style == .system || style == .rounded ? 10 : 8
        return (
            style.scaledFont(size: size, weight: .regular, textStyle: .caption2),
            style.scaledFont(size: size, weight: .semibold, textStyle: .caption2)
        )
    }
}

import SwiftUI
import UIKit

enum ProtocolaAppearance {

    static func configure() {
        configureNavigation()
        configureTabs()
        configureSegments()
    }


    private static func configureNavigation() {
        let large =
            UIFont.systemFont(
                ofSize:
                    Theme.pageTitleSize,
                weight: .bold
            )
        let inline =
            UIFont.systemFont(
                ofSize:
                    Theme.sectionTitleSize,
                weight: .semibold
            )

        UINavigationBar.appearance()
            .largeTitleTextAttributes = [
                .font: large,
                .foregroundColor:
                    UIColor(Theme.ink)
            ]

        UINavigationBar.appearance()
            .titleTextAttributes = [
                .font: inline,
                .foregroundColor:
                    UIColor(Theme.ink)
            ]
    }


    private static func configureTabs() {
        let font =
            UIFont.systemFont(
                ofSize:
                    Theme.tabLabelSize,
                weight: .medium
            )

        UITabBarItem.appearance()
            .setTitleTextAttributes(
                [.font: font],
                for: .normal
            )

        UITabBarItem.appearance()
            .setTitleTextAttributes(
                [.font: font],
                for: .selected
            )
    }


    private static func configureSegments() {
        let font =
            UIFont.systemFont(
                ofSize:
                    Theme.segmentLabelSize,
                weight: .medium
            )

        UISegmentedControl.appearance()
            .selectedSegmentTintColor =
                UIColor(Theme.teal)

        UISegmentedControl.appearance()
            .setTitleTextAttributes(
                [
                    .font: font,
                    .foregroundColor:
                        UIColor(
                            Theme.textSecondary
                        )
                ],
                for: .normal
            )

        UISegmentedControl.appearance()
            .setTitleTextAttributes(
                [
                    .font: font,
                    .foregroundColor:
                        UIColor(
                            Theme.onDarkPrimary
                        )
                ],
                for: .selected
            )
    }
}

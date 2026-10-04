import SwiftUI
import UIKit

enum ProtocolaAppearance {

    static func configure() {
        configureNavigation()
        configureTabs()
        configureSegments()
    }


    private static func configureNavigation() {
        guard
            let largeDescriptor =
                UIFont.systemFont(
                    ofSize:
                        Theme.pageTitleSize,
                    weight: .semibold
                )
                .fontDescriptor
                .withDesign(.serif),
            let inlineDescriptor =
                UIFont.systemFont(
                    ofSize:
                        Theme.sectionTitleSize,
                    weight: .semibold
                )
                .fontDescriptor
                .withDesign(.serif)
        else {
            return
        }

        UINavigationBar.appearance()
            .largeTitleTextAttributes = [
                .font:
                    UIFont(
                        descriptor:
                            largeDescriptor,
                        size:
                            Theme.pageTitleSize
                    ),
                .foregroundColor:
                    UIColor(Theme.ink)
            ]

        UINavigationBar.appearance()
            .titleTextAttributes = [
                .font:
                    UIFont(
                        descriptor:
                            inlineDescriptor,
                        size:
                            Theme.sectionTitleSize
                    ),
                .foregroundColor:
                    UIColor(Theme.ink)
            ]
    }


    private static func configureTabs() {
        guard
            let descriptor =
                UIFont.systemFont(
                    ofSize:
                        Theme.tabLabelSize,
                    weight: .medium
                )
                .fontDescriptor
                .withDesign(.serif)
        else {
            return
        }

        let font =
            UIFont(
                descriptor: descriptor,
                size:
                    Theme.tabLabelSize
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
        guard
            let descriptor =
                UIFont.systemFont(
                    ofSize:
                        Theme.segmentLabelSize,
                    weight: .medium
                )
                .fontDescriptor
                .withDesign(.serif)
        else {
            return
        }

        let font =
            UIFont(
                descriptor: descriptor,
                size:
                    Theme.segmentLabelSize
            )

        UISegmentedControl.appearance()
            .selectedSegmentTintColor =
                UIColor(Theme.ink)

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

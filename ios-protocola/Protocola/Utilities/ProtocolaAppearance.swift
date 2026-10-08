import SwiftUI
import UIKit

enum ProtocolaAppearance {

    static func configure() {
        configureNavigation()
        configureTabs()
        configureSegments()
    }


    private static func serif(
        _ font: UIFont
    ) -> UIFont {
        guard
            let descriptor =
                font.fontDescriptor
                    .withDesign(.serif)
        else {
            return font
        }
        return UIFont(
            descriptor: descriptor,
            size: font.pointSize
        )
    }


    private static func configureNavigation() {
        // Scaled at launch with the user's text size, like Theme's fonts.
        // Navigation titles use New York, matching Theme's display type.
        let large =
            serif(
                UIFont.systemFont(
                    ofSize:
                        Theme.scaledSize(
                            Theme.pageTitleSize,
                            .largeTitle,
                            max: 52
                        ),
                    weight: .medium
                )
            )
        let inline =
            serif(
                UIFont.systemFont(
                    ofSize:
                        Theme.scaledSize(
                            Theme.sectionTitleSize,
                            .headline,
                            max: 28
                        ),
                    weight: .semibold
                )
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
                    Theme.scaledSize(
                        Theme.segmentLabelSize,
                        .footnote,
                        max: 22
                    ),
                weight: .medium
            )

        UISegmentedControl.appearance()
            .selectedSegmentTintColor =
                UIColor(Theme.surface)

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
                            Theme.ink
                        )
                ],
                for: .selected
            )
    }
}

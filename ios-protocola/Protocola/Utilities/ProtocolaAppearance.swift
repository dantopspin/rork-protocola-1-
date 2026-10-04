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
                    ofSize: 34,
                    weight: .semibold
                )
                .fontDescriptor
                .withDesign(.serif),
            let inlineDescriptor =
                UIFont.systemFont(
                    ofSize: 18,
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
                        size: 34
                    ),
                .foregroundColor:
                    UIColor(
                        red: 0.0784,
                        green: 0.0784,
                        blue: 0.0706,
                        alpha: 1
                    )
            ]

        UINavigationBar.appearance()
            .titleTextAttributes = [
                .font:
                    UIFont(
                        descriptor:
                            inlineDescriptor,
                        size: 18
                    ),
                .foregroundColor:
                    UIColor(
                        red: 0.0784,
                        green: 0.0784,
                        blue: 0.0706,
                        alpha: 1
                    )
            ]
    }


    private static func configureTabs() {
        guard
            let descriptor =
                UIFont.systemFont(
                    ofSize: 10,
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
                size: 10
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
                    ofSize: 13,
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
                size: 13
            )

        UISegmentedControl.appearance()
            .selectedSegmentTintColor =
                UIColor(
                    red: 0.0784,
                    green: 0.0784,
                    blue: 0.0706,
                    alpha: 1
                )

        UISegmentedControl.appearance()
            .setTitleTextAttributes(
                [
                    .font: font,
                    .foregroundColor:
                        UIColor(
                            red: 0.4353,
                            green: 0.4235,
                            blue: 0.3961,
                            alpha: 1
                        )
                ],
                for: .normal
            )

        UISegmentedControl.appearance()
            .setTitleTextAttributes(
                [
                    .font: font,
                    .foregroundColor:
                        UIColor.white
                ],
                for: .selected
            )
    }
}

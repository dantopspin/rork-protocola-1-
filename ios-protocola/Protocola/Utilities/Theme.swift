import SwiftUI

enum Theme {

    // MARK: - Palette

    /// Warm neutral canvas. This is the visual default for the app.
    static let paper = Color(
        red: 0.9569,
        green: 0.9490,
        blue: 0.9333
    )

    /// Warm-white content surface.
    static let surface = Color(
        red: 0.9922,
        green: 0.9882,
        blue: 0.9765
    )

    /// Near-black primary ink and primary action color.
    static let ink = Color(
        red: 0.0784,
        green: 0.0784,
        blue: 0.0706
    )

    /// Supporting text and quiet metadata.
    static let muted = Color(
        red: 0.4353,
        green: 0.4235,
        blue: 0.3961
    )

    /// Muted mineral teal. Use sparingly for active/recorded states,
    /// links, chart emphasis, and intentional selection.
    static let teal = Color(
        red: 0.2745,
        green: 0.4235,
        blue: 0.3922
    )

    /// Attention only: low supply, delayed, partial, overdue.
    static let amber = Color(
        red: 0.5804,
        green: 0.4627,
        blue: 0.2471
    )

    /// Destructive semantics only.
    static let danger = Color(
        red: 0.6667,
        green: 0.3216,
        blue: 0.3020
    )


    // MARK: - Structural tones

    static let border = ink.opacity(0.12)
    static let line = ink.opacity(0.09)
    static let neutralTint = ink.opacity(0.045)
    static let tealTint = teal.opacity(0.09)
    static let amberTint = amber.opacity(0.10)
    static let dangerTint = danger.opacity(0.09)

    /// Rare elevation only. Spacing and borders do most of the work.
    static let shadow = ink.opacity(0.055)


    // MARK: - Typography

    /// Classical system serif keeps the app strict and editorial
    /// without shipping or embedding a custom font.
    static let pageTitle =
        Font.system(
            size: 32,
            weight: .semibold,
            design: .serif
        )

    static let modalTitle =
        Font.system(
            size: 20,
            weight: .semibold,
            design: .serif
        )

    static let sectionTitle =
        Font.system(
            size: 17,
            weight: .medium,
            design: .serif
        )

    static let body =
        Font.system(
            size: 15,
            weight: .regular,
            design: .serif
        )

    static let label =
        Font.system(
            size: 14,
            weight: .medium,
            design: .serif
        )

    static let caption =
        Font.system(
            size: 12,
            weight: .regular,
            design: .serif
        )

    static let micro =
        Font.system(
            size: 11,
            weight: .medium,
            design: .serif
        )

    static let buttonLabel =
        Font.system(
            size: 15,
            weight: .medium,
            design: .serif
        )

    static let metric =
        Font.system(
            size: 32,
            weight: .medium,
            design: .serif
        )


    // MARK: - Spacing

    static let spaceXXS: CGFloat = 4
    static let spaceXS: CGFloat = 8
    static let spaceS: CGFloat = 12
    static let spaceM: CGFloat = 16

    /// Standard page horizontal inset.
    static let spaceL: CGFloat = 24

    /// Major section rhythm.
    static let spaceXL: CGFloat = 32

    static let spaceXXL: CGFloat = 40


    // MARK: - Geometry

    /// Sharper than the previous system while still unmistakably iOS.
    static let radiusCard: CGFloat = 12
    static let radiusRow: CGFloat = 10
    static let radiusButton: CGFloat = 10
    static let radiusBadge: CGFloat = 6


    // MARK: - Layout

    static let maxContent: CGFloat = 680
    static let minimumTapTarget: CGFloat = 44
}

import SwiftUI

enum Theme {

    // MARK: - Core palette

    /// Warm, quiet canvas. Slightly cooler and more neutral than the old paper.
    static let paper = Color(
        red: 0.961,
        green: 0.953,
        blue: 0.933
    )

    /// Main content surface. Not pure optical white.
    static let surface = Color(
        red: 0.992,
        green: 0.988,
        blue: 0.976
    )

    /// Secondary structural surface for quiet controls and grouped rows.
    static let surfaceMuted = Color(
        red: 0.935,
        green: 0.928,
        blue: 0.908
    )

    /// Muted mineral green. Used sparingly for state and data emphasis.
    static let teal = Color(
        red: 0.235,
        green: 0.396,
        blue: 0.369
    )

    /// Attention only. Intentionally subdued.
    static let amber = Color(
        red: 0.620,
        green: 0.385,
        blue: 0.145
    )

    /// Editorial near-black.
    static let ink = Color(
        red: 0.060,
        green: 0.058,
        blue: 0.052
    )

    /// Secondary editorial text.
    static let muted = Color(
        red: 0.430,
        green: 0.416,
        blue: 0.385
    )


    // MARK: - Structural tones

    static let border = Color(
        red: 0.835,
        green: 0.820,
        blue: 0.785
    )

    static let line = Color(
        red: 0.865,
        green: 0.852,
        blue: 0.823
    )

    static let tealTint = teal.opacity(0.08)
    static let neutralTint = ink.opacity(0.035)
    static let amberTint = amber.opacity(0.09)


    // MARK: - Spacing

    static let spaceXXS: CGFloat = 4
    static let spaceXS: CGFloat = 8
    static let spaceS: CGFloat = 12
    static let spaceM: CGFloat = 16

    /// Card-to-card / row-group spacing.
    static let spaceL: CGFloat = 20

    /// Screen horizontal padding and major content breathing room.
    static let spaceXL: CGFloat = 24

    /// Major section separation.
    static let spaceXXL: CGFloat = 32


    // MARK: - Corner geometry

    /// Sharper than the previous visual system, while still feeling iOS-native.
    static let radiusCard: CGFloat = 12
    static let radiusRow: CGFloat = 9
    static let radiusButton: CGFloat = 10


    // MARK: - Editorial typography

    static let pageTitle = Font.system(
        size: 34,
        weight: .regular,
        design: .serif
    )

    static let heroTitle = Font.system(
        size: 25,
        weight: .regular,
        design: .serif
    )

    static let metric = Font.system(
        size: 34,
        weight: .regular,
        design: .serif
    )

    static let sectionTitle = Font.system(
        size: 18,
        weight: .medium,
        design: .serif
    )

    static let itemTitle = Font.system(
        size: 17,
        weight: .medium,
        design: .serif
    )

    static let editorialBody = Font.system(
        size: 16,
        weight: .regular,
        design: .serif
    )


    // MARK: - Layout

    static let maxContent: CGFloat = 680
}

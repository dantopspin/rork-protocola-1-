import SwiftUI

enum Theme {

    // MARK: - Core palette

    /// Warm paper background used across Protocola.
    static let paper = Color(
        red: 0.9686,
        green: 0.9608,
        blue: 0.9412
    )

    /// Main light content surface.
    static let surface = Color.white

    /// Primary brand/action color.
    /// Use for primary actions, selected states, links,
    /// recorded/success semantics, and intentional brand moments.
    static let teal = Color(
        red: 0.0588,
        green: 0.4627,
        blue: 0.4314
    )

    /// Attention state only:
    /// partial, delayed, low supply, depleted, warnings.
    static let amber = Color(
        red: 0.7059,
        green: 0.3255,
        blue: 0.0353
    )

    /// Strong editorial ink.
    /// Use for custom hero surfaces, key typography,
    /// and deliberate branded content — not every system label.
    static let ink = Color(
        red: 0.0538,
        green: 0.0519,
        blue: 0.0445
    )

    /// Supporting custom text and metadata.
    /// Prefer `.secondary` on standard native iOS controls where appropriate.
    static let muted = Color(
        red: 0.3816,
        green: 0.3779,
        blue: 0.3632
    )


    // MARK: - Structural tones

    /// Editorial border for custom information/data cards.
    ///
    /// Deliberately softer than full ink:
    /// crisp enough to define structure without becoming
    /// neo-brutalist or visually overpowering.
    static let border = ink.opacity(0.30)

    /// Light separators, internal dividers,
    /// and inactive custom outlines.
    static let line = Color(
        red: 0.8362,
        green: 0.8319,
        blue: 0.8150
    )

    /// Light selected/custom emphasis surface.
    static let tealTint = teal.opacity(0.08)

    /// Very subtle neutral content tint.
    static let neutralTint = ink.opacity(0.045)

    /// Background tint for warning/attention surfaces.
    static let amberTint = amber.opacity(0.10)


    // MARK: - Spacing

    /// Micro spacing inside tightly related content.
    static let spaceXXS: CGFloat = 4

    /// Compact spacing.
    static let spaceXS: CGFloat = 8

    /// Small component spacing.
    static let spaceS: CGFloat = 12

    /// Standard internal card/row spacing.
    static let spaceM: CGFloat = 16

    /// Standard screen/content horizontal inset.
    static let spaceL: CGFloat = 20

    /// Major section separation.
    static let spaceXL: CGFloat = 28


    // MARK: - Corner geometry

    /// Primary custom content cards.
    static let radiusCard: CGFloat = 16

    /// Nested rows, tags, chips, and custom controls.
    static let radiusRow: CGFloat = 12

    /// Custom buttons.
    static let radiusButton: CGFloat = 12


    // MARK: - Layout

    /// Maximum readable width on larger devices.
    static let maxContent: CGFloat = 680
}
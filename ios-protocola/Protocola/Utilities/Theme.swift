import SwiftUI

/// Fixed visual tokens for the entire app.
///
/// Product content must use these values instead of local font sizes, colors,
/// radii, shadows, or spacing. Native iOS chrome may retain system material.
enum Theme {

    // MARK: - Foundation colors

    /// #F5F3EE — main app canvas.
    static let paper = Color(
        red: 0.9608,
        green: 0.9529,
        blue: 0.9333
    )

    /// #FCFBF8 — standard content surface.
    static let surface = Color(
        red: 0.9882,
        green: 0.9843,
        blue: 0.9725
    )

    /// #FFFFFF — rare foreground/modal surface.
    static let surfaceRaised = Color.white

    /// #151513 — primary text, icons, and primary actions.
    static let ink = Color(
        red: 0.0824,
        green: 0.0824,
        blue: 0.0745
    )

    /// #706D66 — supporting text.
    static let textSecondary = Color(
        red: 0.4392,
        green: 0.4275,
        blue: 0.4000
    )

    /// #96928A — dates, metadata, inactive states.
    static let textTertiary = Color(
        red: 0.5882,
        green: 0.5725,
        blue: 0.5412
    )

    /// Compatibility alias used throughout the existing codebase.
    static let muted = textSecondary

    /// #466C64 — semantic active/recorded/chart emphasis only.
    static let teal = Color(
        red: 0.2745,
        green: 0.4235,
        blue: 0.3922
    )

    /// #94763F — overdue, low inventory, attention only.
    static let amber = Color(
        red: 0.5804,
        green: 0.4627,
        blue: 0.2471
    )

    /// #A6534D — destructive semantics only.
    static let danger = Color(
        red: 0.6510,
        green: 0.3255,
        blue: 0.3020
    )

    /// #171715 — at most one high-value dark product surface per screen.
    static let darkSurface = Color(
        red: 0.0902,
        green: 0.0902,
        blue: 0.0824
    )

    static let onDarkPrimary = Color(
        red: 0.9804,
        green: 0.9765,
        blue: 0.9608
    )

    static let onDarkSecondary = onDarkPrimary.opacity(0.62)


    // MARK: - Structural colors

    static let hairline = ink.opacity(0.11)
    static let border = hairline
    static let line = hairline
    static let subtleFill = ink.opacity(0.045)
    static let neutralTint = subtleFill
    static let tealTint = teal.opacity(0.10)
    static let amberTint = amber.opacity(0.10)
    static let dangerTint = danger.opacity(0.10)

    /// Reserved for transient/floating surfaces only.
    static let shadow = ink.opacity(0.055)


    // MARK: - Typography

    static let displaySize: CGFloat = 38
    static let pageTitleSize: CGFloat = 34
    static let metricLargeSize: CGFloat = 34
    static let modalTitleSize: CGFloat = 20
    static let sectionTitleSize: CGFloat = 18
    static let cardTitleSize: CGFloat = 16
    static let bodySize: CGFloat = 15
    static let buttonLabelSize: CGFloat = 15
    static let labelSize: CGFloat = 14
    static let captionSize: CGFloat = 12.5
    static let microSize: CGFloat = 11
    static let tabLabelSize: CGFloat = 10
    static let segmentLabelSize: CGFloat = 13
    static let shareMetricSize: CGFloat = 64

    static let display =
        Font.system(
            size: displaySize,
            weight: .semibold,
            design: .serif
        )

    static let pageTitle =
        Font.system(
            size: pageTitleSize,
            weight: .semibold,
            design: .serif
        )

    static let metricLarge =
        Font.system(
            size: metricLargeSize,
            weight: .medium,
            design: .serif
        )

    /// Compatibility alias for existing metric call sites.
    static let metric = metricLarge

    static let modalTitle =
        Font.system(
            size: modalTitleSize,
            weight: .medium,
            design: .serif
        )

    static let sectionTitle =
        Font.system(
            size: sectionTitleSize,
            weight: .medium,
            design: .serif
        )

    static let cardTitle =
        Font.system(
            size: cardTitleSize,
            weight: .medium,
            design: .serif
        )

    static let body =
        Font.system(
            size: bodySize,
            weight: .regular,
            design: .serif
        )

    static let label =
        Font.system(
            size: labelSize,
            weight: .medium,
            design: .serif
        )

    static let buttonLabel =
        Font.system(
            size: buttonLabelSize,
            weight: .medium,
            design: .serif
        )

    static let caption =
        Font.system(
            size: captionSize,
            weight: .regular,
            design: .serif
        )

    static let micro =
        Font.system(
            size: microSize,
            weight: .medium,
            design: .serif
        )


    // MARK: - Spacing (4 pt base grid)

    static let spaceXXS: CGFloat = 4
    static let spaceXS: CGFloat = 8
    static let spaceS: CGFloat = 12
    static let spaceM: CGFloat = 16
    static let spaceML: CGFloat = 20
    static let spaceL: CGFloat = 24
    static let spaceXL: CGFloat = 32
    static let spaceXXL: CGFloat = 40
    static let spaceXXXL: CGFloat = 48


    // MARK: - Geometry

    static let radiusCard: CGFloat = 12
    static let radiusRow: CGFloat = 10
    static let radiusButton: CGFloat = 10
    static let radiusField: CGFloat = 8
    static let radiusBadge: CGFloat = 6

    static let buttonHeight: CGFloat = 46
    static let compactButtonHeight: CGFloat = 44
    static let rowHeight: CGFloat = 54
    static let dataRowHeight: CGFloat = 48
    static let badgeHeight: CGFloat = 20
    static let iconColumn: CGFloat = 24
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 18
    static let iconLarge: CGFloat = 28

    static let chartHeight: CGFloat = 145
    static let shareCardWidth: CGFloat = 520
    static let shareBarHeight: CGFloat = 64

    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 3

    static let statusDot: CGFloat = 6
    static let siteDot: CGFloat = 8
    static let insertionLineHeight: CGFloat = 2
    static let onboardingRowHeight: CGFloat = 58
    static let onboardingProgressHeight: CGFloat = 4
    static let onboardingProgressActiveWidth: CGFloat = 18
    static let onboardingProgressInactiveWidth: CGFloat = 6
    static let shareBarRadius: CGFloat = 2
    static let emptyStateMinHeight: CGFloat = 260
    static let compactMetricTileHeight: CGFloat = 92
    static let sharePreviewMinHeight: CGFloat = 240


    // MARK: - Layout

    static let pageInset: CGFloat = 24
    static let cardInset: CGFloat = 16
    static let heroInset: CGFloat = 20
    static let maxContent: CGFloat = 680
    static let minimumTapTarget: CGFloat = 44
}

import SwiftUI

/// Fixed visual tokens for the entire app.
///
/// Direction: clinical editorial instrument. Product content is deliberately
/// flat, sharp, typographic, and restrained. Native iOS chrome remains native.
enum Theme {

    // MARK: - Foundation colors

    /// #F8F7F3 — warm near-white paper canvas.
    static let paper = Color(
        red: 0.9725,
        green: 0.9686,
        blue: 0.9529
    )

    /// #FBFAF7 — quiet product surface.
    static let surface = Color(
        red: 0.9843,
        green: 0.9804,
        blue: 0.9686
    )

    static let surfaceRaised = Color.white

    /// #121211 — primary type and rules.
    static let ink = Color(
        red: 0.0706,
        green: 0.0706,
        blue: 0.0667
    )

    /// #67655F — supporting copy.
    static let textSecondary = Color(
        red: 0.4039,
        green: 0.3961,
        blue: 0.3725
    )

    /// #8D8982 — quiet metadata.
    static let textTertiary = Color(
        red: 0.5529,
        green: 0.5373,
        blue: 0.5098
    )

    static let muted = textSecondary

    /// #30536B — the single product accent from the original Peptide Lens
    /// direction. Used for primary actions, progress, selection, and charts.
    static let teal = Color(
        red: 0.1882,
        green: 0.3255,
        blue: 0.4196
    )

    static let amber = Color(
        red: 0.5804,
        green: 0.4627,
        blue: 0.2471
    )

    static let danger = Color(
        red: 0.6510,
        green: 0.3255,
        blue: 0.3020
    )

    /// Dark editorial surface; intentionally the same family as the CTA accent.
    static let darkSurface = teal

    static let onDarkPrimary = Color(
        red: 0.9922,
        green: 0.9882,
        blue: 0.9765
    )

    static let onDarkSecondary =
        onDarkPrimary.opacity(0.72)


    // MARK: - Structural colors

    static let hairline = ink.opacity(0.16)
    static let border = hairline
    static let line = ink.opacity(0.12)
    static let subtleFill = ink.opacity(0.025)
    static let neutralTint = subtleFill
    static let tealTint = teal.opacity(0.08)
    static let amberTint = amber.opacity(0.08)
    static let dangerTint = danger.opacity(0.08)
    static let shadow = ink.opacity(0.035)


    // MARK: - Typography

    static let displaySize: CGFloat = 38
    static let pageTitleSize: CGFloat = 34
    static let metricLargeSize: CGFloat = 34
    static let metricCompactSize: CGFloat = 26
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
    static let eyebrowTracking: CGFloat = 2.0

    static let display =
        Font.system(
            size: displaySize,
            weight: .bold
        )

    static let pageTitle =
        Font.system(
            size: pageTitleSize,
            weight: .bold
        )

    static let metricLarge =
        Font.system(
            size: metricLargeSize,
            weight: .semibold,
            design: .monospaced
        )

    static let metric = metricLarge

    static let metricCompact =
        Font.system(
            size: metricCompactSize,
            weight: .semibold,
            design: .monospaced
        )

    static let modalTitle =
        Font.system(
            size: modalTitleSize,
            weight: .semibold
        )

    static let sectionTitle =
        Font.system(
            size: sectionTitleSize,
            weight: .semibold
        )

    static let cardTitle =
        Font.system(
            size: cardTitleSize,
            weight: .semibold
        )

    static let body =
        Font.system(
            size: bodySize,
            weight: .regular
        )

    static let label =
        Font.system(
            size: labelSize,
            weight: .medium
        )

    static let buttonLabel =
        Font.system(
            size: buttonLabelSize,
            weight: .medium
        )

    static let caption =
        Font.system(
            size: captionSize,
            weight: .regular
        )

    static let micro =
        Font.system(
            size: microSize,
            weight: .semibold
        )

    static let shareMetric =
        Font.system(
            size: shareMetricSize,
            weight: .semibold,
            design: .monospaced
        )


    // MARK: - Spacing

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

    /// Sharp editorial geometry. Rounded native chrome is allowed outside
    /// product content, but app surfaces should read almost rectangular.
    static let radiusCard: CGFloat = 2
    static let radiusRow: CGFloat = 2
    static let radiusButton: CGFloat = 2
    static let radiusField: CGFloat = 0
    static let radiusBadge: CGFloat = 2

    static let buttonHeight: CGFloat = 48
    static let compactButtonHeight: CGFloat = 44
    static let rowHeight: CGFloat = 54
    static let dataRowHeight: CGFloat = 48
    static let badgeHeight: CGFloat = 22
    static let iconColumn: CGFloat = 24
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 18
    static let iconLarge: CGFloat = 28

    static let chartHeight: CGFloat = 145
    static let bodyMapHeight: CGFloat = 360
    static let vialPhotoHeight: CGFloat = 220
    static let shareCardWidth: CGFloat = 520
    static let shareBarHeight: CGFloat = 64

    static let shadowRadius: CGFloat = 6
    static let shadowY: CGFloat = 2
    static let ruleThickness: CGFloat = 1

    static let statusDot: CGFloat = 6
    static let siteDot: CGFloat = 8
    static let insertionLineHeight: CGFloat = 2
    static let onboardingRowHeight: CGFloat = 58
    static let onboardingProgressHeight: CGFloat = 3
    static let onboardingProgressActiveWidth: CGFloat = 18
    static let onboardingProgressInactiveWidth: CGFloat = 6
    static let shareBarRadius: CGFloat = 1
    static let emptyStateMinHeight: CGFloat = 260
    static let compactMetricTileHeight: CGFloat = 92
    static let sharePreviewMinHeight: CGFloat = 240
    static let calendarDayWidth: CGFloat = 64


    // MARK: - Layout

    static let pageInset: CGFloat = 24
    static let cardInset: CGFloat = 16
    static let heroInset: CGFloat = 20
    static let maxContent: CGFloat = 680
    static let minimumTapTarget: CGFloat = 44
}

import SwiftUI
import UIKit

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

    /// #747169 — quiet metadata that still clears 4.5:1 on paper.
    static let textTertiary = Color(
        red: 0.4549,
        green: 0.4431,
        blue: 0.4118
    )

    /// #30536B — the single product accent from the original Peptide Lens
    /// direction. Used for primary actions, progress, selection, and charts.
    static let teal = Color(
        red: 0.1882,
        green: 0.3255,
        blue: 0.4196
    )

    /// #876832 — attention color tuned to clear 4.5:1 in status text.
    static let amber = Color(
        red: 0.5294,
        green: 0.4078,
        blue: 0.1961
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
    static let onDarkHairline =
        onDarkPrimary.opacity(0.12)
    static let onDarkSubtleFill =
        onDarkPrimary.opacity(0.04)
    static let onDarkControlBorder =
        onDarkPrimary.opacity(0.46)


    // MARK: - Structural colors

    static let hairline = ink.opacity(0.16)
    static let controlBorder = ink.opacity(0.46)
    /// Fill for empty or inactive marks (unrecorded status dots, empty
    /// heatmap days). Never a rule; rules use `hairline`.
    static let inactiveFill = ink.opacity(0.12)
    static let subtleFill = ink.opacity(0.025)
    static let tealTint = teal.opacity(0.08)
    static let shadow = ink.opacity(0.035)

    // Interaction-state values live here so controls do not invent local
    // transparency or motion values.
    static let pressedFillOpacity = 0.84
    static let pressedControlOpacity = 0.64
    static let pressedSurfaceOpacity = 0.92
    static let statusFillOpacity = 0.055
    static let statusBorderOpacity = 0.22

    static let motionPressDuration = 0.12
    static let motionFeedbackDuration = 0.15
    static let motionStateDuration = 0.25
    static let motionTransitionDuration = 0.30
    static let motionStaggerDelay = 0.035
    static let motionEntranceOpacity = 0.0
    static let pressedPrimaryScale: CGFloat = 0.985
    static let pressedSecondaryScale: CGFloat = 0.99
    static let pressedRowScale: CGFloat = 0.995
    static let motionEntranceOffset: CGFloat = 8
    static let motionStaggerMaxIndex = 5
    static let springQuickResponse = 0.24
    static let springQuickDamping = 0.82
    static let springStandardResponse = 0.26
    static let springStandardDamping = 0.80
    static let springEmphasisResponse = 0.32
    static let springEmphasisDamping = 0.86


    // MARK: - Typography

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

    // Fonts scale with the user's text-size setting from the sizes above:
    // at the default setting they are exactly these sizes; larger settings
    // grow them along the matching iOS text style. Large display sizes are
    // capped so hero numbers stay inside their layouts.

    static var pageTitle: Font {
        scaled(pageTitleSize, .bold, .largeTitle, max: 52)
    }

    static var metricLarge: Font {
        scaled(metricLargeSize, .semibold, .largeTitle, max: 52, design: .monospaced)
    }

    static var metricCompact: Font {
        scaled(metricCompactSize, .semibold, .title1, max: 40, design: .monospaced)
    }

    static var modalTitle: Font {
        scaled(modalTitleSize, .semibold, .title3, max: 34)
    }

    static var sectionTitle: Font {
        scaled(sectionTitleSize, .semibold, .headline)
    }

    /// Title of a record row (protocol, entry, vial, lab, tool).
    static var cardTitle: Font {
        scaled(cardTitleSize, .semibold, .callout)
    }

    static var body: Font {
        scaled(bodySize, .regular, .body)
    }

    static var label: Font {
        scaled(labelSize, .medium, .subheadline)
    }

    static var buttonLabel: Font {
        scaled(buttonLabelSize, .medium, .body)
    }

    static var caption: Font {
        scaled(captionSize, .regular, .caption1)
    }

    static var micro: Font {
        scaled(microSize, .semibold, .caption2)
    }

    /// Share images are rendered at a fixed size, never scaled.
    static let shareMetric =
        Font.system(
            size: shareMetricSize,
            weight: .semibold,
            design: .monospaced
        )

    static let shareTitle =
        Font.system(
            size: sectionTitleSize,
            weight: .semibold
        )

    static let shareCaption =
        Font.system(
            size: captionSize,
            weight: .regular
        )

    /// Point size for a token at the current text-size setting.
    static func scaledSize(
        _ size: CGFloat,
        _ style: UIFont.TextStyle,
        max: CGFloat? = nil
    ) -> CGFloat {
        let value =
            UIFontMetrics(forTextStyle: style)
                .scaledValue(for: size)
        return max.map { Swift.min(value, $0) } ?? value
    }

    private static func scaled(
        _ size: CGFloat,
        _ weight: Font.Weight,
        _ style: UIFont.TextStyle,
        max: CGFloat? = nil,
        design: Font.Design = .default
    ) -> Font {
        Font.system(
            size: scaledSize(size, style, max: max),
            weight: weight,
            design: design
        )
    }


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

    // Permission sheet and recorded-entries heatmap
    static let iconTileSize: CGFloat = 56
    static let heatmapCellMin: CGFloat = 8
    static let heatmapCellMax: CGFloat = 20
    static let heatmapGap: CGFloat = 4
    /// Teal opacity for heatmap levels 1-3; level 4 is solid teal.
    static let heatmapLevelOpacities: [Double] = [0.28, 0.52, 0.76]

    // Paywall loading/success geometry
    static let paywallSuccessIconSize: CGFloat = 56
    static let paywallSkeletonTitleWidth: CGFloat = 104
    static let paywallSkeletonTitleHeight: CGFloat = 14
    static let paywallSkeletonDetailWidth: CGFloat = 148
    static let paywallSkeletonDetailHeight: CGFloat = 12
    static let paywallSkeletonActionWidth: CGFloat = 88


    // MARK: - Rhythm

    /// Gap between top-level sections of a scrolling screen.
    static let sectionGap: CGFloat = 32
    /// Gap between a section's eyebrow/rule and its content.
    static let sectionHeaderGap: CGFloat = 16
    /// Vertical padding inside a tappable record or navigation row.
    static let rowPadding: CGFloat = 12


    // MARK: - Layout

    static let pageInset: CGFloat = 24
    static let cardInset: CGFloat = 16
    static let heroInset: CGFloat = 20
    static let maxContent: CGFloat = 680
    static let minimumTapTarget: CGFloat = 44
}

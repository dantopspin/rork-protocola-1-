import SwiftUI
import UIKit

/// Fixed visual tokens for the entire app.
///
/// Direction: clinical editorial instrument. Product content is deliberately
/// flat, sharp, typographic, and restrained. Native iOS chrome remains native.
enum Theme {

    /// A colour that follows the system appearance. Every product colour is
    /// defined for both Light and Dark Mode.
    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(
            uiColor: UIColor { traits in
                let value =
                    traits.userInterfaceStyle == .dark
                    ? dark
                    : light
                return UIColor(
                    red: value.0,
                    green: value.1,
                    blue: value.2,
                    alpha: 1
                )
            }
        )
    }


    // MARK: - Foundation colors

    /// #FAF8F4 — light warm cream canvas.
    static let paper = adaptive(
        light: (0.980, 0.973, 0.957),
        dark: (0.071, 0.082, 0.078)
    )

    /// #FBFAF7 — quiet product surface.
    static let surface = adaptive(
        light: (1.0, 1.0, 1.0),
        dark: (0.122, 0.137, 0.129)
    )

    /// #111B29 — navy-black primary type.
    static let ink = adaptive(
        light: (0.067, 0.106, 0.161),
        dark: (0.937, 0.949, 0.941)
    )

    /// #626A73 — supporting copy, cool grey.
    static let textSecondary = adaptive(
        light: (0.384, 0.416, 0.451),
        dark: (0.659, 0.69, 0.675)
    )

    /// #6C737C — quiet metadata that still clears 4.5:1 on paper.
    static let textTertiary = adaptive(
        light: (0.424, 0.451, 0.486),
        dark: (0.596, 0.624, 0.612)
    )

    /// #30536B — the single product accent from the original Peptide Lens
    /// direction. Used for primary actions, progress, selection, and charts.
    static let teal = adaptive(
        light: (0.118, 0.357, 0.322),
        dark: (0.494, 0.769, 0.714)
    )

    /// #876832 — attention color tuned to clear 4.5:1 in status text.
    static let amber = adaptive(
        light: (0.5294, 0.4078, 0.1961),
        dark: (0.851, 0.698, 0.431)
    )

    static let danger = adaptive(
        light: (0.651, 0.3255, 0.302),
        dark: (0.878, 0.541, 0.502)
    )

    /// Filled accent surfaces (primary buttons, the hero card, icon tiles).
    /// Deep teal in both appearances: white text on it stays above 7.9:1,
    /// while `teal` itself lightens in Dark Mode for text and marks.
    static let accentFill = Color(
        red: 0.118,
        green: 0.357,
        blue: 0.322
    )

    /// "Due" and other time-sensitive information states.
    static let info = adaptive(
        light: (0.157, 0.420, 0.737),
        dark: (0.525, 0.737, 0.957)
    )

    /// Dark editorial surface; intentionally the same family as the CTA accent.
    static let darkSurface = accentFill

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
    /// Past days in a bar chart; today stays full strength.
    static let chartPastFill = teal.opacity(0.7)
    /// Always a darkening shadow, in both appearances.
    static let shadow = Color(
        red: 0,
        green: 0,
        blue: 0
    ).opacity(0.06)

    // Interaction-state values live here so controls do not invent local
    // transparency or motion values.
    static let pressedFillOpacity = 0.84
    static let pressedControlOpacity = 0.64
    static let pressedSurfaceOpacity = 0.92
    static let statusFillOpacity = 0.12
    static let statusBorderOpacity = 0.0

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
    static let metricCompactSize: CGFloat = 28
    static let modalTitleSize: CGFloat = 20
    static let sectionTitleSize: CGFloat = 17
    static let cardTitleSize: CGFloat = 17
    static let bodySize: CGFloat = 17
    static let buttonLabelSize: CGFloat = 17
    static let labelSize: CGFloat = 15
    static let captionSize: CGFloat = 13
    static let microSize: CGFloat = 11
    static let tabLabelSize: CGFloat = 10
    static let segmentLabelSize: CGFloat = 13
    static let shareMetricSize: CGFloat = 64
    static let eyebrowTracking: CGFloat = 0.6

    // Fonts scale with the user's text-size setting from the sizes above:
    // at the default setting they are exactly these sizes; larger settings
    // grow them along the matching iOS text style. Large display sizes are
    // capped so hero numbers stay inside their layouts.

    // Display type is New York, Apple's system serif; everything else is
    // SF Pro. Both scale with Dynamic Type.
    static var pageTitle: Font {
        scaled(pageTitleSize, .medium, .largeTitle, max: 52, design: .serif)
    }

    // Numbers use SF Pro with tabular figures, never a second typeface:
    // columns still align, and "0.25" reads as one number, not "0 . 25".
    static var metricLarge: Font {
        scaled(metricLargeSize, .medium, .largeTitle, max: 52, design: .serif)
            .monospacedDigit()
    }

    static var metricCompact: Font {
        scaled(metricCompactSize, .medium, .title1, max: 40, design: .serif)
            .monospacedDigit()
    }

    static var modalTitle: Font {
        scaled(modalTitleSize, .semibold, .title3, max: 34, design: .serif)
    }

    /// Serif title for a record that is the subject of a card (vials).
    static var serifTitle: Font {
        scaled(sectionTitleSize, .medium, .headline, design: .serif)
    }

    static var sectionTitle: Font {
        scaled(sectionTitleSize, .semibold, .headline)
    }

    /// Title of a record row (protocol, entry, vial, lab, tool).
    static var cardTitle: Font {
        scaled(cardTitleSize, .semibold, .headline)
    }

    static var body: Font {
        scaled(bodySize, .regular, .body)
    }

    static var label: Font {
        scaled(labelSize, .medium, .subheadline)
    }

    /// Regular-weight Subheadline: row labels and secondary values.
    static var subheadline: Font {
        scaled(labelSize, .regular, .subheadline)
    }

    static var buttonLabel: Font {
        scaled(buttonLabelSize, .medium, .body)
    }

    static var caption: Font {
        scaled(captionSize, .regular, .footnote)
    }

    /// Section label: Footnote Semibold, sentence case. Replaces the
    /// uppercase tracked eyebrow, the most common templated tell.
    static var sectionLabel: Font {
        scaled(captionSize, .semibold, .footnote)
    }

    /// Status chips: Footnote Medium.
    static var chipLabel: Font {
        scaled(captionSize, .medium, .footnote)
    }

    static var micro: Font {
        scaled(microSize, .semibold, .caption2)
    }

    /// Share images are rendered at a fixed size, never scaled.
    static let shareMetric =
        Font.system(
            size: shareMetricSize,
            weight: .semibold
        )
        .monospacedDigit()

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

    /// Soft geometry: rounded cards, pill buttons and capsule chips.
    static let radiusCard: CGFloat = 18
    static let radiusRow: CGFloat = 14
    /// Pill buttons: half the button height.
    static let radiusButton: CGFloat = 26
    static let radiusField: CGFloat = 12
    /// Capsule chips.
    static let radiusBadge: CGFloat = 14

    static let buttonHeight: CGFloat = 52
    static let compactButtonHeight: CGFloat = 44
    static let rowHeight: CGFloat = 54
    static let dataRowHeight: CGFloat = 48
    static let badgeHeight: CGFloat = 28
    static let iconColumn: CGFloat = 24
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 18
    static let iconLarge: CGFloat = 28

    static let chartHeight: CGFloat = 145
    /// The consistency chart supports its percentage; it never outweighs it.
    static let consistencyChartHeight: CGFloat = 96
    static let bodyMapHeight: CGFloat = 360
    static let vialPhotoHeight: CGFloat = 220
    static let shareCardWidth: CGFloat = 520
    static let shareBarHeight: CGFloat = 64

    static let shadowRadius: CGFloat = 14
    static let shadowY: CGFloat = 4
    static let ruleThickness: CGFloat = 1

    static let statusDot: CGFloat = 6
    /// Colour bar on the leading edge of an entry card.
    static let entryStripeWidth: CGFloat = 4
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
    /// Round icon badge leading a field row (Log Dose sheet).
    static let iconBadgeSize: CGFloat = 40
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

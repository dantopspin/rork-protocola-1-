import SwiftUI

/// Primary action. Near-black on light surfaces; light on the dark hero.
/// Keep one dominant primary action per screen/context.
struct TrackingPrimaryButtonStyle: ButtonStyle {
    var inverted: Bool = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .font(Theme.buttonLabel)
            .frame(
                maxWidth: .infinity,
                minHeight: Theme.buttonHeight
            )
            .foregroundStyle(
                inverted
                    ? Theme.ink
                    : Theme.onDarkPrimary
            )
            .background(
                configuration.isPressed
                    ? (
                        inverted
                        ? Theme.onDarkPrimary.opacity(0.82)
                        : Theme.ink.opacity(0.82)
                    )
                    : (
                        inverted
                        ? Theme.onDarkPrimary
                        : Theme.ink
                    ),
                in: .rect(
                    cornerRadius:
                        Theme.radiusButton
                )
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? 0.985
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.24,
                        dampingFraction: 0.82
                    ),
                value: configuration.isPressed
            )
    }
}


/// Quiet full-width secondary action.
struct TrackingSecondaryButtonStyle: ButtonStyle {
    var onDark: Bool = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .font(Theme.buttonLabel)
            .frame(
                maxWidth: .infinity,
                minHeight:
                    Theme.compactButtonHeight
            )
            .foregroundStyle(
                onDark
                    ? Theme.onDarkPrimary
                    : Theme.ink
            )
            .background(
                onDark
                    ? Theme.onDarkPrimary.opacity(0.07)
                    : Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusButton
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius:
                        Theme.radiusButton
                )
                .stroke(
                    onDark
                        ? Theme.onDarkPrimary.opacity(0.18)
                        : Theme.hairline,
                    lineWidth: 1
                )
            }
            .opacity(
                configuration.isPressed
                    ? 0.72
                    : 1
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? 0.985
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.22,
                        dampingFraction: 0.86
                    ),
                value: configuration.isPressed
            )
    }
}


/// Inline action used inside rows and compact modules.
/// It preserves the 44 pt tap target without expanding to full width.
struct TrackingCompactButtonStyle: ButtonStyle {
    var prominent: Bool = false

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .font(Theme.label)
            .foregroundStyle(
                prominent
                    ? Theme.onDarkPrimary
                    : Theme.ink
            )
            .padding(
                .horizontal,
                Theme.spaceS
            )
            .frame(
                minHeight:
                    Theme.compactButtonHeight
            )
            .background(
                prominent
                    ? Theme.ink
                    : Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusButton
                )
            )
            .overlay {
                if !prominent {
                    RoundedRectangle(
                        cornerRadius:
                            Theme.radiusButton
                    )
                    .stroke(
                        Theme.hairline,
                        lineWidth: 1
                    )
                }
            }
            .opacity(
                configuration.isPressed
                    ? 0.72
                    : 1
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? 0.985
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: 0.22,
                        dampingFraction: 0.86
                    ),
                value: configuration.isPressed
            )
    }
}

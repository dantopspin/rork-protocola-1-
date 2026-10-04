import SwiftUI

/// Primary action. Near-black on light surfaces; white on the dark hero.
/// Keep one dominant action per screen whenever possible.
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
                minHeight: Theme.minimumTapTarget
            )
            .foregroundStyle(
                inverted
                    ? Theme.ink
                    : Color.white
            )
            .background(
                configuration.isPressed
                    ? (
                        inverted
                        ? Color.white.opacity(0.82)
                        : Theme.ink.opacity(0.82)
                    )
                    : (
                        inverted
                        ? Color.white
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


/// Quiet secondary action. Borders and hierarchy do the work;
/// color is reserved for semantics rather than decoration.
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
                minHeight: Theme.minimumTapTarget
            )
            .foregroundStyle(
                onDark
                    ? Color.white.opacity(0.9)
                    : Theme.ink
            )
            .background(
                onDark
                    ? Color.white.opacity(0.07)
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
                        ? Color.white.opacity(0.18)
                        : Theme.border,
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

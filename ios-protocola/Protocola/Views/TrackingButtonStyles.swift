import SwiftUI

/// Rectangular blue-grey primary action from the original Peptide Lens direction.
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
                minHeight:
                    Theme.buttonHeight
            )
            .foregroundStyle(
                inverted
                    ? Theme.teal
                    : Theme.onDarkPrimary
            )
            .background(
                configuration.isPressed
                    ? (
                        inverted
                        ? Theme.onDarkPrimary
                            .opacity(0.84)
                        : Theme.teal
                            .opacity(0.84)
                    )
                    : (
                        inverted
                        ? Theme.onDarkPrimary
                        : Theme.teal
                    ),
                in: .rect(
                    cornerRadius:
                        Theme.radiusButton
                )
            )
            .opacity(
                configuration.isPressed
                    ? 0.92
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(
                        duration: 0.12
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}


/// Flat outlined secondary action.
struct TrackingSecondaryButtonStyle: ButtonStyle {
    var onDark: Bool = false

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
                    ? Theme.onDarkPrimary
                        .opacity(0.04)
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
                        ? Theme
                            .onDarkPrimary
                            .opacity(0.24)
                        : Theme.hairline,
                    lineWidth: 1
                )
            }
            .opacity(
                configuration.isPressed
                    ? 0.64
                    : 1
            )
    }
}


/// Compact rectangular inline action.
struct TrackingCompactButtonStyle: ButtonStyle {
    var prominent: Bool = false

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
                    ? Theme.teal
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
                    ? 0.64
                    : 1
            )
    }
}

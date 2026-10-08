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
                    ? Theme.accentFill
                    : Theme.onDarkPrimary
            )
            .background(
                configuration.isPressed
                    ? (
                        inverted
                        ? Theme.onDarkPrimary
                            .opacity(Theme.pressedFillOpacity)
                        : Theme.accentFill
                            .opacity(Theme.pressedFillOpacity)
                    )
                    : (
                        inverted
                        ? Theme.onDarkPrimary
                        : Theme.accentFill
                    ),
                in: .rect(
                    cornerRadius:
                        Theme.radiusButton
                )
            )
            .opacity(
                configuration.isPressed
                    ? Theme.pressedSurfaceOpacity
                    : 1
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? Theme.pressedPrimaryScale
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(
                        duration:
                            Theme.motionPressDuration
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
                    ? Theme.onDarkSubtleFill
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
                        ? Theme.onDarkControlBorder
                        : Theme.controlBorder,
                    lineWidth:
                        Theme.ruleThickness
                )
            }
            .opacity(
                configuration.isPressed
                    ? Theme.pressedControlOpacity
                    : 1
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? Theme.pressedSecondaryScale
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(
                        duration:
                            Theme.motionPressDuration
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}


/// Compact rectangular inline action.
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
                    ? Theme.accentFill
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
                        Theme.controlBorder,
                        lineWidth:
                            Theme.ruleThickness
                    )
                }
            }
            .opacity(
                configuration.isPressed
                    ? Theme.pressedControlOpacity
                    : 1
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? Theme.pressedSecondaryScale
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(
                        duration:
                            Theme.motionPressDuration
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}


struct TrackingRowButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                configuration.isPressed
                    ? Theme.pressedSurfaceOpacity
                    : 1
            )
            .scaleEffect(
                configuration.isPressed
                    && !reduceMotion
                    ? Theme.pressedRowScale
                    : 1
            )
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(
                        duration:
                            Theme.motionPressDuration
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}

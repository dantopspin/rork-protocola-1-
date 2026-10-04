import SwiftUI

/// Full-width deep-teal primary action with soft press feedback.
/// The strongest action on any screen; used once per screen where possible.
/// On the ink hero, `inverted` flips it: white surface, teal label.
struct TrackingPrimaryButtonStyle: ButtonStyle {
    var inverted: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(inverted ? Theme.teal : Color.white)
            .background(
                configuration.isPressed
                    ? (inverted ? Color.white.opacity(0.85) : Theme.teal.opacity(0.85))
                    : (inverted ? Color.white : Theme.teal),
                in: .rect(cornerRadius: Theme.radiusButton)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Secondary action: white surface with a crisp soft-ink border and an ink label —
/// quiet, never teal. On the ink hero, `onDark` becomes a translucent row
/// with a soft white outline so the primary action stays dominant.
struct TrackingSecondaryButtonStyle: ButtonStyle {
    var onDark: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(onDark ? Color.white.opacity(0.92) : Theme.ink)
            .background(onDark ? Color.white.opacity(0.08) : Theme.surface, in: .rect(cornerRadius: Theme.radiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusButton)
                    .stroke(onDark ? Color.white.opacity(0.28) : Theme.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

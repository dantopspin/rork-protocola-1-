import SwiftUI

struct RecordRow: View {
    let label: String
    let value: String
    var onDark = false

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Label beside value at regular sizes; label above value at
    /// accessibility sizes so neither is truncated.
    private var layout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                )
            )
            : AnyLayout(
                HStackLayout(
                    alignment: .firstTextBaseline,
                    spacing: Theme.spaceM
                )
            )
    }

    var body: some View {
        layout {
            // Label quieter than value: Subheadline vs Body.
            Text(label)
                .font(Theme.subheadline)
                .foregroundStyle(
                    onDark
                        ? Theme.onDarkSecondary
                        : Theme.textSecondary
                )

            if !typeSize.isAccessibilitySize {
                Spacer(
                    minLength:
                        Theme.spaceM
                )
            }

            Text(value)
                .font(Theme.body)
                .multilineTextAlignment(
                    typeSize.isAccessibilitySize
                        ? .leading
                        : .trailing
                )
                .monospacedDigit()
                .foregroundStyle(
                    onDark
                        ? Theme.onDarkPrimary
                        : Theme.ink
                )
        }
    }
}

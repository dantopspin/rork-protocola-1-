import SwiftUI

struct RecordRow: View {
    let label: String
    let value: String
    var onDark = false

    var body: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceM
        ) {
            Text(label)
                .font(Theme.body)
                .foregroundStyle(
                    onDark
                        ? Theme.onDarkSecondary
                        : Theme.muted
                )

            Spacer(
                minLength:
                    Theme.spaceM
            )

            Text(value)
                .font(Theme.body)
                .multilineTextAlignment(
                    .trailing
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

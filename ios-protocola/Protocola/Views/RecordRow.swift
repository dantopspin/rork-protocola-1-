import SwiftUI

struct RecordRow: View {
    let label: String
    let value: String
    var onDark = false

    var body: some View {
        if onDark {
            HStack(
                alignment: .firstTextBaseline
            ) {
                Text(label)
                    .font(Theme.body)
                    .foregroundStyle(
                        Color.white.opacity(0.58)
                    )

                Spacer(
                    minLength: Theme.spaceM
                )

                Text(value)
                    .font(Theme.body)
                    .multilineTextAlignment(
                        .trailing
                    )
                    .monospacedDigit()
                    .foregroundStyle(Theme.onDarkPrimary)
            }

        } else {
            LabeledContent {
                Text(value)
                    .font(Theme.body)
                    .multilineTextAlignment(
                        .trailing
                    )
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)

            } label: {
                Text(label)
                    .font(Theme.body)
                    .foregroundStyle(Theme.muted)
            }
        }
    }
}

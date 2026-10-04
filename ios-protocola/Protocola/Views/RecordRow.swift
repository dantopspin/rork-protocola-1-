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
                    .foregroundStyle(
                        Color.white.opacity(0.64)
                    )

                Spacer(
                    minLength: Theme.spaceM
                )

                Text(value)
                    .multilineTextAlignment(
                        .trailing
                    )
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .font(.subheadline)

        } else {
            LabeledContent {
                Text(value)
                    .multilineTextAlignment(
                        .trailing
                    )
                    .monospacedDigit()
                    .foregroundStyle(.primary)

            } label: {
                Text(label)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }
}

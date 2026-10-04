import SwiftUI

struct TrackingEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(
                    .system(
                        size: 24,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    Theme.muted
                )

            Text(title)
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.ink
                )

            Text(message)
                .font(Theme.body)
                .foregroundStyle(
                    Theme.muted
                )
                .multilineTextAlignment(
                    .center
                )

            if let actionTitle,
               let action {
                Button(
                    actionTitle,
                    action: action
                )
                .buttonStyle(
                    TrackingSecondaryButtonStyle()
                )
                .padding(
                    .top,
                    Theme.spaceXS
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            Theme.spaceL
        )
    }
}

import SwiftUI

/// Branded editorial empty/completion state.
/// Use this instead of the native unavailable placeholder inside product screens.
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
                        size: Theme.iconLarge,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    Theme.textTertiary
                )

            Text(title)
                .font(Theme.modalTitle)
                .foregroundStyle(
                    Theme.ink
                )
                .multilineTextAlignment(
                    .center
                )

            Text(message)
                .font(Theme.body)
                .foregroundStyle(
                    Theme.textSecondary
                )
                .multilineTextAlignment(
                    .center
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            if let actionTitle,
               let action {
                Button(
                    actionTitle,
                    action: action
                )
                .buttonStyle(
                    TrackingCompactButtonStyle()
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

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
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(
                    .system(
                        size:
                            Theme.scaledSize(
                                Theme.iconLarge,
                                .title1,
                                max: Theme.iconLarge * 2
                            ),
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

            Text(message)
                .font(Theme.body)
                .foregroundStyle(
                    Theme.textSecondary
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
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .vertical,
            Theme.spaceL
        )
    }
}

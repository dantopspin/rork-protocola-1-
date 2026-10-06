import SwiftUI

/// Shared editorial trust/benefit row.
///
/// The icon and copy columns are deliberately fixed to one grid so rows never
/// drift horizontally as title/detail lengths change.
struct TrustRow: View {
    let icon: String
    let title: String
    let detail: String
    var compact: Bool = false

    var body: some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceM
        ) {
            Image(systemName: icon)
                .font(Theme.sectionTitle)
                .symbolRenderingMode(
                    .monochrome
                )
                .foregroundStyle(
                    Theme.textSecondary
                )
                .frame(
                    width:
                        Theme.iconColumn,
                    height:
                        Theme.iconColumn,
                    alignment: .top
                )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.ink
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .vertical,
            compact
                ? Theme.spaceS
                : Theme.spaceM
        )
    }
}

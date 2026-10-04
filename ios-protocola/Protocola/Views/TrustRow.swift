import SwiftUI

struct TrustRow: View {
    let icon: String
    let title: String
    let detail: String
    var compact: Bool = false

    var body: some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(Theme.body)
                .foregroundStyle(
                    Theme.muted
                )
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )
            }
        }
        .padding(
            .vertical,
            compact
                ? Theme.spaceXS
                : Theme.spaceS
        )
    }
}

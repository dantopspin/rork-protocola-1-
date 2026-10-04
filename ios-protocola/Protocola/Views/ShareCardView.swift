import SwiftUI

/// Stable share image using the same classical minimal system as the app.
struct ShareCardView: View {
    let data: ShareCardData

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXL
        ) {
            HStack {
                Text("Protocola")
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)

                Spacer()

                Text(data.periodLabel)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.muted)
            }

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                Text(data.percentage)
                    .font(
                        .system(
                            size: 64,
                            weight: .medium,
                            design: .serif
                        )
                    )
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)

                Text(
                    "\(data.recorded) of \(data.scheduled) scheduled entries recorded"
                )
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.muted)
                .monospacedDigit()
            }

            HStack(
                alignment: .bottom,
                spacing: Theme.spaceXXS
            ) {
                ForEach(data.bars) {
                    bar in

                    RoundedRectangle(
                        cornerRadius: 2
                    )
                    .fill(Theme.line)
                    .frame(
                        width: data.barWidth,
                        height: 64
                    )
                    .overlay(
                        alignment: .bottom
                    ) {
                        if bar.scheduled > 0 {
                            RoundedRectangle(
                                cornerRadius: 2
                            )
                            .fill(Theme.teal)
                            .frame(
                                width: data.barWidth,
                                height:
                                    64
                                    * CGFloat(
                                        bar.recorded
                                    )
                                    / CGFloat(
                                        bar.scheduled
                                    )
                            )
                        }
                    }
                }
            }

            Divider()

            Text("Tracked with Protocola")
                .font(Theme.caption)
                .foregroundStyle(Theme.muted)
        }
        .padding(32)
        .frame(
            width: 520,
            alignment: .leading
        )
        .background(Theme.paper)
    }
}

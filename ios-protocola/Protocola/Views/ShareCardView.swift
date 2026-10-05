import SwiftUI

/// Stable share image using the clinical editorial system.
struct ShareCardView: View {
    let data: ShareCardData

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXL
        ) {
            header
            primaryMetric
            adherenceBars

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )

            HStack {
                Text(
                    "Tracked with Protocola"
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )

                Spacer()

                Text(data.periodLabel)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )
                    .monospacedDigit()
            }
        }
        .padding(Theme.spaceXL)
        .frame(
            width: Theme.shareCardWidth,
            alignment: .leading
        )
        .background(Theme.paper)
    }
}


private extension ShareCardView {

    var header: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Eyebrow(text: "Protocola")

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )
        }
    }


    var primaryMetric: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Text(data.percentage)
                .font(Theme.shareMetric)
                .monospacedDigit()
                .foregroundStyle(
                    Theme.ink
                )

            Text(
                "\(data.recorded) of \(data.scheduled) scheduled entries recorded"
            )
            .font(Theme.sectionTitle)
            .foregroundStyle(
                Theme.textSecondary
            )
            .monospacedDigit()
        }
    }


    var adherenceBars: some View {
        HStack(
            alignment: .bottom,
            spacing: Theme.spaceXXS
        ) {
            ForEach(data.bars) {
                bar in

                Rectangle()
                    .fill(Theme.line)
                    .frame(
                        width: data.barWidth,
                        height:
                            Theme.shareBarHeight
                    )
                    .overlay(
                        alignment: .bottom
                    ) {
                        if bar.scheduled > 0 {
                            Rectangle()
                                .fill(
                                    Theme.teal
                                )
                                .frame(
                                    width:
                                        data
                                            .barWidth,
                                    height:
                                        Theme
                                            .shareBarHeight
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
    }
}

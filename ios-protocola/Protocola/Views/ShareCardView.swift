import SwiftUI

/// The rendered share image: printed-lab-note styling on paper, aggregates only,
/// footer "Tracked with Protocola". Fixed width so ImageRenderer output is stable.
struct ShareCardView: View {
    let data: ShareCardData
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            HStack {
                Eyebrow(text: "Protocola")
                Spacer()
                Text(data.periodLabel.uppercased()).font(Theme.micro).tracking(1.4).foregroundStyle(Theme.muted)
            }
            VStack(alignment: .leading, spacing: Theme.spaceXS) {
                Text(data.percentage).font(.system(size: 64, weight: .semibold, design: .rounded)).tracking(-2).monospacedDigit()
                Text("\(data.recorded) of \(data.scheduled) scheduled entries recorded").font(Theme.sectionTitle).foregroundStyle(Theme.muted).monospacedDigit()
            }
            HStack(alignment: .bottom, spacing: Theme.spaceXXS) {
                ForEach(data.bars) { bar in
                    Capsule().fill(Theme.line.opacity(0.35))
                        .frame(width: data.barWidth, height: 64)
                        .overlay(alignment: .bottom) {
                            if bar.scheduled > 0 {
                                Capsule().fill(Theme.teal)
                                    .frame(width: data.barWidth, height: 64 * CGFloat(bar.recorded) / CGFloat(bar.scheduled))
                            }
                        }
                }
            }
            Divider()
            Text("Tracked with Protocola").font(Theme.caption).foregroundStyle(Theme.muted)
        }
        .padding(32)
        .frame(width: 520, alignment: .leading)
        .background(Theme.paper)
    }
}

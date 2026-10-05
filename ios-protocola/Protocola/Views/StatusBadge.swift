import SwiftUI

struct StatusBadge: View {
    let text: String

    private var tint: Color {
        switch text {
        case "Logged",
             "Active",
             "Current",
             "Week recorded":
            return Theme.teal

        case "Partial",
             "Delayed",
             "Low recorded balance",
             "Depleted":
            return Theme.amber

        default:
            return Theme.muted
        }
    }

    var body: some View {
        Text(text)
            .font(Theme.micro)
            .padding(
                .horizontal,
                Theme.spaceXS
            )
            .frame(
                minHeight:
                    Theme.badgeHeight
            )
            .foregroundStyle(tint)
            .background(
                tint.opacity(
                    Theme.statusFillOpacity
                ),
                in: .rect(
                    cornerRadius:
                        Theme.radiusBadge
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius:
                        Theme.radiusBadge
                )
                .stroke(
                    tint.opacity(
                        Theme.statusBorderOpacity
                    ),
                    lineWidth:
                        Theme.ruleThickness
                )
            }
    }
}

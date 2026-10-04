import SwiftUI

struct StatusBadge: View {
    let text: String

    private var tint: Color {
        switch text {
        case "Logged",
             "Active",
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
            .frame(minHeight: 20)
            .foregroundStyle(tint)
            .background(
                tint.opacity(0.09),
                in: .rect(
                    cornerRadius:
                        Theme.radiusBadge
                )
            )
    }
}

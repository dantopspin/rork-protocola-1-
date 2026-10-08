import SwiftUI

struct StatusBadge: View {
    let text: String

    private var tint: Color {
        switch text {
        case "Logged",
             "Taken",
             "Active",
             "Current",
             "Week recorded":
            return Theme.teal

        case "Due",
             "Due now":
            return Theme.info

        case "Partial",
             "Delayed",
             "Low recorded balance",
             "Depleted",
             "Expires soon",
             "Expiry today":
            return Theme.amber

        case "Expiry passed",
             "Overdue":
            return Theme.danger

        default:
            return Theme.textSecondary
        }
    }

    private var icon: String? {
        switch text {
        case "Logged", "Taken":
            return "checkmark.circle.fill"
        case "Due", "Due now":
            return "clock"
        case "Upcoming":
            return "ellipsis.circle.fill"
        case "Skipped":
            return "forward.end.fill"
        case "Expires soon", "Expiry today", "Expiry passed", "Overdue":
            return "exclamationmark.circle.fill"
        default:
            return nil
        }
    }

    var body: some View {
        // Capsule chip: tinted fill, optional status icon, no outline.
        Label {
            Text(text)
        } icon: {
            if let icon {
                Image(systemName: icon)
            }
        }
            .labelStyle(StatusChipLabelStyle())
            .font(Theme.chipLabel)
            .padding(
                .horizontal,
                Theme.spaceS
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
            .contentTransition(.opacity)
            .trackingStateAnimation(
                value: text
            )
    }
}


private struct StatusChipLabelStyle: LabelStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        HStack(spacing: Theme.spaceXXS) {
            configuration.icon
            configuration.title
        }
    }
}

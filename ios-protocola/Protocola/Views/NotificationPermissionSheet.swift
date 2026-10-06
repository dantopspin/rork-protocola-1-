import SwiftUI
import UIKit

/// Pre-permission explanation shown before the one-time iOS notification
/// prompt. "Allow" runs the real system request; "Not now" closes without
/// prompting so the one-time prompt stays available.
///
/// `onFinish` runs after a grant or "Not now" and should close the sheet.
/// After a denial the sheet stays up with a Settings route until closed, so
/// callers continue their flow from the sheet's `onDismiss`.
struct NotificationPermissionSheet: View {
    enum Context {
        case reminders
        case inventory
    }

    private enum Phase {
        case idle
        case requesting
        case denied
    }

    let context: Context
    let onFinish: () -> Void

    @Environment(TrackingStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .idle

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceL
        ) {
            iconTile

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                Text(
                    phase == .denied
                        ? "Notifications are off"
                        : title
                )
                .font(Theme.pageTitle)
                .foregroundStyle(Theme.ink)

                Text(
                    phase == .denied
                        ? "Your records are still saved. Turn on notifications for Protocola in iOS Settings to receive them."
                        : message
                )
                .font(Theme.body)
                .foregroundStyle(Theme.textSecondary)
            }
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .accessibilityElement(children: .combine)

            if phase != .denied {
                EditorialSection(
                    "What you receive"
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceS
                    ) {
                        ForEach(
                            benefits,
                            id: \.text
                        ) { benefit in
                            benefitRow(benefit)
                        }
                    }
                }
            }

            Spacer(minLength: Theme.spaceL)

            actions
        }
        .padding(Theme.pageInset)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(Theme.paper)
        .trackingStateAnimation(value: phase)
        .sensoryFeedback(
            .warning,
            trigger: phase
        ) { _, new in
            new == .denied
        }
        .presentationDetents([.large])
        .presentationBackground(Theme.paper)
    }
}


// MARK: - Parts

private extension NotificationPermissionSheet {

    var iconTile: some View {
        Image(
            systemName:
                phase == .denied
                ? "bell.slash"
                : "bell.badge"
        )
        .font(Theme.modalTitle)
        .foregroundStyle(Theme.onDarkPrimary)
        .contentTransition(
            .symbolEffect(.replace)
        )
        .frame(
            width: Theme.iconTileSize,
            height: Theme.iconTileSize
        )
        .background(
            phase == .denied
                ? Theme.amber
                : Theme.teal,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
        .accessibilityHidden(true)
    }


    func benefitRow(
        _ benefit: Benefit
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceS
        ) {
            Image(systemName: benefit.symbol)
                .font(Theme.label)
                .foregroundStyle(Theme.teal)
                .frame(width: Theme.iconColumn)
                .accessibilityHidden(true)

            Text(benefit.text)
                .font(Theme.body)
                .foregroundStyle(Theme.ink)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }


    var actions: some View {
        VStack(spacing: Theme.spaceXS) {
            Button {
                if phase == .denied {
                    if let url = URL(
                        string:
                            UIApplication
                                .openSettingsURLString
                    ) {
                        openURL(url)
                    }
                } else {
                    Task { await request() }
                }
            } label: {
                ZStack {
                    Text(
                        phase == .denied
                            ? "Open Settings"
                            : "Allow notifications"
                    )
                    .opacity(
                        phase == .requesting ? 0 : 1
                    )

                    if phase == .requesting {
                        ProgressView()
                            .tint(Theme.onDarkPrimary)
                    }
                }
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )
            .disabled(phase == .requesting)
            .accessibilityLabel(
                phase == .requesting
                    ? "Requesting permission"
                    : phase == .denied
                        ? "Open Settings"
                        : "Allow notifications"
            )

            Button(
                phase == .denied
                    ? "Close"
                    : "Not now"
            ) {
                if phase == .denied {
                    dismiss()
                } else {
                    onFinish()
                }
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )
            .disabled(phase == .requesting)
        }
    }


    func request() async {
        guard phase == .idle else {
            return
        }

        phase = .requesting

        let granted =
            await store.notifications
                .requestPermission()

        if granted {
            Haptics.success()
            phase = .idle
            onFinish()
        } else {
            phase = .denied
        }
    }
}


// MARK: - Copy

private extension NotificationPermissionSheet {

    struct Benefit {
        let symbol: String
        let text: String
    }

    var title: String {
        switch context {
        case .reminders:
            "Reminders for your recorded schedule"
        case .inventory:
            "Inventory alerts"
        }
    }

    var message: String {
        switch context {
        case .reminders:
            "Protocola can notify you at the times you recorded. It never suggests a dose or changes your schedule."
        case .inventory:
            "Protocola can notify you when a recorded vial balance is low, projected to run out, or near the expiry date you entered."
        }
    }

    var benefits: [Benefit] {
        switch context {
        case .reminders:
            [
                Benefit(
                    symbol: "clock",
                    text: "A reminder at each scheduled time you recorded"
                ),
                Benefit(
                    symbol: "arrow.clockwise",
                    text: "A note the evening before an OFF cycle ends"
                ),
                Benefit(
                    symbol: "lock",
                    text: "Scheduled on this iPhone. Reminders never show compound names or amounts."
                )
            ]
        case .inventory:
            [
                Benefit(
                    symbol: "shippingbox",
                    text: "Low-balance and projected run-out notes"
                ),
                Benefit(
                    symbol: "calendar",
                    text: "A note before the expiry date you entered"
                ),
                Benefit(
                    symbol: "lock",
                    text: "Built only from your own records on this iPhone"
                )
            ]
        }
    }
}

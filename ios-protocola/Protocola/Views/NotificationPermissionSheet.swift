import SwiftUI

/// Pre-permission explanation shown before the one-time iOS notification
/// prompt. Wraps the vendored SwiftPieces `PermissionSheet` with Protocola
/// copy and design tokens.
///
/// `onFinish` runs when the person grants or taps "Not now" and should close
/// the sheet. After a denial the sheet stays up with a Settings button until
/// swiped away, so callers continue their flow from the sheet's `onDismiss`.
struct NotificationPermissionSheet: View {
    enum Context {
        case reminders
        case inventory
    }

    let context: Context
    let onFinish: () -> Void

    @Environment(TrackingStore.self) private var store

    var body: some View {
        PermissionSheet(
            systemImage: "bell.badge",
            title: title,
            message: message,
            benefits: benefits,
            allowTitle: "Allow notifications",
            deniedTitle: "Notifications are off",
            deniedMessage:
                "Your protocol is still saved. Turn on notifications for Protocola in Settings to receive reminders.",
            style: Self.style,
            request: {
                await store.notifications
                    .requestPermission()
            },
            onGranted: onFinish,
            onSkip: onFinish
        )
        .presentationDetents([.large])
        .presentationCornerRadius(
            Theme.radiusCard
        )
        .presentationBackground(
            Theme.paper
        )
    }

    private var title: String {
        switch context {
        case .reminders:
            "Reminders for your recorded schedule"
        case .inventory:
            "Inventory alerts"
        }
    }

    private var message: String {
        switch context {
        case .reminders:
            "Protocola can notify you at the times you recorded. It never suggests a dose or changes your schedule."
        case .inventory:
            "Protocola can notify you when a recorded vial balance is low, projected to run out, or near the expiry date you entered."
        }
    }

    private var benefits: [PermissionSheet.Benefit] {
        switch context {
        case .reminders:
            [
                .init(
                    symbol: "clock",
                    text: "A reminder at each scheduled time you recorded"
                ),
                .init(
                    symbol: "arrow.clockwise",
                    text: "A note the evening before an OFF cycle ends"
                ),
                .init(
                    symbol: "lock",
                    text: "Scheduled on this iPhone. Notifications never show compound names or amounts."
                )
            ]
        case .inventory:
            [
                .init(
                    symbol: "shippingbox",
                    text: "Low-balance and projected run-out notes"
                ),
                .init(
                    symbol: "calendar",
                    text: "A note before the expiry date you entered"
                ),
                .init(
                    symbol: "lock",
                    text: "Built only from your own records on this iPhone"
                )
            ]
        }
    }

    private static let style =
        PermissionSheet.Style(
            surface: Theme.paper,
            label: Theme.ink,
            secondaryLabel: Theme.textSecondary,
            ink: Theme.onDarkPrimary,
            tile: Theme.teal,
            success: Theme.teal,
            denied: Theme.amber,
            benefitTiles: [Theme.teal],
            action: Theme.teal,
            cornerRadius: Theme.radiusCard
        )
}

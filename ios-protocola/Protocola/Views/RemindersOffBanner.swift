import SwiftUI
import UIKit
import UserNotifications

/// Shown on Today when a protocol has reminders on but iOS won't deliver
/// them, so the person never believes reminders are working when they aren't.
struct RemindersOffBanner: View {
    let status: UNAuthorizationStatus
    let refresh: () async -> Void

    @Environment(\.openURL) private var openURL
    @State private var asking = false

    /// True when reminders are expected but iOS won't deliver them.
    static func isOff(
        _ status: UNAuthorizationStatus?,
        expectsReminders: Bool
    ) -> Bool {
        guard expectsReminders, let status else {
            return false
        }
        return status == .denied || status == .notDetermined
    }

    var body: some View {
        banner
            .sheet(
                isPresented: $asking,
                onDismiss: {
                    Task { await refresh() }
                }
            ) {
                NotificationPermissionSheet(
                    context: .reminders
                ) {
                    asking = false
                }
            }
    }

    private var banner: some View {
        HStack(
            alignment: .center,
            spacing: Theme.spaceS
        ) {
            Image(systemName: "bell.slash")
                .font(Theme.body)
                .foregroundStyle(Theme.ink)
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text("Reminders are off")
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.ink)

                Text(
                    status == .notDetermined
                        ? "Protocola hasn't been allowed to send notifications yet."
                        : "Notifications for Protocola are turned off in iOS Settings."
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Theme.spaceS)

            Button("Turn on") {
                if status == .notDetermined {
                    asking = true
                } else if let url = URL(
                    string: UIApplication.openSettingsURLString
                ) {
                    openURL(url)
                }
            }
            .buttonStyle(
                TrackingCompactButtonStyle(prominent: true)
            )
        }
        .padding(.vertical, Theme.rowPadding)
        .overlay(alignment: .top) {
            EditorialRule()
        }
        .overlay(alignment: .bottom) {
            EditorialRule()
        }
        .accessibilityElement(children: .combine)
    }

}

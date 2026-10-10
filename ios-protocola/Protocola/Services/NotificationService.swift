import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationService {

    private let center =
        UNUserNotificationCenter.current()
    private var desired:
        [ReminderPlanner.Candidate] = []
    private var worker:
        Task<Void, Never>?
    private var needsUpdate = false

    private(set) var status:
        String =
        "Reminders are off until enabled in a protocol."

    // The notification center's delegate is NotificationActionRouter,
    // installed at launch so reminder actions arrive even before a store opens.

    func requestPermission() async -> Bool {
        do {
            let allowed =
                try await center
                    .requestAuthorization(
                        options: [
                            .alert,
                            .sound
                        ]
                    )

            if !allowed {
                status =
                    "Notifications are disabled. You can enable them in iOS Settings."
            }

            return allowed

        } catch {
            status =
                "Notification permission could not be checked. Try again."
            return false
        }
    }

    /// Current system authorization, so callers can explain the permission
    /// before iOS shows its one-time prompt.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center
            .notificationSettings()
            .authorizationStatus
    }

    nonisolated static func allowsDelivery(
        _ status: UNAuthorizationStatus
    ) -> Bool {
        switch status {
        case .authorized,
             .provisional,
             .ephemeral:
            return true
        case .notDetermined,
             .denied:
            return false
        @unknown default:
            return false
        }
    }

    func update(
        _ reminders:
            [ReminderPlanner.Candidate]
    ) {
        desired = reminders
        needsUpdate = true

        guard worker == nil else {
            return
        }

        worker =
            Task { [weak self] in
                guard let self else {
                    return
                }

                while self.needsUpdate {
                    self.needsUpdate =
                        false

                    await self.sync(
                        self.desired
                    )
                }

                self.worker = nil
            }
    }

    private func sync(
        _ entries:
            [ReminderPlanner.Candidate]
    ) async {
        let settings =
            await center
                .notificationSettings()
        let pending =
            await center
                .pendingNotificationRequests()
        let own =
            pending.filter {
                $0.identifier
                    .hasPrefix(
                        "protocola:"
                    )
            }

        guard
            Self.allowsDelivery(
                settings.authorizationStatus
            )
        else {
            center.removePendingNotificationRequests(
                withIdentifiers:
                    own.map(\.identifier)
            )

            status =
                entries.isEmpty
                ? "No reminders enabled."
                : "Notifications are disabled. Enable Protocola in iOS Settings."
            return
        }

        let now = Date.now
        let activeIDs =
            Set(entries.map(\.id))
        var ledger =
            ReminderDeliveryLedgerStore
                .read()

        ledger.prune(
            keeping: activeIDs
        )

        defer {
            ReminderDeliveryLedgerStore
                .write(ledger)
        }

        let eligible =
            entries.filter {
                ledger.shouldSchedule(
                    id: $0.id,
                    at: $0.at,
                    now: now
                )
            }

        let selected =
            ReminderPlanner.select(
                eligible,
                now: now,
                otherPending:
                    pending.count
                    - own.count
            )
        let ids =
            Set(
                selected.map {
                    "protocola:"
                    + $0.id
                }
            )

        center.removePendingNotificationRequests(
            withIdentifiers:
                own.filter {
                    !ids.contains(
                        $0.identifier
                    )
                }
                .map(\.identifier)
        )

        do {
            for entry in selected {
                let content =
                    UNMutableNotificationContent()

                content.title =
                    entry.title
                content.body =
                    entry.body
                content.sound =
                    .default

                // Dose reminders carry Log / Skip actions; cycle and
                // inventory notes do not.
                // A follow-up nudge acts on its original entry.
                if !entry.id.hasPrefix("cycle-restart:"),
                   !entry.id.hasPrefix("vial-"),
                   !entry.id.hasPrefix("weekly-recap:") {
                    let entryID =
                        entry.id.hasPrefix("followup:")
                        ? String(entry.id.dropFirst("followup:".count))
                        : entry.id
                    content.categoryIdentifier =
                        NotificationActionRouter
                            .entryCategory
                    content.userInfo = [
                        NotificationActionRouter
                            .entryIDKey: entryID
                    ]
                }

                let request =
                    Self.request(
                        id: entry.id,
                        at: entry.at,
                        content: content,
                        floating: entry.floating
                    )

                try await center.add(
                    request
                )

                ledger.markScheduled(
                    id: entry.id,
                    at: entry.at
                )
            }

            if let last =
                selected.last {
                status =
                    "\(selected.count) reminders queued through \(last.at.formatted(date: .abbreviated, time: .shortened)). Open the app regularly to extend coverage. Delivery also depends on iOS notification and Focus settings."
            } else {
                status =
                    "No upcoming reminders enabled."
            }

        } catch {
            status =
                "Some reminders could not be scheduled. Reopen Protocola to retry; your protocol is saved."
        }
    }

    static func request(
        id: String,
        at: Date,
        content: UNNotificationContent,
        floating: Bool = false
    ) -> UNNotificationRequest {
        if floating {
            // Wall-clock trigger with no time zone: iOS fires it at this
            // local time in whatever zone the iPhone is in.
            let components =
                Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: at
                )

            return UNNotificationRequest(
                identifier: "protocola:" + id,
                content: content,
                trigger:
                    UNCalendarNotificationTrigger(
                        dateMatching: components,
                        repeats: false
                    )
            )
        }

        var calendar =
            Calendar(
                identifier: .gregorian
            )

        calendar.timeZone =
            TimeZone(
                secondsFromGMT: 0
            ) ?? .current

        var components =
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                    .second
                ],
                from: at
            )

        components.calendar = calendar
        components.timeZone =
            calendar.timeZone

        return UNNotificationRequest(
            identifier:
                "protocola:" + id,
            content: content,
            trigger:
                UNCalendarNotificationTrigger(
                    dateMatching:
                        components,
                    repeats: false
                )
        )
    }
}

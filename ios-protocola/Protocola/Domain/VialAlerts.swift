import Foundation

/// Deterministic inventory alert candidates built from recorded data only.
///
/// Every input is either stored on the vial (user-entered expiry) or derived by
/// TrackingStore from the authoritative ledger and schedule. Protocola never
/// invents a medical expiry or beyond-use date.
nonisolated enum VialAlerts {

    static let depletionWindowDays = 7
    static let expiryWindowDays = 14


    /// Builds independent candidates for depletion, recorded expiry, and
    /// low balance so one condition never hides another.
    static func candidates(
        vial: VialRecord,
        status: String,
        projectedDepletion: Date?,
        now: Date = .now
    ) -> [ReminderPlanner.Candidate] {
        guard vial.lifecycleState != .archived else {
            return []
        }

        var result:
            [ReminderPlanner.Candidate] = []

        if let depletion = projectedDepletion,
           let at = deliveryDate(
                target: depletion,
                leadDays: depletionWindowDays,
                now: now,
                dateOnlyTarget: false
           ) {
            result.append(
                ReminderPlanner.Candidate(
                    id:
                        "vial-depletion:"
                        + vial.id.uuidString
                        + ":"
                        + String(
                            Int(
                                depletion
                                    .timeIntervalSince1970
                            )
                        ),
                    at: at,
                    title:
                        "Protocola · inventory note",
                    body:
                        "At the recorded schedule, "
                        + vial.name
                        + " is projected to run out around "
                        + depletion.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                        + "."
                )
            )
        }

        if let expiry = vial.expiry,
           let at = deliveryDate(
                target: expiry,
                leadDays: expiryWindowDays,
                now: now,
                dateOnlyTarget: true
           ) {
            result.append(
                ReminderPlanner.Candidate(
                    id:
                        "vial-expiry:"
                        + vial.id.uuidString
                        + ":"
                        + String(
                            Int(
                                expiry
                                    .timeIntervalSince1970
                            )
                        ),
                    at: at,
                    title:
                        "Protocola · inventory note",
                    body:
                        "Your recorded expiry date for "
                        + vial.name
                        + " is "
                        + expiry.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                        + ". Open Protocola to review it."
                )
            )
        }

        if status == "Low recorded balance",
           let at =
            nextStableAlertTime(
                after: now
            ) {
            result.append(
                ReminderPlanner.Candidate(
                    id:
                        "vial-low:"
                        + vial.id.uuidString,
                    at: at,
                    title:
                        "Protocola · inventory note",
                    body:
                        "The recorded balance for "
                        + vial.name
                        + " is low. Open Protocola to review your inventory."
                )
            )
        }

        return result.sorted {
            $0.at < $1.at
        }
    }


    /// Convenience for focused callers/tests that need the next inventory
    /// warning only. TrackingStore schedules the complete candidates array.
    static func candidate(
        vial: VialRecord,
        status: String,
        projectedDepletion: Date?,
        now: Date = .now
    ) -> ReminderPlanner.Candidate? {
        candidates(
            vial: vial,
            status: status,
            projectedDepletion:
                projectedDepletion,
            now: now
        )
        .first
    }


    /// Schedule at the threshold when it is still ahead. If the user is
    /// already inside the warning window, use a stable near-term slot instead
    /// of the current instant, because ReminderPlanner rejects non-future
    /// candidates.
    private static func deliveryDate(
        target: Date,
        leadDays: Int,
        now: Date,
        dateOnlyTarget: Bool
    ) -> Date? {
        let calendar = Calendar.current
        let deadline: Date

        if dateOnlyTarget {
            let start =
                calendar.startOfDay(
                    for: target
                )

            guard
                let nextDay =
                    calendar.date(
                        byAdding: .day,
                        value: 1,
                        to: start
                    )
            else {
                return nil
            }

            deadline =
                nextDay.addingTimeInterval(-1)

        } else {
            deadline = target
        }

        guard deadline > now else {
            return nil
        }

        let threshold =
            calendar.date(
                byAdding: .day,
                value: -leadDays,
                to: target
            ) ?? target

        if threshold > now {
            return threshold
        }

        if let slot =
            nextStableAlertTime(
                after: now
            ),
           slot < deadline {
            return slot
        }

        let fallback =
            deadline.addingTimeInterval(
                -60
            )

        return fallback > now
            ? fallback
            : nil
    }


    /// Stable daily slots prevent reminder resyncs from continuously pushing an
    /// already-due warning farther into the future.
    private static func nextStableAlertTime(
        after now: Date
    ) -> Date? {
        let calendar = Calendar.current
        let day =
            calendar.startOfDay(
                for: now
            )

        for hour in [9, 17] {
            if let candidate =
                calendar.date(
                    bySettingHour: hour,
                    minute: 0,
                    second: 0,
                    of: day
                ),
               candidate > now {
                return candidate
            }
        }

        guard
            let tomorrow =
                calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: day
                )
        else {
            return nil
        }

        return calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: tomorrow
        )
    }
}

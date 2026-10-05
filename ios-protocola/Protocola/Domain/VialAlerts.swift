import Foundation

/// Deterministic inventory alert candidates built from recorded data only.
///
/// Every input is either stored on the vial (user-entered expiry) or derived by
/// `TrackingStore` from the authoritative ledger and schedule (balance,
/// projected depletion). Protocola never invents a medical expiry or
/// beyond-use date; the expiry candidate fires only from a date the user
/// recorded themselves.
nonisolated enum VialAlerts {

    /// Days ahead that a projected depletion triggers a reminder.
    static let depletionWindowDays = 7

    /// Days ahead that a user-entered expiry triggers a reminder.
    static let expiryWindowDays = 14


    /// Returns at most one candidate per vial, prioritized low balance →
    /// projected depletion → recorded expiry. Archived vials never alert.
    static func candidate(
        vial: VialRecord,
        status: String,
        projectedDepletion: Date?,
        now: Date = .now
    ) -> ReminderPlanner.Candidate? {
        guard vial.lifecycleState != .archived else {
            return nil
        }

        if status == "Low recorded balance" {
            return ReminderPlanner.Candidate(
                id: "vial-low:" + vial.id.uuidString,
                at: now,
                title: "Protocola · inventory note",
                body:
                    "The recorded balance for "
                    + vial.name
                    + " is low. Open Protocola to review your inventory."
            )
        }

        if let depletion = projectedDepletion,
           isWithin(
               depletionWindowDays,
               of: depletion,
               now: now
           ) {
            return ReminderPlanner.Candidate(
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
                at: now,
                title: "Protocola · inventory note",
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
        }

        if let expiry = vial.expiry,
           isWithin(
               expiryWindowDays,
               of: expiry,
               now: now
           ) {
            return ReminderPlanner.Candidate(
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
                at: now,
                title: "Protocola · inventory note",
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
        }

        return nil
    }


    /// Calendar-day window check on start-of-day boundaries so the alert does
    /// not flicker across midnight.
    private static func isWithin(
        _ days: Int,
        of date: Date,
        now: Date
    ) -> Bool {
        let calendar = Calendar.current

        guard days > 0 else {
            return date <= now
        }

        guard
            let horizon = calendar.date(
                byAdding: .day,
                value: days,
                to: calendar.startOfDay(for: now)
            )
        else {
            return false
        }

        return date < horizon
    }
}

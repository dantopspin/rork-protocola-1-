import Foundation

/// Small local ledger that prevents the same one-shot notification fingerprint
/// from being scheduled again after its delivery window has already passed.
///
/// This is not user data and is intentionally separate from SwiftData. Entries
/// are removed as soon as the corresponding reminder condition disappears.
struct ReminderDeliveryLedger: Codable, Equatable {
    var scheduledAt: [String: Date] = [:]

    mutating func prune(
        keeping activeIDs: Set<String>
    ) {
        scheduledAt =
            scheduledAt.filter {
                activeIDs.contains($0.key)
            }
    }

    func shouldSchedule(
        id: String,
        at date: Date,
        now: Date
    ) -> Bool {
        guard let previous =
            scheduledAt[id]
        else {
            return true
        }

        // A future request with the same fingerprint may legitimately move
        // while the source data is being edited, so let NotificationCenter
        // replace it. Once its previously scheduled window has passed, the
        // same fingerprint must not be recreated on every app refresh.
        if previous > now {
            return true
        }

        return false
    }

    mutating func markScheduled(
        id: String,
        at date: Date
    ) {
        scheduledAt[id] = date
    }
}


enum ReminderDeliveryLedgerStore {
    private static let key =
        "protocola.reminder-delivery-ledger"

    static func read() -> ReminderDeliveryLedger {
        guard
            let data =
                UserDefaults.standard
                    .data(forKey: key),
            let ledger =
                try? JSONDecoder()
                    .decode(
                        ReminderDeliveryLedger.self,
                        from: data
                    )
        else {
            return ReminderDeliveryLedger()
        }

        return ledger
    }

    static func clear() {
        UserDefaults.standard
            .removeObject(forKey: key)
    }


    static func write(
        _ ledger: ReminderDeliveryLedger
    ) {
        guard
            let data =
                try? JSONEncoder()
                    .encode(ledger)
        else {
            return
        }

        UserDefaults.standard
            .set(data, forKey: key)
    }
}

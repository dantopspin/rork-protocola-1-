import Foundation

nonisolated enum ReminderPlanner {

    struct Candidate: Sendable {
        let id: String
        let at: Date
        let title: String
        let body: String
        /// Fire at this wall-clock time in whatever zone the iPhone is in.
        var floating: Bool = false

        init(
            id: String,
            at: Date,
            title: String =
                "Protocola · scheduled entry",
            body: String =
                "An entry in your recorded protocol is scheduled. Open Protocola to review it.",
            floating: Bool = false
        ) {
            self.floating = floating
            self.id = id
            self.at = at
            self.title = title
            self.body = body
        }
    }

    static func select(
        _ candidates: [Candidate],
        now: Date,
        otherPending: Int
    ) -> [Candidate] {
        let capacity =
            max(
                0,
                60 - max(0, otherPending)
            )
        var seen: Set<String> = []
        let upcoming =
            candidates
                .filter {
                    $0.at > now
                }
                .sorted {
                    $0.at < $1.at
                }
                .filter {
                    seen.insert($0.id)
                        .inserted
                }

        // Dose reminders, cycle notes and inventory alerts first; follow-ups
        // and the weekly recap only fill what is left, so they can never
        // push a real dose reminder past iOS's pending limit.
        let isSecondary: (Candidate) -> Bool = {
            $0.id.hasPrefix("followup:")
            || $0.id.hasPrefix("weekly-recap:")
        }
        let primary =
            Array(upcoming.filter { !isSecondary($0) }.prefix(capacity))
        let secondary =
            Array(
                upcoming.filter(isSecondary)
                    .prefix(max(0, capacity - primary.count))
            )
        return (primary + secondary).sorted { $0.at < $1.at }
    }
}

import Foundation

nonisolated enum ReminderPlanner {

    struct Candidate: Sendable {
        let id: String
        let at: Date
        let title: String
        let body: String

        init(
            id: String,
            at: Date,
            title: String =
                "Protocola · scheduled entry",
            body: String =
                "An entry in your recorded protocol is scheduled. Open Protocola to review it."
        ) {
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

        return Array(
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
                .prefix(capacity)
        )
    }
}

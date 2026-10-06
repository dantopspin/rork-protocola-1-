import SwiftUI

/// Calendar of recorded (non-skipped) entries per day for one protocol,
/// drawn with the vendored SwiftPieces `ActivityHeatmap`.
///
/// The streak summary is deliberately hidden: many protocols are not daily
/// (every N days, weekdays, ON/OFF cycles, as needed), so a consecutive-day
/// streak would read as a target Protocola does not set.
struct RecordedEntriesHeatmap: View {
    let logs: [DoseLog]

    static let weeks = 20

    var body: some View {
        EditorialSection("Recorded entries") {
            ActivityHeatmap(
                Self.counts(logs),
                weeks: Self.weeks,
                showsSummary: false,
                messages: ActivityHeatmap.Messages(
                    title: "Recorded entries",
                    noActivity: "No recorded entries"
                ),
                style: Self.style
            ) { value in
                let count = Int(value.rounded())
                return count == 1
                    ? "1 entry"
                    : "\(count) entries"
            }

            Text(
                "Each square is one day of the last \(Self.weeks) weeks. Darker means more entries recorded; skipped entries are not counted."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
        }
    }

    /// Entries per local day. Skipped entries record that nothing was
    /// administered, so they are excluded.
    static func counts(
        _ logs: [DoseLog],
        calendar: Calendar = .current
    ) -> [Date: Int] {
        logs
            .filter {
                $0.status != "Skipped"
            }
            .reduce(into: [:]) { result, log in
                result[
                    calendar.startOfDay(
                        for: log.loggedAt
                    ),
                    default: 0
                ] += 1
            }
    }

    private static let style =
        ActivityHeatmap.Style(
            accent: Theme.teal,
            ground: Theme.paper,
            empty: Theme.line,
            text: Theme.ink,
            secondary: Theme.textSecondary,
            callout: Theme.ink,
            calloutText: Theme.onDarkPrimary,
            cornerRadius: Theme.radiusCard
        )
}

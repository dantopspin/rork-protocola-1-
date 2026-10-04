import Foundation
import CoreGraphics

/// Aggregates rendered on the shareable progress card. Deliberately carries no compound
/// names, doses, sites, or symptoms — privacy is enforced by the type, not the view.
struct ShareCardData {
    let periodLabel: String
    let percentage: String
    let recorded: Int
    let scheduled: Int
    let bars: [Bar]
    struct Bar: Identifiable { let date: Date; let recorded: Int; let scheduled: Int; var id: Date { date } }
    var barWidth: CGFloat { bars.count > 10 ? 8 : 18 }

    init?(summary: InsightsSummary, window: Int) {
        guard summary.scheduled > 0 else { return nil }
        periodLabel = window == 7 ? "Last 7 days" : "Last 30 days"
        percentage = summary.percentage
        recorded = summary.recorded
        scheduled = summary.scheduled
        bars = summary.days.map { Bar(date: $0.date, recorded: $0.recorded, scheduled: $0.scheduled) }
    }
}

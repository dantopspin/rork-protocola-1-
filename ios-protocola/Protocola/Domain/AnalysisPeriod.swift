import Foundation

/// Half-open intervals give boundary records to the after period exactly once.
nonisolated struct AnalysisPeriod: Equatable, Sendable {
    let start: Date
    let end: Date
    func contains(_ date: Date) -> Bool { date >= start && date < end }
    static func comparison(change: Date, now: Date, maximumDays: Int = 30) -> (before: AnalysisPeriod, after: AnalysisPeriod) {
        let duration = max(0, min(now.timeIntervalSince(change), TimeInterval(maximumDays) * 86400))
        return (AnalysisPeriod(start: change.addingTimeInterval(-duration), end: change), AnalysisPeriod(start: change, end: change.addingTimeInterval(duration)))
    }
}

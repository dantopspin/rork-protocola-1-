import Foundation

/// Deterministic consistency for a period: a scheduled entry counts as recorded when a log
/// exists and its status is not Skipped. Corrections replace the log, so an entry counts once.
struct InsightsSummary {
    struct Day: Identifiable { let date: Date; let scheduled: Int; let recorded: Int; var id: Date { date } }
    struct Site: Identifiable { let name: String; let count: Int; var id: String { name } }
    struct Symptom: Identifiable { let id: UUID; let date: Date; let name: String; let severity: Int }
    let days: [Day]
    let sites: [Site]
    let symptoms: [Symptom]
    let scheduled: Int
    let recorded: Int
    let percentage: String
    var fullyRecorded: Bool { scheduled > 0 && recorded == scheduled }
    init(store: TrackingStore, window: Int, now: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(window - 1), to: today) ?? today
        self.init(store: store, period: AnalysisPeriod(start: start, end: now), protocolID: nil)
    }
    init(store: TrackingStore, period: AnalysisPeriod, protocolID: UUID?) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: period.start)
        let window = max(1, (calendar.dateComponents([.day], from: start, to: period.end).day ?? 0) + 1)
        let entries = store.entries(start: period.start, end: period.end).filter { protocolID == nil || $0.revision.protocolID == protocolID }
        days = (0..<window).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let inDay = entries.filter { calendar.isDate($0.at, inSameDayAs: day) }
            return Day(date: day, scheduled: inDay.count, recorded: inDay.filter { $0.log != nil && $0.log?.status != "Skipped" }.count)
        }
        scheduled = entries.count; recorded = entries.filter { $0.log != nil && $0.log?.status != "Skipped" }.count
        percentage = scheduled == 0 ? "—" : "\(recorded * 100 / scheduled)%"
        let logs = store.logs.filter { period.contains($0.loggedAt) && (protocolID == nil || $0.protocolID == protocolID) }
        sites = Dictionary(grouping: logs.filter { !$0.site.isEmpty && $0.status != "Skipped" }, by: \.site).map { Site(name: $0.key, count: $0.value.count) }.sorted { $0.name < $1.name }
        symptoms = logs.filter { !$0.symptoms.isEmpty }.map { Symptom(id: $0.id, date: $0.loggedAt, name: $0.symptoms, severity: $0.symptomSeverity) }
    }
}

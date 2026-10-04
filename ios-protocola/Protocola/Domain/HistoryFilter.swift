import Foundation

@MainActor enum HistoryFilter {
    static func logs(_ records: [DoseLog], search: String, status: String, from: Date?, to: Date?) -> [DoseLog] {
        records.filter {
            (status == "All" || $0.status == status) && matchesDate($0.loggedAt, from: from, to: to) && (search.isEmpty || "\($0.compoundName) \($0.protocolName) \($0.site) \($0.notes) \($0.symptoms)".localizedStandardContains(search))
        }.sorted { $0.loggedAt > $1.loggedAt }
    }
    static func events(_ records: [ProtocolEvent], search: String, from: Date?, to: Date?) -> [ProtocolEvent] {
        records.filter { matchesDate($0.at, from: from, to: to) && (search.isEmpty || "\($0.title) \($0.detail)".localizedStandardContains(search)) }
    }
    private static func matchesDate(_ date: Date, from: Date?, to: Date?) -> Bool {
        let day = Calendar.current.startOfDay(for: date)
        return (from == nil || day >= Calendar.current.startOfDay(for: from ?? date)) && (to == nil || day <= Calendar.current.startOfDay(for: to ?? date))
    }
}

import Foundation

/// One chronological record shared by history, analysis, and document generation.
struct TimelineRecord: Identifiable {
    let id: UUID
    let at: Date
    let protocolID: UUID?
    let title: String
    let detail: String
    let category: String
    let log: DoseLog?
    let event: ProtocolEvent?
    static func build(logs: [DoseLog], events: [ProtocolEvent], includeMetadata: Bool = false) -> [TimelineRecord] {
        let doses = logs.map { log in
            var detail = "\(log.actualAmountText) \(log.unitText) · \(log.routeText) · \(log.status)"
            if log.route.usesInjectionSite, !log.site.isEmpty { detail += "\nSite: \(log.site)" }
            if !log.symptoms.isEmpty { detail += "\nSymptoms: \(log.symptoms) · \(log.symptomSeverity)/10" }
            if !log.notes.isEmpty { detail += "\nNotes: \(log.notes)" }
            return TimelineRecord(id: log.id, at: log.loggedAt, protocolID: log.protocolID, title: log.compoundName, detail: detail, category: "Dose", log: log, event: nil)
        }
        let changes = events.filter { includeMetadata || $0.showsInTimeline }.map { TimelineRecord(id: $0.id, at: $0.at, protocolID: $0.protocolID, title: $0.title, detail: $0.detail, category: $0.category, log: nil, event: $0) }
        return (doses + changes).sorted { $0.at == $1.at ? $0.id.uuidString < $1.id.uuidString : $0.at > $1.at }
    }
}

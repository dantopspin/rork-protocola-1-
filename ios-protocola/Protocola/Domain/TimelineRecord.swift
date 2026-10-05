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
    let lab: LabRecord?

    static func build(
        logs: [DoseLog],
        events: [ProtocolEvent],
        labs: [LabRecord] = [],
        includeMetadata: Bool = false
    ) -> [TimelineRecord] {
        let doses =
            logs.map { log in
                var detail =
                    "\(log.actualAmountText) \(log.unitText) · \(log.routeText) · \(log.status)"

                if log.route
                    .usesInjectionSite,
                   !log.site.isEmpty {
                    detail +=
                        "\nSite: \(log.site)"
                }

                if !log.symptoms.isEmpty {
                    detail +=
                        "\nSymptoms: \(log.symptoms) · \(log.symptomSeverity)/10"
                }

                if !log.notes.isEmpty {
                    detail +=
                        "\nNotes: \(log.notes)"
                }

                return TimelineRecord(
                    id: log.id,
                    at: log.loggedAt,
                    protocolID:
                        log.protocolID,
                    title:
                        log.compoundName,
                    detail: detail,
                    category: "Dose",
                    log: log,
                    event: nil,
                    lab: nil
                )
            }

        let changes =
            events
                .filter {
                    includeMetadata
                    || $0.showsInTimeline
                }
                .map { event in
                    TimelineRecord(
                        id: event.id,
                        at: event.at,
                        protocolID:
                            event.protocolID,
                        title: event.title,
                        detail:
                            event.detail,
                        category:
                            event.category,
                        log: nil,
                        event: event,
                        lab: nil
                    )
                }

        let labRecords =
            labs.map { lab in
                var detail =
                    lab.displayValue

                if let range =
                    lab.referenceRangeText {
                    detail +=
                        "\nReference: "
                        + range
                }

                if !lab.notes.isEmpty {
                    detail +=
                        "\nNotes: "
                        + lab.notes
                }

                return TimelineRecord(
                    id: lab.id,
                    at: lab.collectedAt,
                    protocolID:
                        lab.protocolID,
                    title: lab.marker,
                    detail: detail,
                    category: "Lab",
                    log: nil,
                    event: nil,
                    lab: lab
                )
            }

        return (
            doses
            + changes
            + labRecords
        )
        .sorted {
            $0.at == $1.at
            ? $0.id.uuidString
                < $1.id.uuidString
            : $0.at > $1.at
        }
    }
}

import Foundation
import UIKit

/// Builds the Visit Summary PDF: a structured, neutrally framed summary of the user's
/// recorded data. It renders only what was recorded — no interpretation, averages, or advice.
@MainActor enum VisitSummaryService {
    static func generate(protocols: [ProtocolRecord], compounds: [CompoundRecord], revisions: [ScheduleRevision], logs: [DoseLog], events: [ProtocolEvent] = [], labs: [LabRecord] = [], period: AnalysisPeriod? = nil, summary: InsightsSummary? = nil, now: Date = .now) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 in points
        let margin: CGFloat = 44
        let contentWidth = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            context.beginPage()
            var y = margin
            func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 6) {
                let paragraph = NSMutableParagraphStyle(); paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
                var remaining = text[...]
                while !remaining.isEmpty {
                    var length = min(remaining.count, 1200)
                    var chunk = String(remaining.prefix(length))
                    var attributed = NSAttributedString(string: chunk, attributes: attributes)
                    var height = ceil(attributed.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
                    while height > pageRect.height - margin * 2 && length > 1 {
                        length = max(1, length / 2); chunk = String(remaining.prefix(length))
                        attributed = NSAttributedString(string: chunk, attributes: attributes)
                        height = ceil(attributed.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
                    }
                    if y + height > pageRect.height - margin { context.beginPage(); y = margin }
                    attributed.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    y += height + spacingAfter
                    remaining = remaining.dropFirst(length)
                }
            }
            func gap(_ value: CGFloat = 10) { y += value }
            draw("Visit Summary", font: .systemFont(ofSize: 26, weight: .semibold), spacingAfter: 2)
            draw("Generated \(now.formatted(date: .long, time: .omitted)) · Protocola", font: .systemFont(ofSize: 10), color: .darkGray, spacingAfter: 12)
            draw("A structured summary of records kept in Protocola. It does not interpret data or provide medical guidance.", font: .italicSystemFont(ofSize: 10), color: .darkGray, spacingAfter: 16)

            if let period { draw("Record period: \(period.start.formatted(date: .abbreviated, time: .shortened)) – \(period.end.formatted(date: .abbreviated, time: .shortened))", font: .systemFont(ofSize: 11)) }
            draw("Earlier events may not contain previous values. Only retained records are included. Missing symptoms are not evidence of absence; timing never establishes causation.", font: .systemFont(ofSize: 10), color: .darkGray)
            if let summary { draw("Consistency: \(summary.percentage) · \(summary.recorded) non-skipped recorded scheduled entries / \(summary.scheduled) elapsed scheduled entries", font: .systemFont(ofSize: 11)) }
            draw("Current protocols", font: .systemFont(ofSize: 16, weight: .semibold), spacingAfter: 8)
            if protocols.isEmpty { draw("No protocols recorded.", font: .systemFont(ofSize: 11), color: .darkGray) }
            for record in protocols {
                draw("\(record.name) · \(record.status)", font: .systemFont(ofSize: 12, weight: .semibold), spacingAfter: 2)
                if !record.instructionSource.isEmpty { draw("Recorded source: \(record.instructionSource)", font: .systemFont(ofSize: 11), color: .darkGray, spacingAfter: 2) }
                for revision in revisions.filter({ $0.protocolID == record.id && $0.isEffective(at: now) }) {
                    let compound = compounds.first { $0.id == revision.compoundID }?.name ?? revision.compoundName
                    var line = "\(compound) · \(revision.amountText) \(revision.unitText) · \(revision.routeText)"
                    if let config = revision.config {
                        line += " · " + ScheduleDisplay.summary(config)
                        if let cycle = CycleDisplay.status(config, at: now) {
                            line += " · " + cycle
                        }
                    } else {
                        line += " · Schedule unavailable"
                    }
                    draw(line, font: .systemFont(ofSize: 11), color: .darkGray)
                }
                if !record.notes.isEmpty { draw("Notes: \(record.notes)", font: .systemFont(ofSize: 11), color: .darkGray) }
                gap(6)
            }
            let planned =
                revisions
                    .filter {
                        $0.isPlanned(
                            after: now
                        )
                    }
                    .sorted {
                        $0.effectiveFrom
                            < $1.effectiveFrom
                    }

            if !planned.isEmpty {
                gap()
                draw(
                    "Planned protocol changes",
                    font: .systemFont(
                        ofSize: 16,
                        weight: .semibold
                    ),
                    spacingAfter: 8
                )

                for revision in planned {
                    var line =
                        revision.effectiveFrom
                            .formatted(
                                date: .abbreviated,
                                time: .omitted
                            )
                        + " · "
                        + revision.compoundName
                        + " · "
                        + revision.amountText
                        + " "
                        + revision.unitText

                    if let config =
                        revision.config {
                        line +=
                            " · "
                            + ScheduleDisplay
                                .summary(config)
                    }

                    draw(
                        line,
                        font: .systemFont(
                            ofSize: 11
                        ),
                        color: .darkGray,
                        spacingAfter: 3
                    )
                }

                draw(
                    "Planned changes reflect recorded future revisions and are not dosing recommendations.",
                    font: .italicSystemFont(
                        ofSize: 10
                    ),
                    color: .darkGray,
                    spacingAfter: 8
                )
            }

            gap()

            draw("Key protocol changes", font: .systemFont(ofSize: 16, weight: .semibold))
            for event in events.filter({ $0.category == "Protocol" }).sorted(by: { $0.at < $1.at }) {
                draw("\(event.at.formatted(date: .abbreviated, time: .shortened)) · \(event.title)", font: .systemFont(ofSize: 11, weight: .semibold))
                for line in event.detail.components(separatedBy: "\n") { draw(line, font: .systemFont(ofSize: 10), color: .darkGray) }
                if event.changesData == nil { draw("Previous values unavailable for this older event.", font: .systemFont(ofSize: 10), color: .darkGray) }
            }
            draw("Recorded entries", font: .systemFont(ofSize: 16, weight: .semibold), spacingAfter: 8)
            let ordered = logs.sorted { $0.loggedAt < $1.loggedAt }
            if ordered.isEmpty { draw("No entries recorded.", font: .systemFont(ofSize: 11), color: .darkGray) }
            for log in ordered {
                var line = "\(log.loggedAt.formatted(date: .abbreviated, time: .shortened)) · \(log.compoundName) · \(log.actualAmountText) \(log.unitText) · \(log.routeText) · \(log.status)"
                if log.route.usesInjectionSite, !log.site.isEmpty { line += " · site: \(log.site)" }
                draw(line, font: .systemFont(ofSize: 11), color: .darkGray, spacingAfter: 3)
            }

            let symptoms = Dictionary(grouping: ordered.filter { !$0.symptoms.isEmpty }, by: \.symptoms)
            if !symptoms.isEmpty {
                gap()
                draw("Symptoms recorded", font: .systemFont(ofSize: 16, weight: .semibold), spacingAfter: 8)
                for (name, group) in symptoms.sorted(by: { $0.value.count > $1.value.count }) {
                    draw("\(name) — \(group.count) \(group.count == 1 ? "entry" : "entries")", font: .systemFont(ofSize: 11), color: .darkGray, spacingAfter: 3)
                }
            }
            if !labs.isEmpty {
                gap()
                draw("Lab records", font: .systemFont(ofSize: 16, weight: .semibold), spacingAfter: 8)

                for lab in labs.sorted(by: { $0.collectedAt < $1.collectedAt }) {
                    var line =
                        lab.collectedAt.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                        + " · "
                        + lab.marker
                        + " · "
                        + lab.displayValue

                    if let range =
                        lab.referenceRangeText {
                        line +=
                            " · recorded reference: "
                            + range
                    }

                    draw(
                        line,
                        font: .systemFont(ofSize: 11),
                        color: .darkGray,
                        spacingAfter: 3
                    )

                    if !lab.notes.isEmpty {
                        draw(
                            "Notes: " + lab.notes,
                            font: .systemFont(ofSize: 10),
                            color: .darkGray,
                            spacingAfter: 3
                        )
                    }
                }

                draw(
                    "Lab values and reference ranges are reproduced as recorded and are not interpreted by Protocola.",
                    font: .italicSystemFont(ofSize: 10),
                    color: .darkGray,
                    spacingAfter: 8
                )
            }

            gap()
            draw("Chronological timeline", font: .systemFont(ofSize: 16, weight: .semibold))
            for record in TimelineRecord.build(logs: logs, events: events, labs: labs, includeMetadata: true).reversed() {
                draw("\(record.at.formatted(date: .abbreviated, time: .shortened)) · \(record.title) · \(record.category)", font: .systemFont(ofSize: 11, weight: .semibold))
                for line in record.detail.components(separatedBy: "\n") { draw(line, font: .systemFont(ofSize: 10), color: .darkGray) }
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Protocola-visit-summary-\(UUID().uuidString).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }
}

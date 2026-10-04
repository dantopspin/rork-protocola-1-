import Foundation

/// Canonical local audit values; schedule encoding avoids changes caused by display formatting.
enum ProtocolSnapshot {
    static func schedule(_ config: ScheduleConfig) -> String {
        let times = config.minutes.sorted().map { String(format: "%02d:%02d", $0 / 60, $0 % 60) }.joined(separator: ", ")
        return "\(config.kind.rawValue); days \(config.weekdays.sorted()); interval \(config.interval); times \(times); starts \(config.anchor.ISO8601Format()); zone \(config.timeZoneID)"
    }
    static func values(record: ProtocolRecord, revision: ScheduleRevision?) -> [String: String] {
        var values = ["Name": record.name, "Source": record.instructionSource, "Notes": record.notes, "Status": record.status]
        if let revision {
            values.merge(["Compound": revision.compoundName, "Amount": revision.amountText, "Unit": revision.unitText, "Schedule": revision.config.map(schedule) ?? "Unavailable", "Vial": revision.vialID?.uuidString ?? "", "Site": revision.configuredSite ?? "", "Reminders": revision.reminders ? "On" : "Off"], uniquingKeysWith: { _, new in new })
        }
        return values
    }
    static func values(draft: ProtocolDraft, name: String, compound: String, amount: Decimal, config: ScheduleConfig, status: String) -> [String: String] {
        ["Name": name, "Source": draft.source, "Notes": draft.notes, "Status": status, "Compound": compound, "Amount": DoseCalculator.text(amount), "Unit": draft.unit.rawValue, "Schedule": schedule(config), "Vial": draft.vialID?.uuidString ?? "", "Site": draft.site, "Reminders": draft.reminders && draft.kind != .asRecorded ? "On" : "Off"]
    }
}

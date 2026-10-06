import Foundation

@MainActor enum DemoData {
    static func seed(_ repository: TrackingRepository) throws {
        var vial = VialDraft(); vial.name = "Sample vial 01"; vial.compound = "BPC-157"; vial.amount = "10"; vial.diluent = "2"; vial.batch = "DEMO-01"; vial.notes = "Illustrative records only. Not instructions."
        try repository.saveVial(vial, id: nil)
        let sampleVial = try repository.all(VialRecord.self).first
        var protocolDraft = ProtocolDraft(); protocolDraft.name = "Sample protocol"; protocolDraft.compound = "BPC-157"; protocolDraft.amount = "250"; protocolDraft.vialID = sampleVial?.id; protocolDraft.source = "Illustrative demo — not instructions"
        protocolDraft.start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        protocolDraft.times = [RecordedTime(date: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now)]
        try repository.saveProtocol(protocolDraft, protocolID: nil, compoundID: nil)
        if let revision = try repository.all(ScheduleRevision.self).first, let config = revision.config {
            for offset in 1...5 {
                guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: .now), let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: day)), let at = SchedulingEngine.occurrences(config: config, effectiveFrom: revision.effectiveFrom, effectiveUntil: nil, start: Calendar.current.startOfDay(for: day), end: end).first else { continue }
                var draft = DoseDraft(revision: revision); draft.loggedAt = at; draft.site = offset % 2 == 0 ? "Left abdomen" : "Right abdomen"; draft.notes = "Sample record"
                if offset == 3 { draft.symptoms = "Tenderness"; draft.severity = 2 }
                let entry = ScheduledEntry(id: SchedulingEngine.occurrenceKey(compoundID: revision.compoundID, revisionID: revision.id, at: at, config: config), revision: revision, at: at, log: nil)
                try repository.saveDose(draft, revision: revision, occurrence: entry, correcting: nil)
            }
        }
        let prefs = try repository.preferences()
        try repository.transaction { prefs.onboarded = true; prefs.disclaimerAccepted = true }
    }
}

import Foundation
import Testing
import SwiftData
import UserNotifications
@testable import Protocola

@MainActor struct IntegrityTests {
    @Test func untrackedVolumeIsRecordedWithoutInventingConcentration() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "0.1"; p.unit = .mL
        try repo.saveProtocol(p, protocolID: nil, compoundID: nil)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        let dose = DoseDraft(revision: revision)
        try repo.saveDose(dose, revision: revision, occurrence: nil, correcting: nil)
        let log = try #require(repo.all(DoseLog.self).first)
        #expect(log.concentration == nil)
        #expect(log.vialID == nil)
        #expect(log.consumptionMg == 0)
        #expect(log.volumeMlText == "0.1")
    }
    @Test func strengthEditAndBalanceCorrectionUseUpdatedBase() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var draft = VialDraft(); draft.name = "A"; draft.compound = "C"; draft.amount = "10"; draft.diluent = "2"
        try repo.saveVial(draft, id: nil)
        let vial = try #require(repo.all(VialRecord.self).first)
        draft.amount = "20"; draft.correctedBalance = "15"
        try repo.saveVial(draft, id: vial.id)
        #expect(try repo.balance(vial) == 15)
    }
    @Test func skippedCorrectionAndManualBalanceRemainConsistent() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var v = VialDraft(); v.name = "A"; v.compound = "C"; v.amount = "10"; v.diluent = "2"
        try repo.saveVial(v, id: nil)
        let vial = try #require(repo.all(VialRecord.self).first)
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "250"; p.vialID = vial.id
        try repo.saveProtocol(p, protocolID: nil, compoundID: nil)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        var dose = DoseDraft(revision: revision)
        #expect(dose.site.isEmpty)
        try repo.saveDose(dose, revision: revision, occurrence: nil, correcting: nil)
        let log = try #require(repo.all(DoseLog.self).first)
        v.correctedBalance = "8"
        try repo.saveVial(v, id: vial.id)
        dose.status = "Skipped"
        try repo.saveDose(dose, revision: nil, occurrence: nil, correcting: log)
        #expect(try repo.balance(vial) == Decimal(string: "8.25"))
        try repo.deleteDose(log)
        #expect(try repo.balance(vial) == Decimal(string: "8.25"))
    }
    @Test func persistedRevisionPreservesPastOccurrenceIDs() throws {
        let container = try LocalPersistence.container(inMemory: true)
        let store = TrackingStore(container: container)
        let start = Calendar.current.startOfDay(for: .now)
        let boundary = start.addingTimeInterval(12 * 3600)
        let end = start.addingTimeInterval(24 * 3600)
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "250"; p.start = start
        p.times = [RecordedTime(date: start.addingTimeInterval(8 * 3600)), RecordedTime(date: start.addingTimeInterval(20 * 3600))]
        try store.repository.saveProtocol(p, protocolID: nil, compoundID: nil, now: start)
        store.refresh(now: boundary)
        let first = store.entries(start: start, end: boundary).map(\.id)
        let old = try #require(store.revisions.first)
        p.amount = "500"
        try store.repository.saveProtocol(p, protocolID: old.protocolID, compoundID: old.compoundID, now: boundary)
        store.refresh(now: boundary)
        #expect(store.entries(start: start, end: boundary).map(\.id) == first)
        #expect(store.entries(start: boundary, end: end).allSatisfy { $0.revision.amountText == "500" })
    }
    @Test func exactMatchingDoesNotCompleteSecondDailyEntry() throws {
        let store = TrackingStore(container: try LocalPersistence.container(inMemory: true))
        let start = Calendar.current.startOfDay(for: .now)
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "250"; p.start = start
        p.times = [RecordedTime(date: start.addingTimeInterval(8 * 3600)), RecordedTime(date: start.addingTimeInterval(20 * 3600))]
        try store.repository.saveProtocol(p, protocolID: nil, compoundID: nil)
        store.refresh()
        let entry = try #require(store.today.first)
        let dose = DoseDraft(revision: entry.revision)
        try store.repository.saveDose(dose, revision: entry.revision, occurrence: entry, correcting: nil)
        store.refresh()
        #expect(store.today.filter { $0.log != nil }.count == 1)
        #expect(store.today.filter { $0.log == nil }.count == 1)
    }
    @Test func automaticAIContextGathersRecentRecordsAndExcludesPrivateFields() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var p = ProtocolDraft(); p.name = "Private name"; p.compound = "C"; p.amount = "250"
        try repo.saveProtocol(p, protocolID: nil, compoundID: nil)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        let base = Date.now
        for index in 0..<32 {
            var dose = DoseDraft(revision: revision)
            dose.loggedAt = base.addingTimeInterval(TimeInterval(-index * 60))
            dose.amount = String(index + 1)
            dose.notes = "Private notes"
            if index == 0 { dose.site = "Recorded site"; dose.symptoms = "Recorded symptoms" }
            try repo.saveDose(dose, revision: revision, occurrence: nil, correcting: nil)
        }
        let logs = try repo.all(DoseLog.self).sorted { $0.loggedAt > $1.loggedAt }
        let context = AssistantViewModel.automaticContext(logs)
        #expect(context.lines.count == 30)
        #expect(context.lines[0].contains("actual 1 mcg"))
        #expect(context.text.contains("Recorded site"))
        #expect(context.text.contains("Recorded symptoms"))
        #expect(!context.text.contains("actual 31 "))
        #expect(!context.text.contains("actual 32 "))
        #expect(!context.text.contains("Private notes"))
        #expect(!context.text.contains("Private name"))
    }
    @Test func calendarReminderKeepsAbsoluteTimeAndStableID() throws {
        let at = Date(timeIntervalSince1970: floor(Date.now.timeIntervalSince1970) + 120)
        let request = NotificationService.request(id: "stable-entry", at: at, content: UNMutableNotificationContent())
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(request.identifier == "protocola:stable-entry")
        #expect(trigger.repeats == false)
        let next = try #require(trigger.nextTriggerDate())
        #expect(abs(next.timeIntervalSince(at)) < 1)
    }
}

struct ReminderPlannerTests {
    @Test func capacitySortingAndDeduplication() {
        let now = Date(timeIntervalSince1970: 1_735_689_600)
        var candidates = (1...80).reversed().map { ReminderPlanner.Candidate(id: String($0), at: now.addingTimeInterval(TimeInterval($0 * 60))) }
        candidates.append(.init(id: "1", at: now.addingTimeInterval(60)))
        candidates.append(.init(id: "past", at: now.addingTimeInterval(-60)))
        let selected = ReminderPlanner.select(candidates, now: now, otherPending: 5)
        #expect(selected.count == 55)
        #expect(selected.first?.id == "1")
        #expect(selected.last?.id == "55")
        #expect(!selected.contains { $0.id == "past" })
        #expect(ReminderPlanner.select(candidates, now: now, otherPending: 64).isEmpty)
    }
}

/// Growth pass: deterministic consistency, repeat-last prefill rules, and card aggregates.
@MainActor struct ConsistencyTests {
    @Test func countsStatusesDeterministically() throws {
        let (store, endOfToday, entries) = try sevenDayStore()
        #expect(entries.count == 7)
        // Day 0 Logged, 1 Skipped, 2 Partial, 3 Delayed, 4 Logged then corrected, 5 unlogged, 6 Logged.
        let statuses: [String?] = ["Logged", "Skipped", "Partial", "Delayed", "Logged", nil, "Logged"]
        for (index, entry) in entries.enumerated() {
            guard let status = statuses[index] else { continue }
            var dose = DoseDraft(revision: entry.revision)
            dose.status = status
            try store.repository.saveDose(dose, revision: entry.revision, occurrence: entry, correcting: nil)
        }
        store.refresh(now: endOfToday)
        let corrected = try #require(store.entries(start: entries[0].at, end: endOfToday).first { $0.at == entries[4].at }?.log)
        var edit = DoseDraft(log: corrected)
        edit.amount = "2"
        try store.repository.saveDose(edit, revision: nil, occurrence: nil, correcting: corrected)
        store.refresh(now: endOfToday)
        let summary = InsightsSummary(store: store, window: 7, now: endOfToday)
        #expect(summary.scheduled == 7)
        #expect(summary.recorded == 5) // Skipped excluded; the corrected entry counts once; one day unlogged
        #expect(summary.percentage == "71%")
        #expect(!summary.fullyRecorded)
        let card = ShareCardData(summary: summary, window: 7)
        #expect(card?.periodLabel == "Last 7 days")
        #expect(card?.bars.count == 7)
        #expect(card?.recorded == 5)
    }

    @Test func fullyRecordedFollowsTheSameRuleWhenCorrectingToSkipped() throws {
        let (store, endOfToday, entries) = try sevenDayStore()
        for entry in entries {
            let dose = DoseDraft(revision: entry.revision)
            try store.repository.saveDose(dose, revision: entry.revision, occurrence: entry, correcting: nil)
        }
        store.refresh(now: endOfToday)
        let summary = InsightsSummary(store: store, window: 7, now: endOfToday)
        #expect(summary.recorded == 7)
        #expect(summary.fullyRecorded)
        let skipped = try #require(store.entries(start: entries[0].at, end: endOfToday).first?.log)
        var edit = DoseDraft(log: skipped)
        edit.status = "Skipped"
        try store.repository.saveDose(edit, revision: nil, occurrence: nil, correcting: skipped)
        store.refresh(now: endOfToday)
        let updated = InsightsSummary(store: store, window: 7, now: endOfToday)
        #expect(updated.recorded == 6)
        #expect(updated.scheduled == 7)
        #expect(updated.percentage == "85%")
        #expect(!updated.fullyRecorded)
    }

    /// A daily protocol over the last seven days at 08:00, evaluated at the end of today
    /// so every occurrence sits inside the window regardless of when the test runs.
    private func sevenDayStore() throws -> (TrackingStore, Date, [ScheduledEntry]) {
        let store = TrackingStore(container: try LocalPersistence.container(inMemory: true))
        let calendar = Calendar.current
        let endOfToday = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: .now)!
        let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6, to: endOfToday)!)
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "1"; p.unit = .mg; p.start = start
        p.times = [RecordedTime(date: start.addingTimeInterval(8 * 3600))]
        try store.repository.saveProtocol(p, protocolID: nil, compoundID: nil, now: start)
        store.refresh(now: endOfToday)
        return (store, endOfToday, store.entries(start: start, end: endOfToday))
    }
}

@MainActor struct RepeatLastTests {
    @Test func reusesOnlyCompatibleConvenienceFields() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var v = VialDraft(); v.name = "A"; v.compound = "C"; v.amount = "10"; v.diluent = "2"
        try repo.saveVial(v, id: nil)
        let vial = try #require(repo.all(VialRecord.self).first)
        var scheduled = ProtocolDraft(); scheduled.name = "Scheduled"; scheduled.compound = "C"; scheduled.amount = "250"; scheduled.vialID = vial.id
        try repo.saveProtocol(scheduled, protocolID: nil, compoundID: nil)
        let pinned = try #require(repo.all(ScheduleRevision.self).first { $0.vialID == vial.id })
        var unscheduled = ProtocolDraft(); unscheduled.name = "Open"; unscheduled.compound = "C"; unscheduled.amount = "250"
        try repo.saveProtocol(unscheduled, protocolID: nil, compoundID: nil)
        let open = try #require(repo.all(ScheduleRevision.self).first { $0.vialID == nil })
        var dose = DoseDraft(revision: pinned)
        dose.amount = "999" // history must never override the current scheduled dose
        dose.site = "Left thigh"; dose.symptoms = "Tired"; dose.notes = "Private"; dose.unitsPerMl = "50"
        try repo.saveDose(dose, revision: pinned, occurrence: nil, correcting: nil)
        let last = try #require(repo.all(DoseLog.self).first)
        let prefill = DoseDraft.repeatLast(revision: open, last: last, candidateVial: vial)
        #expect(prefill.amount == open.amountText) // dose comes from the current schedule, never history
        #expect(prefill.unit == open.unit)
        #expect(prefill.vialID == vial.id) // compatible convenience reuse only
        #expect(prefill.unitsPerMl == "50")
        #expect(prefill.site.isEmpty); #expect(prefill.symptoms.isEmpty); #expect(prefill.notes.isEmpty)
        let incompatible = DoseDraft.repeatLast(revision: open, last: last, candidateVial: nil)
        #expect(incompatible.vialID == nil)
        #expect(incompatible.unitsPerMl == "100")
        let scheduleWins = DoseDraft.repeatLast(revision: pinned, last: last, candidateVial: nil)
        #expect(scheduleWins.vialID == vial.id)
    }
}


@MainActor
struct AIPrivacyHardeningTests {

    @Test
    func timelineAIExcludesLabsAndHiddenMetadata() throws {
        let protocolID = UUID()

        let lab =
            LabRecord(
                protocolID: protocolID,
                marker: "Private marker",
                value: 999,
                unit: "unit",
                collectedAt: .now
            )

        let metadata =
            ProtocolEvent(
                protocolID: protocolID,
                title:
                    "Lab record corrected",
                detail: ""
            )

        try metadata.recordChanges(
            [
                RecordChange(
                    field: "Value",
                    before: "1",
                    after: "999"
                )
            ],
            category: "Metadata"
        )

        let records =
            TimelineRecord.build(
                logs: [],
                events: [metadata],
                labs: [lab],
                includeMetadata: true
            )

        let context =
            AssistantViewModel
                .timelineContext(
                    records
                )

        #expect(
            !context.text.contains(
                "Private marker"
            )
        )
        #expect(
            !context.text.contains(
                "Lab record corrected"
            )
        )
        #expect(
            !context.text.contains(
                "999"
            )
        )
        #expect(
            context.text.contains(
                "private metadata and lab records are excluded"
            )
        )
    }
}

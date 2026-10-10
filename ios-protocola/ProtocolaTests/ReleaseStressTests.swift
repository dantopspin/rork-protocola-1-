import Foundation
import Testing
import SwiftData
@testable import Protocola

/// Pre-release "idiot" and stress tests: the inputs real users type and the
/// data volume a long-term user builds up.
@MainActor
struct ReleaseStressTests {

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour, minute: minute))!
    }

    private func dailyDraft(
        name: String = "Protocol",
        compound: String = "Compound",
        hours: [Int],
        start: Date
    ) -> ProtocolDraft {
        var draft = ProtocolDraft()
        draft.name = name
        draft.compound = compound
        draft.amount = "250"
        draft.unit = .mcg
        draft.kind = .daily
        draft.timeZoneID = "UTC"
        draft.followsDeviceTimeZone = false
        draft.start = start
        draft.times = hours.map { RecordedTime(date: date(2, $0)) }
        return draft
    }

    // MARK: - Critical: editing a protocol must not un-log an early dose

    @Test
    func earlyLoggedDoseSurvivesProtocolRename() throws {
        let container = try LocalPersistence.container(inMemory: true)
        let repo = TrackingRepository(container: container)
        let morning = date(2, 10)

        try repo.saveProtocol(
            dailyDraft(hours: [8, 20], start: date(1, 0)),
            protocolID: nil,
            compoundID: nil,
            now: date(1, 0)
        )

        let store = TrackingStore(container: container)
        store.refresh(now: morning)
        let evening = try #require(
            store.entries(start: date(2, 0), end: date(3, 0))
                .first { utc.component(.hour, from: $0.at) == 20 }
        )

        var dose = DoseDraft(revision: evening.revision)
        dose.loggedAt = morning
        try repo.saveDose(dose, revision: evening.revision, occurrence: evening, correcting: nil, now: morning)

        // Rename creates a new schedule revision starting now.
        let record = try #require(repo.all(ProtocolRecord.self).first)
        let compound = try #require(repo.all(CompoundRecord.self).first)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        var edit = ProtocolDraft(protocolRecord: record, revision: revision)
        edit.name = "Renamed"
        try repo.saveProtocol(edit, protocolID: record.id, compoundID: compound.id, now: morning.addingTimeInterval(60))

        store.refresh(now: morning.addingTimeInterval(120))
        let eveningAfter = store.entries(start: date(2, 0), end: date(3, 0))
            .filter { utc.component(.hour, from: $0.at) == 20 }

        #expect(eveningAfter.count == 1)
        let entry = try #require(eveningAfter.first)
        #expect(entry.log != nil, "The 8 PM dose logged early must still show as recorded")

        #expect(throws: TrackingError.self) {
            try repo.saveDose(
                DoseDraft(revision: entry.revision),
                revision: entry.revision,
                occurrence: entry,
                correcting: nil,
                now: morning.addingTimeInterval(180)
            )
        }
        #expect(try repo.all(DoseLog.self).count == 1)
    }

    // MARK: - Idiot inputs

    @Test(arguments: ["", "   ", "abc", "0", "-1", "0.25.5", "1e9", "--2"])
    func garbageAmountsAreRejected(_ input: String) {
        #expect(throws: TrackingError.self) {
            _ = try DoseCalculator.parse(input, label: "Amount")
        }
    }

    @Test
    func paddedAmountIsAccepted() throws {
        #expect(try DoseCalculator.parse("  0.25  ", label: "Amount") == Decimal(string: "0.25"))
    }

    @Test
    func protocolWithUnitTheVialCannotMeasureIsRejected() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))

        var vialDraft = VialDraft()
        vialDraft.name = "Vial 01"
        vialDraft.compound = "Compound"
        vialDraft.amount = "5"
        vialDraft.unit = .mg
        try repo.saveVial(vialDraft, id: nil)
        let vial = try #require(repo.all(VialRecord.self).first)
        #expect(vial.concentration == nil)

        for unit in [AmountUnit.iu, .mL, .units] {
            var draft = dailyDraft(hours: [8], start: date(1, 0))
            draft.unit = unit
            draft.vialID = vial.id
            #expect(throws: TrackingError.self) {
                try repo.saveProtocol(draft, protocolID: nil, compoundID: nil, now: date(1, 0))
            }
        }
        #expect(try repo.all(ProtocolRecord.self).isEmpty)
    }

    @Test
    func vialNamesAreTrimmedSoPickersMatch() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var draft = VialDraft()
        draft.name = "  Vial 01 "
        draft.compound = "Compound  "
        draft.amount = "5"
        draft.unit = .mg
        try repo.saveVial(draft, id: nil)

        let vial = try #require(repo.all(VialRecord.self).first)
        #expect(vial.name == "Vial 01")
        #expect(vial.compoundName == "Compound")
    }

    @Test
    func emptyNamesAreRejectedAndLongNamesKept() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))

        #expect(throws: TrackingError.self) {
            try repo.saveProtocol(
                dailyDraft(name: "   ", hours: [8], start: date(1, 0)),
                protocolID: nil, compoundID: nil, now: date(1, 0)
            )
        }

        let long = String(repeating: "Semaglutide 💉 ", count: 35)
        try repo.saveProtocol(
            dailyDraft(name: long, hours: [8], start: date(1, 0)),
            protocolID: nil, compoundID: nil, now: date(1, 0)
        )
        #expect(try repo.all(ProtocolRecord.self).first?.name == long.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Notifications: follow-ups never crowd out dose reminders

    @Test
    func doseRemindersOutrankFollowUpsAtTheLimit() {
        let now = date(2, 0)
        var candidates: [ReminderPlanner.Candidate] = []
        for hour in 0..<50 {
            let at = now.addingTimeInterval(Double(hour + 1) * 3_600)
            candidates.append(.init(id: "dose-\(hour)", at: at))
            candidates.append(.init(id: "followup:dose-\(hour)", at: at.addingTimeInterval(60)))
        }
        candidates.append(.init(id: "weekly-recap:x", at: now.addingTimeInterval(1_800)))

        let selected = ReminderPlanner.select(candidates, now: now, otherPending: 0)

        #expect(selected.count == 60)
        #expect(selected.filter { $0.id.hasPrefix("dose-") }.count == 50)
        #expect(zip(selected, selected.dropFirst()).allSatisfy { $0.at <= $1.at })
    }

    // MARK: - Stress: a heavy user's year

    @Test
    func heavyUserYearStaysFastAndCorrect() throws {
        let container = try LocalPersistence.container(inMemory: true)
        let repo = TrackingRepository(container: container)
        let now = date(2, 12)
        let yearAgo = utc.date(byAdding: .day, value: -365, to: date(2, 0))!

        // 5 protocols × 3 entries a day for a year.
        for index in 0..<5 {
            try repo.saveProtocol(
                dailyDraft(name: "Protocol \(index)", compound: "Compound \(index)", hours: [8, 14, 20], start: yearAgo),
                protocolID: nil, compoundID: nil, now: yearAgo
            )
        }

        let store = TrackingStore(container: container)
        store.refresh(now: now)
        let past = store.entries(start: yearAgo, end: date(2, 0))
        #expect(past.count >= 5 * 3 * 364)

        // Log every past entry, skipping every tenth.
        try repo.transaction {
            for (offset, entry) in past.enumerated() {
                repo.context.insert(
                    DoseLog(
                        revision: entry.revision,
                        occurrenceID: entry.id,
                        scheduledAt: entry.at,
                        amount: 250,
                        unit: .mcg,
                        vial: nil,
                        scale: 100,
                        consumption: 0,
                        volume: nil,
                        status: offset % 10 == 0 ? "Skipped" : "Logged",
                        site: "",
                        symptoms: "",
                        severity: 0,
                        notes: "",
                        loggedAt: entry.at
                    )
                )
            }
        }

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            store.refresh(now: now)
            _ = store.entries(start: now, end: now.addingTimeInterval(90 * 86_400))
            let year = InsightsSummary(store: store, window: 365, now: now)
            #expect(year.scheduled >= 5 * 3 * 364)
            #expect(year.recorded > 0 && year.recorded < year.scheduled)
        }

        let matched = store.entries(start: yearAgo, end: date(2, 0)).filter { $0.log != nil }.count
        #expect(matched == past.count, "Every logged entry must match its log")

        print("Stress: \(past.count) logs, refresh + 90-day entries + 1-year insights took \(elapsed)")
        #expect(elapsed < .seconds(20))
    }
}

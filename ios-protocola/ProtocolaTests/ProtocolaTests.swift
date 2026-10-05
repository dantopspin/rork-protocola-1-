import Foundation
import SwiftData
import Testing
@testable import Protocola

struct CalculationTests {
    @Test func exactReconstitution() throws {
        let concentration = try DoseCalculator.concentration(vialAmount: 10, unit: .mg, diluentMl: 2)
        let volume = try DoseCalculator.volume(amount: 250, unit: .mcg, concentration: concentration, unitsPerMl: 100)
        #expect(concentration == 5)
        #expect(volume == Decimal(string: "0.05"))
        #expect(volume * 100 == 5)
    }
    @Test func unitConversionsDoNotTreatVolumeAsMass() throws {
        #expect(try DoseCalculator.massMg(1000, unit: .mcg) == 1)
        #expect(try DoseCalculator.massMg(5, unit: .units, concentration: 5, unitsPerMl: 50) == Decimal(string: "0.5"))
        #expect(throws: TrackingError.self) { try DoseCalculator.massMg(1, unit: .mL) }
    }
    @Test func decimalPrecisionAndInvalidInputs() throws {
        #expect(try DoseCalculator.parse("0.125", label: "Amount") * 8 == 1)
        for value in ["", "-1", "nan", "1.2.3", "0", "1e999"] {
            #expect(throws: TrackingError.self) { try DoseCalculator.parse(value, label: "Amount") }
        }
        #expect(throws: TrackingError.self) { try DoseCalculator.concentration(vialAmount: 10, unit: .mg, diluentMl: 0) }
    }
}

struct SchedulingTests {
    @Test func multipleDailyTimesAreDistinct() throws {
        let start = Date(timeIntervalSince1970: 1_735_689_600)
        let config = ScheduleConfig(kind: .daily, weekdays: [], interval: 1, minutes: [480, 1200], anchor: start, timeZoneID: "UTC")
        let dates = SchedulingEngine.occurrences(config: config, effectiveFrom: start, effectiveUntil: nil, start: start, end: start.addingTimeInterval(86400))
        #expect(dates.count == 2)
        #expect(dates[0] == start.addingTimeInterval(480 * 60))
        #expect(dates[1] == start.addingTimeInterval(1200 * 60))
    }
    @Test func futureOnlyRevisionBoundary() {
        let start = Date(timeIntervalSince1970: 1_735_689_600)
        let boundary = start.addingTimeInterval(12 * 3600)
        let config = ScheduleConfig(kind: .daily, weekdays: [], interval: 1, minutes: [480, 1200], anchor: start, timeZoneID: "UTC")
        let old = SchedulingEngine.occurrences(config: config, effectiveFrom: start, effectiveUntil: boundary, start: start, end: start.addingTimeInterval(86400))
        let new = SchedulingEngine.occurrences(config: config, effectiveFrom: boundary, effectiveUntil: nil, start: start, end: start.addingTimeInterval(86400))
        #expect(old.count == 1); #expect(new.count == 1); #expect(old[0] < boundary); #expect(new[0] >= boundary)
    }
    @Test func everyNDaysUsesCalendarAcrossDST() {
        let start = Date(timeIntervalSince1970: 1_741_420_800) // March 8, 2025, midnight in Los Angeles
        let config = ScheduleConfig(kind: .everyNDays, weekdays: [], interval: 2, minutes: [480], anchor: start, timeZoneID: "America/Los_Angeles")
        let dates = SchedulingEngine.occurrences(config: config, effectiveFrom: start, effectiveUntil: nil, start: start, end: start.addingTimeInterval(4 * 86400))
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        #expect(dates.count == 2)
        #expect(calendar.component(.hour, from: dates[0]) == 8)
        #expect(calendar.component(.hour, from: dates[1]) == 8)
    }
    @Test func weekdaysAndAsRecorded() {
        let start = Date(timeIntervalSince1970: 1_735_689_600)
        let config = ScheduleConfig(kind: .weekdays, weekdays: [2, 4, 6], interval: 1, minutes: [480], anchor: start, timeZoneID: "UTC")
        let dates = SchedulingEngine.occurrences(config: config, effectiveFrom: start, effectiveUntil: nil, start: start, end: start.addingTimeInterval(7 * 86400))
        #expect(dates.count == 3)
        var manual = config; manual.kind = .asRecorded
        #expect(SchedulingEngine.occurrences(config: manual, effectiveFrom: start, effectiveUntil: nil, start: start, end: start.addingTimeInterval(86400)).isEmpty)
    }
    @Test func missingExplicitDaysAndDuplicateTimesRejected() {
        let bad = ScheduleConfig(kind: .timesPerWeek, weekdays: [], interval: 1, minutes: [480, 480], anchor: .now, timeZoneID: "UTC")
        #expect(throws: TrackingError.self) { try bad.validate() }
    }
}

struct InventoryTests {
    @Test func correctionsAndDeletionReconcile() throws {
        let before = try InventoryEngine.balance(originalMg: 10, adjustmentsMg: [], consumptionsMg: [Decimal(string: "0.25")!])
        let corrected = try InventoryEngine.reconcile(currentMg: before, oldConsumptionMg: Decimal(string: "0.25")!, newConsumptionMg: Decimal(string: "0.5")!)
        #expect(before == Decimal(string: "9.75"))
        #expect(corrected == Decimal(string: "9.5"))
        #expect(try InventoryEngine.reconcile(currentMg: corrected, oldConsumptionMg: Decimal(string: "0.5")!, newConsumptionMg: 0) == 10)
    }
    @Test func overdrawDoesNotClampSilently() {
        #expect(throws: TrackingError.self) { try InventoryEngine.balance(originalMg: 1, adjustmentsMg: [], consumptionsMg: [2]) }
    }
    @Test func manualAdjustmentSurvivesLogDeletion() throws {
        #expect(try InventoryEngine.balance(originalMg: 10, adjustmentsMg: [-2], consumptionsMg: []) == 8)
    }
}

@MainActor struct PersistenceTests {
    @Test func snapshotsSurviveProtocolEditsAndInventoryCorrections() throws {
        let container = try LocalPersistence.container(inMemory: true)
        let repository = TrackingRepository(container: container)
        var vialDraft = VialDraft(); vialDraft.name = "Vial A"; vialDraft.compound = "Recorded compound"; vialDraft.amount = "10"; vialDraft.diluent = "2"
        try repository.saveVial(vialDraft, id: nil)
        let vial = try #require(repository.all(VialRecord.self).first)
        var protocolDraft = ProtocolDraft(); protocolDraft.name = "Original"; protocolDraft.compound = "Recorded compound"; protocolDraft.amount = "250"; protocolDraft.vialID = vial.id
        try repository.saveProtocol(protocolDraft, protocolID: nil, compoundID: nil)
        let revision = try #require(repository.all(ScheduleRevision.self).first)
        var draft = DoseDraft(revision: revision)
        try repository.saveDose(draft, revision: revision, occurrence: nil, correcting: nil)
        let log = try #require(repository.all(DoseLog.self).first)
        #expect(try repository.balance(vial) == Decimal(string: "9.75"))
        protocolDraft.name = "Edited"; protocolDraft.amount = "500"
        try repository.saveProtocol(protocolDraft, protocolID: revision.protocolID, compoundID: revision.compoundID)
        #expect(log.protocolName == "Original"); #expect(log.scheduledAmountText == "250"); #expect(log.concentrationText == "5")
        draft.amount = "500"
        try repository.saveDose(draft, revision: nil, occurrence: nil, correcting: log)
        #expect(try repository.balance(vial) == Decimal(string: "9.5"))
        let reopened = TrackingRepository(container: container)
        #expect(try reopened.all(DoseLog.self).count == 1)
        try repository.deleteDose(log)
        #expect(try repository.balance(vial) == 10)
        #expect(try repository.all(DoseLog.self).isEmpty)
    }
    @Test func rejectedEntryLeavesInventoryAndLogsUnchanged() throws {
        let repository = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var vialDraft = VialDraft(); vialDraft.name = "A"; vialDraft.compound = "C"; vialDraft.amount = "1"; vialDraft.diluent = "1"
        try repository.saveVial(vialDraft, id: nil)
        let vial = try #require(repository.all(VialRecord.self).first)
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "2"; p.unit = .mg; p.vialID = vial.id
        try repository.saveProtocol(p, protocolID: nil, compoundID: nil)
        let revision = try #require(repository.all(ScheduleRevision.self).first)
        let draft = DoseDraft(revision: revision)
        #expect(throws: TrackingError.self) { try repository.saveDose(draft, revision: revision, occurrence: nil, correcting: nil) }
        #expect(try repository.balance(vial) == 1)
        #expect(try repository.all(DoseLog.self).isEmpty)
    }
    @Test func duplicateOccurrenceIsRejected() throws {
        let repository = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var p = ProtocolDraft(); p.name = "P"; p.compound = "C"; p.amount = "1"; p.unit = .mg
        try repository.saveProtocol(p, protocolID: nil, compoundID: nil)
        let revision = try #require(repository.all(ScheduleRevision.self).first)
        let at = Date.now
        let entry = ScheduledEntry(id: SchedulingEngine.occurrenceKey(compoundID: revision.compoundID, revisionID: revision.id, at: at), revision: revision, at: at, log: nil)
        let draft = DoseDraft(revision: revision)
        try repository.saveDose(draft, revision: revision, occurrence: entry, correcting: nil)
        #expect(throws: TrackingError.self) { try repository.saveDose(draft, revision: revision, occurrence: entry, correcting: nil) }
        #expect(try repository.all(DoseLog.self).count == 1)
    }
}


@MainActor
struct PeptideProtocolMechanicsTests {

    @Test
    func onOffCycleSuppressesOffPeriodOccurrences() throws {
        let start =
            Date(
                timeIntervalSince1970:
                    1_735_689_600
            )

        let config =
            ScheduleConfig(
                kind: .daily,
                weekdays: [],
                interval: 1,
                minutes: [480],
                anchor: start,
                timeZoneID: "UTC",
                cycleOnDays: 2,
                cycleOffDays: 2
            )

        let dates =
            SchedulingEngine
                .occurrences(
                    config: config,
                    effectiveFrom: start,
                    effectiveUntil: nil,
                    start: start,
                    end:
                        start.addingTimeInterval(
                            6 * 86_400
                        )
                )

        #expect(dates.count == 4)
        #expect(
            dates[0]
                == start.addingTimeInterval(
                    480 * 60
                )
        )
        #expect(
            dates[1]
                == start.addingTimeInterval(
                    86_400
                    + 480 * 60
                )
        )
        #expect(
            dates[2]
                == start.addingTimeInterval(
                    4 * 86_400
                    + 480 * 60
                )
        )

        let offPhase =
            try #require(
                config.cyclePhase(
                    at:
                        start.addingTimeInterval(
                            2 * 86_400
                        )
                )
            )

        #expect(
            offPhase.state == .off
        )
        #expect(offPhase.day == 1)

        let onAgain =
            try #require(
                config.cyclePhase(
                    at:
                        start.addingTimeInterval(
                            4 * 86_400
                        )
                )
            )

        #expect(
            onAgain.state == .on
        )
        #expect(onAgain.day == 1)
    }


    @Test
    func asNeededCreatesNoAutomaticOccurrences() throws {
        let start =
            Date(
                timeIntervalSince1970:
                    1_735_689_600
            )

        let config =
            ScheduleConfig(
                kind: .asRecorded,
                weekdays: [],
                interval: 1,
                minutes: [],
                anchor: start,
                timeZoneID: "UTC"
            )

        try config.validate()

        #expect(
            ScheduleDisplay.summary(
                config
            ) == "As needed"
        )

        #expect(
            SchedulingEngine
                .occurrences(
                    config: config,
                    effectiveFrom: start,
                    effectiveUntil: nil,
                    start: start,
                    end:
                        start.addingTimeInterval(
                            7 * 86_400
                        )
                )
                .isEmpty
        )
    }


    @Test
    func nonInjectionRouteIsSnapshottedAndDoesNotConsumeVial() throws {
        let repository =
            TrackingRepository(
                container:
                    try LocalPersistence
                        .container(
                            inMemory: true
                        )
            )

        var vialDraft =
            VialDraft()

        vialDraft.name = "Vial A"
        vialDraft.compound = "C"
        vialDraft.amount = "10"
        vialDraft.diluent = "2"

        try repository.saveVial(
            vialDraft,
            id: nil
        )

        let vial =
            try #require(
                repository
                    .all(
                        VialRecord.self
                    )
                    .first
            )

        var protocolDraft =
            ProtocolDraft()

        protocolDraft.name = "Oral"
        protocolDraft.compound = "C"
        protocolDraft.amount = "1"
        protocolDraft.unit = .mg
        protocolDraft.route = .oral
        protocolDraft.vialID = vial.id

        try repository.saveProtocol(
            protocolDraft,
            protocolID: nil,
            compoundID: nil
        )

        let revision =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first
            )

        #expect(
            revision.route == .oral
        )
        #expect(revision.vialID == nil)

        var dose =
            DoseDraft(
                revision: revision
            )

        dose.site = "Left abdomen"
        dose.vialID = vial.id

        try repository.saveDose(
            dose,
            revision: revision,
            occurrence: nil,
            correcting: nil
        )

        let log =
            try #require(
                repository
                    .all(
                        DoseLog.self
                    )
                    .first
            )

        #expect(log.route == .oral)
        #expect(log.vialID == nil)
        #expect(log.site.isEmpty)
        #expect(
            try repository.balance(vial)
                == 10
        )
    }


    @Test
    func skippedScheduledEntryConsumesZeroInventoryAndCanBeUndone() throws {
        let repository =
            TrackingRepository(
                container:
                    try LocalPersistence
                        .container(
                            inMemory: true
                        )
            )

        var vialDraft =
            VialDraft()

        vialDraft.name = "V"
        vialDraft.compound = "C"
        vialDraft.amount = "10"
        vialDraft.diluent = "2"

        try repository.saveVial(
            vialDraft,
            id: nil
        )

        let vial =
            try #require(
                repository
                    .all(
                        VialRecord.self
                    )
                    .first
            )

        var protocolDraft =
            ProtocolDraft()

        protocolDraft.name = "P"
        protocolDraft.compound = "C"
        protocolDraft.amount = "1"
        protocolDraft.unit = .mg
        protocolDraft.vialID = vial.id

        try repository.saveProtocol(
            protocolDraft,
            protocolID: nil,
            compoundID: nil
        )

        let revision =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first
            )

        let at = Date.now

        let entry =
            ScheduledEntry(
                id:
                    SchedulingEngine
                        .occurrenceKey(
                            compoundID:
                                revision
                                    .compoundID,
                            revisionID:
                                revision.id,
                            at: at
                        ),
                revision: revision,
                at: at,
                log: nil
            )

        var draft =
            DoseDraft(
                revision: revision
            )

        draft.status = "Skipped"

        try repository.saveDose(
            draft,
            revision: revision,
            occurrence: entry,
            correcting: nil
        )

        let log =
            try #require(
                repository
                    .all(
                        DoseLog.self
                    )
                    .first
            )

        #expect(
            log.status == "Skipped"
        )
        #expect(log.consumptionMg == 0)
        #expect(
            try repository.balance(vial)
                == 10
        )

        try repository.deleteDose(log)

        #expect(
            try repository.balance(vial)
                == 10
        )
    }
}



struct InjectionSiteTests {

    @Test
    func canonicalSiteMatchingNormalizesCaseWhitespaceAndHyphens() {
        #expect(
            InjectionSite.match(
                "  LEFT   ABDOMEN "
            ) == .leftAbdomen
        )
        #expect(
            InjectionSite.match(
                "right-upper-arm"
            ) == .rightUpperArm
        )
        #expect(
            InjectionSite.match(
                "custom location"
            ) == nil
        )
    }


    @MainActor
    @Test
    func recentUsesAreCrossProtocolMostRecentAndIgnoreSkippedEntries() throws {
        let repository =
            TrackingRepository(
                container:
                    try LocalPersistence
                        .container(
                            inMemory: true
                        )
            )

        var first =
            ProtocolDraft()
        first.name = "Protocol A"
        first.compound = "Compound A"
        first.amount = "1"
        first.unit = .mg

        try repository.saveProtocol(
            first,
            protocolID: nil,
            compoundID: nil
        )

        var second =
            ProtocolDraft()
        second.name = "Protocol B"
        second.compound = "Compound B"
        second.amount = "1"
        second.unit = .mg

        try repository.saveProtocol(
            second,
            protocolID: nil,
            compoundID: nil
        )

        let revisions =
            try repository
                .all(
                    ScheduleRevision.self
                )

        let revisionA =
            try #require(
                revisions.first {
                    $0.protocolName
                        == "Protocol A"
                }
            )

        let revisionB =
            try #require(
                revisions.first {
                    $0.protocolName
                        == "Protocol B"
                }
            )

        let now = Date.now

        var older =
            DoseDraft(
                revision: revisionA
            )
        older.site =
            InjectionSite
                .leftAbdomen
                .rawValue
        older.loggedAt =
            now.addingTimeInterval(
                -86_400
            )

        try repository.saveDose(
            older,
            revision: revisionA,
            occurrence: nil,
            correcting: nil,
            now: now
        )

        var newer =
            DoseDraft(
                revision: revisionB
            )
        newer.site =
            InjectionSite
                .leftAbdomen
                .rawValue
        newer.loggedAt =
            now.addingTimeInterval(
                -3_600
            )

        try repository.saveDose(
            newer,
            revision: revisionB,
            occurrence: nil,
            correcting: nil,
            now: now
        )

        var skipped =
            DoseDraft(
                revision: revisionA
            )
        skipped.site =
            InjectionSite
                .rightThigh
                .rawValue
        skipped.status = "Skipped"
        skipped.loggedAt = now

        try repository.saveDose(
            skipped,
            revision: revisionA,
            occurrence: nil,
            correcting: nil,
            now: now
        )

        let uses =
            InjectionSite.recentUses(
                from:
                    try repository
                        .all(
                            DoseLog.self
                        )
            )

        #expect(uses.count == 1)
        #expect(
            uses.first?.site
                == .leftAbdomen
        )
        #expect(
            uses.first?
                .protocolName
                == "Protocol B"
        )
    }
}



@MainActor
struct VialIntelligenceTests {

    @Test
    func lifecycleDatesPhotoAndRunwayPersist() throws {
        let container =
            try LocalPersistence
                .container(
                    inMemory: true
                )
        let repository =
            TrackingRepository(
                container: container
            )
        let now =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        var vialDraft = VialDraft()
        vialDraft.name = "Reserve vial"
        vialDraft.compound = "Compound"
        vialDraft.amount = "10"
        vialDraft.diluent = "2"
        vialDraft.state = .reserve
        vialDraft.hasReconstitutedDate = true
        vialDraft.reconstitutedAt =
            now.addingTimeInterval(
                -86_400
            )
        vialDraft.hasOpenedDate = true
        vialDraft.openedAt =
            now.addingTimeInterval(
                -43_200
            )
        vialDraft.photoData =
            Data([1, 2, 3])

        try repository.saveVial(
            vialDraft,
            id: nil,
            now: now
        )

        let vial =
            try #require(
                repository
                    .all(
                        VialRecord.self
                    )
                    .first
            )

        #expect(
            vial.lifecycleState == .reserve
        )
        #expect(vial.reconstitutedAt != nil)
        #expect(vial.openedAt != nil)
        #expect(
            vial.photoData == Data([1, 2, 3])
        )

        var protocolDraft =
            ProtocolDraft()
        protocolDraft.name = "Protocol"
        protocolDraft.compound = "Compound"
        protocolDraft.amount = "2"
        protocolDraft.unit = .mg
        protocolDraft.vialID = vial.id
        protocolDraft.start = now
        protocolDraft.kind = .daily
        protocolDraft.timeZoneID = "UTC"

        try repository.saveProtocol(
            protocolDraft,
            protocolID: nil,
            compoundID: nil,
            now: now
        )

        let store =
            TrackingStore(
                container: container
            )

        #expect(
            store.dosesPerVial(
                vial,
                at: now
            ) == 5
        )
        #expect(
            store
                .scheduledEntriesRemaining(
                    in: vial,
                    at: now
                ) == 5
        )
        #expect(
            store
                .estimatedDepletionDate(
                    in: vial,
                    now: now
                ) != nil
        )
    }

    @Test
    func futureLifecycleDatesAreRejected() throws {
        let repository =
            TrackingRepository(
                container:
                    try LocalPersistence
                        .container(
                            inMemory: true
                        )
            )
        let now = Date.now
        var draft = VialDraft()
        draft.name = "V"
        draft.compound = "C"
        draft.amount = "5"
        draft.diluent = "1"
        draft.hasOpenedDate = true
        draft.openedAt =
            now.addingTimeInterval(
                3_600
            )

        #expect(
            throws: TrackingError.self
        ) {
            try repository.saveVial(
                draft,
                id: nil,
                now: now
            )
        }
    }
}



struct SyringePresetTests {

    @Test
    func standardSyringeScalesMatchRecordedValues() {
        #expect(
            SyringeScalePreset
                .match("40")
                == .u40
        )
        #expect(
            SyringeScalePreset
                .match("100.0")
                == .u100
        )
        #expect(
            SyringeScalePreset
                .match("50")
                == nil
        )
    }
}



struct CycleRestartReminderTests {

    @Test
    func nextRestartUsesCurrentCyclePhase() throws {
        let start =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )
        let config =
            ScheduleConfig(
                kind: .daily,
                weekdays: [],
                interval: 1,
                minutes: [480],
                anchor: start,
                timeZoneID: "UTC",
                cycleOnDays: 2,
                cycleOffDays: 2
            )

        let duringOn =
            Calendar(
                identifier: .gregorian
            )
            .date(
                byAdding: .day,
                value: 1,
                to: start
            )!

        let duringOff =
            Calendar(
                identifier: .gregorian
            )
            .date(
                byAdding: .day,
                value: 2,
                to: start
            )!

        let onRestart =
            try #require(
                CycleDisplay
                    .nextRestart(
                        config,
                        after: duringOn
                    )
            )
        let offRestart =
            try #require(
                CycleDisplay
                    .nextRestart(
                        config,
                        after: duringOff
                    )
            )

        #expect(onRestart == offRestart)
        #expect(onRestart > duringOff)
    }

    @Test
    func reminderPlannerPreservesCycleRestartCopy() {
        let now = Date.now
        let restart =
            ReminderPlanner.Candidate(
                id: "cycle-restart:test",
                at:
                    now.addingTimeInterval(
                        3_600
                    ),
                title:
                    "Protocola · cycle restart",
                body:
                    "A recorded cycle is scheduled to resume."
            )

        let selected =
            ReminderPlanner.select(
                [restart],
                now: now,
                otherPending: 0
            )

        #expect(
            selected.first?.title
                == "Protocola · cycle restart"
        )
        #expect(
            selected.first?.body
                .contains(
                    "scheduled to resume"
                ) == true
        )
    }
}



@MainActor
struct PlannedRevisionTests {

    @Test
    func futureRevisionDoesNotReplaceCurrentUntilEffectiveDate() throws {
        let container =
            try LocalPersistence
                .container(
                    inMemory: true
                )
        let repository =
            TrackingRepository(
                container: container
            )

        let now =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        var draft = ProtocolDraft()
        draft.name = "Plan"
        draft.compound = "Compound"
        draft.amount = "1"
        draft.unit = .mg
        draft.start = now
        draft.kind = .daily
        draft.timeZoneID = "UTC"

        try repository.saveProtocol(
            draft,
            protocolID: nil,
            compoundID: nil,
            now: now
        )

        let record =
            try #require(
                repository
                    .all(
                        ProtocolRecord.self
                    )
                    .first
            )
        let compound =
            try #require(
                repository
                    .all(
                        CompoundRecord.self
                    )
                    .first
            )
        let current =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first
            )

        let futureDate =
            now.addingTimeInterval(
                7 * 86_400
            )

        var futureDraft =
            ProtocolDraft(
                protocolRecord: record,
                revision: current
            )
        futureDraft.amount = "2"

        try repository
            .savePlannedProtocolChange(
                futureDraft,
                protocolID: record.id,
                compoundID: compound.id,
                plannedRevisionID: nil,
                effectiveFrom:
                    futureDate,
                now: now
            )

        let store =
            TrackingStore(
                container: container
            )

        #expect(
            store.currentRevisions(
                record.id,
                at: now
            )
            .first?
            .amount == 1
        )

        let planned =
            store.plannedRevisions(
                record.id,
                after: now
            )

        #expect(planned.count == 1)
        #expect(
            planned.first?.amount == 2
        )

        let shortlyAfter =
            futureDate
                .addingTimeInterval(
                    60
                )

        #expect(
            store.currentRevisions(
                record.id,
                at: shortlyAfter
            )
            .first?
            .amount == 2
        )

        #expect(
            current.effectiveUntil
                == futureDate
        )
    }


    @Test
    func plannedRevisionCanBeUpdatedAndCancelledWithoutChangingHistory() throws {
        let container =
            try LocalPersistence
                .container(
                    inMemory: true
                )
        let repository =
            TrackingRepository(
                container: container
            )
        let now =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        var draft = ProtocolDraft()
        draft.name = "Plan"
        draft.compound = "Compound"
        draft.amount = "1"
        draft.unit = .mg
        draft.start = now
        draft.kind = .daily
        draft.timeZoneID = "UTC"

        try repository.saveProtocol(
            draft,
            protocolID: nil,
            compoundID: nil,
            now: now
        )

        let record =
            try #require(
                repository
                    .all(
                        ProtocolRecord.self
                    )
                    .first
            )
        let compound =
            try #require(
                repository
                    .all(
                        CompoundRecord.self
                    )
                    .first
            )
        let current =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first
            )
        let futureDate =
            now.addingTimeInterval(
                5 * 86_400
            )

        var futureDraft =
            ProtocolDraft(
                protocolRecord: record,
                revision: current
            )
        futureDraft.amount = "2"

        try repository
            .savePlannedProtocolChange(
                futureDraft,
                protocolID: record.id,
                compoundID: compound.id,
                plannedRevisionID: nil,
                effectiveFrom:
                    futureDate,
                now: now
            )

        var planned =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first {
                        $0.effectiveFrom
                            == futureDate
                    }
            )

        futureDraft.amount = "3"

        try repository
            .savePlannedProtocolChange(
                futureDraft,
                protocolID: record.id,
                compoundID: compound.id,
                plannedRevisionID:
                    planned.id,
                effectiveFrom:
                    futureDate,
                now: now
            )

        planned =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first {
                        $0.id == planned.id
                    }
            )

        #expect(planned.amount == 3)
        #expect(current.amount == 1)

        try repository
            .cancelPlannedRevision(
                planned.id,
                now: now
            )

        let remaining =
            try repository
                .all(
                    ScheduleRevision.self
                )

        #expect(remaining.count == 1)
        #expect(
            remaining.first?
                .effectiveUntil == nil
        )
        #expect(
            remaining.first?.amount == 1
        )
    }
}



@MainActor
struct ProtocolEvolutionTests {

    @Test
    func plannedAuditEventsAreNotEffectiveChangeAnchors() throws {
        let event =
            ProtocolEvent(
                protocolID: UUID(),
                title:
                    "Future change planned",
                detail: ""
            )

        try event.recordChanges(
            [
                RecordChange(
                    field: "Amount",
                    before: "1",
                    after: "2"
                )
            ],
            category: "Protocol"
        )

        #expect(
            !event.isChangeAnchor
        )
    }


    @Test
    func evolutionBuildsChangeComparisonAndCycleHistory() throws {
        let container =
            try LocalPersistence
                .container(
                    inMemory: true
                )
        let repository =
            TrackingRepository(
                container: container
            )

        let now = Date.now
        let start =
            now.addingTimeInterval(
                -12 * 86_400
            )
        let changeDate =
            now.addingTimeInterval(
                -4 * 86_400
            )

        var draft = ProtocolDraft()
        draft.name = "Evolution"
        draft.compound = "Compound"
        draft.amount = "1"
        draft.unit = .mg
        draft.start = start
        draft.kind = .daily
        draft.timeZoneID = "UTC"
        draft.cycleEnabled = true
        draft.cycleOnDays = 2
        draft.cycleOffDays = 2

        try repository.saveProtocol(
            draft,
            protocolID: nil,
            compoundID: nil,
            now: start
        )

        let record =
            try #require(
                repository
                    .all(
                        ProtocolRecord.self
                    )
                    .first
            )
        let firstRevision =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first
            )

        var edited =
            ProtocolDraft(
                protocolRecord: record,
                revision: firstRevision
            )
        edited.amount = "2"

        try repository.saveProtocol(
            edited,
            protocolID: record.id,
            compoundID:
                firstRevision
                    .compoundID,
            now: changeDate
        )

        let store =
            TrackingStore(
                container: container
            )
        let summary =
            ProtocolEvolutionSummary(
                store: store,
                protocolID: record.id,
                now: now
            )

        #expect(
            summary.latestChange
                != nil
        )
        #expect(
            summary.sinceLastChange
                != nil
        )
        #expect(
            summary.comparison
                != nil
        )
        #expect(
            !summary.cycleRuns
                .isEmpty
        )
    }
}



struct EstimatedLevelEngineTests {

    @Test
    func oneHalfLifeLeavesHalfTheRecordedMass() {
        let start =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )
        let dose =
            EstimatedLevelEngine
                .DoseInput(
                    at: start,
                    massMg: 2
                )

        let value =
            EstimatedLevelEngine
                .estimatedRemaining(
                    at:
                        start
                            .addingTimeInterval(
                                24 * 3_600
                            ),
                    doses: [dose],
                    halfLifeHours: 24
                )

        #expect(
            abs(value - 1)
                < 0.000_001
        )
    }


    @Test
    func repeatedRecordedDosesAccumulateDeterministically() {
        let start =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )
        let second =
            start.addingTimeInterval(
                24 * 3_600
            )

        let value =
            EstimatedLevelEngine
                .estimatedRemaining(
                    at: second,
                    doses: [
                        .init(
                            at: start,
                            massMg: 1
                        ),
                        .init(
                            at: second,
                            massMg: 1
                        )
                    ],
                    halfLifeHours: 24
                )

        #expect(
            abs(value - 1.5)
                < 0.000_001
        )
    }
}


@MainActor
struct EstimatedLevelOverviewTests {

    @Test
    func overviewUsesActualRecordedDoseAndUserReference() throws {
        let container =
            try LocalPersistence
                .container(
                    inMemory: true
                )
        let repository =
            TrackingRepository(
                container: container
            )
        let now = Date.now

        var protocolDraft =
            ProtocolDraft()
        protocolDraft.name = "Levels"
        protocolDraft.compound =
            "Compound"
        protocolDraft.amount = "2"
        protocolDraft.unit = .mg
        protocolDraft.start =
            now.addingTimeInterval(
                -2 * 86_400
            )
        protocolDraft.kind = .daily

        try repository.saveProtocol(
            protocolDraft,
            protocolID: nil,
            compoundID: nil,
            now:
                protocolDraft.start
        )

        let compound =
            try #require(
                repository
                    .all(
                        CompoundRecord.self
                    )
                    .first
            )
        let revision =
            try #require(
                repository
                    .all(
                        ScheduleRevision.self
                    )
                    .first
            )

        try repository
            .saveCompoundHalfLife(
                compoundID:
                    compound.id,
                hoursText: "24",
                source:
                    "Recorded reference"
            )

        var dose =
            DoseDraft(
                revision: revision
            )
        dose.amount = "2"
        dose.unit = .mg
        dose.loggedAt =
            now.addingTimeInterval(
                -24 * 3_600
            )

        try repository.saveDose(
            dose,
            revision: revision,
            occurrence: nil,
            correcting: nil,
            now: now
        )

        let store =
            TrackingStore(
                container: container
            )
        let overview =
            EstimatedLevelOverview(
                store: store,
                protocolID:
                    revision.protocolID,
                period:
                    AnalysisPeriod(
                        start:
                            now.addingTimeInterval(
                                -48
                                * 3_600
                            ),
                        end: now
                    ),
                now: now
            )

        let series =
            try #require(
                overview.series.first
            )

        #expect(
            series.compoundName
                == "Compound"
        )
        #expect(
            abs(
                series
                    .currentEstimatedMg
                - 1
            ) < 0.000_001
        )
        #expect(
            series.source
                == "Recorded reference"
        )
    }
}


struct ReverseDilutionTests {
    @Test func reverseMatchesForwardRoundTrip() throws {
        // 5 mg vial; a 0.25 mg dose drawn as 10 units on a 100 scale
        // solves to 2 mL of diluent at 2.5 mg/mL.
        let target = try DoseCalculator.diluentForTarget(
            vialAmount: 5,
            vialUnit: .mg,
            dose: Decimal(string: "0.25")!,
            doseUnit: .mg,
            drawUnits: 10,
            scale: 100
        )

        #expect(target.diluentMl == 2)
        #expect(target.concentration == Decimal(string: "2.5")!)

        // Round trip: the forward conversion at the solved concentration
        // must reproduce the requested draw.
        let volume = try DoseCalculator.volume(
            amount: Decimal(string: "0.25")!,
            unit: .mg,
            concentration: target.concentration,
            unitsPerMl: 100
        )

        #expect(volume * 100 == 10)
    }

    @Test func reverseConvertsUnitsExplicitly() throws {
        // 500 mcg vial; 250 mcg dose drawn as 5 units on a 100 scale:
        // draw volume 0.05 mL, concentration 5 mg/mL, diluent 0.1 mL.
        let target = try DoseCalculator.diluentForTarget(
            vialAmount: 500,
            vialUnit: .mcg,
            dose: 250,
            doseUnit: .mcg,
            drawUnits: 5,
            scale: 100
        )

        #expect(target.diluentMl == Decimal(string: "0.1")!)
        #expect(target.concentration == 5)
    }

    @Test func reverseRejectsInvalidInputs() {
        #expect(throws: TrackingError.self) {
            try DoseCalculator.diluentForTarget(vialAmount: 5, vialUnit: .mg, dose: 0, doseUnit: .mg, drawUnits: 10, scale: 100)
        }
        #expect(throws: TrackingError.self) {
            try DoseCalculator.diluentForTarget(vialAmount: 5, vialUnit: .mg, dose: 1, doseUnit: .mg, drawUnits: 0, scale: 100)
        }
        #expect(throws: TrackingError.self) {
            try DoseCalculator.diluentForTarget(vialAmount: 5, vialUnit: .mg, dose: 1, doseUnit: .mg, drawUnits: 10, scale: 0)
        }
    }
}


@MainActor
struct VialAlertTests {
    @Test func inventoryWarningsAreFutureDatedAndReachPlanner() {
        let vial = VialRecord(
            name: "Test vial",
            compoundName: "Compound",
            originalMg: 10,
            diluentMl: 2
        )
        let now =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        let nearDepletion =
            now.addingTimeInterval(
                3 * 86_400
            )

        let warnings =
            VialAlerts.candidates(
                vial: vial,
                status:
                    "Low recorded balance",
                projectedDepletion:
                    nearDepletion,
                now: now
            )

        #expect(
            warnings.contains {
                $0.id.hasPrefix(
                    "vial-depletion:"
                )
            }
        )
        #expect(
            warnings.contains {
                $0.id
                    == "vial-low:"
                    + vial.id.uuidString
            }
        )
        #expect(
            warnings.allSatisfy {
                $0.at > now
            }
        )

        let selected =
            ReminderPlanner.select(
                warnings,
                now: now,
                otherPending: 0
            )

        #expect(
            selected.count
                == warnings.count
        )

        let farTarget =
            now.addingTimeInterval(
                30 * 86_400
            )
        let farWarnings =
            VialAlerts.candidates(
                vial: vial,
                status: "Active",
                projectedDepletion:
                    farTarget,
                now: now
            )

        #expect(
            farWarnings.count == 1
        )
        #expect(
            farWarnings.first?.at
                > now
        )
        #expect(
            ReminderPlanner.select(
                farWarnings,
                now: now,
                otherPending: 0
            ).count == 1
        )
    }

    @Test func expiryAlertUsesOnlyRecordedDateAndSkipsArchived() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        let expiring = VialRecord(
            name: "Expiring vial",
            compoundName: "Compound",
            originalMg: 10,
            diluentMl: 2,
            expiry: now.addingTimeInterval(5 * 86_400)
        )

        let expiry = VialAlerts.candidate(
            vial: expiring,
            status: "Active",
            projectedDepletion: nil,
            now: now
        )
        #expect(expiry?.id.hasPrefix("vial-expiry:") == true)
        #expect(expiry?.at > now)

        let selected =
            ReminderPlanner.select(
                [expiry].compactMap {
                    $0
                },
                now: now,
                otherPending: 0
            )

        #expect(selected.count == 1)

        let archived = VialRecord(
            name: "Archived vial",
            compoundName: "Compound",
            originalMg: 10,
            diluentMl: 2,
            expiry: now.addingTimeInterval(5 * 86_400)
        )
        archived.lifecycleState = .archived

        #expect(
            VialAlerts.candidate(
                vial: archived,
                status: "Low recorded balance",
                projectedDepletion: now,
                now: now
            ) == nil
        )
    }
}

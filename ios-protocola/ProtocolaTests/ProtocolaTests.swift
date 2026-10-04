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

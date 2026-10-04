import Foundation
import Testing
import SwiftData
import PDFKit
@testable import Protocola

@MainActor struct ChangeIntelligenceTests {
    @Test func preservesPreviousValuesAndPastSchedules() throws {
        let store = TrackingStore(container: try LocalPersistence.container(inMemory: true))
        let start = Calendar.current.startOfDay(for: .now)
        let change = start.addingTimeInterval(12 * 3600)
        var draft = ProtocolDraft(); draft.name = "P"; draft.compound = "C"; draft.amount = "250"; draft.start = start
        draft.times = [RecordedTime(date: start.addingTimeInterval(8 * 3600)), RecordedTime(date: start.addingTimeInterval(20 * 3600))]
        try store.repository.saveProtocol(draft, protocolID: nil, compoundID: nil, now: start)
        store.refresh(now: change)
        let old = try #require(store.revisions.first)
        let past = store.entries(start: start, end: change).map(\.id)
        draft.amount = "500"; draft.notes = "New notes"
        try store.repository.saveProtocol(draft, protocolID: old.protocolID, compoundID: old.compoundID, now: change)
        store.refresh(now: change)
        #expect(old.amountText == "250")
        #expect(old.effectiveUntil == change)
        #expect(store.entries(start: start, end: change).map(\.id) == past)
        #expect(store.entries(start: change, end: start.addingTimeInterval(86400)).allSatisfy { $0.revision.amountText == "500" })
        let event = try #require(store.events.first { $0.title == "Protocol changed" })
        #expect(event.changes.contains(RecordChange(field: "Amount", before: "250", after: "500")))
        #expect(event.changes.contains(RecordChange(field: "Notes", before: "", after: "New notes")))
        #expect(event.at == change)
    }
    @Test func renameAppliesToAllFutureCompoundsWithoutRewritingPastNames() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        let beginning = Date.now.addingTimeInterval(-86400)
        var draft = ProtocolDraft(); draft.name = "Before"; draft.compound = "A"; draft.amount = "1"; draft.start = beginning
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil, now: beginning)
        let first = try #require(repo.all(ScheduleRevision.self).first)
        draft.compound = "B"
        try repo.saveProtocol(draft, protocolID: first.protocolID, compoundID: nil, now: beginning.addingTimeInterval(3600))
        let second = try #require(repo.all(ScheduleRevision.self).first { $0.compoundName == "B" })
        draft.name = "After"
        try repo.saveProtocol(draft, protocolID: first.protocolID, compoundID: second.compoundID, now: .now)
        let current = try repo.all(ScheduleRevision.self).filter { $0.effectiveUntil == nil }
        #expect(current.count == 2)
        #expect(current.allSatisfy { $0.protocolName == "After" })
        #expect(first.protocolName == "Before" && second.protocolName == "Before")
    }
    @Test func unchangedSaveDoesNotCreateRevisionOrEvent() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var draft = ProtocolDraft(); draft.name = "P"; draft.compound = "C"; draft.amount = "1"
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil)
        let record = try #require(repo.all(ProtocolRecord.self).first)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        let edit = ProtocolDraft(protocolRecord: record, revision: revision)
        let count = try repo.all(ProtocolEvent.self).count
        try repo.saveProtocol(edit, protocolID: record.id, compoundID: revision.compoundID)
        #expect(try repo.all(ProtocolEvent.self).count == count)
        #expect(try repo.all(ScheduleRevision.self).count == 1)
    }
    @Test func metadataIsAuditedWithoutClutteringTimeline() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var draft = ProtocolDraft(); draft.name = "P"; draft.compound = "C"; draft.amount = "1"
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        draft.notes = "Private note"
        try repo.saveProtocol(draft, protocolID: revision.protocolID, compoundID: revision.compoundID)
        let events = try repo.all(ProtocolEvent.self)
        let metadata = try #require(events.first { $0.category == "Metadata" })
        #expect(!metadata.isChangeAnchor)
        #expect(!TimelineRecord.build(logs: [], events: events).contains { $0.id == metadata.id })
        #expect(TimelineRecord.build(logs: [], events: events, includeMetadata: true).contains { $0.id == metadata.id })
        #expect(try repo.all(ScheduleRevision.self).count == 1)
    }
    @Test func siteChangesAreSeparateFromProtocolAnchors() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var draft = ProtocolDraft(); draft.name = "P"; draft.compound = "C"; draft.amount = "1"
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        draft.site = "Recorded site"
        try repo.saveProtocol(draft, protocolID: revision.protocolID, compoundID: revision.compoundID)
        let event = try #require(repo.all(ProtocolEvent.self).first { $0.category == "Site" })
        #expect(!event.isChangeAnchor)
        #expect(event.changes.first?.after == "Recorded site")
    }
    @Test func comparisonAssignsBoundaryExactlyOnceAndCapsEqualDurations() {
        let change = Date(timeIntervalSince1970: 10000000)
        let periods = AnalysisPeriod.comparison(change: change, now: change.addingTimeInterval(40 * 86400))
        #expect(!periods.before.contains(change))
        #expect(periods.after.contains(change))
        #expect(periods.before.end.timeIntervalSince(periods.before.start) == 30 * 86400)
        #expect(periods.after.end.timeIntervalSince(periods.after.start) == 30 * 86400)
        #expect(!periods.after.contains(periods.after.end))
        let future = AnalysisPeriod.comparison(change: change, now: change.addingTimeInterval(-1))
        #expect(future.after.start == future.after.end)
    }
    @Test func freeGatingAndDowngradePreserveRecords() throws {
        let store = TrackingStore(container: try LocalPersistence.container(inMemory: true))
        var draft = ProtocolDraft(); draft.name = "First"; draft.compound = "C"; draft.amount = "1"
        #expect(store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        let first = try #require(store.protocols.first)
        #expect(store.pendingPaywall == nil)
        let firstRevision = try #require(store.revisions.first)
        #expect(store.saveDose(DoseDraft(revision: firstRevision), revision: firstRevision, occurrence: nil, correcting: nil))
        #expect(!store.pendingPaywall)
        draft.name = "Second"
        #expect(!store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        #expect(store.pendingPaywall == .secondProtocol)
        store.dismissPaywall()
        store.receiveEntitlements(["pro"])
        #expect(store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        let second = try #require(store.protocols.first { $0.id != first.id })
        let revisionCount = store.revisions.count
        store.receiveEntitlements([])
        #expect(store.needsProtocolChoice)
        #expect(!store.canTrack(first.id) && !store.canTrack(second.id))
        store.chooseFreeProtocol(first.id)
        #expect(store.canTrack(first.id))
        #expect(!store.canEdit(second.id))
        #expect(store.protocols.allSatisfy { $0.status == "Active" })
        #expect(store.revisions.count == revisionCount)
        #expect(store.logs.count == 1)
        let secondRevision = try #require(store.currentRevisions(second.id).first)
        #expect(!store.saveDose(DoseDraft(revision: secondRevision), revision: secondRevision, occurrence: nil, correcting: nil))
        store.chooseFreeProtocol(second.id)
        #expect(!store.canTrack(first.id) && store.canTrack(second.id))
        store.receiveEntitlements(["pro"])
        #expect(store.canTrack(first.id) && store.canTrack(second.id))
        #expect(store.logs.count == 1)
    }
    @Test func selectedFreeProtocolPersistsWithoutStatusChanges() throws {
        let container = try LocalPersistence.container(inMemory: true)
        let store = TrackingStore(container: container)
        store.receiveEntitlements(["pro"])
        var draft = ProtocolDraft(); draft.compound = "C"; draft.amount = "1"; draft.name = "One"
        #expect(store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        draft.name = "Two"
        #expect(store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        let selected = try #require(store.protocols.first)
        store.receiveEntitlements([]); store.chooseFreeProtocol(selected.id)
        let reopened = TrackingStore(container: container)
        #expect(reopened.allowedProtocolIDs == [selected.id])
        #expect(reopened.protocols.allSatisfy { $0.status == "Active" })
    }
    @Test func resumeSecondProtocolIsGatedButPausedRecordsDoNotCount() throws {
        let store = TrackingStore(container: try LocalPersistence.container(inMemory: true))
        var draft = ProtocolDraft(); draft.name = "One"; draft.compound = "C"; draft.amount = "1"
        #expect(store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        let first = try #require(store.protocols.first)
        store.changeStatus(first, status: "Paused")
        #expect(store.canCreateProtocol)
        draft.name = "Two"
        #expect(store.saveProtocol(draft, protocolID: nil, compoundID: nil))
        store.changeStatus(first, status: "Active")
        #expect(first.status == "Paused")
        #expect(store.pendingPaywall)
    }
    @Test func entitlementAccessUsesOnlyProAndRetainsVerifiedAccessOnFailure() {
        var access = EntitlementAccess()
        access.receive(activeEntitlements: ["premium"])
        #expect(!access.isPro)
        access.receive(activeEntitlements: ["pro"])
        #expect(access.isPro)
        access.receive(activeEntitlements: nil)
        #expect(access.isPro)
        access.receive(activeEntitlements: [])
        #expect(!access.isPro)
        access.receive(activeEntitlements: ["pro"])
        #expect(access.isPro)
    }
    @Test func timelineAIExcludesPrivateChangesAndDisclosesTruncation() throws {
        let event = ProtocolEvent(protocolID: UUID(), title: "Protocol changed", detail: "")
        try event.recordChanges([RecordChange(field: "Notes", before: "Secret", after: "Hidden"), RecordChange(field: "Amount", before: "1", after: "2")], category: "Protocol")
        let records = TimelineRecord.build(logs: [], events: [event])
        let context = AssistantViewModel.timelineContext(records)
        #expect(context.text.contains("Amount: 1 → 2"))
        #expect(!context.text.contains("Secret") && !context.text.contains("Hidden"))
        let limited = AssistantViewModel.timelineContext(records, limit: 0)
        #expect(limited.text.contains("Incomplete coverage"))
        #expect(!limited.text.contains("Amount:"))
    }
    @Test func summaryIncludesEvolutionAndRejectsFreeAccess() throws {
        let store = TrackingStore(container: try LocalPersistence.container(inMemory: true))
        let beginning = Date.now.addingTimeInterval(-86400)
        var draft = ProtocolDraft(); draft.name = "Protocol timeline"; draft.compound = "Compound"; draft.amount = "100"; draft.start = beginning
        try store.repository.saveProtocol(draft, protocolID: nil, compoundID: nil, now: beginning)
        store.refresh()
        let revision = try #require(store.revisions.first)
        draft.amount = "200"
        try store.repository.saveProtocol(draft, protocolID: revision.protocolID, compoundID: revision.compoundID, now: beginning.addingTimeInterval(3600))
        store.refresh()
        #expect(throws: TrackingError.self) { try store.visitSummaryURL(protocolID: revision.protocolID) }
        store.receiveEntitlements(["pro"])
        let url = try store.visitSummaryURL(protocolID: revision.protocolID, period: AnalysisPeriod(start: beginning, end: .now))
        defer { try? FileManager.default.removeItem(at: url) }
        let pdf = try #require(PDFDocument(url: url))
        let text = try #require(pdf.string)
        #expect(text.contains("Current protocols"))
        #expect(text.contains("Key protocol changes"))
        #expect(text.contains("Chronological timeline"))
        #expect(text.contains("100") && text.contains("200"))
        #expect(text.contains("Consistency:"))
    }
    @Test func legacyEventsRemainReadableWithoutInventedValues() {
        let event = ProtocolEvent(protocolID: UUID(), title: "Protocol updated", detail: "Older retained detail")
        #expect(event.changes.isEmpty)
        #expect(event.changesData == nil)
        #expect(TimelineRecord.build(logs: [], events: [event]).first?.detail == "Older retained detail")
    }
    @Test func correctionAuditAndInventoryRemainReconciled() throws {
        let repo = TrackingRepository(container: try LocalPersistence.container(inMemory: true))
        var vialDraft = VialDraft(); vialDraft.name = "V"; vialDraft.compound = "C"; vialDraft.amount = "10"; vialDraft.diluent = "2"
        try repo.saveVial(vialDraft, id: nil)
        let vial = try #require(repo.all(VialRecord.self).first)
        var draft = ProtocolDraft(); draft.name = "P"; draft.compound = "C"; draft.amount = "1000"; draft.vialID = vial.id
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil)
        let revision = try #require(repo.all(ScheduleRevision.self).first)
        var dose = DoseDraft(revision: revision)
        try repo.saveDose(dose, revision: revision, occurrence: nil, correcting: nil)
        let log = try #require(repo.all(DoseLog.self).first)
        dose.amount = "2000"
        try repo.saveDose(dose, revision: nil, occurrence: nil, correcting: log)
        #expect(try repo.balance(vial) == 8)
        let correction = try #require(repo.all(ProtocolEvent.self).first { $0.title == "Dose corrected" })
        #expect(correction.changes.contains(RecordChange(field: "Amount", before: "1000", after: "2000")))
        try repo.deleteDose(log)
        #expect(try repo.balance(vial) == 10)
        let deletion = try #require(repo.all(ProtocolEvent.self).first { $0.title == "Dose deleted" })
        #expect(deletion.changes.contains(RecordChange(field: "Amount", before: "2000", after: "")))
    }
}

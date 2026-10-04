import Foundation
import SwiftData
import Observation

@MainActor @Observable final class TrackingStore {
    private let realContainer: ModelContainer
    private var demoContainer: ModelContainer?
    private(set) var repository: TrackingRepository
    private(set) var protocols: [ProtocolRecord] = []
    private(set) var compounds: [CompoundRecord] = []
    private(set) var revisions: [ScheduleRevision] = []
    private(set) var vials: [VialRecord] = []
    private(set) var logs: [DoseLog] = []
    private(set) var events: [ProtocolEvent] = []
    private(set) var today: [ScheduledEntry] = []
    private(set) var balances: [UUID: Decimal] = [:]
    private(set) var insights: [Int: InsightsSummary] = [:]
    private(set) var onboarded: Bool = false
    private(set) var isDemo: Bool = false
    private(set) var aiSharing: Bool = false
    private var entitlement = EntitlementAccess()
    var isPremium: Bool { entitlement.isPro }
    private(set) var selectedFreeProtocolID: UUID?
    var activeProtocolIDs: Set<UUID> { Set(protocols.filter { $0.status == "Active" }.map(\.id)) }
    var allowedProtocolIDs: Set<UUID> { ProtocolAccess.allowedIDs(isPro: isPremium, activeIDs: activeProtocolIDs, selectedID: selectedFreeProtocolID) }
    var needsProtocolChoice: Bool { !isDemo && !isPremium && activeProtocolIDs.count > 1 && allowedProtocolIDs.isEmpty }
    func canTrack(_ id: UUID) -> Bool { isDemo || allowedProtocolIDs.contains(id) }
    func canEdit(_ id: UUID) -> Bool { isDemo || isPremium || (activeProtocolIDs.count <= 1 ? protocols.contains { $0.id == id } : selectedFreeProtocolID == id) }
    var canCreateProtocol: Bool { isDemo || ProtocolAccess.canActivate(isPro: isPremium, activeIDs: activeProtocolIDs, targetID: nil) }
    func receiveEntitlements(_ active: Set<String>?) {
        entitlement.receive(activeEntitlements: active)
        refreshDay(); resyncReminders()
    }
    func chooseFreeProtocol(_ id: UUID) {
        guard activeProtocolIDs.contains(id), !isPremium else { return }
        _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.selectedFreeProtocolID = id } }
    }
    /// Contextual access request; successful dose logging never sets this flag.
    private(set) var pendingPaywall: Bool = false
    var error: String?
    let notifications = NotificationService()
    init(container: ModelContainer) {
        realContainer = container; repository = TrackingRepository(container: container)
        refresh()
    }
    func refresh(now: Date = .now) {
        do {
            protocols = try repository.all(ProtocolRecord.self).sorted { $0.createdAt > $1.createdAt }
            compounds = try repository.all(CompoundRecord.self)
            revisions = try repository.all(ScheduleRevision.self)
            vials = try repository.all(VialRecord.self).sorted { $0.createdAt > $1.createdAt }
            logs = try repository.all(DoseLog.self).sorted { $0.loggedAt > $1.loggedAt }
            events = try repository.all(ProtocolEvent.self).sorted { $0.at > $1.at }
            let prefs = try repository.preferences(); onboarded = prefs.onboarded; aiSharing = prefs.aiSharing; selectedFreeProtocolID = prefs.selectedFreeProtocolID
            balances = try Dictionary(uniqueKeysWithValues: vials.map { ($0.id, try repository.balance($0)) })
            refreshDay(now: now)
        } catch { self.error = "Local records could not be loaded. Please try again. Your stored data has not been cleared." }
    }
    func refreshDay(now: Date = .now) {
        let start = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? now
        let generated = entries(start: start, end: end).filter { canTrack($0.revision.protocolID) }
        today = Self.ordered(generated, by: (try? repository.preferences())?.todayOrder ?? [])
        insights = [7: InsightsSummary(store: self, window: 7, now: now), 30: InsightsSummary(store: self, window: 30, now: now)]
    }

    /// Ranks a day's generated entries by a persisted manual order; unknown or stale
    /// keys keep chronological order, so the customization expires with the day.
    static func ordered(_ generated: [ScheduledEntry], by order: [String]) -> [ScheduledEntry] {
        let rank = order.enumerated().reduce(into: [String: Int]()) { $0[$1.element] = $1.offset }
        return generated.sorted { a, b in
            let rankA = rank[a.id] ?? Int.max, rankB = rank[b.id] ?? Int.max
            return rankA == rankB ? a.at < b.at : rankA < rankB
        }
    }

    /// Drag-and-drop reorder: the dragged entry lands just before or after the row
    /// it was dropped on, then the order persists to preferences.
    /// Returns whether the order changed, so callers can cue a completion haptic.
    @discardableResult
    func moveTodayEntry(_ draggedID: String, relativeTo anchorID: String, after: Bool) -> Bool {
        var ids = today.map(\.id)
        guard let from = ids.firstIndex(of: draggedID), let anchor = ids.firstIndex(of: anchorID), from != anchor else { return false }
        let anchorIndex = anchor > from ? anchor - 1 : anchor
        let dragged = ids.remove(at: from)
        ids.insert(dragged, at: after ? anchorIndex + 1 : anchorIndex)
        setTodayOrder(ids)
        return true
    }

    /// Accessibility equivalent: a one-step move up (-1) or down (+1).
    @discardableResult
    func moveTodayEntry(_ id: String, by delta: Int) -> Bool {
        var ids = today.map(\.id)
        guard let index = ids.firstIndex(of: id), ids.indices.contains(index + delta) else { return false }
        ids.swapAt(index, index + delta)
        setTodayOrder(ids)
        return true
    }

    private func setTodayOrder(_ ids: [String]) {
        today = ids.compactMap { id in today.first { $0.id == id } }
        _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.todayOrder = ids } }
    }
    func vialStatus(_ vial: VialRecord) -> String {
        let balance = balances[vial.id] ?? 0
        if vial.isArchived { return "Archived" }
        if balance == 0 { return "Depleted" }
        return balance < vial.originalMg / 5 ? "Low recorded balance" : "Active"
    }
    /// Deterministic supply runway: whole scheduled entries this vial can still serve.
    /// Computed only when a single active, un-ended schedule with a fixed mg amount is
    /// recorded against the vial; frequency-based depletion estimates stay out until validated.
    func scheduledEntriesRemaining(in vial: VialRecord) -> Int? {
        guard !vial.isArchived,
              let revision = revisions.first(where: { $0.enabled && $0.effectiveUntil == nil && $0.vialID == vial.id }),
              revision.unit == .mg, revision.amount > 0 else { return nil }
        let entries = NSDecimalNumber(decimal: (balances[vial.id] ?? 0) / revision.amount).intValue
        return max(0, entries)
    }
    func entries(start: Date, end: Date) -> [ScheduledEntry] {
        revisions.filter(\.enabled).flatMap { revision -> [ScheduledEntry] in
            guard let config = revision.config else { return [] }
            return SchedulingEngine.occurrences(config: config, effectiveFrom: revision.effectiveFrom, effectiveUntil: revision.effectiveUntil, start: start, end: end).map { at in
                let id = SchedulingEngine.occurrenceKey(compoundID: revision.compoundID, revisionID: revision.id, at: at)
                return ScheduledEntry(id: id, revision: revision, at: at, log: logs.first { $0.occurrenceID == id })
            }
        }.sorted { $0.at < $1.at }
    }
    func currentRevisions(_ protocolID: UUID) -> [ScheduleRevision] { revisions.filter { $0.protocolID == protocolID && $0.effectiveUntil == nil } }
    func vial(_ id: UUID?) -> VialRecord? { vials.first { $0.id == id } }
    func perform(_ operation: () throws -> Void) -> Bool {
        do { try operation(); refresh(); resyncReminders(); return true }
        catch { self.error = (error as? TrackingError)?.errorDescription ?? "Changes could not be saved. Please try again."; refresh(); return false }
    }
    func saveProtocol(_ draft: ProtocolDraft, protocolID: UUID?, compoundID: UUID?) -> Bool {
        guard protocolID.map(canEdit) ?? canCreateProtocol else { pendingPaywall = true; return false }
        return perform { try repository.saveProtocol(draft, protocolID: protocolID, compoundID: compoundID) }
    }
    func saveVial(_ draft: VialDraft, id: UUID?) -> Bool { perform { try repository.saveVial(draft, id: id) } }
    func saveDose(_ draft: DoseDraft, revision: ScheduleRevision?, occurrence: ScheduledEntry?, correcting: DoseLog?) -> Bool {
        guard let id = correcting?.protocolID ?? revision?.protocolID, correcting == nil ? canTrack(id) : canEdit(id) else { error = "This protocol is read-only on Free. Choose it for tracking or restore Pro."; return false }
        return perform { try repository.saveDose(draft, revision: revision, occurrence: occurrence, correcting: correcting) }
    }
    func deleteDose(_ log: DoseLog) -> Bool {
        guard canEdit(log.protocolID) else { error = "This protocol is read-only on Free."; return false }
        return perform { try repository.deleteDose(log) }
    }
    func changeStatus(_ record: ProtocolRecord, status: String) {
        if status == "Active", !isDemo, !ProtocolAccess.canActivate(isPro: isPremium, activeIDs: activeProtocolIDs, targetID: record.id) { pendingPaywall = true; return }
        guard canEdit(record.id) else { error = "Choose this protocol for tracking or restore Pro before editing it."; return }
        _ = perform { try repository.changeStatus(record, to: status) }
    }
    func archiveVial(_ vial: VialRecord) {
        _ = perform { try repository.transaction {
            let before = vial.isArchived ? "Archived" : "Active"
            vial.isArchived.toggle()
            let event = ProtocolEvent(protocolID: nil, title: "Vial status changed", detail: "")
            try event.recordChanges([RecordChange(field: "Status", before: before, after: vial.isArchived ? "Archived" : "Active")], category: "Vial")
            repository.context.insert(event)
        } }
    }
    func completeOnboarding() {
        _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.disclaimerAccepted = true; prefs.onboarded = true } }
    }
    func setAISharing(_ enabled: Bool) { _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.aiSharing = enabled } } }
    func dismissPaywall() { pendingPaywall = false }
    func visitSummaryURL(protocolID: UUID? = nil, period: AnalysisPeriod? = nil) throws -> URL {
        guard isPremium else { throw TrackingError.invalidInput("Visit Summary requires Pro.") }
        let selectedProtocols = protocols.filter { protocolID == nil || $0.id == protocolID }
        let selectedLogs = logs.filter { (protocolID == nil || $0.protocolID == protocolID) && (period?.contains($0.loggedAt) ?? true) }
        let selectedEvents = events.filter { (protocolID == nil || $0.protocolID == protocolID) && (period?.contains($0.at) ?? true) }
        return try VisitSummaryService.generate(protocols: selectedProtocols, compounds: compounds, revisions: revisions, logs: selectedLogs, events: selectedEvents, period: period, summary: period.map { InsightsSummary(store: self, period: $0, protocolID: protocolID) })
    }

    func clearData() { _ = perform { try repository.clear() } }
    func resyncReminders() {
        guard !isDemo else { return }
        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: 90, to: now) ?? now
        let upcoming = entries(start: now, end: end).filter { $0.revision.reminders && $0.log == nil && canTrack($0.revision.protocolID) }
        notifications.update(upcoming)
    }
    func enterDemo() {
        do {
            let container = try LocalPersistence.container(inMemory: true)
            let repo = TrackingRepository(container: container)
            try DemoData.seed(repo)
            demoContainer = container; repository = repo; isDemo = true; refresh()
        } catch { self.error = "Demo records could not be loaded. Your own records are unchanged." }
    }
    func exitDemo() { repository = TrackingRepository(container: realContainer); demoContainer = nil; isDemo = false; refresh(); resyncReminders() }
}

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
    private(set) var inventoryAdjustments:
        [InventoryAdjustment] = []
    private(set) var logs: [DoseLog] = []
    private(set) var events: [ProtocolEvent] = []
    private(set) var labs: [LabRecord] = []
    private(set) var today: [ScheduledEntry] = []
    /// Yesterday's scheduled entries that were neither logged nor skipped.
    /// Kept on Today so a dose taken late at night can still be recorded
    /// against its scheduled occurrence after midnight.
    private(set) var carriedOver: [ScheduledEntry] = []
    private(set) var balances: [UUID: Decimal] = [:]
    private(set) var insights: [Int: InsightsSummary] = [:]
    private(set) var onboarded: Bool = false
    private(set) var isDemo: Bool = false
    private(set) var aiSharing: Bool = false
    private(set) var inventoryAlerts: Bool = false
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
    /// Central contextual paywall request used by locked features and deep links.
    private(set) var pendingPaywall: PaywallReason?
    var error: String?
    let notifications = NotificationService()
    init(container: ModelContainer) {
        realContainer = container; repository = TrackingRepository(container: container)
        refresh()
        NotificationActionRouter.shared.handler = { [weak self] entryID, action in
            self?.handleNotificationAction(entryID, action)
        }
    }

    /// Log or skip a scheduled entry from its reminder's action buttons. The
    /// entry keeps the time the action was taken; already-recorded entries
    /// are left untouched.
    func handleNotificationAction(_ entryID: String, _ action: NotificationActionRouter.Action) {
        guard !isDemo else { return }
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let end = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        guard let entry = entries(start: start, end: end).first(where: { $0.id == entryID }), entry.log == nil else { return }
        var draft = DoseDraft(revision: entry.revision)
        if action == .skip {
            draft.status = "Skipped"; draft.vialID = nil; draft.site = ""; draft.symptoms = ""; draft.notes = ""
        }
        _ = saveDose(draft, revision: entry.revision, occurrence: entry, correcting: nil)
    }

    func detachNotificationHandler() {
        NotificationActionRouter.shared.handler = nil
    }
    func refresh(now: Date = .now) {
        do {
            protocols = try repository.all(ProtocolRecord.self).sorted { $0.createdAt > $1.createdAt }
            compounds = try repository.all(CompoundRecord.self)
            revisions = try repository.all(ScheduleRevision.self)
            vials = try repository.all(VialRecord.self).sorted { $0.createdAt > $1.createdAt }
            inventoryAdjustments =
                try repository
                    .all(
                        InventoryAdjustment.self
                    )
                    .sorted {
                        $0.recordedAt
                            > $1.recordedAt
                    }
            logs = try repository.all(DoseLog.self).sorted { $0.loggedAt > $1.loggedAt }
            events = try repository.all(ProtocolEvent.self).sorted { $0.at > $1.at }
            labs = try repository.all(LabRecord.self).sorted { $0.collectedAt > $1.collectedAt }
            let prefs = try repository.preferences(); onboarded = prefs.onboarded; aiSharing = prefs.aiSharing; inventoryAlerts = prefs.inventoryAlerts; selectedFreeProtocolID = prefs.selectedFreeProtocolID
            balances = try Dictionary(uniqueKeysWithValues: vials.map { ($0.id, try repository.balance($0)) })
            refreshDay(now: now)
        } catch { self.error = "Local records could not be loaded. Please try again. Your stored data has not been cleared." }
    }
    func refreshDay(now: Date = .now) {
        let start = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? now
        let generated = entries(start: start, end: end).filter { canTrack($0.revision.protocolID) }
        // Unrecorded entries from the past week stay on Today until they are
        // logged or skipped. Entries dated before the protocol was added to
        // the app are not counted, so a backdated start doesn't flood Today.
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: start) ?? start
        let added = Dictionary(protocols.map { ($0.id, $0.createdAt) }, uniquingKeysWith: { first, _ in first })
        carriedOver = entries(start: weekAgo, end: start).filter {
            $0.log == nil
            && canTrack($0.revision.protocolID)
            && $0.at >= (added[$0.revision.protocolID] ?? .distantPast)
        }
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
    @discardableResult
    func moveTodayEntry(_ draggedID: String, relativeTo anchorID: String, after: Bool) -> Bool {
        var ids = today.map(\.id)
        guard let from = ids.firstIndex(of: draggedID),
              let anchor = ids.firstIndex(of: anchorID),
              from != anchor else { return false }
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
        guard let index = ids.firstIndex(of: id),
              ids.indices.contains(index + delta) else { return false }
        ids.swapAt(index, index + delta)
        setTodayOrder(ids)
        return true
    }

    private func setTodayOrder(_ ids: [String]) {
        today = ids.compactMap { id in today.first { $0.id == id } }
        _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.todayOrder = ids } }
    }
    func vialStatus(
        _ vial: VialRecord
    ) -> String {
        let balance =
            balances[vial.id] ?? 0

        if vial.lifecycleState == .archived {
            return "Archived"
        }

        if balance == 0 {
            return "Depleted"
        }

        if vial.lifecycleState == .sealed {
            return "Sealed"
        }

        if vial.lifecycleState == .reserve {
            return "Reserve"
        }

        return balance
            < vial.originalMg / 5
            ? "Low recorded balance"
            : "Active"
    }

    func scheduledEntriesRemaining(
        in vial: VialRecord,
        at date: Date = .now
    ) -> Int? {
        guard let mass =
            singleScheduledMassMg(
                for: vial,
                at: date
            ),
              mass > 0
        else {
            return nil
        }

        let entries =
            Self.wholeCount(
                (balances[vial.id] ?? 0)
                / mass
            )

        return max(0, entries)
    }

    func dosesPerVial(
        _ vial: VialRecord,
        at date: Date = .now
    ) -> Int? {
        guard let mass =
            singleScheduledMassMg(
                for: vial,
                at: date
            ),
              mass > 0
        else {
            return nil
        }

        let entries =
            Self.wholeCount(
                vial.originalMg / mass
            )

        return max(0, entries)
    }

    /// Floors a Decimal quotient to an Int. A full-precision quotient such as
    /// 10 / 3 carries a 38-digit mantissa, and NSDecimalNumber.intValue is
    /// unreliable once the mantissa exceeds 64 bits, so round to scale 0
    /// before converting.
    nonisolated static func wholeCount(
        _ value: Decimal
    ) -> Int {
        guard !value.isNaN, value > 0 else {
            return 0
        }

        var source = value
        var floored = Decimal()
        NSDecimalRound(
            &floored,
            &source,
            0,
            .down
        )

        return NSDecimalNumber(
            decimal: floored
        ).intValue
    }

    func estimatedDepletionDate(
        in vial: VialRecord,
        now: Date = .now
    ) -> Date? {
        guard vial.lifecycleState
                != .archived,
              (balances[vial.id] ?? 0) > 0
        else {
            return nil
        }

        let calendar = Calendar.current
        guard let horizon =
            calendar.date(
                byAdding: .year,
                value: 2,
                to: now
            )
        else {
            return nil
        }

        let linked =
            revisions.filter {
                $0.enabled
                && $0.vialID == vial.id
                && $0.intersects(
                    start: now,
                    end: horizon
                )
            }

        guard !linked.isEmpty else {
            return nil
        }

        var future:
            [(at: Date, massMg: Decimal)] = []

        for revision in linked {
            guard let config =
                    revision.config,
                  let mass =
                    scheduledMassMg(
                        revision
                    ),
                  mass > 0
            else {
                return nil
            }

            let occurrences =
                SchedulingEngine
                    .occurrences(
                        config: config,
                        effectiveFrom:
                            revision
                                .effectiveFrom,
                        effectiveUntil:
                            revision
                                .effectiveUntil,
                        start: now,
                        end: horizon
                    )

            future.append(
                contentsOf:
                    occurrences.map {
                        (
                            at: $0,
                            massMg: mass
                        )
                    }
            )
        }

        future.sort {
            $0.at < $1.at
        }

        var remaining =
            balances[vial.id] ?? 0

        for entry in future {
            remaining -= entry.massMg

            if remaining <= 0 {
                return entry.at
            }
        }

        return nil
    }

    private func singleScheduledMassMg(
        for vial: VialRecord,
        at date: Date
    ) -> Decimal? {
        let linked =
            revisions.filter {
                $0.enabled
                && $0.vialID == vial.id
                && $0.isEffective(
                    at: date
                )
            }

        guard linked.count == 1,
              let revision = linked.first
        else {
            return nil
        }

        return scheduledMassMg(revision)
    }

    private func scheduledMassMg(
        _ revision: ScheduleRevision
    ) -> Decimal? {
        switch revision.unit {
        case .mg:
            return revision.amount
        case .mcg:
            return revision.amount / 1_000
        case .mL, .units, .iu:
            return nil
        }
    }
    func entries(start: Date, end: Date) -> [ScheduledEntry] {
        revisions.filter(\.enabled).flatMap { revision -> [ScheduledEntry] in
            guard let config = revision.config else { return [] }
            return SchedulingEngine.occurrences(config: config, effectiveFrom: revision.effectiveFrom, effectiveUntil: revision.effectiveUntil, start: start, end: end).map { at in
                let id = SchedulingEngine.occurrenceKey(compoundID: revision.compoundID, revisionID: revision.id, at: at, config: config)
                return ScheduledEntry(id: id, revision: revision, at: at, log: logs.first { $0.occurrenceID == id })
            }
        }.sorted { $0.at < $1.at }
    }
    func currentRevisions(
        _ protocolID: UUID,
        at date: Date = .now
    ) -> [ScheduleRevision] {
        revisions
            .filter {
                $0.protocolID
                    == protocolID
                && $0.isEffective(
                    at: date
                )
            }
            .sorted {
                $0.compoundName
                    < $1.compoundName
            }
    }

    func plannedRevisions(
        _ protocolID: UUID,
        after date: Date = .now
    ) -> [ScheduleRevision] {
        revisions
            .filter {
                $0.protocolID
                    == protocolID
                && $0.isPlanned(
                    after: date
                )
            }
            .sorted {
                $0.effectiveFrom
                    < $1.effectiveFrom
            }
    }

    func plannedRevisions(
        compoundID: UUID,
        after date: Date = .now
    ) -> [ScheduleRevision] {
        revisions
            .filter {
                $0.compoundID
                    == compoundID
                && $0.isPlanned(
                    after: date
                )
            }
            .sorted {
                $0.effectiveFrom
                    < $1.effectiveFrom
            }
    }

    func vial(
        _ id: UUID?
    ) -> VialRecord? {
        vials.first {
            $0.id == id
        }
    }
    func perform(_ operation: () throws -> Void) -> Bool {
        do { try operation(); refresh(); resyncReminders(); return true }
        catch { self.error = (error as? TrackingError)?.errorDescription ?? "Changes could not be saved. Please try again."; refresh(); return false }
    }
    func saveProtocol(
        _ draft: ProtocolDraft,
        protocolID: UUID?,
        compoundID: UUID?
    ) -> Bool {
        guard
            protocolID.map(canEdit)
                ?? canCreateProtocol
        else {
            pendingPaywall = .secondProtocol
            return false
        }

        return perform {
            try repository.saveProtocol(
                draft,
                protocolID:
                    protocolID,
                compoundID:
                    compoundID
            )
        }
    }

    func savePlannedProtocolChange(
        _ draft: ProtocolDraft,
        protocolID: UUID,
        compoundID: UUID,
        plannedRevisionID: UUID?,
        effectiveFrom: Date
    ) -> Bool {
        guard canEdit(protocolID) else {
            error =
                "Choose this protocol for tracking or restore Pro before editing it."
            return false
        }

        return perform {
            try repository
                .savePlannedProtocolChange(
                    draft,
                    protocolID:
                        protocolID,
                    compoundID:
                        compoundID,
                    plannedRevisionID:
                        plannedRevisionID,
                    effectiveFrom:
                        effectiveFrom
                )
        }
    }

    func cancelPlannedRevision(
        _ revision: ScheduleRevision
    ) -> Bool {
        guard
            canEdit(revision.protocolID)
        else {
            error =
                "Choose this protocol for tracking or restore Pro before editing it."
            return false
        }

        return perform {
            try repository
                .cancelPlannedRevision(
                    revision.id
                )
        }
    }

    func saveCompoundHalfLife(
        _ compound: CompoundRecord,
        hoursText: String,
        source: String
    ) -> Bool {
        guard
            canEdit(
                compound.protocolID
            )
        else {
            error =
                "Choose this protocol for tracking or restore Pro before editing it."
            return false
        }

        return perform {
            try repository
                .saveCompoundHalfLife(
                    compoundID:
                        compound.id,
                    hoursText:
                        hoursText,
                    source: source
                )
        }
    }


    func saveVial(
        _ draft: VialDraft,
        id: UUID?
    ) -> Bool {
        perform {
            try repository.saveVial(
                draft,
                id: id
            )
        }
    }
    func saveLab(
        _ draft: LabDraft,
        id: UUID? = nil
    ) -> Bool {
        perform {
            try repository.saveLab(
                draft,
                id: id
            )
        }
    }

    func deleteLab(
        _ lab: LabRecord
    ) -> Bool {
        perform {
            try repository
                .deleteLab(lab)
        }
    }

    func lab(
        _ id: UUID
    ) -> LabRecord? {
        labs.first {
            $0.id == id
        }
    }

    func labs(
        protocolID: UUID
    ) -> [LabRecord] {
        labs.filter {
            $0.protocolID
                == protocolID
        }
    }

    func saveDose(_ draft: DoseDraft, revision: ScheduleRevision?, occurrence: ScheduledEntry?, correcting: DoseLog?) -> Bool {
        guard let id = correcting?.protocolID ?? revision?.protocolID, correcting == nil ? canTrack(id) : canEdit(id) else { error = "This protocol is read-only on Free. Choose it for tracking or restore Pro."; return false }
        return perform { try repository.saveDose(draft, revision: revision, occurrence: occurrence, correcting: correcting) }
    }
    func deleteDose(_ log: DoseLog) -> Bool {
        guard canEdit(log.protocolID) else { error = "This protocol is read-only on Free."; return false }
        return perform { try repository.deleteDose(log) }
    }
    func changeStatus(_ record: ProtocolRecord, status: String) {
        if status == "Active", !isDemo, !ProtocolAccess.canActivate(isPro: isPremium, activeIDs: activeProtocolIDs, targetID: record.id) { pendingPaywall = .secondProtocol; return }
        guard canEdit(record.id) else { error = "Choose this protocol for tracking or restore Pro before editing it."; return }
        _ = perform { try repository.changeStatus(record, to: status) }
    }
    func archiveVial(
        _ vial: VialRecord
    ) {
        _ = perform {
            try repository.transaction {
                let before =
                    vial.lifecycleState
                        .rawValue

                vial.lifecycleState =
                    vial.lifecycleState
                        == .archived
                    ? .active
                    : .archived

                let event =
                    ProtocolEvent(
                        protocolID: nil,
                        title:
                            "Vial status changed",
                        detail: ""
                    )

                try event.recordChanges(
                    [
                        RecordChange(
                            field: "State",
                            before: before,
                            after:
                                vial.lifecycleState
                                    .rawValue
                        )
                    ],
                    category: "Vial"
                )
                repository.context.insert(event)
            }
        }
    }
    func completeOnboarding() {
        _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.disclaimerAccepted = true; prefs.onboarded = true } }
    }
    func setAISharing(_ enabled: Bool) { _ = perform { let prefs = try repository.preferences(); try repository.transaction { prefs.aiSharing = enabled } } }

    /// Persists the optional inventory-alert preference. Requesting notification
    /// permission first mirrors the protocol-reminder flow in the editor.
    func setInventoryAlerts(_ enabled: Bool) async {
        if enabled {
            let allowed =
                await notifications
                    .requestPermission()

            guard allowed else {
                error =
                    "Inventory alerts were not enabled because notifications are disabled for Protocola."
                return
            }
        }

        guard
            perform({
                let prefs =
                    try repository
                        .preferences()

                try repository.transaction {
                    prefs.inventoryAlerts =
                        enabled
                }
            })
        else {
            return
        }

        resyncReminders()
    }
    func requestPaywall(_ reason: PaywallReason) {
        pendingPaywall = reason
    }

    func dismissPaywall() {
        pendingPaywall = nil
    }
    func visitSummaryURL(protocolID: UUID? = nil, period: AnalysisPeriod? = nil) throws -> URL {
        guard isPremium else { throw TrackingError.invalidInput("Visit Summary requires Pro.") }
        let selectedProtocols = protocols.filter { protocolID == nil || $0.id == protocolID }
        let selectedLogs = logs.filter { (protocolID == nil || $0.protocolID == protocolID) && (period?.contains($0.loggedAt) ?? true) }
        let selectedEvents = events.filter { (protocolID == nil || $0.protocolID == protocolID) && (period?.contains($0.at) ?? true) }
        let selectedLabs = labs.filter { (protocolID == nil || $0.protocolID == protocolID) && (period?.contains($0.collectedAt) ?? true) }
        return try VisitSummaryService.generate(protocols: selectedProtocols, compounds: compounds, revisions: revisions, logs: selectedLogs, events: selectedEvents, labs: selectedLabs, period: period, summary: period.map { InsightsSummary(store: self, period: $0, protocolID: protocolID) })
    }

    func clearData() {
        ReminderDeliveryLedgerStore
            .clear()

        _ = perform {
            try repository.clear()
        }
    }
    func resyncReminders() {
        guard !isDemo else {
            // Demo mode must never leave real-record notifications pending.
            notifications.update([])
            return
        }

        let now = Date()
        let end =
            Calendar.current.date(
                byAdding: .day,
                value: 90,
                to: now
            ) ?? now

        let scheduled =
            entries(
                start: now,
                end: end
            )
            .filter {
                $0.revision.reminders
                && $0.log == nil
                && canTrack(
                    $0.revision.protocolID
                )
            }
            .map {
                ReminderPlanner.Candidate(
                    id: $0.id,
                    at: $0.at,
                    floating:
                        $0.revision.config?
                            .followsDeviceTimeZone == true
                )
            }

        let cycleRestarts =
            revisions.compactMap {
                revision
                    -> ReminderPlanner.Candidate?
                in

                guard
                    revision.enabled,
                    revision.reminders,
                    revision.intersects(
                        start: now,
                        end: end
                    ),
                    canTrack(
                        revision.protocolID
                    ),
                    let config =
                        revision.config,
                    config.hasCycle,
                    let restart =
                        CycleDisplay
                            .nextRestart(
                                config,
                                after: now
                            ),
                    restart <= end,
                    // The restart must fall inside this revision's own
                    // window. Otherwise a revision that a planned change
                    // replaces (or that a planned revision only starts
                    // after) still announces restarts it no longer owns,
                    // duplicating or contradicting the successor's notice.
                    restart >= revision.effectiveFrom,
                    revision.effectiveUntil.map({
                        restart < $0
                    }) ?? true,
                    let noticeAt =
                        CycleDisplay
                            .restartNoticeDate(
                                config,
                                restart: restart
                            )
                else {
                    return nil
                }

                return ReminderPlanner
                    .Candidate(
                        id:
                            "cycle-restart:"
                            + revision.id
                                .uuidString
                            + ":"
                            + String(
                                Int(
                                    restart
                                        .timeIntervalSince1970
                                )
                            ),
                        at: noticeAt,
                        title:
                            "Protocola · cycle restart",
                        body:
                            "A recorded cycle is scheduled to resume tomorrow. Open Protocola to review it."
                    )
            }

        // Optional inventory alerts ride the same planner pipeline as schedule
        // reminders; every input is recorded data, never an invented date.
        let inventory: [ReminderPlanner.Candidate] =
            (try? repository.preferences())?.inventoryAlerts == true
            ? vials.flatMap { vial in
                VialAlerts.candidates(
                    vial: vial,
                    status: vialStatus(vial),
                    projectedDepletion: estimatedDepletionDate(
                        in: vial,
                        now: now
                    ),
                    now: now
                )
            }
            : []

        notifications.update(
            scheduled
            + cycleRestarts
            + inventory
        )
    }
    func enterDemo() {
        do {
            let container = try LocalPersistence.container(inMemory: true)
            let repo = TrackingRepository(container: container)
            try DemoData.seed(repo)
            demoContainer = container; repository = repo; isDemo = true; refresh(); resyncReminders()
        } catch { self.error = "Demo records could not be loaded. Your own records are unchanged." }
    }
    func exitDemo() { repository = TrackingRepository(container: realContainer); demoContainer = nil; isDemo = false; refresh(); resyncReminders() }
}

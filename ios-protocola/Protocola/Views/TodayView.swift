import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var target: ScheduledEntry?
    @State private var prefill: DoseDraft?
    @State private var create: Bool = false
    @State private var settings: Bool = false
    @State private var inventory: Bool = false
    @State private var addVial: Bool = false
    @State private var calculator: Bool = false
    @State private var shareCard: Bool = false
    @State private var undoLog: DoseLog?
    @State private var undoTask: Task<Void, Never>?
    @State private var dropTarget: String?
    @State private var dropAfter: Bool = false
    private var recordedCount: Int { store.today.filter { $0.log != nil }.count }
    /// At accessibility text sizes the hero stacks dose above time instead of colliding.
    private var usesStackedHero: Bool { typeSize.isAccessibilitySize }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spaceXL) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())).font(.subheadline).foregroundStyle(Theme.muted)
                if let next = store.today.first(where: { $0.log == nil }) {
                    nextEntryHero(next)
                } else {
                    TrackingCard {
                        TrackingEmptyState(
                            icon: store.today.isEmpty ? "calendar" : "checkmark.circle",
                            title: store.today.isEmpty ? "Nothing scheduled today" : "Today's entries are recorded",
                            message: store.protocols.isEmpty ? "Record a protocol you already have to populate Today." : "You can add an unscheduled entry from a protocol's details.",
                            actionTitle: store.protocols.isEmpty ? "Add protocol" : nil,
                            action: store.protocols.isEmpty ? { create = true } : nil
                        )
                        if !store.today.isEmpty && !store.isDemo {
                            Button { shareCard = true } label: { Label("Share this week", systemImage: "square.and.arrow.up") }
                                .buttonStyle(TrackingSecondaryButtonStyle())
                        }
                    }
                }
                if store.isDemo {
                    TrackingCard {
                        VStack(spacing: Theme.spaceS) {
                            Image(systemName: "square.and.pencil").font(.title2).foregroundStyle(Theme.muted)
                            Text("Ready for your own records?").font(.headline)
                            Text("Exit the demo and set up your protocol. Sample records stay isolated and are never saved to your history.")
                                .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                            Button("Set up your protocol") { store.exitDemo(); create = true }
                                .buttonStyle(TrackingPrimaryButtonStyle()).padding(.top, Theme.spaceXS)
                        }.frame(maxWidth: .infinity).padding(.vertical, Theme.spaceXS)
                    }
                }
                if !store.isDemo && !store.protocols.isEmpty && store.vials.isEmpty {
                    // A single hint stands on whitespace — no container needed.
                    HStack(spacing: Theme.spaceS) {
                        Image(systemName: "shippingbox").font(.body).foregroundStyle(Theme.muted).frame(width: 28)
                        VStack(alignment: .leading, spacing: Theme.spaceXXS) {
                            Text("Add your first vial").font(.subheadline.weight(.medium))
                            Text("Vial balances reconcile automatically from your entries.").font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Button("Add") { addVial = true }.buttonStyle(.bordered).frame(minHeight: 44)
                    }
                }
                if !store.today.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spaceM) {
                        HStack { Eyebrow(text: "Today's entries"); Spacer(); Text("\(recordedCount) / \(store.today.count) recorded").font(.caption).foregroundStyle(Theme.muted).monospacedDigit() }
                        TrackingCard {
                            ForEach(Array(store.today.enumerated()), id: \.element.id) { index, entry in
                                entryRow(entry)
                                    .draggable(entry.id)
                                    .background(dropTarget == entry.id ? Theme.ink.opacity(0.04) : Color.clear)
                                    .overlay(alignment: dropAfter ? .bottom : .top) { insertionLine(for: entry) }
                                    .overlay {
                                        GeometryReader { _ in
                                            VStack(spacing: 0) {
                                                Color.clear.contentShape(.rect)
                                                    .dropDestination(for: String.self) { payload, _ in dropOnEntry(payload, anchorID: entry.id, after: false); return true }
                                                    isTargeted: { hover(entry.id, isBottom: false, active: $0) }
                                                Color.clear.contentShape(.rect)
                                                    .dropDestination(for: String.self) { payload, _ in dropOnEntry(payload, anchorID: entry.id, after: true); return true }
                                                    isTargeted: { hover(entry.id, isBottom: true, active: $0) }
                                            }
                                        }
                                    }
                                    .accessibilityAction(named: Text("Move up")) { shift(entry, by: -1) }
                                    .accessibilityAction(named: Text("Move down")) { shift(entry, by: 1) }
                                if index < store.today.count - 1 { Divider() }
                            }
                        }
                        .animation(reduceMotion ? nil : .easeIn(duration: 0.15), value: dropTarget)
                    }
                }
                TrackingNavLink(
                    action: { inventory = true },
                    label: { Label("Vial inventory", systemImage: "shippingbox") },
                    trailing: { Text("\(store.vials.filter { !$0.isArchived }.count)").foregroundStyle(Theme.muted).monospacedDigit() }
                )
                Text("Your schedule, as recorded. Protocola does not recommend what, when, or where to administer.").font(.caption).foregroundStyle(Theme.muted)
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceS)
        }.background(Theme.paper).navigationTitle("Today")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let log = undoLog, !log.isDeleted { undoBanner(log) }
            }
            .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: undoLog?.id)
            .onDisappear { undoTask?.cancel() }
            .sensoryFeedback(.success, trigger: recordedCount) { old, new in new > old }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Calculator", systemImage: "function") { calculator = true }
                    Button("Settings", systemImage: "gearshape") { settings = true }
                }
            }
            .refreshable { store.refresh(); store.resyncReminders() }
            .sheet(item: $target) { entry in DoseEditorView(revision: entry.revision, occurrence: entry, prefill: prefill) }
            .sheet(isPresented: $create) { ProtocolEditorView() }
            .sheet(isPresented: $settings) { SettingsView() }
            .sheet(isPresented: $addVial) { VialEditorView() }
            .sheet(isPresented: $calculator) { CalculatorView() }
            .sheet(isPresented: $shareCard) { ShareCardPreviewView(data: store.insights[7].flatMap { ShareCardData(summary: $0, window: 7) }) }
            .navigationDestination(isPresented: $inventory) { InventoryView() }
            .trackingErrors()
    }

    /// The ink editorial surface — the single dark anchor in the app. The recorded
    /// action is inverted (white surface, teal label) so it dominates every screen.
    @ViewBuilder private func nextEntryHero(_ next: ScheduledEntry) -> some View {
        TrackingHeroCard {
            HStack {
                Eyebrow(text: "Next scheduled entry", onDark: true)
                Spacer()
                heroTag("Scheduled")
            }
            Text(next.revision.compoundName).font(.title2.weight(.semibold)).foregroundStyle(.white)
            if usesStackedHero {
                VStack(alignment: .leading, spacing: Theme.spaceXS) {
                    heroDose(next)
                    heroTime(next)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Theme.spaceXS) {
                    heroDose(next)
                    Spacer()
                    heroTime(next)
                }
            }
            Divider().overlay(Color.white.opacity(0.16))
            RecordRow(label: "Protocol", value: next.revision.protocolName, onDark: true)
            RecordRow(label: "Vial", value: store.vial(next.revision.vialID)?.name ?? "Not selected", onDark: true)
            if let site = next.revision.configuredSite { RecordRow(label: "Configured site", value: site, onDark: true) }
            Button { logAsScheduled(next) } label: { Label("Log as scheduled", systemImage: "checkmark") }
                .buttonStyle(TrackingPrimaryButtonStyle(inverted: true))
            Button { open(next, prefill: repeatDraft(for: next)) } label: { Label("Adjust details", systemImage: "slider.horizontal.3") }
                .buttonStyle(TrackingSecondaryButtonStyle(onDark: true))
        }
    }

    private func heroDose(_ next: ScheduledEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.spaceXXS) {
            Text(next.revision.amountText).font(.system(.largeTitle, design: .rounded).weight(.semibold)).monospacedDigit().foregroundStyle(.white)
            Text(next.revision.unitText).font(.title3).foregroundStyle(Color.white.opacity(0.64))
        }
    }

    private func heroTime(_ next: ScheduledEntry) -> some View {
        Text(next.at, style: .time).font(.title3.weight(.medium)).monospacedDigit().foregroundStyle(Color.white.opacity(0.92))
    }

    /// On-dark rectangular status tag — pending, deliberately neutral.
    private func heroTag(_ text: String) -> some View {
        Text(text.uppercased()).font(.caption2.weight(.semibold)).tracking(0.8)
            .foregroundStyle(Color.white.opacity(0.85))
            .padding(.horizontal, Theme.spaceXS).padding(.vertical, Theme.spaceXXS)
            .background(Color.white.opacity(0.14), in: .rect(cornerRadius: 6))
    }

    /// Live drop feedback: a faint row tint plus a 2pt insertion line at the
    /// hovered half of the row, showing exactly where the entry will land.
    @ViewBuilder private func insertionLine(for entry: ScheduledEntry) -> some View {
        if dropTarget == entry.id {
            Capsule().fill(Theme.ink).frame(height: 2)
                .padding(.horizontal, Theme.spaceXS)
                .transition(.opacity)
        }
    }

    private func hover(_ id: String, isBottom: Bool, active: Bool) {
        if active {
            dropTarget = id
            dropAfter = isBottom
        } else if dropTarget == id {
            dropTarget = nil
        }
    }

    private func dropOnEntry(_ payload: [String], anchorID: String, after: Bool) {
        guard let draggedID = payload.first else { return }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) {
            store.moveTodayEntry(draggedID, relativeTo: anchorID, after: after)
        }
        dropTarget = nil
    }

    private func shift(_ entry: ScheduledEntry, by delta: Int) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { store.moveTodayEntry(entry.id, by: delta) }
    }

    /// One row of the Today entries card, matching the History list-row pattern.
    @ViewBuilder private func entryRow(_ entry: ScheduledEntry) -> some View {
        HStack(spacing: Theme.spaceS) {
            statusSymbol(for: entry)
            VStack(alignment: .leading, spacing: Theme.spaceXXS) {
                Text(entry.revision.compoundName).font(.headline)
                Text("\(entry.at.formatted(date: .omitted, time: .shortened)) · \(entry.revision.amountText) \(entry.revision.unitText)").font(.caption).foregroundStyle(Theme.muted).monospacedDigit()
            }
            Spacer()
            if let log = entry.log { StatusBadge(text: log.status) }
            else { Button("Log") { open(entry) }.buttonStyle(.bordered).frame(minHeight: 44) }
        }
    }

    /// Fill/fade confirmation on newly recorded entries; static under Reduce Motion.
    @ViewBuilder private func statusSymbol(for entry: ScheduledEntry) -> some View {
        let recorded = entry.log != nil
        Image(systemName: recorded ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(recorded ? Theme.teal : Theme.line)
            .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: entry.log?.id)
    }

    private func open(_ entry: ScheduledEntry, prefill draft: DoseDraft? = nil) {
        prefill = draft
        target = entry
    }

    /// Records the entry exactly as scheduled — scheduled amount, unit, and recorded vial,
    /// logged at the current time through the normal recorded path — then offers a short undo.
    private func logAsScheduled(_ entry: ScheduledEntry) {
        guard entry.log == nil else { return }
        if store.saveDose(DoseDraft(revision: entry.revision), revision: entry.revision, occurrence: entry, correcting: nil),
           let log = store.logs.first(where: { $0.occurrenceID == entry.id }) {
            undoLog = log
        }
    }

    /// Undo reuses the history-safe deletion; the banner auto-dismisses after four seconds.
    /// The only floating element in the app: screen margins, crisp border, one soft shadow.
    private func undoBanner(_ log: DoseLog) -> some View {
        HStack(spacing: Theme.spaceS) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.teal)
            Text("Logged · \(log.compoundName)").font(.subheadline.weight(.medium)).lineLimit(1)
            Spacer(minLength: Theme.spaceXS)
            Button("Undo") { if store.deleteDose(log) { undoLog = nil } }
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.teal)
                .frame(minHeight: 44)
        }
        .padding(.horizontal, Theme.spaceM).padding(.vertical, Theme.spaceXS)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusCard))
        .inkBorder(cornerRadius: Theme.radiusCard)
        .shadow(color: Theme.ink.opacity(0.16), radius: 12, y: 4)
        .padding(.horizontal, Theme.spaceL).padding(.bottom, Theme.spaceXS)
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
        .onAppear { scheduleUndoDismiss() }
    }

    private func scheduleUndoDismiss() {
        undoTask?.cancel()
        undoTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            undoLog = nil
        }
    }

    /// Repeat-last prefill: dose values come from the current schedule; only a still-active
    /// matching vial and its recorded syringe scale are reused from the user's last entry.
    private func repeatDraft(for entry: ScheduledEntry) -> DoseDraft? {
        guard entry.revision.vialID == nil else { return nil }
        let last = store.logs.first { $0.compoundID == entry.revision.compoundID && $0.status != "Skipped" }
        guard let last else { return nil }
        let draft = DoseDraft.repeatLast(revision: entry.revision, last: last, candidateVial: last.vialID.flatMap { store.vial($0) })
        return draft.vialID == nil ? nil : draft
    }
}

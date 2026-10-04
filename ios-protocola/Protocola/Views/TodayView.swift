import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var target: ScheduledEntry?
    @State private var prefill: DoseDraft?
    @State private var create = false
    @State private var settings = false
    @State private var inventory = false
    @State private var addVial = false
    @State private var calculator = false
    @State private var shareCard = false
    @State private var undoLog: DoseLog?
    @State private var undoTask: Task<Void, Never>?
    @State private var dropTarget: String?
    @State private var dropAfter = false

    private var recordedCount: Int {
        store.today.filter { $0.log != nil }.count
    }

    private var nextUnloggedEntry: ScheduledEntry? {
        store.today.first { $0.log == nil }
    }

    /// The hero already represents the next unlogged entry.
    /// Keep it out of the list so the same action is not shown twice.
    private var remainingTodayEntries: [ScheduledEntry] {
        guard let nextUnloggedEntry else {
            return store.today
        }

        return store.today.filter {
            $0.id != nextUnloggedEntry.id
        }
    }

    private var usesStackedHero: Bool {
        typeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {
                Text(
                    Date.now.formatted(
                        .dateTime
                            .weekday(.wide)
                            .month(.wide)
                            .day()
                    )
                )
                .font(Theme.body)
                .foregroundStyle(Theme.muted)

                if let next = nextUnloggedEntry {
                    nextEntryHero(next)
                } else {
                    todayEmptyState
                }

                if store.isDemo {
                    demoCard
                }

                if !store.isDemo,
                   !store.protocols.isEmpty,
                   store.vials.isEmpty {
                    addFirstVialCard
                }

                if lastRecordedLog != nil
                    || activeVial != nil {
                    summaryTiles
                }

                if !remainingTodayEntries.isEmpty {
                    todayEntriesSection
                }

                Text(
                    "Your schedule, as recorded. Protocola does not recommend "
                    + "what, when, or where to administer."
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceXL + Theme.spaceL)
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationTitle("Today")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let log = undoLog,
               !log.isDeleted {
                undoBanner(log)
            }
        }
        .animation(
            reduceMotion
                ? nil
                : .snappy(duration: 0.3),
            value: undoLog?.id
        )
        .onDisappear {
            undoTask?.cancel()
        }
        .sensoryFeedback(
            .success,
            trigger: recordedCount
        ) { old, new in
            new > old
        }
        .sensoryFeedback(
            .selection,
            trigger: dropTarget
        ) { _, newValue in
            newValue != nil
        }
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                Button(
                    "Calculator",
                    systemImage: "function"
                ) {
                    calculator = true
                }

                Button(
                    "Settings",
                    systemImage: "gearshape"
                ) {
                    settings = true
                }
            }
        }
        .refreshable {
            store.refresh()
            store.resyncReminders()
        }
        .sheet(item: $target) { entry in
            DoseEditorView(
                revision: entry.revision,
                occurrence: entry,
                prefill: prefill
            )
        }
        .sheet(isPresented: $create) {
            ProtocolEditorView()
        }
        .sheet(isPresented: $settings) {
            SettingsView()
        }
        .sheet(isPresented: $addVial) {
            VialEditorView()
        }
        .sheet(isPresented: $calculator) {
            CalculatorView()
        }
        .sheet(isPresented: $shareCard) {
            ShareCardPreviewView(
                data:
                    store.insights[7]
                        .flatMap {
                            ShareCardData(
                                summary: $0,
                                window: 7
                            )
                        }
            )
        }
        .navigationDestination(
            isPresented: $inventory
        ) {
            InventoryView()
        }
        .trackingRoutes()
        .trackingErrors()
    }
}


// MARK: - Main sections

private extension TodayView {

    var todayEmptyState: some View {
        VStack(spacing: Theme.spaceM) {
            ContentUnavailableView {
                Label(
                    store.today.isEmpty
                        ? "Nothing scheduled today"
                        : "Today's entries are recorded",
                    systemImage:
                        store.today.isEmpty
                        ? "calendar"
                        : "checkmark.circle"
                )
            } description: {
                Text(
                    store.protocols.isEmpty
                        ? "Add an existing protocol to populate Today."
                        : "Your recorded schedule is clear for today."
                )
            } actions: {
                if store.protocols.isEmpty {
                    Button("Add protocol") {
                        create = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.ink)
                }
            }

            if !store.today.isEmpty,
               !store.isDemo {
                Button {
                    shareCard = true
                } label: {
                    Label(
                        "Share this week",
                        systemImage: "square.and.arrow.up"
                    )
                }
                .buttonStyle(.bordered)
                .tint(Theme.ink)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spaceS)
    }


    var demoCard: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Label(
                "Sample records",
                systemImage: "eye"
            )
            .font(Theme.sectionTitle)

            Text(
                "Sample records stay isolated and are never saved "
                + "to your history."
            )
            .font(Theme.body)
            .foregroundStyle(.secondary)

            Button("Set up your protocol") {
                store.exitDemo()
                create = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.ink)
        }
        .padding(Theme.spaceM)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
    }


    var addFirstVialCard: some View {
        Button {
            addVial = true
        } label: {
            HStack(spacing: Theme.spaceM) {
                Image(systemName: "shippingbox")
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.teal)
                    .frame(width: 28)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Add your first vial")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)

                    Text(
                        "Track inventory and get low-balance context."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: Theme.spaceS)

                Image(systemName: "chevron.right")
                    .font(Theme.micro)
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.spaceM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
    }


    var todayEntriesSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            HStack {
                Text("Today")
                    .font(Theme.sectionTitle)

                Spacer()

                Text(
                    "\(recordedCount) / \(store.today.count) logged"
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }

            VStack(spacing: 0) {
                ForEach(
                    Array(
                        remainingTodayEntries.enumerated()
                    ),
                    id: \.element.id
                ) { index, entry in
                    entryRow(entry)
                        .draggable(entry.id)
                        .background(
                            dropTarget == entry.id
                                ? Theme.tealTint
                                : Color.clear
                        )
                        .overlay(
                            alignment:
                                dropAfter
                                ? .bottom
                                : .top
                        ) {
                            insertionLine(
                                for: entry
                            )
                        }
                        .overlay {
                            GeometryReader { _ in
                                VStack(spacing: 0) {
                                    Color.clear
                                        .contentShape(.rect)
                                        .dropDestination(
                                            for: String.self
                                        ) { payload, _ in
                                            dropOnEntry(
                                                payload,
                                                anchorID: entry.id,
                                                after: false
                                            )
                                            return true
                                        } isTargeted: {
                                            hover(
                                                entry.id,
                                                isBottom: false,
                                                active: $0
                                            )
                                        }

                                    Color.clear
                                        .contentShape(.rect)
                                        .dropDestination(
                                            for: String.self
                                        ) { payload, _ in
                                            dropOnEntry(
                                                payload,
                                                anchorID: entry.id,
                                                after: true
                                            )
                                            return true
                                        } isTargeted: {
                                            hover(
                                                entry.id,
                                                isBottom: true,
                                                active: $0
                                            )
                                        }
                                }
                            }
                        }
                        .accessibilityAction(
                            named: Text("Move up")
                        ) {
                            shift(entry, by: -1)
                        }
                        .accessibilityAction(
                            named: Text("Move down")
                        ) {
                            shift(entry, by: 1)
                        }

                    if index < remainingTodayEntries.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .padding(.horizontal, Theme.spaceM)
            .background(
                Theme.surface,
                in: .rect(
                    cornerRadius: Theme.radiusCard
                )
            )
            .animation(
                reduceMotion
                    ? nil
                    : .easeIn(duration: 0.15),
                value: dropTarget
            )
        }
    }


    var summaryTiles: some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceXS
        ) {
            if let log = lastRecordedLog {
                NavigationLink(
                    value:
                        TrackingRoute
                            .logDetail(log.id)
                ) {
                    summaryTile(
                        title: "Last entry",
                        value: relativeDate(log.loggedAt),
                        detail:
                            log.actualAmountText
                            + " "
                            + log.unitText
                    )
                }
                .buttonStyle(.plain)
            }

            if let vial = activeVial {
                NavigationLink {
                    InventoryView()
                } label: {
                    let balance =
                        store.balances[
                            vial.id
                        ] ?? 0

                    let remaining =
                        store
                            .scheduledEntriesRemaining(
                                in: vial
                            )

                    summaryTile(
                        title: "Vial inventory",
                        value:
                            DoseCalculator.text(
                                balance
                            )
                            + " mg",
                        detail:
                            remaining.map {
                                "~\($0) entries"
                            }
                            ?? "Open inventory"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }


    func summaryTile(
        title: String,
        value: String,
        detail: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXXS
        ) {
            Text(title)
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )

            HStack(
                alignment: .firstTextBaseline
            ) {
                Text(value)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(
                        Theme.ink
                    )
                    .lineLimit(1)

                Spacer(
                    minLength:
                        Theme.spaceXXS
                )

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.muted
                )
            }

            Text(detail)
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )
                .lineLimit(1)
        }
        .padding(Theme.spaceM)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius:
                    Theme.radiusRow
            )
        )
        .inkBorder(
            cornerRadius:
                Theme.radiusRow
        )
    }


    var lastRecordedLog: DoseLog? {
        store.logs
            .filter {
                !$0.isDeleted
            }
            .sorted {
                $0.loggedAt
                    > $1.loggedAt
            }
            .first
    }


    var activeVial: VialRecord? {
        store.vials.first {
            !$0.isArchived
        }
    }


    func relativeDate(
        _ date: Date
    ) -> String {
        let calendar =
            Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let days =
            calendar.dateComponents(
                [.day],
                from:
                    calendar
                        .startOfDay(
                            for: date
                        ),
                to:
                    calendar
                        .startOfDay(
                            for: .now
                        )
            ).day ?? 0

        if days > 0,
           days < 30 {
            return "\(days) days ago"
        }

        return date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }


    var inventoryRow: some View {
        Button {
            inventory = true
        } label: {
            HStack(spacing: Theme.spaceM) {
                Image(systemName: "shippingbox")
                    .foregroundStyle(Theme.teal)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Vial inventory")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)

                    Text(inventorySummary)
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.micro)
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.spaceM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
    }


    var inventorySummary: String {
        let active =
            store.vials.filter {
                !$0.isArchived
            }

        let attention =
            active.filter {
                ["Low recorded balance", "Depleted"]
                    .contains(
                        store.vialStatus($0)
                    )
            }.count

        if attention > 0 {
            return
                "\(active.count) "
                + (
                    active.count == 1
                    ? "vial"
                    : "vials"
                )
                + " · \(attention) need attention"
        }

        return
            "\(active.count) "
            + (
                active.count == 1
                ? "active vial"
                : "active vials"
            )
    }
}


// MARK: - Hero

private extension TodayView {

    @ViewBuilder
    func nextEntryHero(
        _ next: ScheduledEntry
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            HStack {
                Eyebrow(
                    text: "Next entry",
                    onDark: true
                )

                Spacer()

                dueTag(for: next)
            }

            Text(next.revision.compoundName)
                .font(Theme.sectionTitle)
                .foregroundStyle(.white)

            if usesStackedHero {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
                    heroDose(next)
                    heroTime(next)
                }
            } else {
                HStack(
                    alignment: .firstTextBaseline,
                    spacing: Theme.spaceXS
                ) {
                    heroDose(next)

                    Spacer()

                    heroTime(next)
                }
            }

            Label(
                next.revision.protocolName,
                systemImage: "list.bullet.rectangle"
            )
            .font(Theme.body)
            .foregroundStyle(
                Color.white.opacity(0.72)
            )

            Divider()
                .overlay(
                    Color.white.opacity(0.14)
                )

            vialAction(next)

            Button {
                logAsScheduled(next)
            } label: {
                Label(
                    "Log entry",
                    systemImage: "checkmark"
                )
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle(
                    inverted: true
                )
            )

            Button {
                open(
                    next,
                    prefill:
                        repeatDraft(for: next)
                )
            } label: {
                Label(
                    "Adjust details",
                    systemImage:
                        "slider.horizontal.3"
                )
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle(
                    onDark: true
                )
            )
        }
        .padding(Theme.spaceL)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            Theme.ink,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
    }


    @ViewBuilder
    func vialAction(
        _ next: ScheduledEntry
    ) -> some View {
        if let vial =
            store.vial(
                next.revision.vialID
            ) {
            Button {
                open(next)
            } label: {
                HStack(spacing: Theme.spaceS) {
                    Image(
                        systemName: "cross.vial"
                    )

                    Text(vial.name)
                        .lineLimit(1)

                    Spacer()

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                }
                .font(Theme.body)
                .foregroundStyle(
                    Color.white.opacity(0.82)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

        } else {
            Button {
                if store.vials.isEmpty {
                    addVial = true
                } else {
                    open(next)
                }
            } label: {
                HStack(spacing: Theme.spaceS) {
                    Image(
                        systemName: "cross.vial"
                    )

                    Text("Add or select vial")

                    Spacer()

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                }
                .font(Theme.label)
                .foregroundStyle(
                    Color.white.opacity(0.9)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }


    func heroDose(
        _ next: ScheduledEntry
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceXXS
        ) {
            Text(next.revision.amountText)
                .font(Theme.metric)
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(next.revision.unitText)
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Color.white.opacity(0.68)
                )
        }
    }


    func heroTime(
        _ next: ScheduledEntry
    ) -> some View {
        Text(next.at, style: .time)
            .font(Theme.sectionTitle)
            .monospacedDigit()
            .foregroundStyle(
                Color.white.opacity(0.94)
            )
    }


    func dueTag(
        for entry: ScheduledEntry
    ) -> some View {
        let text = dueText(for: entry)

        return Label(
            text,
            systemImage: "clock"
        )
        .font(Theme.micro)
        .foregroundStyle(
            text == "Overdue"
                ? Theme.amber
                : Color.white.opacity(0.76)
        )
        .padding(
            .horizontal,
            Theme.spaceXS
        )
        .padding(
            .vertical,
            Theme.spaceXXS
        )
        .background(
            Color.white.opacity(0.12),
            in: .capsule
        )
    }


    func dueText(
        for entry: ScheduledEntry
    ) -> String {
        let seconds =
            entry.at.timeIntervalSince(.now)

        if seconds < -15 * 60 {
            return "Overdue"
        }

        if seconds <= 15 * 60 {
            return "Due now"
        }

        if seconds < 60 * 60 {
            return
                "In "
                + String(
                    max(
                        1,
                        Int(
                            seconds / 60
                        )
                    )
                )
                + " min"
        }

        if seconds < 24 * 60 * 60 {
            return
                "In "
                + String(
                    max(
                        1,
                        Int(
                            seconds / 3600
                        )
                    )
                )
                + " hr"
        }

        return entry.at.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
}


// MARK: - Entry rows

private extension TodayView {

    @ViewBuilder
    func entryRow(
        _ entry: ScheduledEntry
    ) -> some View {
        HStack(spacing: Theme.spaceS) {
            statusSymbol(for: entry)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(
                    entry.revision.compoundName
                        + " "
                        + entry.revision.amountText
                        + " "
                        + entry.revision.unitText
                )
                .font(Theme.label)

                Text(
                    entry.at.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                    + " · "
                    + entry.revision.protocolName
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }

            Spacer()

            if let log = entry.log {
                StatusBadge(text: log.status)
            } else {
                Button("Log") {
                    open(entry)
                }
                .buttonStyle(.bordered)
                .tint(Theme.ink)
                .controlSize(.small)
            }
        }
        .padding(.vertical, Theme.spaceS)
    }


    @ViewBuilder
    func statusSymbol(
        for entry: ScheduledEntry
    ) -> some View {
        let recorded = entry.log != nil

        Image(
            systemName:
                recorded
                ? "checkmark.circle.fill"
                : "circle"
        )
        .font(Theme.sectionTitle)
        .foregroundStyle(
            recorded
                ? Theme.teal
                : Theme.line
        )
        .animation(
            reduceMotion
                ? nil
                : .snappy(duration: 0.25),
            value: entry.log?.id
        )
    }


    @ViewBuilder
    func insertionLine(
        for entry: ScheduledEntry
    ) -> some View {
        if dropTarget == entry.id {
            Capsule()
                .fill(Theme.teal)
                .frame(height: 2)
                .padding(
                    .horizontal,
                    Theme.spaceXS
                )
                .transition(.opacity)
        }
    }


    func hover(
        _ id: String,
        isBottom: Bool,
        active: Bool
    ) {
        if active {
            dropTarget = id
            dropAfter = isBottom
        } else if dropTarget == id {
            dropTarget = nil
        }
    }


    func dropOnEntry(
        _ payload: [String],
        anchorID: String,
        after: Bool
    ) {
        guard let draggedID =
            payload.first
        else {
            return
        }

        withAnimation(
            reduceMotion
                ? nil
                : .snappy(duration: 0.3)
        ) {
            if store.moveTodayEntry(
                draggedID,
                relativeTo: anchorID,
                after: after
            ) {
                Haptics.impact()
            }
        }

        dropTarget = nil
    }


    func shift(
        _ entry: ScheduledEntry,
        by delta: Int
    ) {
        withAnimation(
            reduceMotion
                ? nil
                : .snappy(duration: 0.3)
        ) {
            if store.moveTodayEntry(
                entry.id,
                by: delta
            ) {
                Haptics.selection()
            }
        }
    }
}


// MARK: - Actions

private extension TodayView {

    func open(
        _ entry: ScheduledEntry,
        prefill draft: DoseDraft? = nil
    ) {
        prefill = draft
        target = entry
    }


    func logAsScheduled(
        _ entry: ScheduledEntry
    ) {
        guard entry.log == nil else {
            return
        }

        if store.saveDose(
            DoseDraft(
                revision: entry.revision
            ),
            revision: entry.revision,
            occurrence: entry,
            correcting: nil
        ),
           let log =
            store.logs.first(
                where: {
                    $0.occurrenceID
                        == entry.id
                }
            ) {
            undoLog = log
        }
    }


    func undoBanner(
        _ log: DoseLog
    ) -> some View {
        HStack(spacing: Theme.spaceS) {
            Image(
                systemName:
                    "checkmark.circle.fill"
            )
            .foregroundStyle(Theme.teal)

            Text(
                "Logged · "
                + log.compoundName
            )
            .font(
                .subheadline.weight(
                    .medium
                )
            )
            .lineLimit(1)

            Spacer(
                minLength: Theme.spaceXS
            )

            Button("Undo") {
                if store.deleteDose(log) {
                    undoLog = nil
                    Haptics.impact()
                }
            }
            .font(
                .subheadline.weight(
                    .semibold
                )
            )
            .foregroundStyle(Theme.teal)
            .frame(minHeight: 44)
        }
        .padding(
            .horizontal,
            Theme.spaceM
        )
        .padding(
            .vertical,
            Theme.spaceXS
        )
        .background(
            .regularMaterial,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
        .quietElevation()
        .padding(
            .horizontal,
            Theme.spaceL
        )
        .padding(
            .bottom,
            Theme.spaceXS
        )
        .transition(
            reduceMotion
                ? .opacity
                : .opacity.combined(
                    with:
                        .move(
                            edge: .bottom
                        )
                )
        )
        .onAppear {
            scheduleUndoDismiss()
        }
    }


    func scheduleUndoDismiss() {
        undoTask?.cancel()

        undoTask = Task {
            try? await Task.sleep(
                for: .seconds(4)
            )

            guard !Task.isCancelled else {
                return
            }

            undoLog = nil
        }
    }


    func repeatDraft(
        for entry: ScheduledEntry
    ) -> DoseDraft? {
        guard entry.revision.vialID == nil else {
            return nil
        }

        let last =
            store.logs.first {
                $0.compoundID
                    == entry.revision.compoundID
                    && $0.status
                    != "Skipped"
            }

        guard let last else {
            return nil
        }

        let draft =
            DoseDraft.repeatLast(
                revision: entry.revision,
                last: last,
                candidateVial:
                    last.vialID.flatMap {
                        store.vial($0)
                    }
            )

        return
            draft.vialID == nil
            ? nil
            : draft
    }
}

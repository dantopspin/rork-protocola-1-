import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var target: ScheduledEntry?
    @State private var manualRevision: ScheduleRevision?
    @State private var prefill: DoseDraft?
    @State private var create = false
    @State private var settings = false
    @State private var inventory = false
    @State private var addVial = false
    @State private var calculator = false
    @State private var stackCalendar = false
    @State private var shareCard = false
    @State private var undoLog: DoseLog?
    @State private var undoTask: Task<Void, Never>?
    @State private var dropTarget: String?
    @State private var dropAfter = false

    private var resolvedCount: Int {
        store.today.filter {
            $0.log != nil
        }.count
    }

    private var asNeededRevisions: [ScheduleRevision] {
        store.revisions.filter {
            $0.enabled
            && $0.effectiveUntil == nil
            && $0.config?.kind == .asRecorded
            && store.canTrack($0.protocolID)
        }
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
                } else if store.today.isEmpty,
                          let cycle = offCycleContext {
                    offCycleCard(cycle)
                } else {
                    todayEmptyState
                }

                if !asNeededRevisions.isEmpty {
                    asNeededSection
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
                .foregroundStyle(Theme.textSecondary)
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
            trigger: resolvedCount
        ) { old, new in
            new > old
        }
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                Button(
                    "Stack calendar",
                    systemImage: "calendar"
                ) {
                    stackCalendar = true
                }

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
        .sheet(item: $manualRevision) {
            revision in

            DoseEditorView(
                revision: revision
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
        .sheet(
            isPresented: $stackCalendar
        ) {
            StackCalendarView()
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
            if store.protocols.isEmpty {
                TrackingEmptyState(
                    icon: "calendar",
                    title: "Nothing scheduled today",
                    message:
                        "Add an existing protocol to populate Today.",
                    actionTitle: "Add protocol"
                ) {
                    create = true
                }

            } else {
                TrackingEmptyState(
                    icon:
                        store.today.isEmpty
                        ? "calendar"
                        : "checkmark.circle",
                    title:
                        store.today.isEmpty
                        ? "Nothing scheduled today"
                        : "Today's entries are recorded",
                    message:
                        !asNeededRevisions.isEmpty
                        ? "No scheduled entries. As-needed protocols are available below."
                        : "Your recorded schedule is clear for today."
                )
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
                .buttonStyle(TrackingCompactButtonStyle())
                .tint(Theme.ink)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spaceS)
    }


    var asNeededSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Text("As needed")
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.ink
                )

            VStack(spacing: 0) {
                ForEach(
                    Array(
                        asNeededRevisions
                            .enumerated()
                    ),
                    id: \.element.id
                ) { index, revision in
                    HStack(
                        spacing: Theme.spaceS
                    ) {
                        VStack(
                            alignment: .leading,
                            spacing:
                                Theme.spaceXXS
                        ) {
                            Text(
                                revision
                                    .compoundName
                            )
                            .font(Theme.label)
                            .foregroundStyle(
                                Theme.ink
                            )

                            Text(
                                revision.amountText
                                + " "
                                + revision.unitText
                                + " · "
                                + revision.routeText
                            )
                            .font(Theme.caption)
                            .foregroundStyle(
                                Theme.muted
                            )
                        }

                        Spacer()

                        Button("Log") {
                            manualRevision =
                                revision
                        }
                        .buttonStyle(TrackingCompactButtonStyle())
                        .tint(Theme.ink)
                        .controlSize(.small)
                    }
                    .padding(
                        .vertical,
                        Theme.spaceS
                    )

                    if index
                        < asNeededRevisions
                            .count - 1 {
                        Divider()
                    }
                }
            }
            .padding(
                .horizontal,
                Theme.spaceM
            )
            .background(
                Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusCard
                )
            )
            .inkBorder(
                cornerRadius:
                    Theme.radiusCard
            )
        }
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
            .foregroundStyle(Theme.textSecondary)

            Button("Set up your protocol") {
                store.exitDemo()
                create = true
            }
            .buttonStyle(TrackingCompactButtonStyle(prominent: true))
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
                    .frame(width: Theme.iconLarge)

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
                    .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: Theme.spaceS)

                Image(systemName: "chevron.right")
                    .font(Theme.micro)
                    .foregroundStyle(Theme.textTertiary)
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
                    "\(resolvedCount) / \(store.today.count) resolved"
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
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
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.micro)
                    .foregroundStyle(Theme.textTertiary)
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
                .foregroundStyle(Theme.onDarkPrimary)

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
                Theme.onDarkPrimary.opacity(0.72)
            )

            Divider()
                .overlay(
                    Theme.onDarkPrimary.opacity(0.14)
                )

            if next.revision.route
                .usesInjectionSite {
                vialAction(next)
            } else {
                HStack(
                    spacing: Theme.spaceS
                ) {
                    Image(
                        systemName:
                            "arrow.triangle.branch"
                    )

                    Text(
                        next.revision
                            .routeText
                    )

                    Spacer()
                }
                .font(Theme.body)
                .foregroundStyle(
                    Theme.onDarkPrimary.opacity(0.72)
                )
            }

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

            Button("Skip this entry") {
                skipEntry(next)
            }
            .font(Theme.caption)
            .foregroundStyle(
                Theme.onDarkPrimary.opacity(0.62)
            )
            .frame(
                maxWidth: .infinity,
                minHeight:
                    Theme.minimumTapTarget
            )
            .buttonStyle(.plain)
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


    func offCycleCard(
        _ context: CycleOffContext
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            HStack {
                Text("Off period")
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )

                Spacer()

                StatusBadge(
                    text: "OFF"
                )
            }

            Text(
                context.revision
                    .compoundName
            )
            .font(Theme.sectionTitle)
            .foregroundStyle(
                Theme.ink
            )

            Text(
                CycleDisplay.status(
                    context.config
                )
                ?? "Cycle is paused"
            )
            .font(Theme.body)
            .foregroundStyle(
                Theme.muted
            )

            Text(
                "No scheduled entries are generated during the recorded OFF period."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.muted
            )
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
                    Theme.radiusCard
            )
        )
        .inkBorder(
            cornerRadius:
                Theme.radiusCard
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
                    .font(Theme.micro)
                }
                .font(Theme.body)
                .foregroundStyle(
                    Theme.onDarkPrimary.opacity(0.82)
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
                    .font(Theme.micro)
                }
                .font(Theme.label)
                .foregroundStyle(
                    Theme.onDarkPrimary.opacity(0.9)
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
                .foregroundStyle(Theme.onDarkPrimary)

            Text(next.revision.unitText)
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.onDarkPrimary.opacity(0.68)
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
                Theme.onDarkPrimary.opacity(0.94)
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
                : Theme.onDarkPrimary.opacity(0.76)
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
            Theme.onDarkPrimary.opacity(0.12),
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
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
            }

            Spacer()

            if let log = entry.log {
                StatusBadge(text: log.status)
            } else {
                Button("Log") {
                    open(entry)
                }
                .buttonStyle(TrackingCompactButtonStyle())
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
                .frame(height: Theme.insertionLineHeight)
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
            store.moveTodayEntry(
                draggedID,
                relativeTo: anchorID,
                after: after
            )
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
            store.moveTodayEntry(
                entry.id,
                by: delta
            )
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


    func skipEntry(
        _ entry: ScheduledEntry
    ) {
        guard entry.log == nil else {
            return
        }

        var draft =
            DoseDraft(
                revision:
                    entry.revision
            )

        draft.status = "Skipped"
        draft.vialID = nil
        draft.site = ""
        draft.symptoms = ""
        draft.notes = ""

        if store.saveDose(
            draft,
            revision:
                entry.revision,
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
                    log.status == "Skipped"
                    ? "xmark.circle.fill"
                    : "checkmark.circle.fill"
            )
            .foregroundStyle(
                log.status == "Skipped"
                    ? Theme.muted
                    : Theme.teal
            )

            Text(
                (
                    log.status == "Skipped"
                    ? "Skipped · "
                    : "Logged · "
                )
                + log.compoundName
            )
            .font(Theme.label)
            .lineLimit(1)

            Spacer(
                minLength: Theme.spaceXS
            )

            Button("Undo") {
                if store.deleteDose(log) {
                    undoLog = nil
                }
            }
            .font(Theme.label)
            .foregroundStyle(Theme.teal)
            .frame(minHeight: Theme.minimumTapTarget)
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


    var offCycleContext: CycleOffContext? {
        let candidates =
            store.revisions
                .filter {
                    $0.enabled
                    && $0.effectiveUntil
                        == nil
                    && store.canTrack(
                        $0.protocolID
                    )
                }

        for revision in candidates {
            guard
                let config =
                    revision.config,
                let phase =
                    config.cyclePhase(
                        at: .now
                    ),
                phase.state == .off
            else {
                continue
            }

            return CycleOffContext(
                revision: revision,
                config: config
            )
        }

        return nil
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


private struct CycleOffContext {
    let revision: ScheduleRevision
    let config: ScheduleConfig
}



// MARK: - Combined stack calendar

struct StackCalendarView: View {
    @Environment(TrackingStore.self)
    private var store
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var anchor = Date.now

    @State
    private var selectedDay =
        Calendar.current
            .startOfDay(for: .now)

    private var calendar:
        Calendar {
        Calendar.current
    }

    private var weekStart: Date {
        calendar
            .dateInterval(
                of: .weekOfYear,
                for: anchor
            )?
            .start
        ?? calendar
            .startOfDay(for: anchor)
    }

    private var weekEnd: Date {
        calendar.date(
            byAdding: .day,
            value: 7,
            to: weekStart
        ) ?? weekStart
    }

    private var weekDays: [Date] {
        (0..<7).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: weekStart
            )
        }
    }

    private var weekEntries:
        [ScheduledEntry] {
        store.entries(
            start: weekStart,
            end: weekEnd
        )
        .filter {
            store.canTrack(
                $0.revision.protocolID
            )
        }
    }

    private var selectedEntries:
        [ScheduledEntry] {
        weekEntries.filter {
            calendar.isDate(
                $0.at,
                inSameDayAs:
                    selectedDay
            )
        }
        .sorted {
            $0.at < $1.at
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceL
                ) {
                    weekNavigation
                    dayStrip

                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceM
                    ) {
                        Text(
                            selectedDay.formatted(
                                .dateTime
                                    .weekday(.wide)
                                    .month(.wide)
                                    .day()
                            )
                        )
                        .font(Theme.sectionTitle)
                        .foregroundStyle(
                            Theme.ink
                        )

                        if selectedEntries
                            .isEmpty {
                            TrackingEmptyState(
                                icon: "calendar",
                                title:
                                    "No scheduled entries",
                                message:
                                    "No recorded schedules create an entry on this day."
                            )
                        } else {
                            ForEach(
                                selectedEntries
                            ) { entry in
                                stackEntryCard(
                                    entry
                                )
                            }
                        }
                    }

                    Text(
                        "Combined calendar of your recorded schedules. It shows what you entered and does not recommend what or when to administer."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
                .screenPadding()
            }
            .background(Theme.paper)
            .navigationTitle(
                "Stack calendar"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {
                    Button("Today") {
                        anchor = .now
                        selectedDay =
                            calendar
                                .startOfDay(
                                    for: .now
                                )
                    }
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var weekNavigation:
        some View {
        HStack(
            spacing: Theme.spaceM
        ) {
            Button {
                moveWeek(-1)
            } label: {
                Image(
                    systemName:
                        "chevron.left"
                )
            }
            .accessibilityLabel(
                "Previous week"
            )

            Spacer()

            Text(weekRangeLabel)
                .font(Theme.label)
                .foregroundStyle(
                    Theme.ink
                )

            Spacer()

            Button {
                moveWeek(1)
            } label: {
                Image(
                    systemName:
                        "chevron.right"
                )
            }
            .accessibilityLabel(
                "Next week"
            )
        }
    }

    private var dayStrip: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(
                spacing: Theme.spaceXS
            ) {
                ForEach(
                    weekDays,
                    id: \.self
                ) { day in
                    dayButton(day)
                }
            }
        }
    }

    private func dayButton(
        _ day: Date
    ) -> some View {
        let selected =
            calendar.isDate(
                day,
                inSameDayAs:
                    selectedDay
            )
        let count =
            entries(on: day).count

        return Button {
            selectedDay = day
        } label: {
            VStack(
                spacing: Theme.spaceXXS
            ) {
                Text(
                    day.formatted(
                        .dateTime
                            .weekday(
                                .abbreviated
                            )
                    )
                )
                .font(Theme.micro)

                Text(
                    day.formatted(
                        .dateTime.day()
                    )
                )
                .font(Theme.sectionTitle)
                .monospacedDigit()

                Text(
                    count == 0
                        ? "—"
                        : String(count)
                )
                .font(Theme.caption)
                .monospacedDigit()
            }
            .foregroundStyle(
                selected
                    ? Theme.onDarkPrimary
                    : Theme.ink
            )
            .frame(
                minWidth:
                    Theme.calendarDayWidth,
                minHeight:
                    Theme.rowHeight
            )
            .padding(
                .vertical,
                Theme.spaceXS
            )
            .background(
                selected
                    ? Theme.ink
                    : Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusRow
                )
            )
            .overlay {
                if !selected {
                    RoundedRectangle(
                        cornerRadius:
                            Theme.radiusRow
                    )
                    .stroke(
                        Theme.hairline,
                        lineWidth: 1
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            day.formatted(
                .dateTime
                    .weekday(.wide)
                    .month(.wide)
                    .day()
            )
        )
        .accessibilityValue(
            count == 1
                ? "1 scheduled entry"
                : String(count)
                    + " scheduled entries"
        )
    }

    private func stackEntryCard(
        _ entry: ScheduledEntry
    ) -> some View {
        TrackingCard {
            HStack(
                alignment:
                    .firstTextBaseline,
                spacing: Theme.spaceS
            ) {
                VStack(
                    alignment: .leading,
                    spacing:
                        Theme.spaceXXS
                ) {
                    Text(
                        entry.at.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .monospacedDigit()

                    Text(
                        entry.revision
                            .compoundName
                    )
                    .font(
                        Theme.sectionTitle
                    )
                    .foregroundStyle(
                        Theme.ink
                    )
                }

                Spacer()

                StatusBadge(
                    text:
                        entry.log?.status
                        ?? "Scheduled"
                )
            }

            Text(
                entry.revision.protocolName
            )
            .font(Theme.body)
            .foregroundStyle(
                Theme.textSecondary
            )

            HStack(
                spacing: Theme.spaceS
            ) {
                Label(
                    entry.revision.amountText
                    + " "
                    + entry.revision.unitText,
                    systemImage:
                        "number"
                )

                Label(
                    entry.revision
                        .route.rawValue,
                    systemImage:
                        "arrow.right.circle"
                )
            }
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }

    private func entries(
        on day: Date
    ) -> [ScheduledEntry] {
        weekEntries.filter {
            calendar.isDate(
                $0.at,
                inSameDayAs: day
            )
        }
    }

    private var weekRangeLabel:
        String {
        guard
            let last =
                calendar.date(
                    byAdding: .day,
                    value: 6,
                    to: weekStart
                )
        else {
            return weekStart.formatted(
                date: .abbreviated,
                time: .omitted
            )
        }

        return
            weekStart.formatted(
                .dateTime
                    .month(.abbreviated)
                    .day()
            )
            + " – "
            + last.formatted(
                .dateTime
                    .month(.abbreviated)
                    .day()
            )
    }

    private func moveWeek(
        _ offset: Int
    ) {
        guard
            let next =
                calendar.date(
                    byAdding:
                        .weekOfYear,
                    value: offset,
                    to: anchor
                )
        else {
            return
        }

        anchor = next
        selectedDay =
            calendar
                .dateInterval(
                    of: .weekOfYear,
                    for: next
                )?
                .start
            ?? calendar
                .startOfDay(
                    for: next
                )
    }
}

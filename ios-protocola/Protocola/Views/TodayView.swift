import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

struct TodayView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @State private var notificationStatus: UNAuthorizationStatus?

    @State private var target: ScheduledEntry?
    @State private var manualRevision: ScheduleRevision?
    @State private var prefill: DoseDraft?
    @State private var create = false
    @State private var inventory = false
    @State private var addVial = false
    @State private var stackCalendar = false
    @State private var shareCard = false
    @State private var siteHistory = false
    @State private var editingSchedule: ScheduleRevision?
    @State private var undoLog: DoseLog?
    @State private var addingSite: DoseLog?
    @State private var undoTask: Task<Void, Never>?
    @State private var dropTarget: String?
    @State private var dropAfter = false

    private var resolvedCount: Int {
        store.today.filter {
            $0.log != nil
        }.count
    }

    func refreshNotificationStatus() async {
        notificationStatus =
            await UNUserNotificationCenter
                .current()
                .notificationSettings()
                .authorizationStatus
    }

    private var expectsReminders: Bool {
        store.today.contains { $0.revision.reminders }
        || nextUpcomingEntry?.revision.reminders == true
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

    private var entryBodyLayout: AnyLayout {
        usesStackedHero
            ? AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: Theme.spaceS
                )
            )
            : AnyLayout(
                HStackLayout(
                    alignment: .center,
                    spacing: Theme.spaceS
                )
            )
    }

    private var entryMetaLayout: AnyLayout {
        usesStackedHero
            ? AnyLayout(
                HStackLayout(
                    alignment: .center,
                    spacing: Theme.spaceS
                )
            )
            : AnyLayout(
                VStackLayout(
                    alignment: .trailing,
                    spacing: Theme.spaceXS
                )
            )
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                if store.isDemo {
                    // In content, not under the bar, so the large
                    // wordmark stays visible in demo mode.
                    DemoBanner()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: Theme.radiusRow,
                                style: .continuous
                            )
                        )
                }

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceL
                ) {
                    weekStrip

                    todayHeader
                }

                Group {
                    if !store.today.isEmpty {
                        todayList
                            .transition(.opacity)
                    } else if store.today.isEmpty,
                              let cycle = offCycleContext {
                        offCycleCard(cycle)
                            .transition(.opacity)
                    } else {
                        todayEmptyState
                            .transition(.opacity)
                    }
                }
                .trackingStateAnimation(
                    value:
                        nextUnloggedEntry?.id
                )

                if !store.protocols.isEmpty {
                    shortcutTiles
                }

                if let recap = weekRecap {
                    weekRecapCard(recap)
                }

                if !store.isDemo,
                   let status = notificationStatus,
                   RemindersOffBanner.isOff(
                       status,
                       expectsReminders: expectsReminders
                   ) {
                    RemindersOffBanner(
                        status: status,
                        refresh: refreshNotificationStatus
                    )
                }


                if !store.carriedOver.isEmpty {
                    missedSection
                }

                if !asNeededRevisions.isEmpty {
                    asNeededSection
                }

                if store.isDemo {
                    demoCard
                }

                if !store.isDemo,
                   !store.protocols.isEmpty,
                   store.vials.isEmpty,
                   nextUnloggedEntry?
                    .revision
                    .route
                    .usesInjectionSite != true {
                    addFirstVialCard
                }

                if lastRecordedLog != nil
                    || activeVial != nil {
                    summaryTiles
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Text(
                    "Your schedule, as recorded. Protocola does not recommend "
                    + "what, when, or where to administer."
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceXL)
        }
        .trackingScrollChrome()
        .background(Theme.paper)
        // Serif wordmark as the large title; the week strip opens the
        // calendar, so the bar keeps a single Settings button.
        .navigationTitle("Protocola")
        // The demo banner sits under the bar and blanks a large title,
        // so demo mode uses the inline wordmark.
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let log = undoLog,
               !log.isDeleted {
                undoBanner(log)
            }
        }
        .animation(
            reduceMotion
                ? nil
                : Theme.stateSpring,
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
        .sensoryFeedback(
            .selection,
            trigger: dropTarget
        ) { _, newValue in
            newValue != nil
        }
        .toolbar {
            SettingsToolbarItem(placement: .topBarTrailing)
        }
        .refreshable {
            store.refresh()
            store.resyncReminders()
        }
        .task {
            await refreshNotificationStatus()
            askForRatingIfEarned()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await refreshNotificationStatus() }
            }
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
        .sheet(
            item: $addingSite,
            onDismiss: { undoLog = nil }
        ) { log in
            DoseEditorView(correcting: log)
        }
        .sheet(isPresented: $addVial) {
            VialEditorView()
        }
        .sheet(
            isPresented: $stackCalendar
        ) {
            StackCalendarView()
        }
        .sheet(isPresented: $siteHistory) {
            InjectionSiteHistoryView(
                logs: siteLogs
            )
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
        .sheet(item: $editingSchedule) {
            revision in

            if let record =
                store.protocols.first(
                    where: {
                        $0.id
                            == revision.protocolID
                    }
                ) {
                ProtocolEditorView(
                    record: record,
                    revision: revision
                )
            } else {
                TrackingEmptyState(
                    icon: "calendar",
                    title: "Protocol unavailable",
                    message:
                        "This schedule can no longer be edited."
                )
                .screenPadding()
                .background(Theme.paper)
            }
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

    // MARK: - Today (cards)

    /// "Today" in the serif display face, with the date on the right.
    var todayHeader: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceS
        ) {
            Text("Today")
                .font(Theme.pageTitle)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: Theme.spaceS)

            Text(
                Date.now.formatted(
                    .dateTime
                        .weekday(.abbreviated)
                        .month(.abbreviated)
                        .day()
                )
            )
            .font(Theme.subheadline)
            .foregroundStyle(Theme.textSecondary)
        }
    }


    /// This week at a glance: today is the filled pill, and a dot marks
    /// each day with scheduled entries. Tapping opens the calendar.
    var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start =
            calendar.dateInterval(
                of: .weekOfYear,
                for: today
            )?.start ?? today
        let days = (0..<7).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: start
            )
        }
        let end =
            calendar.date(
                byAdding: .day,
                value: 7,
                to: start
            ) ?? start
        let scheduled =
            Set(
                store.entries(
                    start: start,
                    end: end
                ).map {
                    calendar.startOfDay(for: $0.at)
                }
            )

        return Button {
            stackCalendar = true
        } label: {
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let isToday =
                        calendar.isDate(
                            day,
                            inSameDayAs: today
                        )

                    VStack(spacing: Theme.spaceXXS) {
                        Text(
                            day.formatted(
                                .dateTime.weekday(
                                    usesStackedHero
                                    ? .narrow
                                    : .abbreviated
                                )
                            )
                        )
                        .font(Theme.chipLabel)
                        .lineLimit(1)

                        Text(
                            day.formatted(
                                .dateTime.day()
                            )
                        )
                        .font(Theme.cardTitle)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                        Circle()
                            .fill(
                                scheduled.contains(day)
                                    ? (
                                        isToday
                                        ? Theme.onDarkPrimary
                                        : Theme.textTertiary
                                    )
                                    : Color.clear
                            )
                            .frame(
                                width: Theme.statusDot,
                                height: Theme.statusDot
                            )
                    }
                    .foregroundStyle(
                        isToday
                            ? Theme.onDarkPrimary
                            : Theme.textSecondary
                    )
                    .padding(.vertical, Theme.spaceXS)
                    .frame(maxWidth: .infinity)
                    .background {
                        if isToday {
                            Capsule()
                                .fill(Theme.accentFill)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(TrackingCardButtonStyle())
        .accessibilityLabel("This week")
        .accessibilityHint("Opens the calendar.")
    }


    /// Every entry for today as a card, then the one action: Log a Dose.
    var todayList: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            VStack(spacing: Theme.spaceS) {
                ForEach(store.today) { entry in
                    entryCard(entry)
                }
            }

            if let next = nextUnloggedEntry {
                Button {
                    open(next)
                } label: {
                    Label(
                        "Log a Dose",
                        systemImage: "plus"
                    )
                }
                .buttonStyle(
                    TrackingPrimaryButtonStyle()
                )
            } else {
                resolvedDayState
            }
        }
    }


    func entryStatus(
        _ entry: ScheduledEntry
    ) -> String {
        if let log = entry.log {
            return log.status == "Skipped"
                ? "Skipped"
                : "Taken"
        }
        return entry.id == nextUnloggedEntry?.id
            ? "Due"
            : "Upcoming"
    }


    func entryStripe(
        _ status: String
    ) -> Color {
        switch status {
        case "Taken": Theme.teal
        case "Due": Theme.info
        default: Theme.inactiveFill
        }
    }


    @ViewBuilder
    func entryCard(
        _ entry: ScheduledEntry
    ) -> some View {
        let status = entryStatus(entry)
        let card = HStack(
            alignment: .center,
            spacing: Theme.spaceS
        ) {
            Capsule()
                .fill(entryStripe(status))
                .frame(width: Theme.entryStripeWidth)
                .frame(maxHeight: .infinity)

            entryBodyLayout {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text(entry.revision.compoundName)
                        .font(Theme.cardTitle)
                        .foregroundStyle(Theme.ink)

                    Text(entry.revision.protocolName)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)

                    Text(
                        DoseText.amount(
                            entry.revision.amountText,
                            entry.revision.unitText
                        )
                        + " · "
                        + entry.revision.routeText
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
                }

                if !usesStackedHero {
                    Spacer(minLength: Theme.spaceXS)
                }

                entryMetaLayout {
                    StatusBadge(text: status)

                    Text(
                        (entry.log?.loggedAt ?? entry.at)
                            .formatted(
                                date: .omitted,
                                time: .shortened
                            )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
                }

            }

            Image(systemName: "chevron.right")
                .font(Theme.micro)
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardInset)
        .background(
            Theme.surface,
            in: RoundedRectangle(
                cornerRadius: Theme.radiusRow,
                style: .continuous
            )
        )
        .quietElevation()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)

        if let log = entry.log {
            NavigationLink(
                value: TrackingRoute.logDetail(log.id)
            ) {
                card
            }
            .buttonStyle(TrackingCardButtonStyle())
        } else {
            Button {
                open(entry)
            } label: {
                card
            }
            .buttonStyle(TrackingCardButtonStyle())
            .accessibilityHint("Opens the log sheet.")
        }
    }


    var todayEmptyState: some View {
        Group {
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

            } else if store.today.isEmpty {
                TrackingEmptyState(
                    icon: "calendar",
                    title: "Nothing scheduled today",
                    message: emptyDayMessage
                )

            } else {
                resolvedDayState
            }
        }
    }


    /// The end-of-day state. It says honestly what happened today (logged,
    /// skipped, or both) and puts the next entry first, because that is the
    /// only thing left to act on.
    var resolvedDayState: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceL
        ) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Label {
                    Text(dayOutcome.title)
                        .foregroundStyle(Theme.ink)
                } icon: {
                    Image(
                        systemName:
                            dayOutcome.icon
                    )
                    .foregroundStyle(
                        dayOutcome.isPositive
                            ? Theme.teal
                            : Theme.textSecondary
                    )
                }
                .font(Theme.modalTitle)

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: Theme.spaceXS
                ) {
                    Text(dayOutcome.detail)
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    if let log = lastTakenTodayLog {
                        NavigationLink(
                            value:
                                TrackingRoute
                                    .logDetail(log.id)
                        ) {
                            Text("View")
                                .font(Theme.label)
                                .foregroundStyle(Theme.teal)
                                .frame(
                                    minHeight:
                                        Theme.minimumTapTarget
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(TrackingCardButtonStyle())
                        .accessibilityLabel("View entry")
                    }
                }
            }

            if let next = nextUpcomingEntry {
                upNextCard(next)
            }

            if !store.isDemo {
                Button {
                    shareCard = true
                } label: {
                    Label(
                        "Share this week",
                        systemImage:
                            "square.and.arrow.up"
                    )
                    .font(Theme.label)
                    .foregroundStyle(Theme.teal)
                    .frame(
                        minHeight:
                            Theme.minimumTapTarget,
                        alignment: .leading
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(TrackingCardButtonStyle())
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .vertical,
            Theme.spaceM
        )
    }


    /// The next scheduled entry, given the most visual weight on a finished day.
    func upNextCard(
        _ next: ScheduledEntry
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            HStack(
                alignment: .center,
                spacing: Theme.spaceS
            ) {
                Eyebrow(text: "Up next")

                Spacer()

                // A countdown only when it adds something; the day label
                // below already names dates further out.
                if next.at.timeIntervalSinceNow < 24 * 60 * 60 {
                    Text(dueText(for: next))
                        .font(Theme.micro)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(upcomingDayLabel(next.at))
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)

                Text(
                    next.at.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(Theme.metricCompact)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            }

            Text(
                DoseText.line(
                    compound:
                        next.revision.compoundName,
                    amount:
                        next.revision.amountText,
                    unit:
                        next.revision.unitText
                )
            )
            .font(Theme.label)
            .foregroundStyle(Theme.textSecondary)
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
        .accessibilityElement(children: .combine)
    }


    func upcomingDayLabel(
        _ date: Date
    ) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Later today"
        }

        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        return date.formatted(
            .dateTime.weekday(.wide).month(.abbreviated).day()
        )
    }


    struct DayOutcome {
        let icon: String
        let title: String
        let detail: String
        let isPositive: Bool
    }


    /// What actually happened today, in plain words. A skipped day is never
    /// presented as a success.
    var dayOutcome: DayOutcome {
        let taken =
            resolvedTodayLogs.filter {
                $0.status != "Skipped"
            }
        let skipped =
            resolvedTodayLogs.count - taken.count
        let time: (DoseLog?) -> String = {
            $0?.loggedAt.formatted(
                date: .omitted,
                time: .shortened
            ) ?? ""
        }

        if taken.isEmpty {
            return DayOutcome(
                icon: "forward.end.circle",
                title: "Nothing more today",
                detail:
                    skipped == 1
                    ? "You skipped today's entry. Nothing else is scheduled."
                    : "You skipped \(skipped) entries today. Nothing else is scheduled.",
                isPositive: false
            )
        }

        if skipped == 0 {
            return DayOutcome(
                icon: "checkmark.circle.fill",
                title: "All done for today",
                detail:
                    taken.count == 1
                    ? "Logged at " + time(lastTakenTodayLog) + "."
                    : "\(taken.count) entries logged. Last at " + time(lastTakenTodayLog) + ".",
                isPositive: true
            )
        }

        return DayOutcome(
            icon: "checkmark.circle",
            title: "Done for today",
            detail: "\(taken.count) logged · \(skipped) skipped.",
            isPositive: true
        )
    }


    var lastTakenTodayLog: DoseLog? {
        resolvedTodayLogs
            .filter { $0.status != "Skipped" }
            .max { $0.loggedAt < $1.loggedAt }
    }


    var resolvedTodayLogs: [DoseLog] {
        store.today.compactMap(\.log)
    }


    /// Always says when the next entry is, so a weekly or future-start
    /// protocol never looks like it wasn't saved.
    var emptyDayMessage: String {
        var parts: [String] = []

        if let next = nextUpcomingEntry {
            parts.append(
                "Next: "
                + next.revision.compoundName
                + ", "
                + next.at.formatted(
                    .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute()
                )
                + "."
            )
        } else if asNeededRevisions.isEmpty {
            parts.append("Your recorded schedule is clear for today.")
        }

        if !asNeededRevisions.isEmpty {
            parts.append("As-needed protocols are available below.")
        }

        return parts.joined(separator: " ")
    }


    var nextUpcomingEntry: ScheduledEntry? {
        let now = Date.now
        let end =
            Calendar.current.date(
                byAdding: .day,
                value: 90,
                to: now
            ) ?? now

        return store.entries(
            start: now,
            end: end
        )
        .first {
            $0.at > now
            && $0.log == nil
        }
    }


    var asNeededSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            Eyebrow(text: "As needed")

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
                                DoseText.line(
                                    compound:
                                        revision.compoundName,
                                    amount:
                                        revision.amountText,
                                    unit:
                                        revision.unitText
                                )
                            )
                            .font(Theme.cardTitle)
                            .foregroundStyle(
                                Theme.ink
                            )
                            .monospacedDigit()

                            Text(revision.routeText)
                            .font(Theme.caption)
                            .foregroundStyle(
                                Theme.textSecondary
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
                        Theme.rowPadding
                    )

                    if index
                        < asNeededRevisions
                            .count - 1 {
                        EditorialRule()
                    }
                }
            }
            .padding(.horizontal, Theme.cardInset)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
        }
    }


    var demoCard: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            Eyebrow(text: "Sample records")

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
        .padding(
            .vertical,
            Theme.spaceM
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.horizontal, Theme.cardInset)
        .background(
            Theme.surface,
            in: .rect(cornerRadius: Theme.radiusCard)
        )
        .quietElevation()
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
                        .font(Theme.cardTitle)
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
            .padding(
                .vertical,
                Theme.rowPadding
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(TrackingCardButtonStyle())
        .padding(.horizontal, Theme.cardInset)
        .background(
            Theme.surface,
            in: .rect(cornerRadius: Theme.radiusCard)
        )
        .quietElevation()
    }


    func missedDayLabel(_ date: Date) -> String {
        Calendar.current.isDateInYesterday(date)
            ? "Yesterday"
            : date.formatted(
                .dateTime.weekday(.abbreviated).month(.abbreviated).day()
            )
    }


    /// Unrecorded entries from the past week. Logging defaults the recorded
    /// time to the scheduled time, which the editor lets the person change.
    var missedRowLayout: AnyLayout {
        usesStackedHero
            ? AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: Theme.spaceS
                )
            )
            : AnyLayout(
                HStackLayout(spacing: Theme.spaceS)
            )
    }


    var missedSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            HStack {
                Eyebrow(text: "Not recorded")

                Spacer()

                Text(
                    String(store.carriedOver.count)
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
            }

            VStack(spacing: 0) {
                ForEach(
                    Array(
                        store.carriedOver.enumerated()
                    ),
                    id: \.element.id
                ) { index, entry in
                    missedRowLayout {
                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceXXS
                        ) {
                            // Name on one line, details on the next, so the
                            // dose never wraps onto a line of its own.
                            Text(entry.revision.compoundName)
                                .font(Theme.cardTitle)
                                .foregroundStyle(Theme.ink)

                            Text(
                                entry.revision.amountText
                                + " "
                                + entry.revision.unitText
                                + " · "
                                + missedDayLabel(entry.at)
                                + ", "
                                + entry.at.formatted(
                                    date: .omitted,
                                    time: .shortened
                                )
                            )
                            .font(Theme.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .monospacedDigit()
                        }

                        if !usesStackedHero {
                            Spacer(minLength: Theme.spaceXS)
                        }

                        // At accessibility sizes the buttons move under the
                        // text so the name never breaks mid-word.
                        HStack(spacing: Theme.spaceS) {
                        Button("Skip") {
                            skipEntry(entry)
                        }
                        .buttonStyle(TrackingCompactButtonStyle())
                        .accessibilityLabel(
                            "Skip "
                            + entry.revision.compoundName
                            + " from "
                            + missedDayLabel(entry.at)
                        )

                        Button("Log") {
                            var draft =
                                DoseDraft(
                                    revision:
                                        entry.revision
                                )
                            draft.loggedAt = entry.at
                            open(entry, prefill: draft)
                        }
                        .buttonStyle(
                            TrackingCompactButtonStyle(
                                prominent: true
                            )
                        )
                        .accessibilityLabel(
                            "Log "
                            + entry.revision.compoundName
                            + " from "
                            + missedDayLabel(entry.at)
                        )
                        }
                    }
                    .padding(.vertical, Theme.rowPadding)

                    if index < store.carriedOver.count - 1 {
                        EditorialRule()
                    }
                }
            }
            .padding(.horizontal, Theme.cardInset)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
        }
    }


    var todayEntriesSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            HStack {
                Eyebrow(text: "Today")

                Spacer()

                Text(
                    "\(resolvedCount) of \(store.today.count) done"
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
                        EditorialRule()
                    }
                }
            }
            .padding(.horizontal, Theme.cardInset)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
            .animation(
                reduceMotion
                    ? nil
                    : Theme.pressSpring,
                value: dropTarget
            )
        }
    }


    /// Logs that carry an injection site, for the Sites shortcut.
    var siteLogs: [DoseLog] {
        store.logs.filter {
            !$0.isDeleted
            && $0.route.usesInjectionSite
            && $0.status != "Skipped"
            && !$0.site
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }
    }


    var shortcutTiles: some View {
        let tileCount =
            1
            + (siteLogs.isEmpty ? 0 : 1)
            + (store.isDemo ? 0 : 1)
        let columns =
            Array(
                repeating:
                    GridItem(
                        .flexible(),
                        spacing: Theme.spaceS
                    ),
                count: usesStackedHero ? 2 : tileCount
            )

        return LazyVGrid(
            columns: columns,
            spacing: Theme.spaceS
        ) {
            shortcutTile("Calendar", icon: "calendar") {
                stackCalendar = true
            }

            if !siteLogs.isEmpty {
                shortcutTile("Sites", icon: "figure.stand") {
                    siteHistory = true
                }
            }

            if !store.isDemo {
                shortcutTile("Share", icon: "square.and.arrow.up") {
                    shareCard = true
                }
            }
        }
    }


    func shortcutTile(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.spaceXS) {
                Image(systemName: icon)
                    .font(Theme.label)
                    .foregroundStyle(Theme.teal)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spaceM)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusRow)
            )
            .quietElevation()
            .contentShape(Rectangle())
        }
        .buttonStyle(TrackingCardButtonStyle())
    }


    var summaryTiles: some View {
        let layout =
            usesStackedHero
            ? AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: Theme.sectionHeaderGap
                )
            )
            : AnyLayout(
                HStackLayout(
                    alignment: .top,
                    spacing: Theme.spaceS
                )
            )

        return layout {
            if let log = lastRecordedLog {
                NavigationLink(
                    value:
                        TrackingRoute
                            .logDetail(log.id)
                ) {
                    summaryTile(
                        title: "Last entry",
                        icon: "clock.arrow.circlepath",
                        value: relativeDate(log.loggedAt),
                        detail:
                            DoseText.amount(
                                log.actualAmountText,
                                log.unitText
                            )
                    )
                }
                .buttonStyle(TrackingCardButtonStyle())
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
                        title: "Vial",
                        icon: "testtube.2",
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
                .buttonStyle(TrackingCardButtonStyle())
            }
        }
    }


    func summaryTile(
        title: String,
        icon: String,
        value: String,
        detail: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            HStack(spacing: Theme.spaceXS) {
                Image(systemName: icon)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.teal)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Spacer(minLength: Theme.spaceXXS)

                Image(systemName: "chevron.right")
                    .font(Theme.micro)
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }

            Text(value)
                .font(Theme.metricCompact)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .monospacedDigit()

            Text(detail)
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .padding(Theme.cardInset)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            Theme.surface,
            in: .rect(cornerRadius: Theme.radiusCard)
        )
        .quietElevation()
    }


    /// The last dose actually taken. Skips are not doses, so they never
    /// appear here as "0 mg".
    var lastRecordedLog: DoseLog? {
        store.logs
            .filter {
                !$0.isDeleted
                && $0.status != "Skipped"
            }
            .sorted {
                $0.loggedAt
                    > $1.loggedAt
            }
            .first
    }


    struct WeekRecap {
        let recorded: Int
        let scheduled: Int
        let skipped: Int
        let vialLine: String?
    }

    /// Shown on Sunday and Monday: the week as recorded. Facts only.
    var weekRecap: WeekRecap? {
        let weekday = Calendar.current.component(.weekday, from: .now)
        guard
            weekday == 1 || weekday == 2,
            let week = store.insights[7],
            week.scheduled > 0
        else {
            return nil
        }
        let start =
            Calendar.current.date(
                byAdding: .day,
                value: -7,
                to: .now
            ) ?? .now
        let skipped =
            store.logs.filter {
                !$0.isDeleted
                && $0.status == "Skipped"
                && $0.loggedAt >= start
            }.count
        let vialLine: String? =
            activeVial.flatMap { vial in
                store.estimatedDepletionDate(in: vial).map { date in
                    let days =
                        max(
                            0,
                            Calendar.current.dateComponents(
                                [.day],
                                from: .now,
                                to: date
                            ).day ?? 0
                        )
                    return vial.name + ": about "
                        + (
                            days >= 14
                            ? String(days / 7) + " weeks"
                            : String(days) + (days == 1 ? " day" : " days")
                        )
                        + " left"
                }
            }
        return WeekRecap(
            recorded: week.recorded,
            scheduled: week.scheduled,
            skipped: skipped,
            vialLine: vialLine
        )
    }

    func weekRecapCard(
        _ recap: WeekRecap
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Label("Your week", systemImage: "calendar.badge.checkmark")
                .font(Theme.label)
                .foregroundStyle(Theme.ink)

            Text(
                "\(recap.recorded) of \(recap.scheduled) entries recorded"
                + (recap.skipped > 0 ? " · \(recap.skipped) skipped" : "")
            )
            .font(Theme.serifTitle)
            .foregroundStyle(Theme.ink)
            .monospacedDigit()

            if let vialLine = recap.vialLine {
                Text(vialLine)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(Theme.cardInset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.surface,
            in: .rect(cornerRadius: Theme.radiusCard)
        )
        .quietElevation()
        .accessibilityElement(children: .combine)
    }

    /// Asks for an App Store rating after a fully recorded week, at most
    /// once every 120 days. Apple also caps the prompt itself.
    func askForRatingIfEarned() {
        let key = "protocola.lastRatingRequest"
        guard
            !store.isDemo,
            let week = store.insights[7],
            week.fullyRecorded,
            week.scheduled >= 3
        else {
            return
        }
        let last =
            UserDefaults.standard.object(forKey: key) as? Date
            ?? .distantPast
        guard
            Date.now.timeIntervalSince(last) > 120 * 24 * 60 * 60
        else {
            return
        }
        UserDefaults.standard.set(Date.now, forKey: key)
        requestReview()
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
                        .font(Theme.cardTitle)
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
        .buttonStyle(TrackingCardButtonStyle())
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
    /// Four levels only: label, what (compound + dose), when, and Log.
    /// Reference details (protocol, vial) live on the protocol screen.
    func nextEntryHero(
        _ next: ScheduledEntry
    ) -> some View {
        TrackingHeroCard {
            HStack(
                alignment: .center,
                spacing: Theme.spaceS
            ) {
                Eyebrow(
                    text: "Next entry",
                    onDark: true
                )

                Spacer()

                Menu {
                    Button {
                        open(
                            next,
                            prefill:
                                repeatDraft(
                                    for: next
                                )
                        )
                    } label: {
                        Label(
                            "Adjust details",
                            systemImage:
                                "slider.horizontal.3"
                        )
                    }

                    Button {
                        skipEntry(next)
                    } label: {
                        Label(
                            "Skip entry",
                            systemImage:
                                "forward.end"
                        )
                    }
                } label: {
                    Image(
                        systemName:
                            "ellipsis.circle"
                    )
                    .font(Theme.sectionTitle)
                    .foregroundStyle(
                        Theme.onDarkPrimary
                    )
                    .frame(
                        minWidth:
                            Theme.minimumTapTarget,
                        minHeight:
                            Theme.minimumTapTarget
                    )
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(
                    "Entry actions"
                )
            }

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(next.revision.compoundName)
                    .font(Theme.modalTitle)
                    .foregroundStyle(Theme.onDarkPrimary)

                heroDose(next)
            }

            heroTime(next)

            Button {
                logAsScheduled(next)
            } label: {
                Text("Log")
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle(inverted: true)
            )
        }
    }


    func protocolActionLight(
        _ next: ScheduledEntry
    ) -> some View {
        NavigationLink(
            value:
                TrackingRoute
                    .protocolDetail(
                        next.revision
                            .protocolID
                    )
        ) {
            HStack(
                alignment:
                    .firstTextBaseline,
                spacing: Theme.spaceM
            ) {
                Text("Protocol")
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.onDarkSecondary
                    )

                Spacer()

                Text(
                    next.revision
                        .protocolName
                )
                .font(Theme.body)
                .foregroundStyle(
                    Theme.onDarkPrimary
                )
                .lineLimit(usesStackedHero ? 3 : 1)

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.onDarkSecondary
                )
                .accessibilityHidden(true)
            }
            .frame(
                minHeight:
                    Theme.minimumTapTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(TrackingCardButtonStyle())
        .accessibilityHint(
            "Opens protocol details."
        )
    }


    @ViewBuilder
    func vialActionLight(
        _ next: ScheduledEntry
    ) -> some View {
        if let vial =
            store.vial(
                next.revision.vialID
            ) {
            Button {
                open(next)
            } label: {
                HStack(
                    alignment:
                        .firstTextBaseline,
                    spacing: Theme.spaceM
                ) {
                    Text("Vial")
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme.onDarkSecondary
                        )

                    Spacer()

                    Text(vial.name)
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme.onDarkPrimary
                        )
                        .lineLimit(usesStackedHero ? 3 : 1)

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.onDarkSecondary
                    )
                }
                .frame(
                    minHeight:
                        Theme.minimumTapTarget
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(TrackingCardButtonStyle())

        } else {
            Button {
                if store.vials.isEmpty {
                    addVial = true
                } else {
                    open(next)
                }
            } label: {
                HStack(
                    alignment:
                        .firstTextBaseline,
                    spacing: Theme.spaceM
                ) {
                    Text("Vial")
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme.onDarkSecondary
                        )

                    Spacer()

                    Text(
                        store.vials.isEmpty
                        ? "Add vial"
                        : "Choose vial"
                    )
                    .font(Theme.body)
                    .foregroundStyle(Theme.onDarkPrimary)

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.onDarkSecondary
                    )
                }
                .frame(
                    minHeight:
                        Theme.minimumTapTarget
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(TrackingCardButtonStyle())
        }
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
                        Theme.textSecondary
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
                Theme.textSecondary
            )

            Text(
                "No scheduled entries are generated during the recorded OFF period."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
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
    func heroDose(
        _ next: ScheduledEntry
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceXS
        ) {
            Text(next.revision.amountText)
                .foregroundStyle(Theme.onDarkPrimary)

            Text(next.revision.unitText)
                .foregroundStyle(
                    Theme.onDarkSecondary
                )
        }
        .font(Theme.metricCompact)
        .accessibilityElement(children: .combine)
    }


    /// One line for when: the time and how soon, instead of a time plus a
    /// separate chip saying the same thing.
    func heroTime(
        _ next: ScheduledEntry
    ) -> some View {
        Button {
            editingSchedule =
                next.revision
        } label: {
            Text(
                "\(next.at, style: .time) · \(dueText(for: next))"
            )
            .font(Theme.body)
            .monospacedDigit()
            .foregroundStyle(Theme.onDarkSecondary)
            .frame(
                maxWidth: .infinity,
                minHeight:
                    Theme.minimumTapTarget,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(TrackingCardButtonStyle())
        .accessibilityHint(
            "Opens the protocol schedule editor."
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
        .foregroundStyle(Theme.onDarkPrimary)
        .lineLimit(1)
        .fixedSize()
        .padding(
            .horizontal,
            Theme.spaceXS
        )
        .padding(
            .vertical,
            Theme.spaceXXS
        )
        .background(
            Theme.onDarkHairline,
            in: .rect(
                cornerRadius:
                    Theme.radiusBadge
            )
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
                    DoseText.line(
                        compound:
                            entry.revision.compoundName,
                        amount:
                            entry.revision.amountText,
                        unit:
                            entry.revision.unitText
                    )
                )
                .font(Theme.cardTitle)
                .monospacedDigit()

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
        .padding(.vertical, Theme.rowPadding)
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
                : Theme.inactiveFill
        )
        .animation(
            reduceMotion
                ? nil
                : Theme.stateSpring,
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
            Haptics.selection()
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
                : Theme.momentumSpring
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
                : Theme.stateSpring
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
                    ? Theme.textSecondary
                    : Theme.teal
            )

            // The recorded time is the confirmation: an early tap is visible
            // at once, while Undo is still on screen.
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                Text(
                    (
                        log.status == "Skipped"
                        ? "Skipped at "
                        : "Logged at "
                    )
                    + log.loggedAt.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()

                Text(log.compoundName)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(
                minLength: Theme.spaceXS
            )

            if log.status != "Skipped",
               log.route.usesInjectionSite,
               log.site.isEmpty {
                Button("Add site") {
                    undoTask?.cancel()
                    addingSite = log
                }
                .font(Theme.label)
                .foregroundStyle(Theme.teal)
                .frame(minHeight: Theme.minimumTapTarget)
            }

            Button("Undo") {
                if store.deleteDose(log) {
                    undoLog = nil
                    Haptics.impact()
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
            // Long enough to read and reach, including with VoiceOver.
            try? await Task.sleep(
                for: .seconds(8)
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
                    spacing: Theme.sectionGap
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
                .minimumTapTarget()
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
                .minimumTapTarget()
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
                        lineWidth: Theme.ruleThickness
                    )
                }
            }
        }
        .buttonStyle(TrackingCardButtonStyle())
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
                    DoseText.amount(
                        entry.revision.amountText,
                        entry.revision.unitText
                    ),
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

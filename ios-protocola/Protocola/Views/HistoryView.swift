import SwiftUI

struct HistoryView: View {
    @Environment(TrackingStore.self) private var store

    @State private var search = ""
    @State private var category = "Timeline"
    @State private var protocolID: UUID?
    @State private var dates = false
    @State private var from =
        Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: .now
        ) ?? .now
    @State private var to = Date.now
    @State private var summary = false
    @State private var siteHistory = false
    @State private var filtersPresented = false
    /// Doses only by default, like a dose diary; All events adds vial,
    /// protocol and lab records.
    @State private var dosesOnly: Bool
    /// Days back from today; nil shows everything.
    @State private var rangeDays: Int? = 30
    @State private var searchShown = false
    /// Switches to the Insights tab; nil hides "See more".
    var openInsights: (() -> Void)? = nil

    init(
        protocolID: UUID? = nil,
        openInsights: (() -> Void)? = nil
    ) {
        self.openInsights = openInsights
        _protocolID =
            State(
                initialValue: protocolID
            )
        _dosesOnly = State(initialValue: protocolID == nil)
    }

    static let rangeOptions: [(label: String, days: Int?)] = [
        ("Last 7 days", 7),
        ("Last 30 days", 30),
        ("Last 90 days", 90),
        ("All time", nil)
    ]

    private var rangeLabel: String {
        Self.rangeOptions.first { $0.days == rangeDays }?.label
        ?? "All time"
    }

    private var injectionSiteLogs: [DoseLog] {
        store.logs.filter {
            $0.route.usesInjectionSite
            && $0.status != "Skipped"
            && !$0.site
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        }
    }

    private var records: [TimelineRecord] {
        let end =
            Calendar.current.date(
                byAdding: .day,
                value: 1,
                to:
                    Calendar.current
                        .startOfDay(
                            for: to
                        )
            ) ?? to

        return TimelineRecord.build(
            logs: store.logs,
            events: store.events,
            labs: store.labs,
            includeMetadata:
                category
                    == "All audit events"
                || category
                    == "Metadata"
        )
        .filter { record in
            (!dosesOnly || record.log != nil)
            && (
                rangeDays.map { days in
                    record.at
                        >= Calendar.current.date(
                            byAdding: .day,
                            value: -(days - 1),
                            to: Calendar.current.startOfDay(for: .now)
                        ) ?? .distantPast
                } ?? true
            )
            && (
                protocolID == nil
                || record.protocolID
                    == protocolID
            )
            && (
                [
                    "Timeline",
                    "All audit events"
                ]
                .contains(category)
                || record.category
                    == category
                || (
                    category == "Symptoms"
                    && !(
                        record.log?
                            .symptoms
                        ?? ""
                    )
                    .isEmpty
                )
                || (
                    category == "Notes"
                    && (
                        !(
                            record.log?
                                .notes
                            ?? ""
                        )
                        .isEmpty
                        || record.title
                            .localizedCaseInsensitiveContains(
                                "note"
                            )
                    )
                )
            )
            && (
                !dates
                || (
                    record.at
                        >= Calendar.current
                            .startOfDay(
                                for: from
                            )
                    && record.at < end
                )
            )
            && (
                search.isEmpty
                || (
                    record.title
                    + " "
                    + record.detail
                    + " "
                    + humanDetail(record)
                )
                .localizedStandardContains(
                    search
                )
            )
        }
    }

    private var hasAnyHistory: Bool {
        !store.logs.isEmpty
        || !store.labs.isEmpty
        || !store.events.isEmpty
    }


    private var groupedDays: [TimelineDay] {
        let grouped =
            Dictionary(
                grouping: records
            ) {
                Calendar.current
                    .startOfDay(
                        for: $0.at
                    )
            }

        return grouped
            .map {
                TimelineDay(
                    date: $0.key,
                    records:
                        $0.value.sorted {
                            $0.at > $1.at
                        }
                )
            }
            .sorted {
                $0.date > $1.date
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceM
                ) {
                    DemoBannerCard()

                    if hasAnyHistory {
                        // Filters share one row; they stack at large
                        // text sizes instead of squeezing.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: Theme.spaceS) {
                                dosesPicker
                                rangeMenu
                            }

                            VStack(
                                alignment: .leading,
                                spacing: Theme.spaceS
                            ) {
                                dosesPicker
                                rangeMenu
                            }
                        }

                        if searchShown || !search.isEmpty {
                            TrackingSearchField(
                                prompt:
                                    "Search your timeline",
                                text: $search
                            )
                        }
                    }
                }

                if groupedDays.isEmpty {
                    TrackingEmptyState(
                        icon:
                            "clock.arrow.circlepath",
                        title:
                            "No records to show",
                        message:
                            hasActiveFilters || hasAnyHistory
                            ? "Try a longer range, All events, or a different search."
                            : "Recorded entries and protocol changes appear here."
                    )
                } else {
                    ForEach(
                        Array(
                            groupedDays.enumerated()
                        ),
                        id: \.element.id
                    ) { index, day in
                        dayGroup(day)
                            .trackingStagger(
                                index: index
                            )
                    }
                }

                if let week = store.insights[7],
                   week.scheduled > 0 {
                    weekPreview(week)
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .trackingScrollChrome()
        .background(Theme.paper)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            SettingsToolbarItem()

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                if hasAnyHistory
                    || hasActiveFilters {
                    Button {
                        filtersPresented = true
                    } label: {
                        Label(
                            "Filter history",
                            systemImage:
                                hasActiveFilters
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease"
                        )
                    }
                }
            }

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                if hasAnyHistory {
                    Button {
                        searchShown.toggle()
                        if !searchShown { search = "" }
                    } label: {
                        Label(
                            searchShown
                            ? "Close search"
                            : "Search history",
                            systemImage: "magnifyingglass"
                        )
                    }
                }
            }

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                if hasAnyHistory {
                    Menu {
                        if !injectionSiteLogs.isEmpty {
                            Button {
                                siteHistory = true
                            } label: {
                                Label(
                                    "Injection site history",
                                    systemImage:
                                        "figure.stand"
                                )
                            }
                        }

                        Button {
                            if store.isPremium {
                                summary = true
                            } else {
                                store.requestPaywall(
                                    .summary
                                )
                            }
                        } label: {
                            Label(
                                "Visit Summary",
                                systemImage:
                                    "doc.text"
                            )
                        }
                    } label: {
                        Label(
                            "History actions",
                            systemImage:
                                "ellipsis"
                        )
                    }
                }
            }
        }
        .sheet(
            isPresented:
                $filtersPresented
        ) {
            dateFilterSheet
        }
        .sheet(isPresented: $summary) {
            VisitSummaryView()
        }
        .sheet(
            isPresented: $siteHistory
        ) {
            InjectionSiteHistoryView(
                logs: injectionSiteLogs
            )
        }
        .trackingRoutes()
        .trackingErrors()
    }
}


// MARK: - Filters

private extension HistoryView {

    var dateFilterSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        "Type",
                        selection: $category
                    ) {
                        ForEach(
                            eventFilters,
                            id: \.value
                        ) { filter in
                            Text(filter.label)
                                .tag(filter.value)
                        }
                    }
                } header: {
                    Eyebrow(text: "Record type")
                }

                Section {
                    Picker(
                        "Protocol",
                        selection: $protocolID
                    ) {
                        Text("All protocols")
                            .tag(nil as UUID?)

                        ForEach(store.protocols) {
                            record in
                            Text(record.name)
                                .tag(Optional(record.id))
                        }
                    }
                } header: {
                    Eyebrow(text: "Protocol")
                }

                Section {
                    Toggle(
                        "Use date range",
                        isOn: $dates
                    )

                    if dates {
                        DatePicker(
                            "From",
                            selection: $from,
                            displayedComponents:
                                .date
                        )

                        DatePicker(
                            "To",
                            selection: $to,
                            in: from...,
                            displayedComponents:
                                .date
                        )
                    }
                } header: {
                    Eyebrow(text: "Date range")
                } footer: { FormFooter {
                    Text(
                        "Date filters change what appears in History only. "
                        + "Your records are not modified."
                    )
                }
}

                if hasActiveFilters {
                    Section {
                        Button(
                            "Clear filters",
                            role: .destructive
                        ) {
                            protocolID = nil
                            category = "Timeline"
                            dates = false
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        filtersPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }


    var selectedProtocolLabel: String {
        guard let protocolID,
              let protocolRecord =
                store.protocols.first(
                    where: {
                        $0.id == protocolID
                    }
                )
        else {
            return "All protocols"
        }

        return protocolRecord.name
    }


    var selectedEventLabel: String {
        eventFilters.first {
            $0.value == category
        }?.label
        ?? "All events"
    }


    var hasActiveFilters: Bool {
        protocolID != nil
        || category != "Timeline"
        || dates
        || !search.isEmpty
    }


    var eventFilters: [EventFilter] {
        [
            .init(
                label: "All events",
                value: "Timeline"
            ),
            .init(
                label: "Entries",
                value: "Dose"
            ),
            .init(
                label: "Protocol changes",
                value: "Protocol"
            ),
            .init(
                label: "Symptoms",
                value: "Symptoms"
            ),
            .init(
                label: "Notes",
                value: "Notes"
            ),
            .init(
                label: "Vials",
                value: "Vial"
            ),
            .init(
                label: "Labs",
                value: "Lab"
            ),
            .init(
                label: "Corrections",
                value: "Correction"
            ),
            .init(
                label: "All audit events",
                value: "All audit events"
            )
        ]
    }
}


// MARK: - Timeline

private extension HistoryView {

    var dosesPicker: some View {
        Picker(
            "Show",
            selection: $dosesOnly
        ) {
            Text("Doses").tag(true)
            Text("All events").tag(false)
        }
        .pickerStyle(.segmented)
    }


    var rangeMenu: some View {
        Menu {
            ForEach(
                Self.rangeOptions,
                id: \.label
            ) { option in
                Button {
                    rangeDays = option.days
                } label: {
                    if option.days == rangeDays {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.spaceXS) {
                Text(rangeLabel)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(Theme.micro)
                    .accessibilityHidden(true)
            }
            .font(Theme.label)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.spaceS)
            .frame(minHeight: Theme.minimumTapTarget)
            .background(
                Theme.surface,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        Theme.hairline,
                        lineWidth: Theme.ruleThickness
                    )
            )
        }
        .accessibilityLabel("Range, " + rangeLabel)
    }


    /// Last 7 days at a glance: consistency and recorded entries per day.
    func weekPreview(
        _ week: InsightsSummary
    ) -> some View {
        let peak = max(week.days.map(\.recorded).max() ?? 0, 1)

        return VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            HStack(alignment: .firstTextBaseline) {
                Text("Insights")
                    .font(Theme.modalTitle)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: Theme.spaceXS)

                if let openInsights {
                    Button {
                        openInsights()
                    } label: {
                        HStack(spacing: Theme.spaceXXS) {
                            Text("See more")
                            Image(systemName: "chevron.right")
                                .font(Theme.micro)
                                .accessibilityHidden(true)
                        }
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, Theme.spaceS)
                        .frame(minHeight: Theme.minimumTapTarget)
                        .background(Theme.surface, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    Theme.hairline,
                                    lineWidth: Theme.ruleThickness
                                )
                        )
                    }
                    .buttonStyle(TrackingCardButtonStyle())
                }
            }

            HStack(
                alignment: .top,
                spacing: Theme.spaceS
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Label("Consistency", systemImage: "checkmark.circle")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)

                    Text(week.percentage)
                        .font(Theme.metricCompact)
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)

                    Text(
                        "\(week.recorded) of \(week.scheduled) scheduled · 7 days"
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
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

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
                    Label("Recorded", systemImage: "chart.bar")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)

                    HStack(
                        alignment: .bottom,
                        spacing: Theme.spaceXXS
                    ) {
                        ForEach(week.days) { day in
                            Capsule()
                                .fill(
                                    day.recorded == 0
                                    ? Theme.inactiveFill
                                    : Theme.chartPastFill
                                )
                                .frame(
                                    height:
                                        Theme.iconTileSize
                                        * max(
                                            0.12,
                                            Double(day.recorded)
                                                / Double(peak)
                                        )
                                )
                        }
                    }
                    .frame(
                        height: Theme.iconTileSize,
                        alignment: .bottom
                    )
                    .accessibilityHidden(true)

                    Text("Entries per day · 7 days")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
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
                .accessibilityElement(children: .combine)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }


    func dayGroup(
        _ day: TimelineDay
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
        ) {
            Eyebrow(
                text: dayTitle(day.date)
            )

            VStack(spacing: Theme.spaceS) {
                ForEach(day.records) { record in
                    HStack(spacing: Theme.spaceS) {
                        Circle()
                            .fill(Theme.textTertiary)
                            .frame(
                                width: Theme.statusDot,
                                height: Theme.statusDot
                            )
                            .accessibilityHidden(true)

                        recordLink(record)
                    }
                }
            }
            .background(alignment: .leading) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: Theme.ruleThickness)
                    .padding(
                        .leading,
                        (Theme.statusDot - Theme.ruleThickness) / 2
                    )
                    .accessibilityHidden(true)
            }
        }
    }


    @ViewBuilder
    func recordLink(
        _ record: TimelineRecord
    ) -> some View {
        if let log = record.log {
            NavigationLink(
                value:
                    TrackingRoute
                        .logDetail(log.id)
            ) {
                TimelineRow(
                    record: record,
                    title: humanTitle(record),
                    detail: humanDetail(record),
                    icon: icon(for: record),
                    tint: tint(for: record)
                )
            }
            .buttonStyle(
                TrackingRowButtonStyle()
            )

        } else if let event = record.event {
            NavigationLink {
                EventDetailView(event: event)
            } label: {
                TimelineRow(
                    record: record,
                    title: humanTitle(record),
                    detail: humanDetail(record),
                    icon: icon(for: record),
                    tint: tint(for: record)
                )
            }
            .buttonStyle(
                TrackingRowButtonStyle()
            )

        } else if let lab = record.lab {
            NavigationLink {
                LabDetailView(
                    labID: lab.id
                )
            } label: {
                TimelineRow(
                    record: record,
                    title: humanTitle(record),
                    detail: humanDetail(record),
                    icon: icon(for: record),
                    tint: tint(for: record)
                )
            }
            .buttonStyle(
                TrackingRowButtonStyle()
            )
        }
    }


    func humanTitle(
        _ record: TimelineRecord
    ) -> String {
        if record.lab != nil {
            return "Lab recorded"
        }

        if let log = record.log {
            return log.compoundName
        }

        if let event = record.event {
            if event.title == "Protocol created" {
                return "Protocol created"
            }

            if event.title
                .localizedCaseInsensitiveContains(
                    "schedule"
                ) {
                return "Schedule changed"
            }

            if event.title
                .localizedCaseInsensitiveContains(
                    "vial"
                ) {
                return event.title
            }

            return event.title
        }

        return record.title
    }


    func humanDetail(
        _ record: TimelineRecord
    ) -> String {
        if let lab = record.lab {
            return
                lab.marker
                + " · "
                + lab.displayValue
        }

        if let log = record.log {
            var parts = [
                DoseText.amount(
                    log.actualAmountText,
                    log.unitText
                )
            ]

            switch log.status {
            case "Skipped": parts = ["Skipped"]
            case "Delayed": parts.append("Late")
            case "Partial": parts.append("Partial")
            default: break
            }

            if !log.site.isEmpty,
               log.status != "Skipped" {
                parts.append(log.site)
            } else if log.status != "Skipped" {
                parts.append(log.route.rawValue)
            }

            return parts.joined(
                separator: " · "
            )
        }

        guard let event = record.event else {
            return record.detail
        }

        let protocolName =
            protocolName(
                for: event.protocolID
            )

        if event.title == "Protocol created" {
            let name =
                afterValue(
                    "Name",
                    in: event
                )
                ?? protocolName

            let compound =
                afterValue(
                    "Compound",
                    in: event
                )

            let amount =
                afterValue(
                    "Amount",
                    in: event
                )

            let unit =
                afterValue(
                    "Unit",
                    in: event
                )

            var parts: [String] = []

            if let name,
               !name.isEmpty {
                parts.append(name)
            }

            if let compound,
               !compound.isEmpty {
                if let amount,
                   !amount.isEmpty {
                    parts.append(
                        DoseText.line(
                            compound: compound,
                            amount: amount,
                            unit: unit ?? ""
                        )
                    )
                } else {
                    parts.append(compound)
                }
            }

            if !parts.isEmpty {
                return parts.joined(
                    separator: " · "
                )
            }
        }

        if event.title == "Vial added" {
            let parts = [
                afterValue("Name", in: event),
                afterValue("Compound", in: event),
                afterValue("Amount", in: event)
                    .map { DoseText.amount($0, "mg") }
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

            if !parts.isEmpty {
                return parts.joined(separator: " · ")
            }
        }

        let meaningful =
            event.changes.filter {
                $0.isMeaningful
            }

        if !meaningful.isEmpty {
            let summaries =
                meaningful.prefix(2).map {
                    change in
                    humanChange(change)
                }

            if let protocolName,
               !protocolName.isEmpty {
                return
                    protocolName
                    + " · "
                    + summaries.joined(
                        separator: " · "
                    )
            }

            return summaries.joined(
                separator: " · "
            )
        }

        // Any other event: its first two changes in plain words, never the
        // raw "Field: Not recorded → value" log text.
        let summaries =
            event.changes
                .prefix(2)
                .map(humanChange)

        if !summaries.isEmpty {
            return (
                [protocolName ?? ""]
                + summaries
            )
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        }

        return
            event.detail.isEmpty
            ? event.category
            : event.detail
    }


    /// Strips the internal record id that vial values carry, e.g.
    /// "Sample vial 01 (CDE7C24F-…)" → "Sample vial 01".
    static func displayValue(
        _ value: String
    ) -> String {
        value.replacingOccurrences(
            of: #" \([0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}\)$"#,
            with: "",
            options: .regularExpression
        )
    }


    func humanChange(
        _ change: RecordChange
    ) -> String {
        let old = Self.displayValue(change.before)
        let new = Self.displayValue(change.after)

        // A value set for the first time or cleared is not a "from → to".
        if old.isEmpty {
            return change.field + ": " + new
        }

        if new.isEmpty {
            return change.field + " cleared"
        }

        switch change.field {
        case "Amount":
            return old + " → " + new

        case "Schedule":
            return "Schedule: " + new

        case "Status":
            return old + " → " + new

        case "Compound":
            return old + " → " + new

        default:
            return
                change.field
                + ": "
                + old
                + " → "
                + new
        }
    }


    func afterValue(
        _ field: String,
        in event: ProtocolEvent
    ) -> String? {
        event.changes.first {
            $0.field == field
        }?.after
    }


    func protocolName(
        for id: UUID?
    ) -> String? {
        guard let id else {
            return nil
        }

        return store.protocols.first {
            $0.id == id
        }?.name
    }


    func icon(
        for record: TimelineRecord
    ) -> String {
        if let log = record.log {
            return
                log.status == "Skipped"
                ? "xmark"
                : "checkmark"
        }

        switch record.category {
        case "Protocol":
            return
                record.title
                    == "Protocol created"
                ? "plus"
                : "calendar"

        case "Vial":
            return "shippingbox"

        case "Lab":
            return "testtube.2"

        case "Correction":
            return "arrow.counterclockwise"

        case "Symptoms":
            return "waveform.path.ecg"

        default:
            return "circle"
        }
    }


    func tint(
        for record: TimelineRecord
    ) -> Color {
        if record.log?.status == "Skipped" {
            return Theme.textSecondary
        }

        switch record.category {
        case "Dose":
            return Theme.teal

        case "Protocol":
            return Theme.teal

        case "Vial":
            return Theme.teal

        case "Lab":
            return Theme.teal

        default:
            return Theme.textSecondary
        }
    }


    func dayTitle(
        _ date: Date
    ) -> String {
        let calendar =
            Calendar.current

        let short =
            date.formatted(
                .dateTime
                    .month(.abbreviated)
                    .day()
            )

        if calendar.isDateInToday(date) {
            return "Today · " + short
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday · " + short
        }

        return date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day()
        )
    }
}


// MARK: - Supporting types

private struct TimelineDay: Identifiable {
    let date: Date
    let records: [TimelineRecord]

    var id: Date {
        date
    }
}


private struct EventFilter: Identifiable {
    let label: String
    let value: String

    var id: String {
        value
    }
}


private struct TimelineRow: View {
    let record: TimelineRecord
    let title: String
    let detail: String
    let icon: String
    let tint: Color

    private var isRecordedDose: Bool {
        guard let log = record.log else { return false }
        return log.status != "Skipped"
    }

    private var isSkippedDose: Bool {
        record.log?.status == "Skipped"
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(Theme.label)
                .foregroundStyle(
                    isRecordedDose
                    ? Theme.onDarkPrimary
                    : tint
                )
                .frame(
                    width: Theme.iconColumn,
                    height: Theme.iconColumn
                )
                .padding(Theme.spaceXXS)
                .background {
                    if isRecordedDose {
                        Circle()
                            .fill(Theme.accentFill)
                    } else if isSkippedDose {
                        Circle()
                            .strokeBorder(
                                Theme.controlBorder,
                                lineWidth: Theme.ruleThickness
                            )
                    } else {
                        Circle()
                            .fill(
                                tint.opacity(
                                    Theme.statusFillOpacity
                                )
                            )
                    }
                }
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(3)
                    .monospacedDigit()
            }

            Spacer(
                minLength: Theme.spaceS
            )

            Text(
                record.at.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
            .monospacedDigit()

            Image(systemName: "chevron.right")
                .font(Theme.micro)
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(Theme.cardInset)
        .background(
            Theme.surface,
            in: RoundedRectangle(
                cornerRadius: Theme.radiusRow,
                style: .continuous
            )
        )
        .quietElevation()
    }
}


private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        HStack(spacing: Theme.spaceXS) {
            configuration.title
                .lineLimit(1)

            configuration.icon
                .font(Theme.micro)
        }
    }
}

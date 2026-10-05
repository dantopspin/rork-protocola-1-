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

    init(protocolID: UUID? = nil) {
        _protocolID =
            State(
                initialValue: protocolID
            )
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
            (
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
        || store.events.contains {
            $0.showsInTimeline
        }
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
                spacing: Theme.spaceL
            ) {
                PrimaryPageHeader(
                    title: "History"
                )

                if hasAnyHistory {
                    TrackingSearchField(
                        prompt:
                            "Search your timeline",
                        text: $search
                    )
                }

                if groupedDays.isEmpty {
                    TrackingEmptyState(
                        icon:
                            "clock.arrow.circlepath",
                        title:
                            "No records to show",
                        message:
                            hasActiveFilters
                            ? "Try changing your filters or search."
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
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
                    + Theme.spaceL
            )
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                                : "line.3.horizontal.decrease.circle"
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
                                "ellipsis.circle"
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
                } footer: {
                    Text(
                        "Date filters change what appears in History only. "
                        + "Your records are not modified."
                    )
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

    func dayGroup(
        _ day: TimelineDay
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Eyebrow(
                text: dayTitle(day.date)
            )

            EditorialRule()

            VStack(spacing: 0) {
                ForEach(
                    Array(
                        day.records.enumerated()
                    ),
                    id: \.element.id
                ) { index, record in
                    recordLink(record)

                    if index
                        < day.records.count - 1 {
                        EditorialRule()
                    }
                }
            }

            EditorialRule()
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
            switch log.status {
            case "Skipped":
                return "Entry skipped"

            case "Delayed":
                return "Entry recorded late"

            case "Partial":
                return "Partial entry recorded"

            default:
                return "Entry recorded"
            }
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
                log.protocolName,
                log.compoundName
                    + " "
                    + log.actualAmountText
                    + " "
                    + log.unitText
            ]

            if !log.site.isEmpty,
               log.status != "Skipped" {
                parts.append(log.site)
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
                var dose = compound

                if let amount,
                   !amount.isEmpty {
                    dose += " " + amount

                    if let unit,
                       !unit.isEmpty {
                        dose += " " + unit
                    }
                }

                parts.append(dose)
            }

            if !parts.isEmpty {
                return parts.joined(
                    separator: " · "
                )
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

        if let protocolName,
           !protocolName.isEmpty,
           !event.detail.isEmpty {
            return
                protocolName
                + " · "
                + event.detail
        }

        return
            event.detail.isEmpty
            ? event.category
            : event.detail
    }


    func humanChange(
        _ change: RecordChange
    ) -> String {
        let old =
            change.before.isEmpty
            ? "Not recorded"
            : change.before

        let new =
            change.after.isEmpty
            ? "Not recorded"
            : change.after

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
            return Theme.muted
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
            return Theme.muted
        }
    }


    func dayTitle(
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

    var body: some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(Theme.label)
                .foregroundStyle(tint)
                .frame(
                    width: Theme.iconColumn,
                    height: Theme.iconColumn
                )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
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
        }
        .padding(
            .vertical,
            Theme.spaceS
        )
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

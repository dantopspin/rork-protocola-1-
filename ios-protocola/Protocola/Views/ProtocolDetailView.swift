import SwiftUI

struct ProtocolDetailView: View {
    let protocolID: UUID

    @Environment(TrackingStore.self)
    private var store

    @State private var editing:
        ScheduleRevision?
    @State private var planning:
        ScheduleRevision?
    @State private var editingPlanned:
        ScheduleRevision?
    @State private var cancellingPlanned:
        ScheduleRevision?
    @State private var logging:
        ScheduleRevision?
    @State private var addCompound = false
    @State private var choice = false

    var body: some View {
        Group {
            if let record =
                store.protocols.first(
                    where: {
                        $0.id == protocolID
                    }
                ) {
                protocolContent(record)

            } else {
                TrackingEmptyState(
                    icon:
                        "list.bullet.rectangle",
                    title:
                        "Protocol unavailable",
                    message:
                        "This protocol is no longer available."
                )
                .screenPadding()
            }
        }
        .sheet(
            isPresented: $choice
        ) {
            FreeProtocolChoiceView()
        }
        .trackingErrors()
    }
}


// MARK: - Content

private extension ProtocolDetailView {

    func protocolContent(
        _ record: ProtocolRecord
    ) -> some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                protocolHeader(record)

                if !store.canEdit(
                    record.id
                ) {
                    readOnlyBlock(record)
                }

                ForEach(
                    store.currentRevisions(
                        record.id
                    )
                ) { revision in
                    scheduleBlock(
                        revision,
                        record: record
                    )
                }

                let planned =
                    store.plannedRevisions(
                        record.id
                    )

                if !planned.isEmpty {
                    plannedChangesBlock(
                        planned,
                        record: record
                    )
                }

                phasesBlock(record)

                toolsBlock(record)

                recordedInstructions(
                    record
                )
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .trackingScrollChrome()
        .background(Theme.paper)
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {
            // The header carries the name; keep the bar quiet like the
            // reference while the title still names the back button.
            ToolbarItem(placement: .principal) {
                Text("")
                    .accessibilityHidden(true)
            }

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Menu {
                    Button {
                        addCompound = true
                    } label: {
                        Label(
                            "Add compound",
                            systemImage: "plus"
                        )
                    }
                    .disabled(
                        !store.canEdit(
                            record.id
                        )
                    )

                    Button {
                        store.changeStatus(
                            record,
                            status:
                                record.status
                                    == "Active"
                                ? "Paused"
                                : "Active"
                        )
                    } label: {
                        Label(
                            record.status
                                == "Active"
                            ? "Pause protocol"
                            : "Resume protocol",
                            systemImage:
                                record.status
                                    == "Active"
                                ? "pause"
                                : "play"
                        )
                    }
                    .disabled(
                        !store.canEdit(
                            record.id
                        )
                    )

                    if record.status
                        != "Archived" {
                        Divider()

                        Button(
                            role: .destructive
                        ) {
                            store.changeStatus(
                                record,
                                status: "Archived"
                            )
                        } label: {
                            Label(
                                "Archive protocol",
                                systemImage:
                                    "archivebox"
                            )
                        }
                        .disabled(
                            !store.canEdit(
                                record.id
                            )
                        )
                    }
                } label: {
                    Label(
                        "Protocol actions",
                        systemImage:
                            "ellipsis.circle"
                    )
                }
            }
        }
        .sheet(item: $editing) {
            revision in
            ProtocolEditorView(
                record: record,
                revision: revision
            )
        }
        .sheet(item: $planning) {
            revision in
            ProtocolEditorView(
                record: record,
                revision: revision,
                planningFuture: true
            )
        }
        .sheet(
            item: $editingPlanned
        ) { revision in
            ProtocolEditorView(
                record: record,
                revision: revision,
                planningFuture: true,
                editingPlanned: true
            )
        }
        .alert(
            "Cancel planned change?",
            isPresented:
                Binding(
                    get: {
                        cancellingPlanned
                            != nil
                    },
                    set: { shown in
                        if !shown {
                            cancellingPlanned =
                                nil
                        }
                    }
                )
        ) {
            Button(
                "Keep plan",
                role: .cancel
            ) {
                cancellingPlanned =
                    nil
            }

            Button(
                "Cancel planned change",
                role: .destructive
            ) {
                if let revision =
                    cancellingPlanned {
                    _ =
                        store
                            .cancelPlannedRevision(
                                revision
                            )
                }

                cancellingPlanned =
                    nil
            }
        } message: {
            Text(
                "This removes only the future revision. Past and current records stay unchanged."
            )
        }
        .sheet(item: $logging) {
            revision in
            DoseEditorView(
                revision: revision
            )
        }
        .sheet(
            isPresented:
                $addCompound
        ) {
            ProtocolEditorView(
                record: record
            )
        }
    }


    /// Every recorded schedule for this protocol as phases, inline.
    @ViewBuilder
    func phasesBlock(
        _ record: ProtocolRecord
    ) -> some View {
        let revisions =
            store.revisions
                .filter { $0.protocolID == record.id }
                .sorted { $0.effectiveFrom > $1.effectiveFrom }

        if !revisions.isEmpty {
            EditorialSection("Phases") {
                PhaseTimeline(revisions: revisions)
            }
        }
    }


    /// Icon tile, serif name, compound count and start date, status chip.
    func protocolHeader(
        _ record: ProtocolRecord
    ) -> some View {
        let current = store.currentRevisions(record.id)
        let started =
            store.revisions
                .filter { $0.protocolID == record.id }
                .map(\.effectiveFrom)
                .min()
        let count =
            String(current.count)
            + (current.count == 1 ? " compound" : " compounds")
        let subtitle =
            started.map {
                count
                + " · since "
                + $0.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            } ?? count

        return HStack(
            alignment: .center,
            spacing: Theme.spaceM
        ) {
            Image(systemName: "list.bullet.clipboard")
                .font(Theme.modalTitle)
                .foregroundStyle(Theme.teal)
                .frame(
                    width: Theme.iconTileSize,
                    height: Theme.iconTileSize
                )
                .background(
                    Theme.tealTint,
                    in: .rect(cornerRadius: Theme.radiusRow)
                )
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(record.name)
                    .font(Theme.modalTitle)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()

                StatusBadge(text: record.status)
                    .padding(.top, Theme.spaceXXS)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }


    func readOnlyBlock(
        _ record: ProtocolRecord
    ) -> some View {
        EditorialSection(
            "Free tracking"
        ) {
            HStack(
                spacing: Theme.spaceS
            ) {
                Image(
                    systemName: "lock"
                )
                .foregroundStyle(
                    Theme.textSecondary
                )

                Text(
                    "Read-only on Free"
                )
                .font(Theme.label)
                .foregroundStyle(
                    Theme.ink
                )
            }

            Text(
                "Your full history is preserved. Choose one active protocol to continue editing and logging on Free."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )

            Button(
                "Choose protocol for Free tracking"
            ) {
                choice = true
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )
        }
    }


    func recordedInstructions(
        _ record: ProtocolRecord
    ) -> some View {
        EditorialSection(
            "Recorded instructions"
        ) {
            RecordRow(
                label: "Source",
                value:
                    record
                        .instructionSource
            )

            RecordRow(
                label: "Status",
                value: record.status
            )

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.ink
                    )
            }
        }
    }


    func scheduleBlock(
        _ revision: ScheduleRevision,
        record: ProtocolRecord
    ) -> some View {
        EditorialSection(
            "Schedule"
        ) {
            HStack(
                alignment: .top,
                spacing: Theme.spaceM
            ) {
                // One caps label per section: the compound is a title and
                // the dose is the data, not two more eyebrows.
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text(revision.compoundName)
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.ink)

                    HStack(
                        alignment: .firstTextBaseline,
                        spacing: Theme.spaceXS
                    ) {
                        Text(revision.amountText)
                            .foregroundStyle(Theme.ink)

                        Text(revision.unitText)
                            .foregroundStyle(
                                Theme.textSecondary
                            )
                    }
                    .font(Theme.metricCompact)
                    .accessibilityElement(children: .combine)
                }

                Spacer()

                // Only meaningful once there is more than one revision.
                if store.revisions.filter({
                    $0.protocolID == record.id
                }).count > 1 {
                    StatusBadge(text: "Current")
                }

                Menu {
                    Button {
                        editing = revision
                    } label: {
                        Label(
                            "Edit schedule",
                            systemImage:
                                "pencil"
                        )
                    }

                    Button {
                        planning = revision
                    } label: {
                        Label(
                            "Plan future change",
                            systemImage:
                                "calendar.badge.plus"
                        )
                    }
                } label: {
                    Image(
                        systemName:
                            "ellipsis.circle"
                    )
                    .font(
                        Theme.sectionTitle
                    )
                    .foregroundStyle(
                        Theme.ink
                    )
                    .frame(
                        minWidth:
                            Theme.minimumTapTarget,
                        minHeight:
                            Theme.minimumTapTarget
                    )
                }
                .disabled(
                    !store.canEdit(
                        record.id
                    )
                )
                .accessibilityLabel(
                    revision.compoundName
                    + " actions"
                )
            }

            RecordRow(
                label: "Route",
                value:
                    revision.routeText
            )

            RecordRow(
                label: "Schedule",
                value:
                    revision.config.map(
                        ScheduleDisplay
                            .summary
                    )
                    ?? "Not available"
            )

            RecordRow(
                label: "Effective",
                value:
                    phaseRangeLabel(
                        revision
                    )
            )

            if let config =
                revision.config,
               let cycle =
                    CycleDisplay.status(
                        config
                    ) {
                RecordRow(
                    label: "Cycle",
                    value: cycle
                )
            }

            if revision.route
                .usesInjectionSite {
                RecordRow(
                    label: "Vial",
                    value:
                        store.vial(
                            revision.vialID
                        )?.name
                        ?? "Not selected"
                )
            }

            if revision.route
                .usesInjectionSite,
               let site =
                    revision
                        .configuredSite {
                RecordRow(
                    label:
                        "Configured site",
                    value: site
                )
            }

            Button {
                logging = revision
            } label: {
                Text(
                    revision.config?.kind
                        == .asRecorded
                    ? "Log entry"
                    : "Log unscheduled entry"
                )
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )
            .disabled(
                !store.canTrack(
                    record.id
                )
            )


        }
    }


    func plannedChangesBlock(
        _ revisions:
            [ScheduleRevision],
        record: ProtocolRecord
    ) -> some View {
        EditorialSection(
            "Planned changes"
        ) {
            ForEach(
                Array(
                    revisions
                        .enumerated()
                ),
                id: \.element.id
            ) { index, revision in
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {
                    HStack(
                        alignment:
                            .firstTextBaseline,
                        spacing:
                            Theme.spaceS
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
                            .font(
                                Theme
                                    .sectionTitle
                            )
                            .foregroundStyle(
                                Theme.ink
                            )

                            Text(
                                phaseRangeLabel(
                                    revision
                                )
                            )
                            .font(
                                Theme.caption
                            )
                            .foregroundStyle(
                                Theme
                                    .textSecondary
                            )
                            .monospacedDigit()
                        }

                        Spacer()

                        StatusBadge(
                            text: "Planned"
                        )
                    }

                    Text(
                        revision.amountText
                        + " "
                        + revision.unitText
                    )
                    .font(
                        Theme.metricCompact
                    )
                    .foregroundStyle(
                        Theme.ink
                    )
                    .monospacedDigit()

                    RecordRow(
                        label: "Schedule",
                        value:
                            revision.config.map(
                                ScheduleDisplay
                                    .summary
                            )
                            ?? "Not available"
                    )

                    HStack(
                        spacing:
                            Theme.spaceS
                    ) {
                        Button(
                            "Edit plan"
                        ) {
                            editingPlanned =
                                revision
                        }

                        Button(
                            "Cancel plan",
                            role: .destructive
                        ) {
                            cancellingPlanned =
                                revision
                        }
                    }
                    .font(Theme.label)
                }
                .padding(
                    .vertical,
                    Theme.spaceS
                )
                .trackingStagger(
                    index: index
                )

                if index
                    < revisions.count - 1 {
                    EditorialRule()
                }
            }

            Text(
                "Planned revisions do not change past records and take effect only on their recorded date."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
        .disabled(
            !store.canEdit(record.id)
        )
    }


    func phaseRangeLabel(
        _ revision: ScheduleRevision
    ) -> String {
        let start =
            revision.effectiveFrom
                .formatted(
                    date: .abbreviated,
                    time: .omitted
                )

        if let exclusiveEnd =
            revision.effectiveUntil {
            let displayEnd =
                exclusiveEnd
                    .addingTimeInterval(-1)

            let end =
                displayEnd.formatted(
                    date: .abbreviated,
                    time: .omitted
                )

            return
                start == end
                ? start
                : start + " – " + end
        }

        switch revision.temporalState() {
        case .planned:
            return "From " + start

        case .current:
            return "Since " + start

        case .historical:
            return start
        }
    }


    func toolsBlock(
        _ record: ProtocolRecord
    ) -> some View {
        EditorialSection("Tools") {
            NavigationLink {
                ProtocolEvolutionView(
                    protocolID: record.id
                )
            } label: {
                navigationRow(
                    "Protocol evolution"
                )
            }
            .buttonStyle(TrackingRowButtonStyle())

            EditorialRule()

            NavigationLink {
                InventoryView()
            } label: {
                navigationRow(
                    "Vial inventory"
                )
            }
            .buttonStyle(TrackingRowButtonStyle())

            EditorialRule()

            NavigationLink {
                LabListView(
                    protocolID: record.id
                )
            } label: {
                navigationRow(
                    "Labs"
                )
            }
            .buttonStyle(TrackingRowButtonStyle())


        }
    }


    func protocolActions(
        _ record: ProtocolRecord
    ) -> some View {
        EditorialSection(
            "Protocol status"
        ) {
            Button {
                store.changeStatus(
                    record,
                    status:
                        record.status
                            == "Active"
                        ? "Paused"
                        : "Active"
                )
            } label: {
                Text(
                    record.status
                        == "Active"
                    ? "Pause protocol"
                    : "Resume protocol"
                )
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )

            if record.status
                != "Archived" {
                Button(
                    "Archive protocol",
                    role: .destructive
                ) {
                    store.changeStatus(
                        record,
                        status: "Archived"
                    )
                }
                .font(Theme.label)
                .frame(
                    minHeight:
                        Theme
                            .minimumTapTarget
                )
            }

            Text(
                "Changes apply from now onward. Past schedules and entry snapshots remain unchanged."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
        .disabled(
            !store.canEdit(record.id)
        )
    }


    func navigationRow(
        _ title: String
    ) -> some View {
        HStack(
            spacing: Theme.spaceM
        ) {
            Text(title)
                .font(Theme.body)
                .foregroundStyle(
                    Theme.ink
                )

            Spacer()

            Image(
                systemName:
                    "chevron.right"
            )
            .font(Theme.micro)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
        .padding(
            .vertical,
            Theme.rowPadding
        )
        .contentShape(Rectangle())
    }


}


// MARK: - Protocol evolution

struct ProtocolEvolutionView: View {
    let protocolID: UUID

    @Environment(TrackingStore.self)
    private var store

    private var summary:
        ProtocolEvolutionSummary {
        ProtocolEvolutionSummary(
            store: store,
            protocolID: protocolID
        )
    }

    private var timeline:
        [ScheduleRevision] {
        store.revisions
            .filter {
                $0.protocolID
                    == protocolID
            }
            .sorted {
                $0.effectiveFrom
                    > $1.effectiveFrom
            }
    }

    var body: some View {
        Form {
            if store.isPremium {
                sinceLastChangeSection

                if summary.comparison != nil {
                    comparisonSection
                }

                if !summary.cycleRuns.isEmpty {
                    cycleHistorySection
                }

            } else if summary.latestChange
                != nil
                || !summary.cycleRuns
                    .isEmpty {
                Section {
                    Button {
                        store.requestPaywall(.compare)
                    } label: {
                        Label(
                            "Unlock change analysis",
                            systemImage:
                                "arrow.left.arrow.right"
                        )
                    }

                } header: {
            Eyebrow(text: "Evolution analysis")
        } footer: { FormFooter {
                    Text(
                        "Pro adds deterministic before/after, since-change, and cycle-history analysis."
                    )
                }
}
            }

            revisionTimelineSection

            Section {
                NavigationLink {
                    HistoryView(
                        protocolID:
                            protocolID
                    )
                } label: {
                    Label(
                        "Open full timeline",
                        systemImage:
                            "clock.arrow.circlepath"
                    )
                }
            } header: {
                Eyebrow(text: "History")
            }
        }
        .listStyle(.plain)
        .paperList()
            .scrollContentBackground(.hidden)
        .navigationTitle(
            "Protocol evolution"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


private extension ProtocolEvolutionView {

    @ViewBuilder
    var sinceLastChangeSection:
        some View {
        if let since =
            summary.sinceLastChange {
            Section {
                Text(
                    since.change.detail
                )
                .font(Theme.body)
                .foregroundStyle(
                    Theme.ink
                )

                RecordRow(
                    label: "Changed",
                    value:
                        since.change.at
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .omitted
                            )
                )

                RecordRow(
                    label: "Days since",
                    value:
                        String(
                            since.days
                        )
                )

                RecordRow(
                    label: "Consistency",
                    value:
                        since.metrics
                            .percentage
                        + " · "
                        + String(
                            since.metrics
                                .recordedScheduled
                        )
                        + "/"
                        + String(
                            since.metrics
                                .scheduled
                        )
                )

                RecordRow(
                    label: "Logged entries",
                    value:
                        String(
                            since.metrics
                                .loggedEntries
                        )
                )

                if since.metrics
                    .skippedEntries > 0 {
                    RecordRow(
                        label: "Skipped",
                        value:
                            String(
                                since.metrics
                                    .skippedEntries
                            )
                    )
                }

                if since.metrics
                    .observations > 0 {
                    RecordRow(
                        label:
                            "Recorded observations",
                        value:
                            String(
                                since.metrics
                                    .observations
                            )
                    )
                }

            } header: {
            Eyebrow(text: "Since last change")
        } footer: { FormFooter {
                Text(
                    "Descriptive record summary only. Changes in consistency or observations do not establish medical effect or causation."
                )
            }
}
        }
    }


    @ViewBuilder
    var comparisonSection:
        some View {
        if let comparison =
            summary.comparison {
            Section {
                Text(
                    comparison
                        .change
                        .detail
                )
                .font(Theme.body)
                .foregroundStyle(
                    Theme.ink
                )

                RecordRow(
                    label: "Consistency",
                    value:
                        comparison.before
                            .percentage
                        + " → "
                        + comparison.after
                            .percentage
                )

                if let delta =
                    comparison
                        .consistencyDelta {
                    RecordRow(
                        label:
                            "Consistency change",
                        value:
                            (
                                delta > 0
                                ? "+"
                                : ""
                            )
                            + String(delta)
                            + " percentage points"
                    )
                }

                RecordRow(
                    label: "Logged entries",
                    value:
                        String(
                            comparison
                                .before
                                .loggedEntries
                        )
                        + " → "
                        + String(
                            comparison
                                .after
                                .loggedEntries
                        )
                )

                RecordRow(
                    label: "Skipped",
                    value:
                        String(
                            comparison
                                .before
                                .skippedEntries
                        )
                        + " → "
                        + String(
                            comparison
                                .after
                                .skippedEntries
                        )
                )

                RecordRow(
                    label: "Observations",
                    value:
                        String(
                            comparison
                                .before
                                .observations
                        )
                        + " → "
                        + String(
                            comparison
                                .after
                                .observations
                        )
                )

                let labPairs =
                    LabComparisonEngine
                        .pairs(
                            labs: store.labs,
                            protocolID:
                                protocolID,
                            change:
                                comparison
                                    .change
                                    .at,
                            beforePeriod:
                                comparison
                                    .beforePeriod,
                            afterPeriod:
                                comparison
                                    .afterPeriod
                        )

                if !labPairs.isEmpty {
                    VStack(
                        alignment: .leading,
                        spacing:
                            Theme.spaceS
                    ) {
                        Eyebrow(text: "Labs around change")

                        ForEach(
                            labPairs
                        ) { pair in
                            RecordRow(
                                label:
                                    pair.marker,
                                value:
                                    pair.valueText
                            )
                        }

                        Text(
                            "Closest matching recorded values in each comparison window."
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }
                }

                Text(
                    comparison
                        .beforePeriod
                        .start
                        .formatted(
                            date:
                                .abbreviated,
                            time:
                                .omitted
                        )
                    + " – "
                    + comparison
                        .afterPeriod
                        .end
                        .formatted(
                            date:
                                .abbreviated,
                            time:
                                .omitted
                        )
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
                .monospacedDigit()

            } header: {
            Eyebrow(text: "Before / after")
        } footer: { FormFooter {
                Text(
                    "Equal-duration windows, up to 30 days each. Differences are descriptive and do not establish causation."
                )
            }
}
        }
    }


    var cycleHistorySection:
        some View {
        Section {
            ForEach(
                summary.cycleRuns
            ) { run in
                VStack(
                    alignment: .leading,
                    spacing:
                        Theme.spaceXS
                ) {
                    HStack(
                        alignment:
                            .firstTextBaseline,
                        spacing:
                            Theme.spaceS
                    ) {
                        Text(
                            run.compoundName
                        )
                        .font(
                            Theme.sectionTitle
                        )
                        .foregroundStyle(
                            Theme.ink
                        )

                        Spacer()

                        StatusBadge(
                            text:
                                run.isCurrent
                                ? "Active"
                                : (
                                    run.isRestart
                                    ? "Restarted"
                                    : "Recorded"
                                )
                        )
                    }

                    Text(
                        run.startedAt
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .omitted
                            )
                        + " – "
                        + run.endedAt
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .omitted
                            )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )

                    RecordRow(
                        label:
                            "Scheduled consistency",
                        value:
                            run.percentage
                            + " · "
                            + String(
                                run.recorded
                            )
                            + "/"
                            + String(
                                run.scheduled
                            )
                    )
                }
                .padding(
                    .vertical,
                    Theme.spaceXXS
                )
            }

        } header: {
            Eyebrow(text: "Cycle history")
        } footer: { FormFooter {
            Text(
                "Cycle history reflects the ON/OFF schedule you recorded and entries logged against it. It does not recommend a cycle."
            )
        }
}
    }


    var revisionTimelineSection:
        some View {
        Section {
            PhaseTimeline(revisions: timeline)
        } header: {
            Eyebrow(text: "Phases")
        }
    }


    func stateLabel(
        _ revision: ScheduleRevision
    ) -> String {
        switch revision.temporalState() {
        case .historical:
            return "Past"
        case .current:
            return "Current"
        case .planned:
            return "Planned"
        }
    }


    func effectiveLabel(
        _ revision: ScheduleRevision
    ) -> String {
        let start =
            revision.effectiveFrom
                .formatted(
                    date: .abbreviated,
                    time: .omitted
                )

        if let end =
            revision.effectiveUntil {
            return
                start
                + " – "
                + end.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
        }

        return
            revision.isPlanned()
            ? "From " + start
            : start + " – present"
    }
}

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
    @State private var calculator = false
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
        .sheet(
            isPresented: $calculator
        ) {
            CalculatorView()
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
                spacing: Theme.spaceXL
            ) {
                if !store.canEdit(
                    record.id
                ) {
                    readOnlyBlock(record)
                }

                recordedInstructions(
                    record
                )

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

                toolsBlock(record)
                protocolActions(record)
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(
            .inline
        )
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


    func readOnlyBlock(
        _ record: ProtocolRecord
    ) -> some View {
        editorialSection(
            "Free tracking"
        ) {
            HStack(
                spacing: Theme.spaceS
            ) {
                Image(
                    systemName: "lock"
                )
                .foregroundStyle(
                    Theme.muted
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
        editorialSection(
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
        editorialSection(
            revision.compoundName
        ) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Eyebrow(
                    text:
                        revision.config?
                            .kind
                            == .asRecorded
                        ? "Recorded amount"
                        : "Scheduled amount"
                )

                Text(
                    revision.amountText
                    + " "
                    + revision.unitText
                )
                .font(
                    Theme.metricLarge
                )
                .foregroundStyle(
                    Theme.ink
                )
                .monospacedDigit()
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
                TrackingPrimaryButtonStyle()
            )
            .disabled(
                !store.canTrack(
                    record.id
                )
            )

            HStack(
                spacing: Theme.spaceS
            ) {
                Button(
                    "Edit schedule"
                ) {
                    editing = revision
                }
                .buttonStyle(
                    TrackingSecondaryButtonStyle()
                )
                .disabled(
                    !store.canEdit(
                        record.id
                    )
                )

                Button(
                    "Plan change"
                ) {
                    planning = revision
                }
                .buttonStyle(
                    TrackingSecondaryButtonStyle()
                )
                .disabled(
                    !store.canEdit(
                        record.id
                    )
                )
            }
        }
    }


    func plannedChangesBlock(
        _ revisions:
            [ScheduleRevision],
        record: ProtocolRecord
    ) -> some View {
        editorialSection(
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
                                "Effective "
                                + revision
                                    .effectiveFrom
                                    .formatted(
                                        date:
                                            .abbreviated,
                                        time:
                                            .omitted
                                    )
                            )
                            .font(
                                Theme.caption
                            )
                            .foregroundStyle(
                                Theme
                                    .textSecondary
                            )
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

                if index
                    < revisions.count - 1 {
                    Rectangle()
                        .fill(
                            Theme.hairline
                        )
                        .frame(
                            height:
                                Theme
                                    .ruleThickness
                        )
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


    func toolsBlock(
        _ record: ProtocolRecord
    ) -> some View {
        editorialSection("Tools") {
            NavigationLink {
                ProtocolEvolutionView(
                    protocolID: record.id
                )
            } label: {
                navigationRow(
                    "Protocol evolution"
                )
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )

            NavigationLink {
                InventoryView()
            } label: {
                navigationRow(
                    "Vial inventory"
                )
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )

            Button {
                calculator = true
            } label: {
                navigationRow(
                    "Calculator"
                )
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )

            Button {
                addCompound = true
            } label: {
                navigationRow(
                    "Add compound"
                )
            }
            .buttonStyle(.plain)
            .disabled(
                !store.canEdit(
                    record.id
                )
            )
        }
    }


    func protocolActions(
        _ record: ProtocolRecord
    ) -> some View {
        editorialSection(
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
                Theme.muted
            )
        }
        .padding(
            .vertical,
            Theme.spaceS
        )
        .contentShape(Rectangle())
    }


    func editorialSection<
        Content: View
    >(
        _ title: String,
        @ViewBuilder content:
            () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            Eyebrow(text: title)

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )

            content()

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    height:
                        Theme.ruleThickness
                )
        }
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
        List {
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
                    Text("Evolution analysis")
                } footer: {
                    Text(
                        "Pro adds deterministic before/after, since-change, and cycle-history analysis."
                    )
                }
            }

            revisionTimelineSection

            Section("History") {
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
                Text("Since last change")
            } footer: {
                Text(
                    "Descriptive record summary only. Changes in consistency or observations do not establish medical effect or causation."
                )
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
                Text("Before / after")
            } footer: {
                Text(
                    "Equal-duration windows, up to 30 days each. Differences are descriptive and do not establish causation."
                )
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
            Text("Cycle history")
        } footer: {
            Text(
                "Cycle history reflects the ON/OFF schedule you recorded and entries logged against it. It does not recommend a cycle."
            )
        }
    }


    var revisionTimelineSection:
        some View {
        Section("Revision timeline") {
            ForEach(timeline) {
                revision in

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
                            revision
                                .compoundName
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
                                stateLabel(
                                    revision
                                )
                        )
                    }

                    RecordRow(
                        label: "Amount",
                        value:
                            revision
                                .amountText
                            + " "
                            + revision
                                .unitText
                    )

                    RecordRow(
                        label: "Effective",
                        value:
                            effectiveLabel(
                                revision
                            )
                    )

                    RecordRow(
                        label: "Schedule",
                        value:
                            revision.config
                                .map(
                                    ScheduleDisplay
                                        .summary
                                )
                            ?? "Not available"
                    )
                }
                .padding(
                    .vertical,
                    Theme.spaceXXS
                )
            }
        }
    }


    func stateLabel(
        _ revision: ScheduleRevision
    ) -> String {
        switch revision.temporalState() {
        case .historical:
            return "Historical"
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

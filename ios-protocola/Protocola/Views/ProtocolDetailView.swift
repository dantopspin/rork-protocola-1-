import SwiftUI

struct ProtocolDetailView: View {
    let protocolID: UUID

    @Environment(TrackingStore.self) private var store

    @State private var editing: ScheduleRevision?
    @State private var planning: ScheduleRevision?
    @State private var editingPlanned: ScheduleRevision?
    @State private var cancellingPlanned: ScheduleRevision?
    @State private var logging: ScheduleRevision?
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
                protocolList(record)

            } else {
                TrackingEmptyState(
                    icon:
                        "list.bullet.rectangle",
                    title: "Protocol unavailable",
                    message:
                        "This protocol is no longer available."
                )
                .screenPadding()
            }
        }
        .sheet(isPresented: $choice) {
            FreeProtocolChoiceView()
        }
        .sheet(isPresented: $calculator) {
            CalculatorView()
        }
        .trackingErrors()
    }
}


// MARK: - Content

private extension ProtocolDetailView {

    func protocolList(
        _ record: ProtocolRecord
    ) -> some View {
        List {
            if !store.canEdit(record.id) {
                Section {
                    Label(
                        "Read-only on Free",
                        systemImage: "lock"
                    )
                    .foregroundStyle(Theme.textSecondary)

                    Button(
                        "Choose protocol for Free tracking"
                    ) {
                        choice = true
                    }

                } footer: {
                    Text(
                        "Your full history is preserved. Choose one active protocol to continue editing and logging on Free."
                    )
                }
            }

            Section("Recorded instructions") {
                RecordRow(
                    label: "Source",
                    value:
                        record.instructionSource
                )

                RecordRow(
                    label: "Status",
                    value: record.status
                )

                if !record.notes.isEmpty {
                    Text(record.notes)
                        .font(Theme.body)
                }
            }

            ForEach(
                store.currentRevisions(
                    record.id
                )
            ) { revision in
                scheduleSection(
                    revision,
                    record: record
                )
            }

            let planned =
                store.plannedRevisions(
                    record.id
                )

            if !planned.isEmpty {
                plannedChangesSection(
                    planned,
                    record: record
                )
            }

            Section("Tools") {
                NavigationLink {
                    HistoryView(
                        protocolID: record.id
                    )
                } label: {
                    Label(
                        "Protocol evolution",
                        systemImage:
                            "clock.arrow.circlepath"
                    )
                }

                NavigationLink {
                    InventoryView()
                } label: {
                    Label(
                        "Vial inventory",
                        systemImage: "shippingbox"
                    )
                }

                Button {
                    calculator = true
                } label: {
                    Label(
                        "Calculator",
                        systemImage: "function"
                    )
                }

                Button {
                    addCompound = true
                } label: {
                    Label(
                        "Add compound",
                        systemImage: "plus"
                    )
                }
                .disabled(
                    !store.canEdit(record.id)
                )
            }

            Section {
                Button {
                    store.changeStatus(
                        record,
                        status:
                            record.status == "Active"
                            ? "Paused"
                            : "Active"
                    )
                } label: {
                    Text(
                        record.status == "Active"
                            ? "Pause protocol"
                            : "Resume protocol"
                    )
                }

                if record.status != "Archived" {
                    Button(
                        "Archive protocol",
                        role: .destructive
                    ) {
                        store.changeStatus(
                            record,
                            status: "Archived"
                        )
                    }
                }

            } footer: {
                Text(
                    "Changes apply from now onward. Past schedules and entry snapshots remain unchanged."
                )
            }
            .disabled(
                !store.canEdit(record.id)
            )
        }
        .listStyle(.insetGrouped)
        .paperList()
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
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
                cancellingPlanned = nil
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

                cancellingPlanned = nil
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
            isPresented: $addCompound
        ) {
            ProtocolEditorView(
                record: record
            )
        }
    }


    func plannedChangesSection(
        _ revisions: [ScheduleRevision],
        record: ProtocolRecord
    ) -> some View {
        Section("Planned changes") {
            ForEach(revisions) {
                revision in

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
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
                                revision
                                    .compoundName
                            )
                            .font(
                                Theme.sectionTitle
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
                                Theme.textSecondary
                            )
                        }

                        Spacer()

                        StatusBadge(
                            text: "Planned"
                        )
                    }

                    RecordRow(
                        label: "Amount",
                        value:
                            revision.amountText
                            + " "
                            + revision.unitText
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

                    HStack(
                        spacing: Theme.spaceS
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
                    Theme.spaceXXS
                )
            }

        } footer: {
            Text(
                "Planned revisions do not change past records and take effect only on their recorded date."
            )
        }
        .disabled(
            !store.canEdit(record.id)
        )
    }


    func scheduleSection(
        _ revision: ScheduleRevision,
        record: ProtocolRecord
    ) -> some View {
        Section(revision.compoundName) {
            RecordRow(
                label:
                    revision.config?.kind
                        == .asRecorded
                    ? "Recorded amount"
                    : "Scheduled amount",
                value:
                    revision.amountText
                    + " "
                    + revision.unitText
            )

            RecordRow(
                label: "Route",
                value: revision.routeText
            )

            RecordRow(
                label: "Schedule",
                value:
                    revision.config.map(
                        ScheduleDisplay.summary
                    )
                    ?? "Not available"
            )

            if let config = revision.config,
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
                revision.configuredSite {
                RecordRow(
                    label: "Configured site",
                    value: site
                )
            }

            Button {
                editing = revision
            } label: {
                Label(
                    "Edit recorded schedule",
                    systemImage: "pencil"
                )
            }
            .disabled(
                !store.canEdit(record.id)
            )

            Button {
                planning = revision
            } label: {
                Label(
                    "Plan future change",
                    systemImage:
                        "calendar.badge.plus"
                )
            }
            .disabled(
                !store.canEdit(record.id)
            )

            Button {
                logging = revision
            } label: {
                Label(
                    revision.config?.kind
                        == .asRecorded
                    ? "Log entry"
                    : "Log unscheduled entry",
                    systemImage:
                        "plus.circle"
                )
            }
            .disabled(
                !store.canTrack(record.id)
            )
        }
    }
}

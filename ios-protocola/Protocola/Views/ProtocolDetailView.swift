import SwiftUI

struct ProtocolDetailView: View {
    let protocolID: UUID

    @Environment(TrackingStore.self) private var store

    @State private var editing: ScheduleRevision?
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
                ContentUnavailableView(
                    "Protocol unavailable",
                    systemImage:
                        "list.bullet.rectangle"
                )
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
                    .foregroundStyle(.secondary)

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


    func scheduleSection(
        _ revision: ScheduleRevision,
        record: ProtocolRecord
    ) -> some View {
        Section(revision.compoundName) {
            RecordRow(
                label: "Scheduled amount",
                value:
                    revision.amountText
                    + " "
                    + revision.unitText
            )

            RecordRow(
                label: "Schedule",
                value:
                    revision.config.map(
                        ScheduleDisplay.summary
                    )
                    ?? "Not available"
            )

            RecordRow(
                label: "Vial",
                value:
                    store.vial(
                        revision.vialID
                    )?.name
                    ?? "Not selected"
            )

            if let site =
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
                logging = revision
            } label: {
                Label(
                    "Log unscheduled entry",
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

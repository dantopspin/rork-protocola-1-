import SwiftUI

struct VialDetailView: View {
    let vialID: UUID

    @Environment(TrackingStore.self) private var store

    @State private var edit = false

    var body: some View {
        Group {
            if let vial = store.vial(vialID) {
                List {
                    inventorySection(vial)
                    vialDetailsSection(vial)
                    actionsSection(vial)
                    recordedEntriesSection(vial)
                }
                .listStyle(.insetGrouped)
                .paperList()
                .trackingRoutes()
                .navigationTitle(vial.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        Button(
                            "Edit vial",
                            systemImage: "pencil"
                        ) {
                            edit = true
                        }
                    }
                }
                .sheet(isPresented: $edit) {
                    VialEditorView(
                        vial: vial
                    )
                }

            } else {
                ContentUnavailableView(
                    "Vial unavailable",
                    systemImage: "shippingbox"
                )
            }
        }
        .trackingErrors()
    }
}


// MARK: - Sections

private extension VialDetailView {

    func inventorySection(
        _ vial: VialRecord
    ) -> some View {
        Section("Inventory") {
            RecordRow(
                label: "Remaining",
                value:
                    DoseCalculator.text(
                        store.balances[
                            vial.id
                        ] ?? 0
                    )
                    + " mg"
            )

            RecordRow(
                label: "Status",
                value:
                    store.vialStatus(vial)
            )

            if let entries =
                store
                    .scheduledEntriesRemaining(
                        in: vial
                    ),
               entries > 0 {
                RecordRow(
                    label:
                        "Scheduled entries",
                    value:
                        "~"
                        + String(entries)
                        + " remaining"
                )
            }

            if let expiry = vial.expiry {
                RecordRow(
                    label: "Expiry / discard",
                    value:
                        expiry.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                )
            }

            let status =
                store.vialStatus(vial)

            if [
                "Low recorded balance",
                "Depleted"
            ]
            .contains(status) {
                Label(
                    status,
                    systemImage:
                        "exclamationmark.circle"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.amber)
            }
        }
    }


    func vialDetailsSection(
        _ vial: VialRecord
    ) -> some View {
        Section("Recorded vial") {
            RecordRow(
                label: "Compound",
                value: vial.compoundName
            )

            RecordRow(
                label: "Original",
                value:
                    vial.originalMgText
                    + " mg"
            )

            RecordRow(
                label: "Diluent",
                value:
                    vial.diluentMlText
                    + " mL"
            )

            RecordRow(
                label: "Concentration",
                value:
                    vial.concentration.map {
                        DoseCalculator.text($0)
                            + " mg/mL"
                    }
                    ?? "Not recorded"
            )

            RecordRow(
                label: "Batch",
                value:
                    vial.batch.isEmpty
                    ? "Not recorded"
                    : vial.batch
            )

            RecordRow(
                label: "Supplier / clinic",
                value:
                    vial.supplier.isEmpty
                    ? "Not recorded"
                    : vial.supplier
            )

            if !vial.storageNotes.isEmpty {
                Text(vial.storageNotes)
                    .font(.subheadline)
            }
        }
    }


    func actionsSection(
        _ vial: VialRecord
    ) -> some View {
        Section {
            Button {
                store.archiveVial(vial)
            } label: {
                Label(
                    vial.isArchived
                        ? "Restore vial"
                        : "Archive vial",
                    systemImage:
                        vial.isArchived
                        ? "arrow.uturn.backward"
                        : "archivebox"
                )
            }
        }
    }


    func recordedEntriesSection(
        _ vial: VialRecord
    ) -> some View {
        let logs =
            store.logs.filter {
                $0.vialID == vial.id
            }

        return Section("Recorded entries") {
            if logs.isEmpty {
                Text(
                    "No entries use this vial yet."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

            } else {
                ForEach(logs) { log in
                    NavigationLink(
                        value:
                            TrackingRoute
                                .logDetail(log.id)
                    ) {
                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceXXS
                        ) {
                            HStack(
                                alignment:
                                    .firstTextBaseline
                            ) {
                                Text(
                                    log.actualAmountText
                                    + " "
                                    + log.unitText
                                )
                                .font(.headline)

                                Spacer()

                                Text(log.status)
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }

                            Text(
                                log.loggedAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        }
                        .padding(
                            .vertical,
                            Theme.spaceXXS
                        )
                    }
                }
            }
        }
    }
}

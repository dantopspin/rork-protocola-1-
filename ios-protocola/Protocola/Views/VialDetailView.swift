import SwiftUI
import UIKit

struct VialDetailView: View {
    let vialID: UUID

    @Environment(TrackingStore.self)
    private var store

    @State private var edit = false

    var body: some View {
        Group {
            if let vial = store.vial(vialID) {
                List {
                    inventorySection(vial)

                    if vial.photoData != nil {
                        photoSection(vial)
                    }

                    vialDetailsSection(vial)
                    actionsSection(vial)
                    recordedEntriesSection(vial)
                }
                .listStyle(.plain)
                .paperList()
            .scrollContentBackground(.hidden)
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
                    VialEditorView(vial: vial)
                }

            } else {
                TrackingEmptyState(
                    icon: "shippingbox",
                    title: "Vial unavailable",
                    message:
                        "This vial record is no longer available."
                )
                .screenPadding()
            }
        }
        .trackingErrors()
    }
}

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
                label: "State",
                value:
                    vial.lifecycleState
                        .rawValue
            )

            RecordRow(
                label: "Balance status",
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
                    label: "Scheduled entries",
                    value:
                        "~"
                        + String(entries)
                        + " remaining"
                )
            }

            if let doses =
                store.dosesPerVial(vial),
               doses > 0 {
                RecordRow(
                    label: "Original vial yield",
                    value:
                        "~"
                        + String(doses)
                        + (
                            doses == 1
                            ? " entry"
                            : " entries"
                        )
                )
            }

            if let depletion =
                store
                    .estimatedDepletionDate(
                        in: vial
                    ) {
                RecordRow(
                    label: "Estimated depletion",
                    value:
                        depletion.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
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
            ].contains(status) {
                Label(
                    status,
                    systemImage:
                        "exclamationmark.circle"
                )
                .font(Theme.label)
                .foregroundStyle(Theme.amber)
            }

            Text(
                "Supply estimates use only compatible fixed-mass schedules linked to this vial and your recorded balance."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }

    func photoSection(
        _ vial: VialRecord
    ) -> some View {
        Section("Reference photo") {
            if let data = vial.photoData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight:
                            Theme.vialPhotoHeight
                    )
                    .clipShape(
                        .rect(
                            cornerRadius:
                                Theme.radiusRow
                        )
                    )
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

            if let reconstituted =
                vial.reconstitutedAt {
                RecordRow(
                    label: "Reconstituted",
                    value:
                        reconstituted.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                )
            }

            if let opened = vial.openedAt {
                RecordRow(
                    label: "Opened",
                    value:
                        opened.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                )
            }

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
                    .font(Theme.body)
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
                    vial.lifecycleState
                        == .archived
                        ? "Restore as active"
                        : "Archive vial",
                    systemImage:
                        vial.lifecycleState
                            == .archived
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
                .font(Theme.body)
                .foregroundStyle(
                    Theme.textSecondary
                )
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
                                .font(
                                    Theme.sectionTitle
                                )

                                Spacer()

                                Text(log.status)
                                    .font(Theme.caption)
                                    .foregroundStyle(
                                        Theme.textSecondary
                                    )
                            }

                            Text(
                                log.loggedAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(Theme.caption)
                            .foregroundStyle(
                                Theme.textSecondary
                            )
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

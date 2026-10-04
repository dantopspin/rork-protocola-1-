import SwiftUI

struct LogDetailView: View {
    let logID: UUID

    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var edit = false
    @State private var confirm = false

    var body: some View {
        Group {
            if let log =
                store.logs.first(
                    where: {
                        $0.id == logID
                    }
                ) {
                List {
                    entrySection(log)
                    recordedContextSection(log)
                    observationsSection(log)
                    actionsSection(log)
                }
                .listStyle(.insetGrouped)
                .paperList()
                .navigationTitle("Entry details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        Button(
                            "Correct entry",
                            systemImage: "pencil"
                        ) {
                            edit = true
                        }
                        .disabled(
                            !store.canEdit(
                                log.protocolID
                            )
                        )
                    }
                }
                .sheet(isPresented: $edit) {
                    DoseEditorView(
                        correcting: log
                    )
                }
                .confirmationDialog(
                    "Delete this entry?",
                    isPresented: $confirm,
                    titleVisibility: .visible
                ) {
                    Button(
                        "Delete and reconcile",
                        role: .destructive
                    ) {
                        if store.deleteDose(log) {
                            dismiss()
                        }
                    }

                    Button(
                        "Cancel",
                        role: .cancel
                    ) {}
                } message: {
                    Text(
                        "The consumed amount will be restored to the recorded vial balance. This cannot be undone."
                    )
                }

            } else {
                TrackingEmptyState(
                    icon: "clock",
                    title: "Entry unavailable",
                    message:
                        "This recorded entry is no longer available."
                )
                .screenPadding()
            }
        }
        .trackingErrors()
    }
}


// MARK: - Sections

private extension LogDetailView {

    func entrySection(
        _ log: DoseLog
    ) -> some View {
        Section("Recorded entry") {
            RecordRow(
                label: "Compound",
                value: log.compoundName
            )

            RecordRow(
                label: "Protocol",
                value: log.protocolName
            )

            RecordRow(
                label: "Route",
                value: log.routeText
            )

            RecordRow(
                label: "Actual amount",
                value:
                    log.actualAmountText
                    + " "
                    + log.unitText
            )

            RecordRow(
                label: "Recorded time",
                value:
                    log.loggedAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
            )

            RecordRow(
                label: "Status",
                value: log.status
            )
        }
    }


    func recordedContextSection(
        _ log: DoseLog
    ) -> some View {
        Section("Historical snapshot") {
            RecordRow(
                label: "Scheduled amount",
                value:
                    log.scheduledAmountText
                    + " "
                    + log.scheduledUnitText
            )

            if let scheduled =
                log.scheduledAt {
                RecordRow(
                    label: "Scheduled time",
                    value:
                        scheduled.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                )
            }

            if log.route.usesInjectionSite {
                RecordRow(
                    label: "Vial",
                    value: log.vialName
                )
            }

            if log.route.usesInjectionSite,
               let concentration =
                log.concentrationText {
                RecordRow(
                    label:
                        "Recorded concentration",
                    value:
                        concentration
                        + " mg/mL"
                )
            }

            if log.route.usesInjectionSite,
               let volume =
                log.volumeMlText {
                RecordRow(
                    label: "Volume",
                    value:
                        volume + " mL"
                )

                if let volumeDecimal =
                    Decimal(string: volume) {
                    RecordRow(
                        label: "Syringe units",
                        value:
                            DoseCalculator.text(
                                volumeDecimal
                                * log.unitsPerMl
                            )
                    )
                }
            }

            if let corrected =
                log.correctedAt {
                RecordRow(
                    label: "Corrected",
                    value:
                        corrected.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                )
            }
        }
    }


    func observationsSection(
        _ log: DoseLog
    ) -> some View {
        Section("Observations") {
            if log.route.usesInjectionSite {
                RecordRow(
                    label: "Site",
                    value:
                        log.site.isEmpty
                        ? "Not recorded"
                        : log.site
                )
            }

            if !log.symptoms.isEmpty {
                RecordRow(
                    label: "Symptoms",
                    value:
                        log.symptoms
                        + " · "
                        + String(
                            log.symptomSeverity
                        )
                        + "/10"
                )
            }

            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(Theme.body)
            }

            if log.symptoms.isEmpty,
               log.notes.isEmpty,
               (
                    !log.route
                        .usesInjectionSite
                    || log.site.isEmpty
               ) {
                Text(
                    "No site, symptoms, or notes were recorded."
                )
                .font(Theme.body)
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }


    func actionsSection(
        _ log: DoseLog
    ) -> some View {
        Section {
            Button(
                "Delete entry",
                role: .destructive
            ) {
                confirm = true
            }
            .disabled(
                !store.canEdit(
                    log.protocolID
                )
            )

        } footer: {
            Text(
                "Corrections and deletions automatically reconcile inventory. Protocol edits never rewrite this historical snapshot."
            )
        }
    }
}

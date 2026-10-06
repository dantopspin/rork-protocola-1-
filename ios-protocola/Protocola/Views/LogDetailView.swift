import SwiftUI

struct LogDetailView: View {
    let logID: UUID

    @Environment(TrackingStore.self)
    private var store

    @Environment(\.dismiss)
    private var dismiss

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
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.sectionGap
                    ) {
                        recordedEntry(log)
                        historicalSnapshot(log)
                        observations(log)
                    }
                    .screenPadding()
                    .padding(
                        .bottom,
                        Theme.spaceXL
                    )
                }
                .scrollIndicators(.hidden)
                .background(Theme.paper)
                .navigationTitle(
                    "Entry details"
                )
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .toolbar {
                    ToolbarItem(
                        placement:
                            .topBarTrailing
                    ) {
                        Menu {
                            Button {
                                edit = true
                            } label: {
                                Label(
                                    "Correct entry",
                                    systemImage:
                                        "pencil"
                                )
                            }
                            .disabled(
                                !store.canEdit(
                                    log.protocolID
                                )
                            )

                            Divider()

                            Button(
                                role: .destructive
                            ) {
                                confirm = true
                            } label: {
                                Label(
                                    "Delete entry",
                                    systemImage:
                                        "trash"
                                )
                            }
                            .disabled(
                                !store.canEdit(
                                    log.protocolID
                                )
                            )
                        } label: {
                            Label(
                                "Entry actions",
                                systemImage:
                                    "ellipsis.circle"
                            )
                        }
                    }
                }
                .sheet(
                    isPresented: $edit
                ) {
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
                        if store
                            .deleteDose(log) {
                            Haptics.impact()
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
                    title:
                        "Entry unavailable",
                    message:
                        "This recorded entry is no longer available."
                )
                .screenPadding()
            }
        }
        .trackingErrors()
    }
}


private extension LogDetailView {

    func recordedEntry(
        _ log: DoseLog
    ) -> some View {
        EditorialSection(
            "Recorded entry"
        ) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Eyebrow(text: "Actual amount")

                Text(
                    log.actualAmountText
                    + " "
                    + log.unitText
                )
                .font(Theme.metricLarge)
                .foregroundStyle(
                    Theme.ink
                )
                .monospacedDigit()

                HStack(
                    spacing: Theme.spaceS
                ) {
                    StatusBadge(
                        text: log.status
                    )

                    Text(
                        log.loggedAt.formatted(
                            date:
                                .abbreviated,
                            time:
                                .shortened
                        )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .monospacedDigit()
                }
            }

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
        }
    }


    func historicalSnapshot(
        _ log: DoseLog
    ) -> some View {
        EditorialSection(
            "Historical snapshot"
        ) {
            RecordRow(
                label:
                    "Scheduled amount",
                value:
                    log.scheduledAmountText
                    + " "
                    + log.scheduledUnitText
            )

            if let scheduled =
                log.scheduledAt {
                RecordRow(
                    label:
                        "Scheduled time",
                    value:
                        scheduled.formatted(
                            date:
                                .abbreviated,
                            time:
                                .shortened
                        )
                )
            }

            if log.route
                .usesInjectionSite {
                RecordRow(
                    label: "Vial",
                    value:
                        log.vialName
                )
            }

            if log.route
                .usesInjectionSite,
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

            if log.route
                .usesInjectionSite,
               let volume =
                    log.volumeMlText {
                RecordRow(
                    label: "Volume",
                    value:
                        volume
                        + " mL"
                )

                if let volumeDecimal =
                    Decimal(
                        string: volume
                    ) {
                    RecordRow(
                        label:
                            "Syringe units",
                        value:
                            DoseCalculator
                                .text(
                                    volumeDecimal
                                    * log
                                        .unitsPerMl
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
                            date:
                                .abbreviated,
                            time:
                                .shortened
                        )
                )
            }

            Text(
                "This snapshot is retained exactly as recorded. Later protocol changes do not rewrite it."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    func observations(
        _ log: DoseLog
    ) -> some View {
        EditorialSection(
            "Observations"
        ) {
            if log.route
                .usesInjectionSite {
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
                    .foregroundStyle(
                        Theme.ink
                    )
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
                .foregroundStyle(
                    Theme.textSecondary
                )
            }
        }
    }


    func actions(
        _ log: DoseLog
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Button(
                "Delete entry",
                role: .destructive
            ) {
                confirm = true
            }
            .font(Theme.label)
            .frame(
                minHeight:
                    Theme.minimumTapTarget
            )
            .disabled(
                !store.canEdit(
                    log.protocolID
                )
            )

            Text(
                "Corrections and deletions automatically reconcile inventory."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


}

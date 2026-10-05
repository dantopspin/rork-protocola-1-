import SwiftUI

struct VisitSummaryView: View {
    @Environment(TrackingStore.self)
    private var store

    @Environment(\.dismiss)
    private var dismiss

    @State private var protocolID: UUID?
    @State private var fullHistory = true
    @State private var from =
        Calendar.current.date(
            byAdding: .day,
            value: -30,
            to: .now
        ) ?? .now
    @State private var to = Date.now
    @State private var url: URL?
    @State private var sharing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXL
                ) {
                    scopeSection
                    contentsSection
                    actionSection
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
                "Visit Summary"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                protocolID =
                    protocolID
                    ?? store.protocols
                        .first?
                        .id
            }
            .sheet(
                isPresented: $sharing
            ) {
                if let url {
                    ActivityView(
                        items: [url]
                    )
                }
            }
            .trackingErrors()
        }
    }
}


private extension VisitSummaryView {

    var scopeSection: some View {
        EditorialSection(
            "Record scope"
        ) {
            Picker(
                "Protocol",
                selection: $protocolID
            ) {
                ForEach(
                    store.protocols
                ) {
                    Text($0.name)
                        .tag(
                            Optional($0.id)
                        )
                }
            }

            Toggle(
                "Full recorded history",
                isOn: $fullHistory
            )

            if !fullHistory {
                DatePicker(
                    "From",
                    selection: $from,
                    displayedComponents:
                        .date
                )

                DatePicker(
                    "Through",
                    selection: $to,
                    displayedComponents:
                        .date
                )
            }
        }
    }


    var contentsSection: some View {
        EditorialSection(
            "Included records"
        ) {
            RecordRow(
                label: "Current protocol",
                value: "Included"
            )

            RecordRow(
                label: "Protocol changes",
                value: "Included"
            )

            RecordRow(
                label: "Recorded entries",
                value: "Included"
            )

            RecordRow(
                label: "Symptoms",
                value: "Included"
            )

            RecordRow(
                label: "Consistency",
                value: "Included"
            )

            RecordRow(
                label: "Labs",
                value:
                    String(
                        selectedLabCount
                    )
                    + (
                        selectedLabCount == 1
                        ? " record"
                        : " records"
                    )
            )

            RecordRow(
                label: "Timeline",
                value: "Included"
            )

            Text(
                "Prepared on this iPhone from retained records. The document is descriptive and does not provide medical interpretation."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    var selectedLabCount: Int {
        guard let protocolID else {
            return 0
        }

        let record =
            store.protocols.first {
                $0.id == protocolID
            }

        let start =
            fullHistory
            ? fullHistoryStart(
                record: record,
                protocolID:
                    protocolID
            )
            : Calendar.current
                .startOfDay(
                    for: from
                )

        let end =
            fullHistory
            ? Date.now
            : min(
                .now,
                Calendar.current.date(
                    byAdding: .day,
                    value: 1,
                    to:
                        Calendar.current
                            .startOfDay(
                                for: to
                            )
                ) ?? to
            )

        return store.labs.filter {
            $0.protocolID == protocolID
            && $0.collectedAt >= start
            && $0.collectedAt < end
        }.count
    }


    func fullHistoryStart(
        record: ProtocolRecord?,
        protocolID: UUID
    ) -> Date {
        let protocolStart =
            record?.createdAt
            ?? from
        let firstLinkedLab =
            store.labs
                .filter {
                    $0.protocolID
                        == protocolID
                }
                .map(\.collectedAt)
                .min()

        return min(
            protocolStart,
            firstLinkedLab
                ?? protocolStart
        )
    }


    var actionSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            if !store.isPremium {
                Text(
                    "Visit Summary PDF is included with Pro."
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
            }

            Button {
                prepareSummary()
            } label: {
                Text(
                    store.isPremium
                    ? "Prepare and share PDF"
                    : "Unlock Visit Summary"
                )
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )
            .disabled(protocolID == nil)
        }
    }




    func prepareSummary() {
        guard store.isPremium else {
            store.requestPaywall(
                .summary
            )
            return
        }

        guard let protocolID else {
            return
        }

        let record =
            store.protocols.first {
                $0.id == protocolID
            }

        let start =
            fullHistory
            ? fullHistoryStart(
                record: record,
                protocolID:
                    protocolID
            )
            : Calendar.current
                .startOfDay(
                    for: from
                )

        let end =
            fullHistory
            ? Date.now
            : min(
                .now,
                Calendar.current.date(
                    byAdding: .day,
                    value: 1,
                    to:
                        Calendar.current
                            .startOfDay(
                                for: to
                            )
                ) ?? to
            )

        guard start <= end else {
            store.error =
                "Choose a valid date range."
            return
        }

        do {
            url =
                try store
                    .visitSummaryURL(
                        protocolID:
                            protocolID,
                        period:
                            AnalysisPeriod(
                                start: start,
                                end: end
                            )
                    )

            Haptics.success()
            sharing = true

        } catch {
            store.error =
                "The Visit Summary could not be prepared. Please try again."
        }
    }
}

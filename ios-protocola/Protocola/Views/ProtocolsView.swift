import SwiftUI

struct ProtocolsView: View {
    @Environment(TrackingStore.self)
    private var store

    @State private var create = false
    @State private var choice = false
    @State private var calculator = false

    private var activeProtocols:
        [ProtocolRecord] {
        store.protocols.filter {
            $0.status == "Active"
        }
    }

    private var otherProtocols:
        [ProtocolRecord] {
        store.protocols.filter {
            $0.status != "Active"
        }
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {
                if !store.isPremium,
                   store.activeProtocolIDs.count > 1 {
                    freeChoiceCallout
                }

                if store.protocols.isEmpty {
                    TrackingEmptyState(
                        icon: "list.bullet.rectangle",
                        title: "No protocols yet",
                        message:
                            "Add an existing protocol to start building your recorded history.",
                        actionTitle: "Add protocol"
                    ) {
                        create = true
                    }

                } else {
                    if !activeProtocols.isEmpty {
                        protocolSection(
                            title: "Active protocols",
                            records:
                                activeProtocols,
                            featured: true
                        )
                    }

                    if !otherProtocols.isEmpty {
                        protocolSection(
                            title: "Other protocols",
                            records:
                                otherProtocols,
                            featured: false
                        )
                    }

                    toolsSection
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
        .navigationTitle("Protocols")
        .toolbar {
            ToolbarItem(
                placement:
                    .topBarTrailing
            ) {
                Button(
                    "Add protocol",
                    systemImage: "plus"
                ) {
                    if store.canCreateProtocol {
                        create = true
                    } else {
                        store.requestPaywall(
                            .secondProtocol
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $create) {
            ProtocolEditorView()
        }
        .sheet(isPresented: $choice) {
            FreeProtocolChoiceView()
        }
        .sheet(isPresented: $calculator) {
            CalculatorView()
        }
        .trackingRoutes()
        .trackingErrors()
    }
}


private extension ProtocolsView {

    var freeChoiceCallout: some View {
        Button {
            choice = true
        } label: {
            HStack(
                spacing: Theme.spaceS
            ) {
                VStack(
                    alignment: .leading,
                    spacing:
                        Theme.spaceXXS
                ) {
                    Eyebrow(
                        text: "Free tracking"
                    )

                    Text(
                        "Choose the protocol you want active on Free"
                    )
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.ink
                    )
                }

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
        }
        .buttonStyle(.plain)
        .overlay(
            alignment: .bottom
        ) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
    }


    func protocolSection(
        title: String,
        records: [ProtocolRecord],
        featured: Bool
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Eyebrow(text: title)

            VStack(spacing: 0) {
                ForEach(
                    Array(
                        records.enumerated()
                    ),
                    id: \.element.id
                ) { index, record in
                    NavigationLink(
                        value:
                            TrackingRoute
                                .protocolDetail(
                                    record.id
                                )
                    ) {
                        protocolRow(
                            record,
                            emphasized:
                                featured
                                && index == 0
                        )
                    }
                    .buttonStyle(.plain)

                    if index
                        < records.count - 1 {
                        Rectangle()
                            .fill(
                                Theme.hairline
                            )
                            .frame(height: 1)
                    }
                }
            }
            .overlay(
                alignment: .top
            ) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
            }
            .overlay(
                alignment: .bottom
            ) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
            }
        }
    }


    func protocolRow(
        _ record: ProtocolRecord,
        emphasized: Bool
    ) -> some View {
        let revisions =
            store.currentRevisions(
                record.id
            )
        let primary =
            revisions.first

        return VStack(
            alignment: .leading,
            spacing:
                emphasized
                ? Theme.spaceM
                : Theme.spaceS
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
                    Text(record.name)
                        .font(
                            emphasized
                            ? Theme.modalTitle
                            : Theme.sectionTitle
                        )
                        .foregroundStyle(
                            Theme.ink
                        )
                        .lineLimit(2)

                    if let primary {
                        Text(
                            primary.compoundName
                            + " · "
                            + primary.amountText
                            + " "
                            + primary.unitText
                        )
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme.muted
                        )
                    }
                }

                Spacer()

                StatusBadge(
                    text:
                        record.status
                            == "Active"
                        ? (
                            store.canTrack(
                                record.id
                            )
                            ? "Active"
                            : "Read-only"
                        )
                        : record.status
                )

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.muted
                )
            }

            if let primary {
                Text(
                    primary.config.map(
                        ScheduleDisplay.summary
                    )
                    ?? "Schedule unavailable"
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )

                if let config =
                    primary.config,
                   let cycle =
                    CycleDisplay.status(
                        config
                    ) {
                    Text(cycle)
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.muted
                        )
                }
            }

            if emphasized {
                HStack(
                    spacing:
                        Theme.spaceXXL
                ) {
                    editorialMetric(
                        label: "Next entry",
                        value:
                            nextEntry(
                                for: record.id
                            )?
                            .at
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .shortened
                            )
                            ?? "Not scheduled"
                    )

                    editorialMetric(
                        label: "Compounds",
                        value:
                            String(
                                revisions.count
                            )
                    )
                }
            }
        }
        .padding(
            .vertical,
            emphasized
                ? Theme.spaceM
                : Theme.spaceS
        )
        .contentShape(Rectangle())
    }


    func editorialMetric(
        label: String,
        value: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXXS
        ) {
            Eyebrow(text: label)

            Text(value)
                .font(Theme.label)
                .foregroundStyle(
                    Theme.ink
                )
                .monospacedDigit()
        }
    }


    var toolsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Eyebrow(text: "Tools")

            VStack(spacing: 0) {
                NavigationLink {
                    InventoryView()
                } label: {
                    toolRow(
                        title:
                            "Vial inventory",
                        detail:
                            inventorySummary
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)

                Button {
                    calculator = true
                } label: {
                    toolRow(
                        title:
                            "Calculator",
                        detail:
                            "Dose · Volume · Units"
                    )
                }
                .buttonStyle(.plain)
            }
            .overlay(
                alignment: .top
            ) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
            }
            .overlay(
                alignment: .bottom
            ) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
            }
        }
    }


    func toolRow(
        title: String,
        detail: String
    ) -> some View {
        HStack(
            spacing: Theme.spaceM
        ) {
            VStack(
                alignment: .leading,
                spacing:
                    Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )
            }

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
}


private extension ProtocolsView {

    func nextEntry(
        for protocolID: UUID
    ) -> ScheduledEntry? {
        let now = Date.now
        let end =
            Calendar.current.date(
                byAdding: .day,
                value: 90,
                to: now
            ) ?? now

        return store.entries(
            start: now,
            end: end
        )
        .first {
            $0.revision.protocolID
                == protocolID
        }
    }


    var inventorySummary: String {
        let active =
            store.vials.filter {
                !$0.isArchived
            }

        guard !active.isEmpty else {
            return "No vials recorded"
        }

        let low =
            active.filter {
                [
                    "Low recorded balance",
                    "Depleted"
                ]
                .contains(
                    store.vialStatus($0)
                )
            }.count

        if low > 0 {
            return
                "\(active.count) "
                + (
                    active.count == 1
                    ? "vial"
                    : "vials"
                )
                + " · \(low) need attention"
        }

        return
            "\(active.count) "
            + (
                active.count == 1
                ? "active vial"
                : "active vials"
            )
    }
}

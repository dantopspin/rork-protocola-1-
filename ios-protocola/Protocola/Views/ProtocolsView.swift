import SwiftUI

struct ProtocolsView: View {
    @Environment(TrackingStore.self) private var store

    @State private var create = false
    @State private var choice = false
    @State private var calculator = false

    private var activeProtocols: [ProtocolRecord] {
        store.protocols.filter {
            $0.status == "Active"
        }
    }

    private var otherProtocols: [ProtocolRecord] {
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
                            title: "Active",
                            records: activeProtocols,
                            featured: true
                        )
                    }

                    if !otherProtocols.isEmpty {
                        protocolSection(
                            title: "Other protocols",
                            records: otherProtocols,
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
                placement: .topBarTrailing
            ) {
                Button(
                    "Add protocol",
                    systemImage: "plus"
                ) {
                    if store.canCreateProtocol {
                        create = true
                    } else {
                        store.requestPaywall(.secondProtocol)
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


// MARK: - Sections

private extension ProtocolsView {

    var freeChoiceCallout: some View {
        Button {
            choice = true
        } label: {
            HStack(
                spacing: Theme.spaceS
            ) {
                Image(
                    systemName:
                        "checkmark.circle"
                )
                .foregroundStyle(
                    Theme.muted
                )

                Text(
                    "Choose protocol to track on Free"
                )
                .font(Theme.label)
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
            .padding(Theme.spaceM)
        }
        .buttonStyle(.plain)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius:
                    Theme.radiusRow
            )
        )
        .inkBorder(
            cornerRadius:
                Theme.radiusRow
        )
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
            Text(title)
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.ink
                )

            VStack(
                spacing: Theme.spaceXS
            ) {
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
                        protocolCard(
                            record,
                            emphasized:
                                featured
                                && index == 0
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }


    func protocolCard(
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
            spacing: Theme.spaceM
        ) {
            HStack(
                alignment: .top,
                spacing: Theme.spaceS
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text(record.name)
                        .font(Theme.sectionTitle)
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
                        record.status == "Active"
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
            }

            if emphasized {
                Divider()

                HStack(
                    spacing: Theme.spaceXL
                ) {
                    VStack(
                        alignment: .leading,
                        spacing:
                            Theme.spaceXXS
                    ) {
                        Text("Next entry")
                            .font(Theme.caption)
                            .foregroundStyle(
                                Theme.muted
                            )

                        Text(
                            nextEntry(
                                for:
                                    record.id
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
                        .font(Theme.label)
                        .foregroundStyle(
                            Theme.ink
                        )
                        .monospacedDigit()
                    }

                    VStack(
                        alignment: .leading,
                        spacing:
                            Theme.spaceXXS
                    ) {
                        Text("Compounds")
                            .font(Theme.caption)
                            .foregroundStyle(
                                Theme.muted
                            )

                        Text(
                            String(
                                revisions.count
                            )
                        )
                        .font(Theme.label)
                        .foregroundStyle(
                            Theme.ink
                        )
                        .monospacedDigit()
                    }
                }
            }
        }
        .padding(
            emphasized
                ? Theme.spaceM
                : Theme.spaceM
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            emphasized
                ? Theme.neutralTint
                : Theme.surface,
            in: .rect(
                cornerRadius:
                    Theme.radiusCard
            )
        )
        .inkBorder(
            cornerRadius:
                Theme.radiusCard
        )
    }


    var toolsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Text("Tools")
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.ink
                )

            VStack(spacing: 0) {
                NavigationLink {
                    InventoryView()
                } label: {
                    toolRow(
                        icon: "shippingbox",
                        title: "Vial inventory",
                        detail: inventorySummary
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(
                        .leading,
                        48
                    )

                Button {
                    calculator = true
                } label: {
                    toolRow(
                        icon: "function",
                        title: "Calculator",
                        detail:
                            "Dose · Volume · Units"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(
                .horizontal,
                Theme.spaceM
            )
            .background(
                Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusCard
                )
            )
            .inkBorder(
                cornerRadius:
                    Theme.radiusCard
            )
        }
    }


    func toolRow(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(
            spacing: Theme.spaceM
        ) {
            Image(systemName: icon)
                .font(Theme.label)
                .foregroundStyle(
                    Theme.teal
                )
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
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


// MARK: - Derived values

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

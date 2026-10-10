import SwiftUI

struct ProtocolsView: View {
    @Environment(\.dynamicTypeSize)
    private var typeSize

    @Environment(TrackingStore.self)
    private var store

    @State private var create = false
    @State private var choice = false

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
                spacing: Theme.sectionGap
            ) {
                DemoBannerCard()

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
            )
        }
        .trackingScrollChrome()
        .background(Theme.paper)
        .navigationTitle("Protocols")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            SettingsToolbarItem()

            ToolbarItem(
                placement:
                    .topBarTrailing
            ) {
                ProminentAddButton(
                    title: "Add protocol"
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
                    Theme.textSecondary
                )
            }
            .padding(
                .vertical,
                Theme.rowPadding
            )
        }
        .buttonStyle(TrackingCardButtonStyle())
        .overlay(
            alignment: .bottom
        ) {
            EditorialRule()
        }
    }


    func protocolSection(
        title: String,
        records: [ProtocolRecord],
        featured: Bool
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.sectionHeaderGap
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
                        )
                    }
                    .buttonStyle(
                        TrackingRowButtonStyle()
                    )
                    .trackingStagger(
                        index: index
                    )

                    if index
                        < records.count - 1 {
                        EditorialRule()
                    }
                }
            }
            .padding(.horizontal, Theme.cardInset)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
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
            spacing: Theme.spaceS
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
                        .font(Theme.cardTitle)
                        .foregroundStyle(
                            Theme.ink
                        )
                        .lineLimit(2)

                    if let primary {
                        Text(
                            DoseText.line(
                                compound:
                                    primary.compoundName,
                                amount:
                                    primary.amountText,
                                unit:
                                    primary.unitText
                            )
                        )
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme.ink
                        )
                        .monospacedDigit()
                    }
                }

                Spacer()

                // "Active" repeats the section it sits in; only show a badge
                // when the state is something else (read-only, paused…).
                let badge =
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

                if badge != "Active" {
                    StatusBadge(text: badge)
                }

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.textSecondary
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
                    Theme.textSecondary
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
                            Theme.textSecondary
                        )
                }
            }

            if emphasized {
                metricsLayout {
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
            Theme.rowPadding
        )
        .contentShape(Rectangle())
    }


    /// Side by side at regular sizes, stacked at accessibility sizes.
    var metricsLayout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: Theme.spaceS
                )
            )
            : AnyLayout(
                HStackLayout(
                    spacing: Theme.spaceXXL
                )
            )
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
            spacing: Theme.sectionHeaderGap
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
                .buttonStyle(TrackingCardButtonStyle())
            }
            .padding(.horizontal, Theme.cardInset)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
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
                    .font(Theme.cardTitle)
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
            }

            Spacer()

            Image(
                systemName:
                    "chevron.right"
            )
            .font(Theme.micro)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
        .padding(
            .vertical,
            Theme.rowPadding
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
        // The next entry still to record: one already logged early is not "next".
        .first {
            $0.revision.protocolID
                == protocolID
            && $0.log == nil
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

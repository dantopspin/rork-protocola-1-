import SwiftUI

struct InventoryView: View {
    @Environment(TrackingStore.self)
    private var store

    @State private var add = false
    @State private var showArchived = false

    private var activeVials:
        [VialRecord] {
        vials(in: .active)
    }

    private var reserveVials:
        [VialRecord] {
        vials(in: .reserve)
    }

    private var sealedVials:
        [VialRecord] {
        vials(in: .sealed)
    }

    private var archivedVials:
        [VialRecord] {
        vials(in: .archived)
    }

    private var availableVials:
        [VialRecord] {
        activeVials
        + reserveVials
        + sealedVials
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                if availableVials.isEmpty,
                   (
                        !showArchived
                        || archivedVials
                            .isEmpty
                   ) {
                    TrackingEmptyState(
                        icon: "shippingbox",
                        title:
                            "No vials recorded",
                        message:
                            "Add the vial details from your own label or instructions.",
                        actionTitle:
                            "Add vial"
                    ) {
                        add = true
                    }
                }

                vialSection(
                    "Active",
                    vials: activeVials
                )
                vialSection(
                    "Reserve",
                    vials: reserveVials
                )
                vialSection(
                    "Sealed",
                    vials: sealedVials
                )

                if showArchived {
                    vialSection(
                        "Archived",
                        vials:
                            archivedVials
                    )
                }

                Text(
                    "Balances are estimates from your recorded entries and manual corrections. Runway appears only when linked schedules can be represented as fixed mass."
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItemGroup(
                placement:
                    .topBarTrailing
            ) {
                if !archivedVials
                    .isEmpty {
                    Menu {
                        Toggle(
                            "Show archived",
                            isOn:
                                $showArchived
                        )
                    } label: {
                        Label(
                            "Inventory options",
                            systemImage:
                                "ellipsis.circle"
                        )
                    }
                }

                Button(
                    "Add vial",
                    systemImage: "plus"
                ) {
                    add = true
                }
            }
        }
        .sheet(isPresented: $add) {
            VialEditorView()
        }
        .trackingRoutes()
        .trackingErrors()
    }
}


private extension InventoryView {

    func vials(
        in state:
            VialLifecycleState
    ) -> [VialRecord] {
        store.vials.filter {
            $0.lifecycleState
                == state
        }
    }


    @ViewBuilder
    func vialSection(
        _ title: String,
        vials: [VialRecord]
    ) -> some View {
        if !vials.isEmpty {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionHeaderGap
            ) {
                Eyebrow(text: title)

                VStack(spacing: 0) {
                    ForEach(
                        Array(
                            vials.enumerated()
                        ),
                        id:
                            \.element.id
                    ) { index, vial in
                        vialLink(vial)

                        if index
                            < vials.count - 1 {
                            EditorialRule()
                        }
                    }
                }
                .overlay(
                    alignment: .top
                ) {
                    EditorialRule()
                }
                .overlay(
                    alignment: .bottom
                ) {
                    EditorialRule()
                }
            }
        }
    }


    func vialLink(
        _ vial: VialRecord
    ) -> some View {
        NavigationLink(
            value:
                TrackingRoute
                    .vialDetail(vial.id)
        ) {
            VStack(
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
                        Text(vial.name)
                            .font(Theme.cardTitle)
                            .foregroundStyle(
                                Theme.ink
                            )
                            .lineLimit(2)

                        Text(
                            vial.compoundName
                        )
                        .font(Theme.body)
                        .foregroundStyle(
                            Theme
                                .textSecondary
                        )
                    }

                    Spacer()

                    VStack(
                        alignment: .trailing,
                        spacing:
                            Theme.spaceXXS
                    ) {
                        Eyebrow(
                            text: "Remaining"
                        )

                        Text(
                            DoseCalculator
                                .text(
                                    store.balances[
                                        vial.id
                                    ] ?? 0
                                )
                            + " mg"
                        )
                        .font(
                            Theme.metricCompact
                        )
                        .foregroundStyle(
                            Theme.ink
                        )
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

                HStack(
                    spacing: Theme.spaceS
                ) {
                    if let entries =
                        store
                            .scheduledEntriesRemaining(
                                in: vial
                            ),
                       entries > 0 {
                        Text(
                            "~"
                            + String(entries)
                            + " "
                            + (
                                entries == 1
                                ? "entry"
                                : "entries"
                            )
                        )
                    }

                    if let depletion =
                        store
                            .estimatedDepletionDate(
                                in: vial
                            ) {
                        Text(
                            "Depletes "
                            + depletion
                                .formatted(
                                    date:
                                        .abbreviated,
                                    time:
                                        .omitted
                                )
                        )
                    }

                    if let expiryText =
                        expiryText(vial) {
                        Text(expiryText)
                    }
                }
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )

                let status =
                    store.vialStatus(vial)

                if [
                    "Low recorded balance",
                    "Depleted"
                ]
                .contains(status) {
                    Text(status)
                        .font(Theme.micro)
                        .foregroundStyle(
                            Theme.amber
                        )
                }
            }
            .padding(
                .vertical,
                Theme.rowPadding
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }


    func expiryText(
        _ vial: VialRecord
    ) -> String? {
        guard let expiry =
            vial.expiry
        else {
            return nil
        }

        let calendar =
            Calendar.current
        let today =
            calendar.startOfDay(
                for: .now
            )
        let expiryDay =
            calendar.startOfDay(
                for: expiry
            )
        let days =
            calendar.dateComponents(
                [.day],
                from: today,
                to: expiryDay
            ).day ?? 0

        if days < 0 {
            return "Expired"
        }

        if days == 0 {
            return "Expires today"
        }

        if days <= 14 {
            return
                "Expires in "
                + String(days)
                + (
                    days == 1
                    ? " day"
                    : " days"
                )
        }

        return nil
    }
}

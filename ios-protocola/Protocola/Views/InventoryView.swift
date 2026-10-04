import SwiftUI

struct InventoryView: View {
    @Environment(TrackingStore.self)
    private var store

    @State private var add = false
    @State private var showArchived = false

    private var activeVials: [VialRecord] {
        vials(in: .active)
    }

    private var reserveVials: [VialRecord] {
        vials(in: .reserve)
    }

    private var sealedVials: [VialRecord] {
        vials(in: .sealed)
    }

    private var archivedVials: [VialRecord] {
        vials(in: .archived)
    }

    private var availableVials: [VialRecord] {
        activeVials
        + reserveVials
        + sealedVials
    }

    var body: some View {
        List {
            if availableVials.isEmpty,
               (
                    !showArchived
                    || archivedVials.isEmpty
               ) {
                Section {
                    TrackingEmptyState(
                        icon: "shippingbox",
                        title: "No vials recorded",
                        message:
                            "Add the vial details from your own label or instructions.",
                        actionTitle: "Add vial"
                    ) {
                        add = true
                    }
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
                    vials: archivedVials
                )
            }

            Section {
                Text(
                    "Balances are estimates from your recorded entries and manual corrections. Runway appears only when linked schedules can be represented as fixed mass."
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
            }
        }
        .listStyle(.insetGrouped)
        .paperList()
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {
                if !archivedVials.isEmpty {
                    Menu {
                        Toggle(
                            "Show archived",
                            isOn: $showArchived
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
        in state: VialLifecycleState
    ) -> [VialRecord] {
        store.vials.filter {
            $0.lifecycleState == state
        }
    }

    @ViewBuilder
    func vialSection(
        _ title: String,
        vials: [VialRecord]
    ) -> some View {
        if !vials.isEmpty {
            Section(title) {
                ForEach(vials) { vial in
                    vialLink(vial)
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
                spacing: Theme.spaceXS
            ) {
                HStack(
                    alignment:
                        .firstTextBaseline
                ) {
                    Text(vial.name)
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)

                    Spacer(
                        minLength: Theme.spaceS
                    )

                    Text(
                        DoseCalculator.text(
                            store.balances[
                                vial.id
                            ] ?? 0
                        )
                        + " mg"
                    )
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                }

                Text(vial.compoundName)
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )

                HStack(
                    spacing: Theme.spaceS
                ) {
                    if let entries =
                        store
                            .scheduledEntriesRemaining(
                                in: vial
                            ),
                       entries > 0 {
                        Label(
                            "~"
                            + String(entries)
                            + " "
                            + (
                                entries == 1
                                ? "entry"
                                : "entries"
                            ),
                            systemImage: "calendar"
                        )
                    }

                    if let depletion =
                        store
                            .estimatedDepletionDate(
                                in: vial
                            ) {
                        Label(
                            depletion.formatted(
                                date: .abbreviated,
                                time: .omitted
                            ),
                            systemImage: "hourglass"
                        )
                    }

                    if let expiryText =
                        expiryText(vial) {
                        Label(
                            expiryText,
                            systemImage:
                                "calendar.badge.exclamationmark"
                        )
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
                ].contains(status) {
                    Label(
                        status,
                        systemImage:
                            "exclamationmark.circle"
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.amber
                    )
                }
            }
            .padding(
                .vertical,
                Theme.spaceXXS
            )
        }
    }

    func expiryText(
        _ vial: VialRecord
    ) -> String? {
        guard let expiry = vial.expiry else {
            return nil
        }

        let calendar = Calendar.current
        let today =
            calendar.startOfDay(for: .now)
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

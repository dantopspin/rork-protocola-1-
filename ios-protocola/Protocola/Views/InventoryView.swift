import SwiftUI

struct InventoryView: View {
    @Environment(TrackingStore.self) private var store

    @State private var add = false
    @State private var showArchived = false

    private var activeVials: [VialRecord] {
        store.vials.filter {
            !$0.isArchived
        }
    }

    private var archivedVials: [VialRecord] {
        store.vials.filter {
            $0.isArchived
        }
    }

    var body: some View {
        List {
            if activeVials.isEmpty,
               (!showArchived || archivedVials.isEmpty) {
                Section {
                    ContentUnavailableView {
                        Label(
                            "No vials recorded",
                            systemImage: "shippingbox"
                        )
                    } description: {
                        Text(
                            "Add the vial details from your own label or instructions."
                        )
                    } actions: {
                        Button("Add vial") {
                            add = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.ink)
                    }
                }
            }

            if !activeVials.isEmpty {
                Section("Active") {
                    ForEach(activeVials) {
                        vial in
                        vialLink(vial)
                    }
                }
            }

            if showArchived,
               !archivedVials.isEmpty {
                Section("Archived") {
                    ForEach(archivedVials) {
                        vial in
                        vialLink(vial)
                    }
                }
            }

            Section {
                Text(
                    "Balances are estimates from your recorded entries and manual corrections. "
                    + "Scheduled-entry estimates appear only when the vial is linked to a compatible fixed-mass schedule."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
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


// MARK: - Rows

private extension InventoryView {

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
                    alignment: .firstTextBaseline
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
                    .font(
                        .subheadline.weight(
                            .medium
                        )
                    )
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                }

                Text(vial.compoundName)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)

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
                            "~\(entries) "
                            + (
                                entries == 1
                                ? "entry"
                                : "entries"
                            ),
                            systemImage:
                                "calendar"
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
                .foregroundStyle(.secondary)

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
                    .font(Theme.micro)
                    .foregroundStyle(Theme.amber)
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

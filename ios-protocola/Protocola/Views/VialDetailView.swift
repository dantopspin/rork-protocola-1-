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
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceXL
                    ) {
                        inventoryOverview(vial)

                        if vial.photoData != nil {
                            referencePhoto(vial)
                        }

                        recordedVial(vial)
                        recordedEntries(vial)
                    }
                    .screenPadding()
                    .padding(
                        .bottom,
                        Theme.spaceXL
                    )
                }
                .scrollIndicators(.hidden)
                .background(Theme.paper)
                .trackingRoutes()
                .navigationTitle(vial.name)
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
                                    "Edit vial",
                                    systemImage:
                                        "pencil"
                                )
                            }

                            Divider()

                            Button {
                                store.archiveVial(
                                    vial
                                )
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
                        } label: {
                            Label(
                                "Vial actions",
                                systemImage:
                                    "ellipsis.circle"
                            )
                        }
                    }
                }
                .sheet(isPresented: $edit) {
                    VialEditorView(
                        vial: vial
                    )
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

    func inventoryOverview(
        _ vial: VialRecord
    ) -> some View {
        EditorialSection("Inventory") {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceS
            ) {
                Eyebrow(text: "Remaining")

                Text(
                    DoseCalculator.text(
                        store.balances[
                            vial.id
                        ] ?? 0
                    )
                    + " mg"
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
                        text:
                            store.vialStatus(
                                vial
                            )
                    )

                    Text(
                        vial.lifecycleState
                            .rawValue
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
            }

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
                    label:
                        "Original vial yield",
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
                    label:
                        "Estimated depletion",
                    value:
                        depletion.formatted(
                            date:
                                .abbreviated,
                            time: .omitted
                        )
                )
            }

            if let reconstituted =
                vial.reconstitutedAt {
                RecordRow(
                    label:
                        "Reconstituted",
                    value:
                        daysSinceLabel(
                            reconstituted
                        )
                )
            }

            if let opened =
                vial.openedAt {
                RecordRow(
                    label: "Opened",
                    value:
                        daysSinceLabel(
                            opened
                        )
                )
            }

            if let expiry = vial.expiry {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
                    RecordRow(
                        label:
                            "Recorded expiry",
                        value:
                            expiry.formatted(
                                date:
                                    .abbreviated,
                                time: .omitted
                            )
                            + expiryCountdownLabel(
                                expiry
                            )
                    )

                    if let status =
                        expiryStatus(
                            expiry
                        ) {
                        StatusBadge(
                            text: status
                        )
                    }
                }
            }

            Text(
                "Supply estimates use compatible fixed-mass schedules linked to this vial and your recorded balance."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    /// Calendar-day counts on start-of-day boundaries, computed only from
    /// dates the user recorded. Protocola never invents a beyond-use date.
    func daysSinceLabel(
        _ date: Date
    ) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current
                .startOfDay(for: date),
            to: Calendar.current
                .startOfDay(for: .now)
        ).day ?? 0

        if days <= 0 {
            return "Today"
        }

        return days == 1
            ? "1 day ago"
            : String(days) + " days ago"
    }


    func expiryStatus(
        _ expiry: Date
    ) -> String? {
        let days =
            Calendar.current
                .dateComponents(
                    [.day],
                    from:
                        Calendar.current
                            .startOfDay(
                                for: .now
                            ),
                    to:
                        Calendar.current
                            .startOfDay(
                                for: expiry
                            )
                )
                .day ?? 0

        if days < 0 {
            return
                "Expiry passed"
        }

        if days == 0 {
            return
                "Expiry today"
        }

        if days <= 14 {
            return
                "Expires soon"
        }

        return nil
    }


    func expiryCountdownLabel(
        _ expiry: Date
    ) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current
                .startOfDay(for: .now),
            to: Calendar.current
                .startOfDay(for: expiry)
        ).day ?? 0

        if days > 1 {
            return " · in " + String(days) + " days"
        }

        if days == 1 {
            return " · tomorrow"
        }

        if days == 0 {
            return " · today"
        }

        if days == -1 {
            return " · 1 day ago"
        }

        return " · "
            + String(-days)
            + " days ago"
    }


    func referencePhoto(
        _ vial: VialRecord
    ) -> some View {
        EditorialSection(
            "Reference photo"
        ) {
            if let data = vial.photoData,
               let image =
                UIImage(data: data) {
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


    func recordedVial(
        _ vial: VialRecord
    ) -> some View {
        EditorialSection(
            "Recorded vial"
        ) {
            RecordRow(
                label: "Compound",
                value:
                    vial.compoundName
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
                        DoseCalculator.text(
                            $0
                        )
                        + " mg/mL"
                    }
                    ?? "Not recorded"
            )

            if let reconstituted =
                vial.reconstitutedAt {
                RecordRow(
                    label: "Reconstituted",
                    value:
                        reconstituted
                            .formatted(
                                date:
                                    .abbreviated,
                                time:
                                    .omitted
                            )
                )
            }

            if let opened =
                vial.openedAt {
                RecordRow(
                    label: "Opened",
                    value:
                        opened.formatted(
                            date:
                                .abbreviated,
                            time:
                                .omitted
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
                label:
                    "Supplier / clinic",
                value:
                    vial.supplier.isEmpty
                    ? "Not recorded"
                    : vial.supplier
            )

            if !vial.storageNotes
                .isEmpty {
                Text(
                    vial.storageNotes
                )
                .font(Theme.body)
                .foregroundStyle(
                    Theme.ink
                )
            }
        }
    }


    @ViewBuilder
    func recordedEntries(
        _ vial: VialRecord
    ) -> some View {
        let logs =
            store.logs
                .filter {
                    $0.vialID
                        == vial.id
                }
                .sorted {
                    $0.loggedAt
                        > $1.loggedAt
                }

        EditorialSection(
            "Recorded entries"
        ) {
            if logs.isEmpty {
                Text(
                    "No entries use this vial yet."
                )
                .font(Theme.body)
                .foregroundStyle(
                    Theme.textSecondary
                )

            } else {
                ForEach(
                    Array(
                        logs.enumerated()
                    ),
                    id: \.element.id
                ) { index, log in
                    NavigationLink(
                        value:
                            TrackingRoute
                                .logDetail(
                                    log.id
                                )
                    ) {
                        HStack(
                            alignment:
                                .firstTextBaseline,
                            spacing:
                                Theme.spaceM
                        ) {
                            VStack(
                                alignment:
                                    .leading,
                                spacing:
                                    Theme.spaceXXS
                            ) {
                                Text(
                                    log.actualAmountText
                                    + " "
                                    + log.unitText
                                )
                                .font(
                                    Theme.metricCompact
                                )
                                .foregroundStyle(
                                    Theme.ink
                                )
                                .monospacedDigit()

                                Text(
                                    log.loggedAt
                                        .formatted(
                                            date:
                                                .abbreviated,
                                            time:
                                                .shortened
                                        )
                                )
                                .font(
                                    Theme.caption
                                )
                                .foregroundStyle(
                                    Theme
                                        .textSecondary
                                )
                                .monospacedDigit()
                            }

                            Spacer()

                            StatusBadge(
                                text:
                                    log.status
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
                        .padding(
                            .vertical,
                            Theme.spaceS
                        )
                        .contentShape(
                            Rectangle()
                        )
                    }
                    .buttonStyle(.plain)

                    if index
                        < logs.count - 1 {
                        Rectangle()
                            .fill(
                                Theme.hairline
                            )
                            .frame(
                                height:
                                    Theme
                                        .ruleThickness
                            )
                    }
                }
            }
        }
    }


    func archiveAction(
        _ vial: VialRecord
    ) -> some View {
        Button {
            store.archiveVial(vial)
        } label: {
            Text(
                vial.lifecycleState
                    == .archived
                ? "Restore as active"
                : "Archive vial"
            )
        }
        .buttonStyle(
            TrackingSecondaryButtonStyle()
        )
    }


}

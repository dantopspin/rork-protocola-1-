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

                if !availableVials.isEmpty {
                    inventorySummary
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
        .navigationTitle("Vials")
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


    /// Inventory at a glance: how many vials, how long they last, and
    /// how many expire soon.
    var inventorySummary: some View {
        let runwayDays =
            availableVials
                .compactMap {
                    store.estimatedDepletionDate(in: $0)
                }
                .max()
                .map {
                    max(
                        0,
                        Calendar.current.dateComponents(
                            [.day],
                            from: .now,
                            to: $0
                        ).day ?? 0
                    )
                }
        let expiring =
            availableVials.filter {
                expiryText($0) != nil
            }.count

        return TrackingCard {
            Text("Inventory at a glance")
                .font(Theme.serifTitle)
                .foregroundStyle(Theme.textSecondary)

            HStack(alignment: .top, spacing: 0) {
                summaryFigure(
                    value: String(availableVials.count),
                    label:
                        availableVials.count == 1
                        ? "Vial"
                        : "Vials",
                    tint: Theme.ink
                )

                summaryFigure(
                    value:
                        runwayDays.map(Self.runwayText)
                        ?? "—",
                    label: "Projected supply",
                    tint: Theme.ink
                )

                summaryFigure(
                    value: String(expiring),
                    label: "Expiring soon",
                    tint:
                        expiring > 0
                        ? Theme.danger
                        : Theme.ink
                )
            }
        }
    }


    static func runwayText(
        _ days: Int
    ) -> String {
        days >= 14
            ? String(days / 7) + " weeks"
            : String(days) + (days == 1 ? " day" : " days")
    }


    func summaryFigure(
        value: String,
        label: String,
        tint: Color
    ) -> some View {
        VStack(spacing: Theme.spaceXXS) {
            Text(value)
                .font(Theme.metricCompact)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(Theme.caption)
                .foregroundStyle(
                    tint == Theme.ink
                        ? Theme.textSecondary
                        : tint
                )
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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

                VStack(spacing: Theme.spaceS) {
                    ForEach(vials) { vial in
                        vialLink(vial)
                    }
                }
            }
        }
    }


    /// A vial card: icon tile, serif name, remaining bar, runway and expiry.
    func vialLink(
        _ vial: VialRecord
    ) -> some View {
        let balance = store.balances[vial.id] ?? 0
        let fraction: Double = {
            let total = NSDecimalNumber(decimal: vial.originalMg).doubleValue
            guard total > 0 else { return 0 }
            return min(
                1,
                max(
                    0,
                    NSDecimalNumber(decimal: balance).doubleValue / total
                )
            )
        }()
        let status = store.vialStatus(vial)
        let expiry = expiryText(vial)
        let barTint: Color =
            expiry == "Expired" || status == "Depleted"
            ? Theme.danger
            : (
                status == "Low recorded balance" || expiry != nil
                ? Theme.amber
                : Theme.teal
            )

        return NavigationLink(
            value:
                TrackingRoute
                    .vialDetail(vial.id)
        ) {
            HStack(
                alignment: .top,
                spacing: Theme.spaceS
            ) {
                Image(systemName: "testtube.2")
                    .font(Theme.modalTitle)
                    .foregroundStyle(Theme.teal)
                    .frame(
                        width: Theme.iconTileSize,
                        height: Theme.iconTileSize
                    )
                    .background(
                        Theme.tealTint,
                        in: .rect(cornerRadius: Theme.radiusRow)
                    )
                    .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    HStack(
                        alignment: .firstTextBaseline,
                        spacing: Theme.spaceXS
                    ) {
                        Text(vial.compoundName)
                            .font(Theme.serifTitle)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)

                        Spacer(minLength: Theme.spaceXS)

                        if let expiry {
                            StatusBadge(
                                text:
                                    expiry == "Expired"
                                    ? "Expiry passed"
                                    : "Expires soon"
                            )
                            .accessibilityLabel(expiry)
                        }
                    }

                    Text(
                        [
                            vial.name,
                            vial.concentration.map {
                                DoseCalculator.text($0) + " mg/mL"
                            },
                            vial.supplier.isEmpty
                                ? nil
                                : vial.supplier
                        ]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()

                    ProgressView(value: fraction)
                        .tint(barTint)
                        .padding(.vertical, Theme.spaceXS)
                        .accessibilityHidden(true)

                    HStack(spacing: Theme.spaceXS) {
                        Text(
                            DoseCalculator.text(balance)
                            + " mg remaining"
                        )
                        .foregroundStyle(Theme.ink)

                        Spacer(minLength: Theme.spaceXS)

                        if let entries =
                            store.scheduledEntriesRemaining(in: vial),
                           entries > 0 {
                            Text(
                                runwaySummary(
                                    vial,
                                    entries: entries
                                )
                            )
                            .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .font(Theme.caption)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                    if let expiry {
                        Text(expiry)
                            .font(Theme.caption)
                            .foregroundStyle(barTint)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(Theme.micro)
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Theme.spaceM)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }


    /// "~6 weeks (35 entries)" when a depletion date is known, otherwise
    /// just the entry count.
    func runwaySummary(
        _ vial: VialRecord,
        entries: Int
    ) -> String {
        let count =
            String(entries)
            + (entries == 1 ? " entry" : " entries")
        guard
            let depletion =
                store.estimatedDepletionDate(in: vial)
        else {
            return "~" + count
        }
        let days =
            max(
                0,
                Calendar.current.dateComponents(
                    [.day],
                    from: .now,
                    to: depletion
                ).day ?? 0
            )
        return "~" + Self.runwayText(days) + " (" + count + ")"
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

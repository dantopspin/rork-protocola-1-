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

                if store.isDemo {
                    // In content so the large title stays visible.
                    DemoBanner()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: Theme.radiusRow,
                                style: .continuous
                            )
                        )
                }

                if !archivedVials.isEmpty {
                    Picker(
                        "Vials shown",
                        selection: $showArchived
                    ) {
                        Text("Current").tag(false)
                        Text("Archived").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                if showArchived {
                    vialSection(
                        "Archived",
                        vials:
                            archivedVials
                    )
                } else {
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

                    if let depletion = earliestDepletion {
                        depletionCard(depletion)
                    }
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
        .trackingScrollChrome()
        .background(Theme.paper)
        .navigationTitle("Vials")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(
                placement:
                    .topBarTrailing
            ) {
                addVialButton
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

            HStack(alignment: .center, spacing: 0) {
                summaryFigure(
                    value: String(availableVials.count),
                    label:
                        availableVials.count == 1
                        ? "Vial"
                        : "Vials",
                    tint: Theme.ink
                )

                figureDivider

                summaryFigure(
                    value:
                        runwayDays.map(Self.runwayText)
                        ?? "—",
                    label: "Projected supply",
                    tint: Theme.ink
                )

                figureDivider

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


    /// Thin vertical rule between summary figures.
    var figureDivider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(width: Theme.ruleThickness)
            .frame(maxHeight: Theme.iconTileSize)
            .accessibilityHidden(true)
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


    /// Filled accent + on iOS 26; the system button elsewhere.
    @ViewBuilder
    var addVialButton: some View {
        let button =
            Button(
                "Add vial",
                systemImage: "plus"
            ) {
                add = true
            }

        if #available(iOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .tint(Theme.accentFill)
        } else {
            button
        }
    }


    /// The available vial expected to run out first, from recorded
    /// schedules. Nil when no runway can be estimated.
    var earliestDepletion: (vial: VialRecord, date: Date)? {
        availableVials
            .compactMap { vial in
                store.estimatedDepletionDate(in: vial)
                    .map { (vial: vial, date: $0) }
            }
            .min { $0.date < $1.date }
    }


    func depletionCard(
        _ depletion: (vial: VialRecord, date: Date)
    ) -> some View {
        HStack(spacing: Theme.spaceS) {
            IconBadge(systemImage: "chart.line.downtrend.xyaxis")

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text("Projected depletion")
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)

                Text(
                    depletion.vial.name
                    + " · around "
                    + depletion.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                    + ", based on your recorded schedule."
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.cardInset)
        .background(
            Theme.subtleFill,
            in: .rect(cornerRadius: Theme.radiusCard)
        )
        .accessibilityElement(children: .combine)
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
            expiry == "Expired"
                || status == "Depleted"
                || status == "Low recorded balance"
            ? Theme.danger
            : (
                expiry != nil
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
                VialTile(
                    vial: vial,
                    fraction: fraction
                )

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

                    let remainingMl: String? =
                        vial.concentration.flatMap { strength in
                            guard strength > 0 else { return nil }
                            var ml = balance / strength
                            var rounded = Decimal()
                            NSDecimalRound(&rounded, &ml, 2, .plain)
                            return DoseCalculator.text(rounded) + " mL"
                        }
                    let remainingText =
                        Text(
                            remainingMl.map {
                                $0 + " · "
                                + DoseCalculator.text(balance)
                                + " mg remaining"
                            }
                            ?? DoseCalculator.text(balance)
                                + " mg remaining"
                        )
                        .foregroundStyle(Theme.ink)
                    let runway: String? = {
                        guard
                            let entries =
                                store.scheduledEntriesRemaining(in: vial),
                            entries > 0
                        else {
                            return nil
                        }
                        return runwaySummary(
                            vial,
                            entries: entries
                        )
                    }()

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Theme.spaceXS) {
                            remainingText

                            Spacer(minLength: Theme.spaceXS)

                            if let runway {
                                Text(runway)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .lineLimit(1)

                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceXXS
                        ) {
                            remainingText

                            if let runway {
                                Text(runway)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .font(Theme.caption)
                    .monospacedDigit()

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
        .buttonStyle(TrackingCardButtonStyle())
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

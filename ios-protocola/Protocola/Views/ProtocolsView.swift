import SwiftUI

struct ProtocolsView: View {
    @Environment(TrackingStore.self) private var store

    @State private var create = false
    @State private var choice = false
    @State private var paywall = false
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
        List {
            if !store.isPremium,
               store.activeProtocolIDs.count > 1 {
                Section {
                    Button {
                        choice = true
                    } label: {
                        Label(
                            "Choose protocol to track on Free",
                            systemImage: "checkmark.circle"
                        )
                    }
                }
            }

            if !activeProtocols.isEmpty {
                Section("Active") {
                    ForEach(activeProtocols) { record in
                        protocolLink(record)
                    }
                }
            }

            if !otherProtocols.isEmpty {
                Section("Other") {
                    ForEach(otherProtocols) { record in
                        protocolLink(record)
                    }
                }
            }

            if store.protocols.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label(
                            "No protocols yet",
                            systemImage:
                                "list.bullet.rectangle"
                        )
                    } description: {
                        Text(
                            "Add an existing protocol to start "
                            + "building your recorded history."
                        )
                    } actions: {
                        Button("Add protocol") {
                            create = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.teal)
                    }
                }
            }

            Section("Tools") {
                NavigationLink {
                    InventoryView()
                } label: {
                    HStack(spacing: Theme.spaceM) {
                        Image(
                            systemName: "shippingbox"
                        )
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.teal)
                        .frame(width: 28)

                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceXXS
                        ) {
                            Text("Vial inventory")
                                .foregroundStyle(
                                    Theme.ink
                                )

                            Text(inventorySummary)
                                .font(Theme.body)
                                .foregroundStyle(
                                    .secondary
                                )
                        }

                        Spacer()
                    }
                    .padding(
                        .vertical,
                        Theme.spaceXXS
                    )
                }

                Button {
                    calculator = true
                } label: {
                    HStack(spacing: Theme.spaceM) {
                        Image(systemName: "function")
                            .foregroundStyle(Theme.muted)
                            .frame(width: 28)

                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceXXS
                        ) {
                            Text("Calculator")
                                .font(Theme.label)
                                .foregroundStyle(Theme.ink)

                            Text("Dose · Volume · Units")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.muted)
                        }

                        Spacer()
                    }
                    .padding(
                        .vertical,
                        Theme.spaceXXS
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .paperList()
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
                        paywall = true
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
        .fullScreenCover(
            isPresented: $paywall
        ) {
            PaywallView(
                reason: .secondProtocol
            )
        }
        .trackingRoutes()
        .trackingErrors()
    }
}


// MARK: - Protocol rows

private extension ProtocolsView {

    func protocolLink(
        _ record: ProtocolRecord
    ) -> some View {
        NavigationLink(
            value:
                TrackingRoute
                    .protocolDetail(record.id)
        ) {
            protocolRow(record)
        }
    }


    func protocolRow(
        _ record: ProtocolRecord
    ) -> some View {
        let revisions =
            store.currentRevisions(
                record.id
            )

        let primary =
            revisions.first

        return VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            HStack(
                alignment: .firstTextBaseline
            ) {
                Text(record.name)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Spacer(
                    minLength: Theme.spaceS
                )

                statusLabel(record)
            }

            if let primary {
                Text(
                    primary.compoundName
                    + " · "
                    + primary.amountText
                    + " "
                    + primary.unitText
                )
                .font(Theme.body)
                .foregroundStyle(.secondary)

                Text(
                    primary.config.map(
                        ScheduleDisplay.summary
                    )
                    ?? "Schedule unavailable"
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)

                if let next =
                    nextEntry(
                        for: record.id
                    ) {
                    Text(
                        "Next: "
                        + next.at.formatted(
                            .dateTime
                                .day()
                                .month(
                                    .abbreviated
                                )
                                .hour()
                                .minute()
                        )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }

                if revisions.count > 1 {
                    Text(
                        "+\(revisions.count - 1) more "
                        + (
                            revisions.count - 1 == 1
                            ? "compound"
                            : "compounds"
                        )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("No active schedule")
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(
            .vertical,
            Theme.spaceXS
        )
    }


    @ViewBuilder
    func statusLabel(
        _ record: ProtocolRecord
    ) -> some View {
        StatusBadge(
            text:
                record.status == "Active"
                ? (
                    store.canTrack(record.id)
                    ? "Active"
                    : "Read-only"
                )
                : record.status
        )
    }


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


    func scheduleSummary(
        _ revision: ScheduleRevision
    ) -> String {
        guard let config = revision.config else {
            return "Schedule unavailable"
        }

        if config.kind == .asRecorded {
            return "As recorded"
        }

        let times =
            config.minutes
                .sorted()
                .map {
                    timeText(
                        minute: $0,
                        timeZoneID:
                            config.timeZoneID
                    )
                }
                .joined(separator: ", ")

        switch config.kind {
        case .daily:
            return
                times.isEmpty
                ? "Daily"
                : "Daily at " + times

        case .weekly:
            let day =
                config.weekdays.first
                    .map(weekdayName)
                ?? "Weekly"

            return
                times.isEmpty
                ? day
                : day + " at " + times

        case .weekdays:
            let days =
                config.weekdays
                    .sorted()
                    .map(weekdayShort)
                    .joined(separator: ", ")

            return
                days
                + (
                    times.isEmpty
                    ? ""
                    : " · " + times
                )

        case .everyNDays:
            return
                "Every "
                + String(config.interval)
                + (
                    config.interval == 1
                    ? " day"
                    : " days"
                )
                + (
                    times.isEmpty
                    ? ""
                    : " · " + times
                )

        case .timesPerWeek:
            let days =
                config.weekdays
                    .sorted()
                    .map(weekdayShort)
                    .joined(separator: ", ")

            return
                days
                + (
                    times.isEmpty
                    ? ""
                    : " · " + times
                )

        case .asRecorded:
            return "As recorded"
        }
    }


    func timeText(
        minute: Int,
        timeZoneID: String
    ) -> String {
        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            TimeZone(identifier: timeZoneID)
            ?? .current

        let date =
            calendar.date(
                bySettingHour:
                    minute / 60,
                minute:
                    minute % 60,
                second: 0,
                of: .now
            )
            ?? .now

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }


    func weekdayName(
        _ value: Int
    ) -> String {
        let names =
            Calendar.current.weekdaySymbols

        guard (1...7).contains(value) else {
            return "Weekly"
        }

        return names[value - 1]
    }


    func weekdayShort(
        _ value: Int
    ) -> String {
        let names =
            Calendar.current
                .shortWeekdaySymbols

        guard (1...7).contains(value) else {
            return "—"
        }

        return names[value - 1]
    }
}


// MARK: - Inventory

private extension ProtocolsView {

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

        let expiring =
            active.filter { vial in
                guard let expiry =
                    vial.expiry
                else {
                    return false
                }

                let limit =
                    Calendar.current.date(
                        byAdding: .day,
                        value: 14,
                        to: .now
                    ) ?? .now

                return
                    expiry >= .now
                    && expiry <= limit
            }.count

        var parts: [String] = [
            "\(active.count) "
                + (
                    active.count == 1
                    ? "vial"
                    : "vials"
                )
        ]

        if low > 0 {
            parts.append(
                "\(low) low balance"
            )
        }

        if expiring > 0 {
            parts.append(
                "\(expiring) expiring soon"
            )
        }

        return parts.joined(
            separator: " · "
        )
    }
}

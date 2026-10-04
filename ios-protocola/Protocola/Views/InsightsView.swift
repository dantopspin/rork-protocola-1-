import SwiftUI
import Charts

struct InsightsView: View {
    @Environment(TrackingStore.self) private var store

    @State private var protocolID: UUID?
    @State private var window = 7
    @State private var changeID: UUID?
    @State private var assistant = false
    @State private var paywall: PaywallReason?
    @State private var comparing = false
    @State private var shareCard = false

    private var selected: ProtocolRecord? {
        store.protocols.first {
            $0.id == protocolID
        } ?? store.protocols.first
    }

    private var changes: [ProtocolEvent] {
        store.events
            .filter {
                $0.protocolID == selected?.id
                    && $0.isChangeAnchor
                    && $0.title != "Protocol created"
            }
            .sorted {
                $0.at > $1.at
            }
    }

    private var latest: ProtocolEvent? {
        changes.first
    }

    private var period: AnalysisPeriod {
        let now = Date.now
        let beginning =
            selected?.createdAt ?? now

        let today =
            Calendar.current
                .startOfDay(for: now)

        let requested =
            Calendar.current.date(
                byAdding: .day,
                value: -(window - 1),
                to: today
            ) ?? today

        return AnalysisPeriod(
            start: max(beginning, requested),
            end: now
        )
    }

    private var periodLogs: [DoseLog] {
        store.logs.filter {
            period.contains($0.loggedAt)
                && $0.protocolID == selected?.id
        }
    }

    private var weeklyShareData: ShareCardData? {
        guard
            let summary = store.insights[7],
            summary.recorded > 0
        else {
            return nil
        }

        return ShareCardData(
            summary: summary,
            window: 7
        )
    }

    var body: some View {
        Group {
            if store.protocols.isEmpty {
                emptyProtocolState
            } else {
                insightsContent
            }
        }
        .background(Theme.paper)
        .navigationTitle("Insights")
        .sheet(isPresented: $assistant) {
            AssistantView()
        }
        .fullScreenCover(item: $paywall) {
            PaywallView(reason: $0)
        }
        .sheet(isPresented: $shareCard) {
            ShareCardPreviewView(
                data: weeklyShareData
            )
        }
        .trackingErrors()
    }
}


// MARK: - Main content

private extension InsightsView {

    var emptyProtocolState: some View {
        TrackingEmptyState(
            icon: "chart.xyaxis.line",
            title: "No protocol yet",
            message:
                "Add a protocol first. Insights are built from your recorded entries and changes."
        )
        .screenPadding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Theme.paper)
    }


    var insightsContent: some View {
        let summary =
            InsightsSummary(
                store: store,
                period: period,
                protocolID: selected?.id
            )

        return ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {
                if store.protocols.count > 1 {
                    protocolSelector
                }

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
                    Picker(
                        "Period",
                        selection: $window
                    ) {
                        Text("7D").tag(7)
                        Text("30D").tag(30)
                        Text("90D").tag(90)
                        Text("1Y").tag(365)
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.ink)

                    Text(periodLabel)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.muted)
                        .monospacedDigit()
                }

                if periodLogs.isEmpty {
                    emptyInsightsState
                } else {
                    if summary.scheduled > 0 {
                        consistencyHero(summary)
                    } else {
                        activityHero(summary)
                    }

                    supportingStats(summary)

                    if let latest {
                        changeContext(latest)
                    }

                    if !summary.sites.isEmpty {
                        sitesCard(summary)
                    }

                    if !summary.symptoms.isEmpty {
                        symptomsCard(summary)
                    }
                }

                proFeatures

                if weeklyShareData != nil {
                    Button {
                        shareCard = true
                    } label: {
                        Label(
                            "Share weekly card",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .buttonStyle(
                        TrackingSecondaryButtonStyle()
                    )
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL + Theme.spaceL
            )
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if protocolID == nil {
                protocolID = selected?.id
            }
        }
    }


    var protocolSelector: some View {
        Menu {
            ForEach(store.protocols) {
                record in

                Button(record.name) {
                    protocolID = record.id
                    comparing = false
                    changeID = nil
                }
            }
        } label: {
            HStack(
                spacing: Theme.spaceS
            ) {
                Text(
                    selected?.name
                        ?? "Protocol"
                )
                .font(Theme.label)
                .foregroundStyle(Theme.ink)

                Spacer()

                Image(
                    systemName:
                        "chevron.up.chevron.down"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.muted
                )
            }
            .padding(Theme.spaceM)
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
        .buttonStyle(.plain)
    }


    var emptyInsightsState: some View {
        TrackingEmptyState(
            icon: "chart.xyaxis.line",
            title: "No insights yet",
            message:
                "Record entries from Today. Consistency, changes, sites, and observations will appear as your history grows."
        )
        .frame(minHeight: Theme.emptyStateMinHeight)
    }
}


// MARK: - Period

private extension InsightsView {

    var periodLabel: String {
        guard let selected else {
            return ""
        }

        if Calendar.current.isDateInToday(
            selected.createdAt
        ) {
            return "Started today"
        }

        let start =
            period.start.formatted(
                .dateTime
                    .month(.abbreviated)
                    .day()
            )

        let end =
            period.end.formatted(
                .dateTime
                    .month(.abbreviated)
                    .day()
            )

        if Calendar.current.isDate(
            period.start,
            inSameDayAs: period.end
        ) {
            return start
        }

        return start + " – " + end
    }
}


// MARK: - Primary insight

private extension InsightsView {

    func consistencyHero(
        _ summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            HStack(
                alignment: .top
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Consistency")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)

                    Text(summary.percentage)
                        .font(Theme.metric)
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)

                    Text(
                        "\(summary.recorded) of \(summary.scheduled) scheduled"
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.muted)
                }

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(Theme.muted)
            }

            Chart(summary.days) {
                day in

                BarMark(
                    x: .value(
                        "Day",
                        day.date,
                        unit: .day
                    ),
                    y: .value(
                        "Scheduled",
                        day.scheduled
                    )
                )
                .foregroundStyle(
                    Theme.line
                )

                BarMark(
                    x: .value(
                        "Day",
                        day.date,
                        unit: .day
                    ),
                    y: .value(
                        "Recorded",
                        day.recorded
                    )
                )
                .foregroundStyle(
                    Theme.teal
                )
            }
            .frame(height: Theme.chartHeight)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(
                    values: .automatic(
                        desiredCount:
                            min(
                                summary.days.count,
                                7
                            )
                    )
                ) { value in
                    AxisGridLine()
                        .foregroundStyle(
                            Theme.line
                        )

                    AxisValueLabel(
                        format:
                            .dateTime
                                .day()
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.muted
                    )
                }
            }
        }
        .padding(Theme.spaceM)
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


    func activityHero(
        _ summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Text("Recorded entries")
                .font(Theme.label)
                .foregroundStyle(Theme.ink)

            Text(String(periodLogs.count))
                .font(Theme.metric)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)

            Text(
                "No recurring schedule is recorded for this period."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.muted)
        }
        .padding(Theme.spaceM)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
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


    func supportingStats(
        _ summary: InsightsSummary
    ) -> some View {
        let skipped =
            periodLogs.filter {
                $0.status == "Skipped"
            }.count

        return HStack(
            spacing: Theme.spaceXS
        ) {
            statTile(
                value:
                    String(summary.recorded),
                label: "Logged",
                dot: Theme.teal
            )

            statTile(
                value: String(skipped),
                label: "Skipped",
                dot: Theme.muted
            )

            statTile(
                value:
                    String(
                        summary.sites.count
                    ),
                label: "Sites",
                dot: Theme.line
            )
        }
    }


    func statTile(
        value: String,
        label: String,
        dot: Color
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Text(value)
                .font(Theme.metricCompact)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)

            HStack(spacing: 5) {
                Circle()
                    .fill(dot)
                    .frame(
                        width: Theme.statusDot,
                        height: Theme.statusDot
                    )

                Text(label)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )
            }
        }
        .padding(Theme.spaceM)
        .frame(
            maxWidth: .infinity,
            minHeight: Theme.compactMetricTileHeight,
            alignment: .leading
        )
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
}


// MARK: - Change context

private extension InsightsView {

    func changeContext(
        _ change: ProtocolEvent
    ) -> some View {
        Button {
            if store.isPremium {
                comparing = true
                changeID = change.id
            } else {
                paywall = .compare
            }
        } label: {
            HStack(
                spacing: Theme.spaceM
            ) {
                Image(
                    systemName:
                        "arrow.left.arrow.right"
                )
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.onDarkPrimary.opacity(0.76)
                )

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Since last change")
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.onDarkPrimary.opacity(0.58)
                        )

                    Text(
                        changeSummary(change)
                    )
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.onDarkPrimary)
                    .lineLimit(2)

                    Text(
                        change.at.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.onDarkPrimary.opacity(0.58)
                    )
                }

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.onDarkPrimary.opacity(0.52)
                )
            }
            .padding(Theme.spaceM)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Theme.darkSurface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusCard
                )
            )
        }
        .buttonStyle(.plain)
    }


    func changeSummary(
        _ change: ProtocolEvent
    ) -> String {
        if let amount =
            change.changes.first(
                where: {
                    $0.field == "Amount"
                }
            ) {
            let before =
                amount.before.isEmpty
                ? "Not recorded"
                : amount.before

            let after =
                amount.after.isEmpty
                ? "Not recorded"
                : amount.after

            return before + " → " + after
        }

        let meaningful =
            change.changes.first {
                $0.isMeaningful
            }

        if let meaningful {
            return
                meaningful.field
                + ": "
                + meaningful.before
                + " → "
                + meaningful.after
        }

        return change.detail
    }
}


// MARK: - Secondary insight cards

private extension InsightsView {

    func sitesCard(
        _ summary: InsightsSummary
    ) -> some View {
        NavigationLink {
            SitesBreakdownView(
                sites: summary.sites
            )
        } label: {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceM
            ) {
                HStack {
                    Text("Top injection sites")
                        .font(Theme.sectionTitle)
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

                let total =
                    max(
                        1,
                        summary.sites
                            .reduce(0) {
                                $0 + $1.count
                            }
                    )

                ForEach(
                    summary.sites.prefix(3)
                ) { site in
                    HStack(
                        spacing: Theme.spaceS
                    ) {
                        Circle()
                            .fill(Theme.teal)
                            .opacity(
                                opacity(
                                    for: site,
                                    in: summary.sites
                                )
                            )
                            .frame(
                                width: Theme.siteDot,
                                height: Theme.siteDot
                            )

                        Text(site.name)
                            .font(Theme.body)
                            .foregroundStyle(
                                Theme.ink
                            )

                        Spacer()

                        Text(
                            String(
                                Int(
                                    (
                                        Double(
                                            site.count
                                        )
                                        / Double(
                                            total
                                        )
                                    ) * 100
                                )
                            )
                            + "%"
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.muted
                        )
                        .monospacedDigit()
                    }
                }
            }
            .padding(Theme.spaceM)
        }
        .buttonStyle(.plain)
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


    func opacity(
        for site: InsightsSummary.Site,
        in sites: [InsightsSummary.Site]
    ) -> Double {
        guard
            let index =
                sites.firstIndex(
                    where: {
                        $0.id == site.id
                    }
                )
        else {
            return 0.45
        }

        return max(
            0.35,
            1 - Double(index) * 0.22
        )
    }


    func symptomsCard(
        _ summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            HStack {
                Text("Recorded observations")
                    .font(Theme.sectionTitle)

                Spacer()

                Text(
                    String(
                        summary.symptoms.count
                    )
                )
                .font(Theme.body)
                .foregroundStyle(
                    Theme.muted
                )
                .monospacedDigit()
            }

            if let latest =
                summary.symptoms
                    .sorted(
                        by: {
                            $0.date > $1.date
                        }
                    )
                    .first {
                Text(
                    latest.name
                    + " · severity "
                    + String(
                        latest.severity
                    )
                    + "/10"
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )
            }

            Text(
                "Recorded observations only. Timing does not establish causation."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.muted
            )
        }
        .padding(Theme.spaceM)
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


// MARK: - Pro features

private extension InsightsView {

    @ViewBuilder
    var proFeatures: some View {
        if comparing,
           store.isPremium {
            Picker(
                "Recorded change",
                selection: $changeID
            ) {
                ForEach(changes) {
                    Text(
                        $0.at.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .tag(Optional($0.id))
                }
            }
            .tint(Theme.ink)
            .onAppear {
                if changeID == nil {
                    changeID =
                        changes.first?.id
                }
            }

            if let change =
                changes.first(
                    where: {
                        $0.id == changeID
                    }
                ) {
                ComparisonCard(
                    protocolID:
                        selected?.id,
                    change: change
                )
            }
        }

        if store.isPremium,
           !periodLogs.isEmpty {
            Button {
                assistant = true
            } label: {
                Label(
                    "Ask your timeline",
                    systemImage: "text.bubble"
                )
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )

        } else if !store.isPremium,
                  !periodLogs.isEmpty,
                  let protocolName =
                    selected?.name {
            Button {
                paywall = .ask
            } label: {
                Label(
                    "Ask about \(protocolName)",
                    systemImage: "text.bubble"
                )
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )
        }
    }
}


// MARK: - Supporting views

private struct SitesBreakdownView: View {
    let sites: [InsightsSummary.Site]

    var body: some View {
        List {
            Section("Recorded sites") {
                ForEach(sites) {
                    site in

                    RecordRow(
                        label: site.name,
                        value:
                            String(site.count)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .paperList()
        .navigationTitle(
            "Injection Sites"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


struct PeriodSummaryCard: View {
    let summary: InsightsSummary
    let logs: [DoseLog]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Text("Recorded in this period")
                .font(Theme.sectionTitle)

            RecordRow(
                label: "Entries",
                value: String(logs.count)
            )

            RecordRow(
                label: "Consistency",
                value:
                    summary.percentage
                    + " · "
                    + String(
                        summary.recorded
                    )
                    + "/"
                    + String(
                        summary.scheduled
                    )
            )

            ForEach(
                [
                    "Logged",
                    "Partial",
                    "Delayed",
                    "Skipped"
                ],
                id: \.self
            ) { status in
                let count =
                    logs.filter {
                        $0.status == status
                    }.count

                if count > 0 {
                    RecordRow(
                        label: status,
                        value: String(count)
                    )
                }
            }
        }
        .padding(Theme.spaceM)
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
}


private struct ComparisonCard: View {
    let protocolID: UUID?
    let change: ProtocolEvent

    @Environment(TrackingStore.self)
    private var store

    var body: some View {
        let periods =
            AnalysisPeriod.comparison(
                change: change.at,
                now: .now
            )

        VStack(
            alignment: .leading,
            spacing: Theme.spaceL
        ) {
            Text(change.detail)
                .font(Theme.body)

            periodView(
                "Before",
                period: periods.before
            )

            periodView(
                "After",
                period: periods.after
            )

            Text(
                "Equal-duration windows, up to 30 days each. Differences do not establish causation or medical conclusions."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.muted
            )
        }
    }


    func periodView(
        _ title: String,
        period: AnalysisPeriod
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Text(title)
                .font(Theme.sectionTitle)

            Text(
                period.start.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
                + " – "
                + period.end.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.muted
            )
            .monospacedDigit()

            PeriodSummaryCard(
                summary:
                    InsightsSummary(
                        store: store,
                        period: period,
                        protocolID:
                            protocolID
                    ),
                logs:
                    store.logs.filter {
                        $0.protocolID
                            == protocolID
                            && period.contains(
                                $0.loggedAt
                            )
                    }
            )
        }
    }
}

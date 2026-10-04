import SwiftUI
import Charts

struct InsightsView: View {
    @Environment(TrackingStore.self) private var store

    @State private var protocolID: UUID?
    @State private var window = 0
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
        store.events.filter {
            $0.protocolID == selected?.id
                && $0.isChangeAnchor
                && $0.title
                    != "Protocol created"
        }
    }

    private var latest: ProtocolEvent? {
        changes.first
    }

    private var period: AnalysisPeriod {
        let now = Date.now
        let beginning =
            selected?.createdAt ?? now

        let start: Date

        if window == 0 {
            start =
                latest?.at
                ?? beginning
        } else {
            let today =
                Calendar.current
                    .startOfDay(for: now)

            start =
                Calendar.current.date(
                    byAdding: .day,
                    value: -(window - 1),
                    to: today
                ) ?? today
        }

        return AnalysisPeriod(
            start: min(start, now),
            end: now
        )
    }

    private var periodLogs: [DoseLog] {
        store.logs.filter {
            period.contains($0.loggedAt)
                && $0.protocolID
                    == selected?.id
        }
    }

    private var weeklyShareData: ShareCardData? {
        guard let summary =
            store.insights[7],
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
            reason in
            PaywallView(reason: reason)
        }
        .sheet(isPresented: $shareCard) {
            ShareCardPreviewView(
                data: weeklyShareData
            )
        }
        .trackingErrors()
    }
}


// MARK: - Main states

private extension InsightsView {

    var emptyProtocolState: some View {
        ContentUnavailableView {
            Label(
                "No protocol yet",
                systemImage:
                    "chart.xyaxis.line"
            )
        } description: {
            Text(
                "Add a protocol first. Insights are built "
                + "from your own recorded entries and changes."
            )
        }
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
                spacing: Theme.spaceM
            ) {
                protocolSelector

                Picker(
                    "Period",
                    selection: $window
                ) {
                    Text("Current phase")
                        .tag(0)

                    Text("7D")
                        .tag(7)

                    Text("30D")
                        .tag(30)
                }
                .pickerStyle(.segmented)

                Text(periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                if periodLogs.isEmpty {
                    emptyInsightsState

                } else {
                    overview(
                        summary: summary
                    )

                    if summary.scheduled > 0 {
                        consistencyChart(summary)
                    }

                    if !summary.sites.isEmpty {
                        sitesRow(summary)
                    }

                    if !summary.symptoms.isEmpty {
                        symptomsRow(summary)
                    }
                }

                proFeatures

                if weeklyShareData != nil {
                    Button {
                        shareCard = true
                    } label: {
                        Label(
                            "Share weekly card",
                            systemImage:
                                "square.and.arrow.up"
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.teal)
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
        .onAppear {
            if protocolID == nil {
                protocolID = selected?.id
            }
        }
    }


    @ViewBuilder
    var protocolSelector: some View {
        if let selected {
            if store.protocols.count > 1 {
                Menu {
                    ForEach(store.protocols) {
                        protocol in
                        Button(protocol.name) {
                            protocolID =
                                protocol.id
                            comparing = false
                            changeID = nil
                        }
                    }
                } label: {
                    protocolSelectorLabel(
                        selected.name,
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)

            } else {
                protocolSelectorLabel(
                    selected.name,
                    showsChevron: false
                )
            }
        }
    }


    func protocolSelectorLabel(
        _ name: String,
        showsChevron: Bool
    ) -> some View {
        HStack(spacing: Theme.spaceS) {
            Image(
                systemName:
                    "list.bullet.rectangle"
            )
            .foregroundStyle(Theme.teal)

            Text(name)
                .font(
                    .subheadline.weight(
                        .medium
                    )
                )
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Spacer()

            if showsChevron {
                Image(
                    systemName: "chevron.down"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(
            .horizontal,
            Theme.spaceM
        )
        .frame(minHeight: 44)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusRow
            )
        )
    }


    var emptyInsightsState: some View {
        ContentUnavailableView {
            Label(
                "No insights yet",
                systemImage:
                    "chart.xyaxis.line"
            )
        } description: {
            Text(
                "Record your first entry from Today. "
                + "Overview, consistency, sites, and observations "
                + "will appear here as your history grows."
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 260
        )
    }
}


// MARK: - Period and overview

private extension InsightsView {

    var periodLabel: String {
        let calendar =
            Calendar.current

        if window == 0,
           latest == nil,
           let created =
                selected?.createdAt,
           calendar.isDateInToday(
                created
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

        if calendar.isDate(
            period.start,
            inSameDayAs: period.end
        ) {
            return start
        }

        return start + " – " + end
    }


    func overview(
        summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Text("Overview")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(
                        .flexible(),
                        spacing: Theme.spaceXS
                    ),
                    GridItem(
                        .flexible(),
                        spacing: Theme.spaceXS
                    )
                ],
                spacing: Theme.spaceXS
            ) {
                InsightStatTile(
                    icon: "checkmark.circle",
                    label: "Entries",
                    value:
                        String(
                            periodLogs.count
                        ),
                    detail:
                        summary.scheduled > 0
                        ? "of \(summary.scheduled) scheduled"
                        : "recorded"
                )

                InsightStatTile(
                    icon: "scope",
                    label: "Consistency",
                    value:
                        summary.percentage,
                    detail:
                        summary.scheduled > 0
                        ? "\(summary.recorded) of \(summary.scheduled) logged"
                        : "No schedule"
                )

                InsightStatTile(
                    icon:
                        "checkmark.circle.fill",
                    label: "Logged",
                    value:
                        String(
                            summary.recorded
                        ),
                    detail:
                        summary.recorded == 1
                        ? "entry"
                        : "entries"
                )

                let skipped =
                    periodLogs.filter {
                        $0.status == "Skipped"
                    }.count

                InsightStatTile(
                    icon: "xmark.circle.fill",
                    label: "Skipped",
                    value: String(skipped),
                    detail:
                        skipped == 1
                        ? "entry"
                        : "entries",
                    attention: skipped > 0
                )
            }
        }
    }


    func consistencyChart(
        _ summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            HStack {
                Text("Recorded vs scheduled")
                    .font(
                        .subheadline.weight(
                            .semibold
                        )
                    )

                Spacer()

                chartLegend
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
                    Theme.line.opacity(0.9)
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
                .foregroundStyle(Theme.teal)
            }
            .frame(height: 170)
            .chartYAxis {
                AxisMarks(
                    position: .leading
                ) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
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
                    AxisValueLabel(
                        format:
                            .dateTime
                                .day()
                    )
                }
            }

            Text(
                "Recorded means a scheduled entry has a non-skipped log."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(Theme.spaceM)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusCard
            )
        )
    }


    var chartLegend: some View {
        HStack(spacing: Theme.spaceS) {
            legendItem(
                "Logged",
                color: Theme.teal
            )

            legendItem(
                "Scheduled",
                color: Theme.line
            )
        }
    }


    func legendItem(
        _ title: String,
        color: Color
    ) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(
                    width: 7,
                    height: 7
                )

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Observation rows

private extension InsightsView {

    func sitesRow(
        _ summary: InsightsSummary
    ) -> some View {
        NavigationLink {
            SitesBreakdownView(
                sites: summary.sites
            )
        } label: {
            HStack(spacing: Theme.spaceM) {
                Image(
                    systemName: "mappin.circle"
                )
                .foregroundStyle(Theme.teal)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Injection sites")
                        .font(
                            .subheadline.weight(
                                .medium
                            )
                        )
                        .foregroundStyle(Theme.ink)

                    Text(
                        summary.sites.prefix(2)
                            .map {
                                "\($0.name) · \($0.count)"
                            }
                            .joined(
                                separator: "   "
                            )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
            }
            .padding(Theme.spaceM)
        }
        .buttonStyle(.plain)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusRow
            )
        )
    }


    func symptomsRow(
        _ summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            HStack {
                Label(
                    "Recorded observations",
                    systemImage:
                        "waveform.path.ecg"
                )
                .font(
                    .subheadline.weight(
                        .medium
                    )
                )

                Spacer()

                Text(
                    String(
                        summary.symptoms.count
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(
                "Recorded observations only. Timing does not establish causation."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(Theme.spaceM)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusRow
            )
        )
    }
}


// MARK: - Pro features

private extension InsightsView {

    @ViewBuilder
    var proFeatures: some View {
        if store.isPremium,
           !changes.isEmpty {
            Button {
                comparing.toggle()
            } label: {
                Label(
                    comparing
                        ? "Hide comparison"
                        : "Compare change periods",
                    systemImage:
                        "arrow.left.arrow.right"
                )
            }
            .buttonStyle(.bordered)
            .tint(Theme.teal)

        } else if !store.isPremium,
                  !changes.isEmpty {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceS
            ) {
                Text("Protocola Pro")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.teal)

                Text(
                    "\(changes.count) recorded "
                    + (
                        changes.count == 1
                        ? "change"
                        : "changes"
                    )
                    + " ready to compare"
                )
                .font(.headline)

                Text(
                    "Compare descriptive windows around your own recorded changes."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button("See comparison") {
                    paywall = .compare
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.teal)
            }
            .padding(Theme.spaceM)
            .background(
                Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusCard
                )
            )
        }

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
            .onAppear {
                changeID =
                    changes.first?.id
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
            .buttonStyle(.bordered)
            .tint(Theme.teal)

        } else if !store.isPremium,
                  !periodLogs.isEmpty,
                  let protocolName =
                    selected?.name {
            Button {
                paywall = .ask
            } label: {
                Label(
                    "Ask about \(protocolName)",
                    systemImage:
                        "text.bubble"
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(.bordered)
            .tint(Theme.teal)
        }
    }
}


// MARK: - Supporting views

private struct InsightStatTile: View {
    let icon: String
    let label: String
    let value: String
    let detail: String
    var attention = false

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            HStack(spacing: Theme.spaceXS) {
                Image(systemName: icon)
                    .foregroundStyle(
                        attention
                            ? Theme.amber
                            : Theme.teal
                    )

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(Theme.spaceM)
        .frame(
            maxWidth: .infinity,
            minHeight: 108,
            alignment: .leading
        )
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius: Theme.radiusRow
            )
        )
    }
}


private struct SitesBreakdownView: View {
    let sites: [InsightsSummary.Site]

    var body: some View {
        List {
            Section("Recorded sites") {
                ForEach(sites) { site in
                    HStack {
                        Text(site.name)

                        Spacer()

                        Text(
                            String(site.count)
                        )
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .paperList()
        .navigationTitle("Injection Sites")
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
                .font(
                    .subheadline.weight(
                        .semibold
                    )
                )

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
                cornerRadius: Theme.radiusRow
            )
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
                .font(.subheadline)

            periodView(
                "Before",
                period: periods.before
            )

            periodView(
                "After",
                period: periods.after
            )

            Text(
                "Equal-duration windows, up to 30 days each. "
                + "Differences do not establish causation or medical conclusions."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
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
                .font(.headline)

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
            .font(.caption)
            .foregroundStyle(.secondary)
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

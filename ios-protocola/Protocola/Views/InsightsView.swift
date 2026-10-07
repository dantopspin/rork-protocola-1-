import SwiftUI
import Charts

struct InsightsView: View {
    let onGoToday: () -> Void

    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    init(
        onGoToday:
            @escaping () -> Void = {}
    ) {
        self.onGoToday = onGoToday
    }

    @State private var protocolID: UUID?
    @State private var window = 7
    @State private var changeID: UUID?
    @State private var assistant = false
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

    private var hasRecordedHistory: Bool {
        guard let selected else {
            return false
        }

        return store.logs.contains {
            $0.protocolID == selected.id
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            SettingsToolbarItem()
        }
        .sheet(isPresented: $assistant) {
            AssistantView()
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
        VStack(
            alignment: .leading,
            spacing: Theme.spaceL
        ) {
            PrimaryPageHeader(
                title: "Insights"
            )

            TrackingEmptyState(
                icon: "chart.xyaxis.line",
                title: "No protocol yet",
                message:
                    "Add a protocol first. Insights are built from recorded entries and changes.",
                actionTitle: "Go to Today",
                action: onGoToday
            )
        }
        .screenPadding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
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
                spacing: Theme.sectionGap
            ) {
                PrimaryPageHeader(
                    title: "Insights"
                )

                if store.protocols.count > 1 {
                    protocolSelector
                }

                if hasRecordedHistory {
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
                            .foregroundStyle(Theme.textSecondary)
                            .monospacedDigit()
                    }
                }

                Group {
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

                        estimatedLevelsEntry

                        RecordedEntriesHeatmap(
                            logs:
                                store.logs.filter {
                                    $0.protocolID
                                        == selected?.id
                                }
                        )

                        if !summary.sites.isEmpty {
                            sitesCard(summary)
                        }

                        if !summary.symptoms.isEmpty {
                            symptomsCard(summary)
                        }
                    }
                }
                .id(
                    String(window)
                    + "-"
                    + (
                        selected?.id
                            .uuidString
                        ?? "none"
                    )
                )
                .transition(
                    reduceMotion
                    ? .opacity
                    : .opacity.combined(
                        with: .move(
                            edge: .top
                        )
                    )
                )

                if let selected,
                   !store.labs(
                        protocolID:
                            selected.id
                   ).isEmpty {
                    labsEntry(selected)
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
        .trackingStateAnimation(
            value:
                String(window)
                + "-"
                + (
                    selected?.id
                        .uuidString
                    ?? "none"
                )
        )
        .sensoryFeedback(
            .selection,
            trigger: window
        )
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
                    Theme.textSecondary
                )
            }
            .padding(
                .vertical,
                Theme.spaceS
            )
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
        .buttonStyle(.plain)
    }


    var emptyInsightsState: some View {
        TrackingEmptyState(
            icon: "chart.xyaxis.line",
            title:
                "Your insights will build here",
            message:
                "Track entries over time to see consistency, changes, sites, and recorded patterns.",
            actionTitle: "Go to Today",
            action: onGoToday
        )
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
                    Eyebrow(text: "Consistency")

                    Text(summary.percentage)
                        .font(Theme.metricLarge)
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)

                    Text(
                        "\(summary.recorded) of \(summary.scheduled) scheduled"
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(Theme.textSecondary)
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
                    ),
                    // Recorded overlays scheduled; stacking would double the height.
                    stacking: .unstacked
                )
                .foregroundStyle(
                    Theme.inactiveFill
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
                    ),
                    // Recorded overlays scheduled; stacking would double the height.
                    stacking: .unstacked
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
                            Theme.inactiveFill
                        )

                    AxisValueLabel(
                        format:
                            .dateTime
                                .day(),
                        centered: true
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
            }
        }
        .padding(
            .vertical,
            Theme.spaceM
        )
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


    func activityHero(
        _ summary: InsightsSummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Eyebrow(text: "Recorded entries")

            Text(String(periodLogs.count))
                .font(Theme.metricLarge)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)

            Text(
                "No recurring schedule is recorded for this period."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(
            .vertical,
            Theme.spaceM
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
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


    func supportingStats(
        _ summary: InsightsSummary
    ) -> some View {
        let skipped =
            periodLogs.filter {
                $0.status == "Skipped"
            }.count

        return HStack(
            alignment: .top,
            spacing: Theme.spaceM
        ) {
            statTile(
                value:
                    String(summary.recorded),
                label: "Logged",
                dot: Theme.teal
            )

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    width: Theme.ruleThickness,
                    height:
                        Theme.compactMetricTileHeight
                )

            statTile(
                value: String(skipped),
                label: "Skipped",
                dot: Theme.textSecondary
            )

            Rectangle()
                .fill(Theme.hairline)
                .frame(
                    width: Theme.ruleThickness,
                    height:
                        Theme.compactMetricTileHeight
                )

            statTile(
                value:
                    String(
                        summary.sites.count
                    ),
                label: "Sites",
                dot: Theme.inactiveFill
            )
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

            HStack(spacing: Theme.spaceXXS) {
                Circle()
                    .fill(dot)
                    .frame(
                        width: Theme.statusDot,
                        height: Theme.statusDot
                    )

                Text(label)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
            }
        }
        .padding(
            .vertical,
            Theme.spaceM
        )
        .frame(
            maxWidth: .infinity,
            minHeight:
                Theme.compactMetricTileHeight,
            alignment: .leading
        )
    }
}


// MARK: - Change context

private extension InsightsView {

    func changeContext(
        _ change: ProtocolEvent
    ) -> some View {
        EditorialSection(
            "Since last change"
        ) {
            Button {
                if store.isPremium {
                    comparing = true
                    changeID = change.id
                } else {
                    store.requestPaywall(.compare)
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
                    .foregroundStyle(Theme.teal)
                    .frame(width: Theme.iconColumn)

                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceXXS
                    ) {
                        Text(
                            changeSummary(change)
                        )
                        .font(Theme.cardTitle)
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                        .lineLimit(2)

                        Text(
                            change.at.formatted(
                                date: .abbreviated,
                                time: .omitted
                            )
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }

                    Spacer()

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
                .frame(
                    minHeight:
                        Theme.minimumTapTarget
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
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


// MARK: - Estimated levels entry

private extension InsightsView {

    @ViewBuilder
    var estimatedLevelsEntry:
        some View {
        if let selected {
            if store.isPremium {
                NavigationLink {
                    EstimatedLevelsView(
                        protocolID:
                            selected.id
                    )
                } label: {
                    estimatedLevelsLabel
                }
                .buttonStyle(.plain)

            } else {
                Button {
                    store.requestPaywall(.levels)
                } label: {
                    estimatedLevelsLabel
                }
                .buttonStyle(.plain)
            }
        }
    }


    var estimatedLevelsLabel:
        some View {
        HStack(
            spacing: Theme.spaceM
        ) {
            Image(
                systemName:
                    "waveform.path.ecg"
            )
            .font(Theme.sectionTitle)
            .foregroundStyle(
                Theme.teal
            )
            .frame(width: Theme.iconColumn)

            VStack(
                alignment: .leading,
                spacing:
                    Theme.spaceXXS
            ) {
                Text("Estimated levels")
                    .font(Theme.cardTitle)
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(
                    "Half-life model from actual recorded doses"
                )
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


// MARK: - Labs

private extension InsightsView {

    func labsEntry(
        _ protocolRecord:
            ProtocolRecord
    ) -> some View {
        let labs =
            store.labs(
                protocolID:
                    protocolRecord.id
            )
        let latest =
            labs.max {
                $0.collectedAt
                    < $1.collectedAt
            }

        return NavigationLink {
            LabListView(
                protocolID:
                    protocolRecord.id
            )
        } label: {
            HStack(
                spacing: Theme.spaceM
            ) {
                Image(
                    systemName:
                        "testtube.2"
                )
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.teal
                )
            .frame(width: Theme.iconColumn)

                VStack(
                    alignment: .leading,
                    spacing:
                        Theme.spaceXXS
                ) {
                    Text("Labs")
                        .font(Theme.cardTitle)
                        .foregroundStyle(
                            Theme.ink
                        )

                    if let latest {
                        Text(
                            latest.marker
                            + " · "
                            + latest.displayValue
                            + " · "
                            + latest.collectedAt
                                .formatted(
                                    date:
                                        .abbreviated,
                                    time:
                                        .omitted
                                )
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                        .lineLimit(1)
                    }
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
        .buttonStyle(.plain)
    }
}


// MARK: - Secondary insight cards

private extension InsightsView {

    func sitesCard(
        _ summary: InsightsSummary
    ) -> some View {
        EditorialSection(
            "Top injection sites"
        ) {
        NavigationLink {
            SitesBreakdownView(
                sites: summary.sites
            )
        } label: {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceS
            ) {

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
                                    ) * 100 + 0.5 // round to nearest
                                )
                            )
                            + "%"
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                        .monospacedDigit()
                    }
                }


                HStack {
                    Text("All sites")
                        .font(Theme.label)
                        .foregroundStyle(Theme.teal)

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
                .frame(
                    minHeight:
                        Theme.minimumTapTarget
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        }
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
        EditorialSection(
            "Recorded observations"
        ) {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            RecordRow(
                label: "Observations recorded",
                value:
                    String(
                        summary.symptoms.count
                    )
            )

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
                    Theme.textSecondary
                )
            }

            Text(
                "Recorded observations only. Timing does not establish causation."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
        }
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
                store.requestPaywall(.ask)
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
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                EditorialSection(
                    "Recorded sites"
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceS
                    ) {
                        ForEach(sites) { site in
                            RecordRow(
                                label: site.name,
                                value:
                                    String(site.count)
                            )
                            .monospacedDigit()
                        }
                    }
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationTitle(
            "Injection sites"
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
            Eyebrow(text: "Recorded in this period")

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

            if let protocolID {
                let labPairs =
                    LabComparisonEngine
                        .pairs(
                            labs: store.labs,
                            protocolID:
                                protocolID,
                            change:
                                change.at,
                            beforePeriod:
                                periods.before,
                            afterPeriod:
                                periods.after
                        )

                if !labPairs.isEmpty {
                    VStack(
                        alignment: .leading,
                        spacing:
                            Theme.spaceS
                    ) {
                        Eyebrow(text: "Labs around change")

                        ForEach(
                            labPairs
                        ) { pair in
                            RecordRow(
                                label:
                                    pair.marker,
                                value:
                                    pair.valueText
                            )
                        }

                        Text(
                            "Closest matching recorded values in the before and after windows. No causal interpretation is applied."
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }
                }
            }

            Text(
                "Equal-duration windows, up to 30 days each. Differences do not establish causation or medical conclusions."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
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
            Eyebrow(text: title)

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
                Theme.textSecondary
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



// MARK: - Estimated level detail

struct EstimatedLevelsView: View {
    let protocolID: UUID

    @Environment(TrackingStore.self)
    private var store

    @State
    private var window = 30

    @State
    private var editingCompound:
        CompoundRecord?

    private var period:
        AnalysisPeriod {
        let now = Date.now
        let start =
            Calendar.current.date(
                byAdding: .day,
                value:
                    -(window - 1),
                to:
                    Calendar.current
                        .startOfDay(
                            for: now
                        )
            ) ?? now

        return AnalysisPeriod(
            start: start,
            end: now
        )
    }

    private var overview:
        EstimatedLevelOverview {
        EstimatedLevelOverview(
            store: store,
            protocolID: protocolID,
            period: period
        )
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                Picker(
                    "Period",
                    selection: $window
                ) {
                    Text("7D").tag(7)
                    Text("30D").tag(30)
                    Text("90D").tag(90)
                }
                .pickerStyle(.segmented)
                .tint(Theme.ink)

                modelExplanation

                if overview.series.count
                    > 1 {
                    multiCompoundOverview
                }

                ForEach(
                    overview.series
                ) { series in
                    compoundCard(series)
                }

                if !overview
                    .missingReference
                    .isEmpty {
                    missingReferenceCard
                }

                if overview.series.isEmpty,
                   overview
                    .missingReference
                    .isEmpty {
                    TrackingEmptyState(
                        icon:
                            "waveform.path.ecg",
                        title:
                            "No compounds to model",
                        message:
                            "Add a compound to this protocol first."
                    )
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
        .background(Theme.paper)
        .navigationTitle(
            "Estimated levels"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            item: $editingCompound
        ) { compound in
            CompoundHalfLifeEditorView(
                compound: compound
            )
        }
    }
}


private extension EstimatedLevelsView {

    var modelExplanation:
        some View {
        TrackingCard {
            Eyebrow(text: "Model assumptions")

            Text(
                "Each curve uses simple exponential decay from actual recorded doses and the reference half-life you enter. It is not a measured blood concentration, exposure, efficacy, or safety estimate."
            )
            .font(Theme.body)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    var multiCompoundOverview:
        some View {
        TrackingCard {
            Eyebrow(text: "Current estimates")

            ForEach(
                overview.series
            ) { series in
                RecordRow(
                    label:
                        series
                            .compoundName,
                    value:
                        series.currentText
                )
            }

            Text(
                "Values are compound-specific remaining-amount estimates and should not be compared as equivalent biological effect."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    func compoundCard(
        _ series:
            EstimatedLevelOverview.Series
    ) -> some View {
        TrackingCard {
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
                    Text(
                        series.compoundName
                    )
                    .font(
                        Theme.sectionTitle
                    )
                    .foregroundStyle(
                        Theme.ink
                    )

                    Text(
                        "Half-life input · "
                        + series
                            .halfLifeText
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }

                Spacer()

                Button("Edit reference") {
                    editingCompound =
                        store.compounds
                            .first {
                                $0.id
                                    == series
                                        .compoundID
                            }
                }
                .font(Theme.label)
            }

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text("Estimated remaining")
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )

                Text(series.currentText)
                    .font(
                        Theme.metricLarge
                    )
                    .foregroundStyle(
                        Theme.ink
                    )
                    .monospacedDigit()
            }

            Chart {
                ForEach(
                    series.samples
                ) { sample in
                    LineMark(
                        x: .value(
                            "Time",
                            sample.at
                        ),
                        y: .value(
                            "Estimated remaining",
                            sample
                                .estimatedMg
                        )
                    )
                    .foregroundStyle(
                        Theme.teal
                    )
                }

                ForEach(
                    series.revisionDates,
                    id: \.self
                ) { date in
                    RuleMark(
                        x: .value(
                            "Protocol change",
                            date
                        )
                    )
                    .foregroundStyle(
                        Theme.hairline
                    )
                }
            }
            .frame(
                height:
                    Theme.chartHeight
            )
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(
                    values:
                        .automatic(
                            desiredCount: 4
                        )
                ) { value in
                    AxisGridLine()
                        .foregroundStyle(
                            Theme.inactiveFill
                        )

                    AxisValueLabel(
                        format:
                            .dateTime
                                .month(
                                    .abbreviated
                                )
                                .day()
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
            }

            if let source =
                series.source,
               !source.isEmpty {
                RecordRow(
                    label:
                        "Reference source",
                    value: source
                )
            }

            if series
                .unsupportedLogCount > 0 {
                Text(
                    String(
                        series
                            .unsupportedLogCount
                    )
                    + " recorded "
                    + (
                        series
                            .unsupportedLogCount
                            == 1
                        ? "entry could"
                        : "entries could"
                    )
                    + " not be converted to mass because no concentration snapshot was available."
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.amber
                )
            }

            Text(
                "Vertical markers show effective protocol-revision dates. The curve itself uses recorded doses, so corrected or changed doses alter the model automatically."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    var missingReferenceCard:
        some View {
        TrackingCard {
            Text("Add half-life reference")
                .font(Theme.cardTitle)
                .foregroundStyle(
                    Theme.ink
                )

            Text(
                "Protocola does not guess a pharmacokinetic half-life. Record a reference value and optional source for each compound you want to model."
            )
            .font(Theme.body)
            .foregroundStyle(
                Theme.textSecondary
            )

            ForEach(
                overview
                    .missingReference
            ) { compound in
                Button {
                    editingCompound =
                        compound
                } label: {
                    HStack(
                        spacing:
                            Theme.spaceS
                    ) {
                        Text(
                            compound.name
                        )
                        .font(
                            Theme.body
                        )
                        .foregroundStyle(
                            Theme.ink
                        )

                        Spacer()

                        Text("Set reference")
                            .font(
                                Theme.label
                            )
                            .foregroundStyle(
                                Theme.teal
                            )
                    }
                    .contentShape(
                        Rectangle()
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}


struct CompoundHalfLifeEditorView:
    View {
    let compound: CompoundRecord

    @Environment(TrackingStore.self)
    private var store
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var hoursText: String

    @State
    private var source: String

    init(
        compound: CompoundRecord
    ) {
        self.compound = compound
        _hoursText =
            State(
                initialValue:
                    compound
                        .referenceHalfLifeHoursText
                    ?? ""
            )
        _source =
            State(
                initialValue:
                    compound
                        .referenceHalfLifeSource
                    ?? ""
            )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Half-life (hours)",
                        text: $hoursText
                    )
                    .keyboardType(
                        .decimalPad
                    )

                    TextField(
                        "Reference source (optional)",
                        text: $source,
                        axis: .vertical
                    )

                } header: {
                    Eyebrow(text: compound.name)
                } footer: {
                    Text(
                        "Enter a half-life from a source you trust. This value powers a mathematical decay model only; Protocola does not infer a clinical half-life or recommend treatment."
                    )
                }

                if compound
                    .referenceHalfLifeHours
                    != nil {
                    Section {
                        Button(
                            "Clear reference",
                            role: .destructive
                        ) {
                            hoursText = ""
                            source = ""
                            save()
                        }
                    }
                }
            }
            .paperList()
            .doneKeyboard()
            .navigationTitle(
                "Level reference"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .trackingErrors()
        }
    }


    private func save() {
        if store
            .saveCompoundHalfLife(
                compound,
                hoursText:
                    hoursText,
                source: source
            ) {
            dismiss()
        }
    }
}

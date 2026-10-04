import SwiftUI
import Charts

struct InsightsView: View {
    @Environment(TrackingStore.self) private var store
    @State private var protocolID: UUID?
    @State private var window: Int = 0
    @State private var changeID: UUID?
    @State private var assistant: Bool = false
    @State private var paywall: PaywallReason?
    @State private var comparing: Bool = false
    @State private var shareCard: Bool = false
    private var selected: ProtocolRecord? { store.protocols.first { $0.id == protocolID } ?? store.protocols.first }
    private var changes: [ProtocolEvent] { store.events.filter { $0.protocolID == selected?.id && $0.isChangeAnchor && $0.title != "Protocol created" } }
    private var latest: ProtocolEvent? { changes.first }
    private var period: AnalysisPeriod {
        let now = Date.now
        let beginning = selected?.createdAt ?? now
        let start = window == 0 ? (latest?.at ?? beginning) : (Calendar.current.date(byAdding: .day, value: -window, to: now) ?? now)
        return AnalysisPeriod(start: min(start, now), end: now)
    }
    var body: some View {
        let summary = InsightsSummary(store: store, period: period, protocolID: selected?.id)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spaceXL) {
                Picker("Protocol", selection: $protocolID) { ForEach(store.protocols) { Text($0.name).tag(Optional($0.id)) } }
                    .onAppear { if protocolID == nil { protocolID = selected?.id } }
                Picker("Period", selection: $window) { Text("Since change").tag(0); Text("7 days").tag(7); Text("30 days").tag(30) }.pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: Theme.spaceXS) {
                    Text(window == 0 ? (latest == nil ? "Since this protocol began" : "Since your last protocol change") : "Last \(window) days").font(.title2.weight(.semibold))
                    Text("\(period.start.formatted(date: .abbreviated, time: .shortened)) – \(period.end.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(Theme.muted)
                    if window == 0, let latest { Text(latest.detail).font(.subheadline).foregroundStyle(Theme.muted) }
                }
                PeriodSummaryCard(summary: summary, logs: store.logs.filter { period.contains($0.loggedAt) && $0.protocolID == selected?.id })
                TrackingCard {
                    Eyebrow(text: "Recorded scheduled entries")
                    Chart(summary.days) { day in BarMark(x: .value("Day", day.date, unit: .day), y: .value("Recorded", day.recorded)).foregroundStyle(Theme.teal) }.frame(height: 140)
                    Text("Consistency = recorded non-skipped scheduled entries ÷ elapsed scheduled entries. Unscheduled logs do not enter this percentage.").font(.caption).foregroundStyle(Theme.muted)
                }
                TrackingCard {
                    Eyebrow(text: "Sites and symptoms")
                    ForEach(summary.sites) { RecordRow(label: $0.name, value: "\($0.count) entries") }
                    ForEach(summary.symptoms) { symptom in
                        Text("\(symptom.date.formatted(date: .abbreviated, time: .shortened)) · \(symptom.name) · severity \(symptom.severity)/10").font(.subheadline)
                    }
                    if summary.symptoms.isEmpty { Text("No symptoms recorded in this period. This does not mean no symptoms occurred.").font(.subheadline).foregroundStyle(Theme.muted) }
                    Text("Recorded observations only. Timing does not establish causation.").font(.caption).foregroundStyle(Theme.muted)
                }
                if store.isPremium {
                    Button { comparing.toggle() } label: { Label("Compare change periods", systemImage: "arrow.left.arrow.right") }.buttonStyle(TrackingSecondaryButtonStyle())
                } else if changes.isEmpty {
                    Button { paywall = .compare } label: { Label("Compare change periods · Pro", systemImage: "arrow.left.arrow.right") }.buttonStyle(TrackingSecondaryButtonStyle())
                } else {
                    TrackingCard {
                        Eyebrow(text: "Protocola Pro")
                        Text("\(changes.count) recorded \(changes.count == 1 ? "change" : "changes") ready to compare").font(.headline)
                        Text("Before-and-after windows computed from your own records.").font(.subheadline).foregroundStyle(Theme.muted)
                        Button("See comparison") { paywall = .compare }.buttonStyle(TrackingPrimaryButtonStyle())
                    }
                }
                if comparing && store.isPremium {
                    Picker("Recorded change", selection: $changeID) { ForEach(changes) { Text($0.at.formatted(date: .abbreviated, time: .shortened)).tag(Optional($0.id)) } }
                        .onAppear { changeID = changes.first?.id }
                    if let change = changes.first(where: { $0.id == changeID }) {
                        ComparisonCard(protocolID: selected?.id, change: change)
                    } else { Text("A meaningful recorded change is needed for comparison.").foregroundStyle(Theme.muted) }
                }
                if store.isPremium {
                    Button { assistant = true } label: { Label("Ask your timeline", systemImage: "text.bubble") }.buttonStyle(TrackingSecondaryButtonStyle())
                } else if let protocolName = selected?.name {
                    TrackingCard {
                        Eyebrow(text: "Protocola Pro")
                        Text("Ask about \(protocolName)").font(.headline)
                        Text("Answers grounded in this protocol's recorded entries and changes.").font(.subheadline).foregroundStyle(Theme.muted)
                        Button("Try Ask Protocola") { paywall = .ask }.buttonStyle(TrackingSecondaryButtonStyle())
                    }
                } else {
                    Button { paywall = .ask } label: { Label("Ask your timeline · Pro", systemImage: "text.bubble") }.buttonStyle(TrackingSecondaryButtonStyle())
                }
                Button { shareCard = true } label: { Label("Share this week's card", systemImage: "square.and.arrow.up") }.buttonStyle(TrackingSecondaryButtonStyle())
            }.screenPadding().padding(.bottom, Theme.spaceS)
        }.background(Theme.paper).navigationTitle("Insights")
            .sheet(isPresented: $assistant) { AssistantView() }
            .fullScreenCover(item: $paywall) { reason in PaywallView(reason: reason) }
            .sheet(isPresented: $shareCard) { ShareCardPreviewView(data: ShareCardData(summary: InsightsSummary(store: store, window: 7), window: 7)) }
            .trackingErrors()
    }
}

struct PeriodSummaryCard: View {
    let summary: InsightsSummary
    let logs: [DoseLog]
    var body: some View {
        TrackingCard {
            Eyebrow(text: "Recorded in this period")
            RecordRow(label: "Entries", value: String(logs.count))
            RecordRow(label: "Consistency", value: "\(summary.percentage) · \(summary.recorded)/\(summary.scheduled)")
            ForEach(["Logged", "Partial", "Delayed", "Skipped"], id: \.self) { status in RecordRow(label: status, value: String(logs.filter { $0.status == status }.count)) }
            RecordRow(label: "Symptom observations", value: String(summary.symptoms.count))
            if logs.isEmpty { Text("No recorded entries; insufficient observation data for interpretation.").font(.caption).foregroundStyle(Theme.muted) }
        }
    }
}

private struct ComparisonCard: View {
    let protocolID: UUID?
    let change: ProtocolEvent
    @Environment(TrackingStore.self) private var store
    var body: some View {
        let periods = AnalysisPeriod.comparison(change: change.at, now: .now)
        VStack(alignment: .leading, spacing: Theme.spaceL) {
            Text(change.detail).font(.subheadline)
            periodView("Before", period: periods.before)
            periodView("After", period: periods.after)
            Text("Equal-duration windows, up to 30 days each. Records at the change time belong to After. Other changes within these windows are not controlled for; differences do not establish causation or medical conclusions.").font(.caption).foregroundStyle(Theme.muted)
        }
    }
    private func periodView(_ title: String, period: AnalysisPeriod) -> some View {
        VStack(alignment: .leading, spacing: Theme.spaceXS) {
            Text(title).font(.headline)
            Text("\(period.start.formatted(date: .abbreviated, time: .shortened)) – \(period.end.formatted(date: .abbreviated, time: .shortened)) (end excluded)").font(.caption).foregroundStyle(Theme.muted)
            if let beginning = store.protocols.first(where: { $0.id == protocolID })?.createdAt, beginning > period.start { Text("Partial coverage: protocol began \(beginning.formatted(date: .abbreviated, time: .shortened)).").font(.caption).foregroundStyle(Theme.amber) }
            PeriodSummaryCard(summary: InsightsSummary(store: store, period: period, protocolID: protocolID), logs: store.logs.filter { $0.protocolID == protocolID && period.contains($0.loggedAt) })
        }
    }
}

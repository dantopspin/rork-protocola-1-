import SwiftUI

struct HistoryView: View {
    @Environment(TrackingStore.self) private var store
    @State private var search: String = ""
    @State private var category: String = "Timeline"
    @State private var protocolID: UUID?
    @State private var dates: Bool = false
    @State private var from: Date = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    @State private var to: Date = .now
    @State private var paywall: Bool = false
    @State private var summary: Bool = false
    init(protocolID: UUID? = nil) { _protocolID = State(initialValue: protocolID) }
    private var records: [TimelineRecord] {
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to)) ?? to
        return TimelineRecord.build(logs: store.logs, events: store.events, includeMetadata: category == "All audit events" || category == "Metadata").filter {
            (protocolID == nil || $0.protocolID == protocolID) &&
            (["Timeline", "All audit events"].contains(category) || $0.category == category || (category == "Symptoms" && !($0.log?.symptoms ?? "").isEmpty)) &&
            (!dates || ($0.at >= Calendar.current.startOfDay(for: from) && $0.at < end)) &&
            (search.isEmpty || "\($0.title) \($0.detail)".localizedStandardContains(search))
        }
    }
    var body: some View {
        List {
            Section {
                Picker("Protocol", selection: $protocolID) {
                    Text("All protocols").tag(nil as UUID?)
                    ForEach(store.protocols) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Events", selection: $category) { ForEach(["Timeline", "Dose", "Protocol", "Symptoms", "Vial", "Site", "Correction", "Metadata", "All audit events"], id: \.self) { Text($0).tag($0) } }
                Toggle("Filter dates", isOn: $dates)
                if dates { DatePicker("From", selection: $from, displayedComponents: .date); DatePicker("To", selection: $to, displayedComponents: .date) }
            }
            Section("Recorded timeline") {
                ForEach(records) { record in
                    if let log = record.log {
                        NavigationLink(value: TrackingRoute.logDetail(log.id)) { TimelineRow(record: record) }
                    } else if let event = record.event {
                        NavigationLink { EventDetailView(event: event) } label: { TimelineRow(record: record) }
                    }
                }
                if records.isEmpty { TrackingEmptyState(icon: "clock.arrow.circlepath", title: "No records to show", message: "Entries and changes appear here. Try a different filter.") }
            }
        }.paperList().navigationTitle("History").searchable(text: $search, prompt: "Search your timeline")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { if store.isPremium { summary = true } else { paywall = true } } label: { Label("Visit Summary", systemImage: "doc.text") } } }
            .fullScreenCover(isPresented: $paywall) { PaywallView(reason: .summary) }
            .sheet(isPresented: $summary) { VisitSummaryView() }
            .trackingRoutes().trackingErrors()
    }
}

private struct TimelineRow: View {
    let record: TimelineRecord
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXS) {
            HStack { Text(record.title).font(.headline); Spacer(); StatusBadge(text: record.category) }
            Text(record.at.formatted(date: .abbreviated, time: .shortened)).font(.caption).monospacedDigit().foregroundStyle(Theme.muted)
            Text(record.detail).font(.subheadline).foregroundStyle(Theme.muted).lineLimit(3)
        }.padding(.vertical, Theme.spaceXS)
    }
}

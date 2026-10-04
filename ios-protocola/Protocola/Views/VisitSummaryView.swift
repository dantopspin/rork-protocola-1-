import SwiftUI

struct VisitSummaryView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var protocolID: UUID?
    @State private var fullHistory: Bool = true
    @State private var from: Date = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    @State private var to: Date = .now
    @State private var url: URL?
    @State private var sharing: Bool = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Record scope") {
                    Picker("Protocol", selection: $protocolID) { ForEach(store.protocols) { Text($0.name).tag(Optional($0.id)) } }
                    Toggle("Full recorded history", isOn: $fullHistory)
                    if !fullHistory { DatePicker("From", selection: $from, displayedComponents: .date); DatePicker("Through", selection: $to, displayedComponents: .date) }
                }
                Section {
                    Text("Current protocol, key changes, entries, symptoms, consistency, and a chronological timeline. Built on this iPhone from retained records, not medical interpretation.").font(.subheadline).foregroundStyle(Theme.muted)
                    Button("Prepare and share PDF") {
                        guard store.isPremium, let protocolID else { return }
                        let record = store.protocols.first { $0.id == protocolID }
                        let start = fullHistory ? (record?.createdAt ?? from) : Calendar.current.startOfDay(for: from)
                        let end = fullHistory ? Date.now : min(.now, Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to)) ?? to)
                        guard start <= end else { store.error = "Choose a valid date range."; return }
                        do { url = try store.visitSummaryURL(protocolID: protocolID, period: AnalysisPeriod(start: start, end: end)); sharing = true }
                        catch { store.error = "The Visit Summary could not be prepared. Please try again." }
                    }.disabled(protocolID == nil || !store.isPremium)
                }
            }.paperList().navigationTitle("Visit Summary").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .onAppear { protocolID = store.protocols.first?.id }
                .sheet(isPresented: $sharing) { if let url { ActivityView(items: [url]) } }
                .trackingErrors()
        }
    }
}

import SwiftUI

struct ProtocolDetailView: View {
    let protocolID: UUID
    @Environment(TrackingStore.self) private var store
    @State private var editing: ScheduleRevision?
    @State private var logging: ScheduleRevision?
    @State private var addCompound: Bool = false
    @State private var calculator: Bool = false
    @State private var inventory: Bool = false
    @State private var choice: Bool = false
    var body: some View {
        Group {
            if let record = store.protocols.first(where: { $0.id == protocolID }) {
                List {
                    if !store.canEdit(record.id) {
                        Section { Text("Read-only on Free. Your records are preserved.").foregroundStyle(Theme.muted); Button("Choose protocol for Free tracking") { choice = true } }
                    }
                    Section("Existing instructions") {
                        RecordRow(label: "Source", value: record.instructionSource)
                        RecordRow(label: "Status", value: record.status)
                        if !record.notes.isEmpty { Text(record.notes).font(.subheadline) }
                    }
                    ForEach(store.currentRevisions(record.id)) { revision in
                        Section(revision.compoundName) {
                            RecordRow(label: "Scheduled amount", value: "\(revision.amountText) \(revision.unitText)")
                            RecordRow(label: "Schedule", value: revision.config?.kind.rawValue ?? "Not available")
                            if let config = revision.config {
                                RecordRow(label: "Times", value: config.minutes.map { String(format: "%02d:%02d", $0 / 60, $0 % 60) }.joined(separator: ", "))
                            }
                            RecordRow(label: "Vial", value: store.vial(revision.vialID)?.name ?? "Not selected")
                            if let site = revision.configuredSite { RecordRow(label: "Configured site", value: site) }
                            Button("Edit recorded schedule") { editing = revision }.disabled(!store.canEdit(record.id))
                            Button("Log unscheduled entry") { logging = revision }.disabled(!store.canTrack(record.id))
                        }
                    }
                    Section {
                        NavigationLink { HistoryView(protocolID: record.id) } label: { Label("Protocol evolution", systemImage: "clock.arrow.circlepath") }
                        Button("Add compound") { addCompound = true }.disabled(!store.canEdit(record.id))
                        Button { inventory = true } label: { Label("Inventory", systemImage: "shippingbox") }
                        Button { calculator = true } label: { Label("Calculator", systemImage: "function") }
                    }
                    Section {
                        Button(record.status == "Active" ? "Pause protocol" : "Resume protocol") { store.changeStatus(record, status: record.status == "Active" ? "Paused" : "Active") }
                        if record.status != "Archived" { Button("Archive protocol", role: .destructive) { store.changeStatus(record, status: "Archived") } }
                    }.disabled(!store.canEdit(record.id))
                    Section { Text("Changes apply from now onward. Past schedules and log snapshots are retained.") }
                }.paperList().navigationTitle(record.name).navigationBarTitleDisplayMode(.inline)
                    .sheet(item: $editing) { revision in ProtocolEditorView(record: record, revision: revision) }
                    .sheet(item: $logging) { revision in DoseEditorView(revision: revision) }
                    .sheet(isPresented: $addCompound) { ProtocolEditorView(record: record) }
            } else { ContentUnavailableView("Protocol unavailable", systemImage: "list.bullet.rectangle") }
        }
        .sheet(isPresented: $choice) { FreeProtocolChoiceView() }
        .sheet(isPresented: $calculator) { CalculatorView() }
        .navigationDestination(isPresented: $inventory) { InventoryView() }.trackingErrors()
    }
}

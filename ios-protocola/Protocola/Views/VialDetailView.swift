import SwiftUI

struct VialDetailView: View {
    let vialID: UUID
    @Environment(TrackingStore.self) private var store
    @State private var edit: Bool = false
    var body: some View {
        Group {
            if let vial = store.vial(vialID) {
                List {
                    Section("Recorded vial") {
                        RecordRow(label: "Compound", value: vial.compoundName)
                        RecordRow(label: "Original", value: "\(vial.originalMgText) mg")
                        RecordRow(label: "Diluent", value: "\(vial.diluentMlText) mL")
                        RecordRow(label: "Concentration", value: vial.concentration.map { "\(DoseCalculator.text($0)) mg/mL" } ?? "Not recorded")
                        RecordRow(label: "Remaining", value: "\(DoseCalculator.text(store.balances[vial.id] ?? 0)) mg")
                        RecordRow(label: "Batch", value: vial.batch.isEmpty ? "Not recorded" : vial.batch)
                        RecordRow(label: "Supplier / clinic", value: vial.supplier.isEmpty ? "Not recorded" : vial.supplier)
                        if let expiry = vial.expiry { RecordRow(label: "Expiry / discard", value: expiry.formatted(date: .abbreviated, time: .omitted)) }
                        if !vial.storageNotes.isEmpty { Text(vial.storageNotes) }
                    }
                    Section {
                        Button("Edit vial / correct balance") { edit = true }
                        Button(vial.isArchived ? "Restore vial" : "Archive vial") { store.archiveVial(vial) }
                    }
                    Section("Recorded entries") {
                        ForEach(store.logs.filter { $0.vialID == vial.id }) { log in
                            NavigationLink(value: TrackingRoute.logDetail(log.id)) {
                                VStack(alignment: .leading, spacing: Theme.spaceXS) {
                                    HStack { Text("\(log.actualAmountText) \(log.unitText)").font(.headline); Spacer(); StatusBadge(text: log.status) }
                                    Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(Theme.muted).monospacedDigit()
                                }.padding(.vertical, Theme.spaceXS)
                            }
                        }
                        if !store.logs.contains(where: { $0.vialID == vial.id }) { Text("No entries use this vial yet.").font(.subheadline).foregroundStyle(Theme.muted) }
                    }
                }.paperList().trackingRoutes().navigationTitle(vial.name).navigationBarTitleDisplayMode(.inline).sheet(isPresented: $edit) { VialEditorView(vial: vial) }
            } else { ContentUnavailableView("Vial unavailable", systemImage: "shippingbox") }
        }.trackingErrors()
    }
}

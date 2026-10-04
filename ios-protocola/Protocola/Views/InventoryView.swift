import SwiftUI

struct InventoryView: View {
    @Environment(TrackingStore.self) private var store
    @State private var add: Bool = false
    @State private var showArchived: Bool = false
    var body: some View {
        List {
            Section {
                Toggle("Show archived vials", isOn: $showArchived)
                ForEach(store.vials.filter { showArchived || !$0.isArchived }) { vial in
                    NavigationLink(value: TrackingRoute.vialDetail(vial.id)) {
                        VStack(alignment: .leading, spacing: Theme.spaceXS) {
                            HStack { Text(vial.name).font(.headline); Spacer(); if vial.isArchived { StatusBadge(text: "Archived") } }
                            Text(vial.compoundName).font(.subheadline).foregroundStyle(Theme.muted)
                            Text("\(DoseCalculator.text(store.balances[vial.id] ?? 0)) mg remaining").font(.subheadline.monospacedDigit()).foregroundStyle(Theme.ink)
                            if let entries = store.scheduledEntriesRemaining(in: vial), entries > 0 {
                                Text("About \(entries) scheduled \(entries == 1 ? "entry" : "entries") remaining").font(.caption).foregroundStyle(Theme.muted).monospacedDigit()
                            }
                            if ["Low recorded balance", "Depleted"].contains(store.vialStatus(vial)) { Label(store.vialStatus(vial), systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(Theme.amber) }
                        }.padding(.vertical, Theme.spaceXS)
                    }
                }
                if store.vials.isEmpty { TrackingEmptyState(icon: "shippingbox", title: "No vials recorded", message: "Add the vial details from your own label or instructions.", actionTitle: "Add vial", action: { add = true }) }
            }
            Section { Text("Balances are estimates from your recorded entries and manual corrections. Entry counts appear only when a single fixed-mg schedule is recorded against the vial.").font(.footnote).foregroundStyle(Theme.muted) }
        }.paperList().navigationTitle("Inventory").toolbar { Button("Add vial", systemImage: "plus") { add = true } }
            .sheet(isPresented: $add) { VialEditorView() }
            .trackingRoutes().trackingErrors()
    }
}

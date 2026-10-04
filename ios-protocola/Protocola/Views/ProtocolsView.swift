import SwiftUI

struct ProtocolsView: View {
    @Environment(TrackingStore.self) private var store
    @State private var create: Bool = false
    @State private var inventory: Bool = false
    @State private var choice: Bool = false
    @State private var paywall: Bool = false
    var body: some View {
        List {
            if !store.isPremium && store.activeProtocolIDs.count > 1 {
                Section { Button("Choose the protocol to track on Free") { choice = true } }
            }
            Section {
                ForEach(store.protocols) { record in
                    NavigationLink(value: TrackingRoute.protocolDetail(record.id)) {
                        VStack(alignment: .leading, spacing: Theme.spaceS) {
                            HStack { Text(record.name).font(.headline); Spacer(); StatusBadge(text: record.status == "Active" && !store.canTrack(record.id) ? "Read-only · Free" : record.status) }
                            ForEach(store.currentRevisions(record.id)) { revision in
                                Text("\(revision.compoundName) · \(revision.amountText) \(revision.unitText)").font(.subheadline).foregroundStyle(Theme.muted)
                            }
                            Text(record.instructionSource).font(.caption).foregroundStyle(Theme.muted)
                        }.padding(.vertical, Theme.spaceXS)
                    }
                }
                if store.protocols.isEmpty {
                    TrackingEmptyState(icon: "list.bullet.rectangle", title: "No protocols yet", message: "Record existing instructions, not a generated plan.", actionTitle: "Add your protocol", action: { create = true })
                }
            } header: { Text("Your recorded protocols") }
            Section { Button { inventory = true } label: { Label("Vial inventory", systemImage: "shippingbox") } }
        }.paperList().navigationTitle("Protocols")
            .toolbar { Button("Add protocol", systemImage: "plus") { if store.canCreateProtocol { create = true } else { paywall = true } } }
            .sheet(isPresented: $create) { ProtocolEditorView() }
            .sheet(isPresented: $choice) { FreeProtocolChoiceView() }
            .fullScreenCover(isPresented: $paywall) { PaywallView(reason: .secondProtocol) }
            .trackingRoutes()
            .navigationDestination(isPresented: $inventory) { InventoryView() }.trackingErrors()
    }
}

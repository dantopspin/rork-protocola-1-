import SwiftUI

struct FreeProtocolChoiceView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Free includes one actively tracked protocol. Choose which one to keep using. All other protocols and their history stay on this iPhone, read-only, with reminders inactive.").font(.subheadline).foregroundStyle(Theme.muted)
                }
                Section("Track on Free") {
                    ForEach(store.protocols.filter { $0.status == "Active" }) { record in
                        Button { store.chooseFreeProtocol(record.id); dismiss() } label: {
                            HStack { Text(record.name); Spacer(); if store.selectedFreeProtocolID == record.id { Image(systemName: "checkmark") } }.frame(minHeight: 44)
                        }
                    }
                }
            }.paperList().navigationTitle("Choose your protocol").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .trackingErrors()
        }
    }
}

import SwiftUI

struct EventDetailView: View {
    let event: ProtocolEvent
    var body: some View {
        List {
            Section { Text(event.at.formatted(date: .long, time: .shortened)); Text(event.category).foregroundStyle(Theme.muted) }
            if event.changes.isEmpty {
                Section("Retained record") { Text(event.detail); Text("This older event does not contain structured previous values.").font(Theme.caption).foregroundStyle(Theme.muted) }
            } else {
                ForEach(event.changes) { change in
                    Section(change.field) { RecordRow(label: "Previous", value: change.before.isEmpty ? "Not recorded" : change.before); RecordRow(label: "New", value: change.after.isEmpty ? "Not recorded" : change.after) }
                }
            }
        }.paperList().navigationTitle(event.title).navigationBarTitleDisplayMode(.inline)
    }
}

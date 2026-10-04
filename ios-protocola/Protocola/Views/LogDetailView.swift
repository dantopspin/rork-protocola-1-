import SwiftUI

struct LogDetailView: View {
    let logID: UUID
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var edit: Bool = false
    @State private var confirm: Bool = false
    var body: some View {
        Group {
            if let log = store.logs.first(where: { $0.id == logID }) {
                List {
                    Section("Historical snapshot") {
                        RecordRow(label: "Compound", value: log.compoundName)
                        RecordRow(label: "Protocol", value: log.protocolName)
                        RecordRow(label: "Scheduled amount", value: "\(log.scheduledAmountText) \(log.scheduledUnitText)")
                        if let scheduled = log.scheduledAt { RecordRow(label: "Scheduled time", value: scheduled.formatted(date: .abbreviated, time: .shortened)) }
                        RecordRow(label: "Actual amount", value: "\(log.actualAmountText) \(log.unitText)")
                        RecordRow(label: "Recorded time", value: log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                        RecordRow(label: "Status", value: log.status)
                        RecordRow(label: "Vial", value: log.vialName)
                        if let c = log.concentrationText { RecordRow(label: "Recorded concentration", value: "\(c) mg/mL") }
                        if let v = log.volumeMlText { RecordRow(label: "Volume", value: "\(v) mL") }
                        RecordRow(label: "Site", value: log.site.isEmpty ? "Not recorded" : log.site)
                        if !log.symptoms.isEmpty { RecordRow(label: "Symptoms", value: "\(log.symptoms) · \(log.symptomSeverity)/10") }
                        if !log.notes.isEmpty { Text(log.notes) }
                        if let corrected = log.correctedAt { RecordRow(label: "Corrected", value: corrected.formatted(date: .abbreviated, time: .shortened)) }
                    }
                    Section {
                        Button("Correct this entry") { edit = true }.disabled(!store.canEdit(log.protocolID))
                        Button("Delete entry", role: .destructive) { confirm = true }.disabled(!store.canEdit(log.protocolID))
                    } footer: { Text("Corrections and deletions automatically reconcile inventory. Protocol edits never rewrite this snapshot.") }
                }.paperList().navigationTitle("Entry details").navigationBarTitleDisplayMode(.inline)
                    .sheet(isPresented: $edit) { DoseEditorView(correcting: log) }
                    .confirmationDialog("Delete this entry? Its consumed amount will be restored to the vial balance.", isPresented: $confirm, titleVisibility: .visible) { Button("Delete and reconcile", role: .destructive) { if store.deleteDose(log) { dismiss() } } }
            } else { ContentUnavailableView("Entry unavailable", systemImage: "clock") }
        }.trackingErrors()
    }
}

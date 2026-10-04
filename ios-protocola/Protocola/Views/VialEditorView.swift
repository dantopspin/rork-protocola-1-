import SwiftUI

struct VialEditorView: View {
    let vial: VialRecord?
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: VialDraft
    init(vial: VialRecord? = nil) { self.vial = vial; _draft = State(initialValue: vial.map(VialDraft.init) ?? VialDraft()) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Label values") {
                    TextField("Vial name", text: $draft.name)
                    TextField("Compound", text: $draft.compound)
                    HStack {
                        TextField("Original amount", text: $draft.amount).keyboardType(.decimalPad)
                        Picker("Unit", selection: $draft.unit) { Text("mg").tag(AmountUnit.mg); Text("mcg").tag(AmountUnit.mcg) }.labelsHidden()
                    }
                    TextField("Diluent volume (mL)", text: $draft.diluent).keyboardType(.decimalPad)
                    TextField("Batch (optional)", text: $draft.batch)
                    TextField("Supplier / clinic (optional)", text: $draft.supplier)
                    TextField("Storage notes (optional)", text: $draft.notes, axis: .vertical)
                    Toggle("Record expiry / discard date", isOn: $draft.hasExpiry)
                    if draft.hasExpiry { DatePicker("Date from your instructions", selection: $draft.expiry, displayedComponents: .date) }
                }
                if let vial {
                    Section {
                        RecordRow(label: "Current estimate", value: "\(DoseCalculator.text(store.balances[vial.id] ?? 0)) mg")
                        TextField("Correct remaining balance (mg)", text: $draft.correctedBalance).keyboardType(.decimalPad)
                    } header: { Text("Manual correction") } footer: { Text("Leave blank to keep the balance. A correction is recorded as an adjustment; later log corrections or deletions still reconcile the consumed amount.") }
                }
                Section { Text("Vial strength is not inferred. After the first recorded dose, strength and compound are locked to preserve historical calculations.").font(.footnote).foregroundStyle(Theme.muted) }
            }.paperList().doneKeyboard().navigationTitle(vial == nil ? "Record vial" : "Edit vial").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { if store.saveVial(draft, id: vial?.id) { dismiss() } } }
                }.trackingErrors()
        }
    }
}

import SwiftUI

struct CalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: CalculatorViewModel = CalculatorViewModel()
    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("Explicit vial values") {
                    HStack {
                        TextField("Vial amount", text: $model.vialAmount).keyboardType(.decimalPad)
                        Picker("Mass unit", selection: $model.vialUnit) { Text("mg").tag(AmountUnit.mg); Text("mcg").tag(AmountUnit.mcg) }.labelsHidden()
                    }
                    TextField("Diluent volume (mL)", text: $model.diluent).keyboardType(.decimalPad)
                }
                Section("Value to convert") {
                    HStack {
                        TextField("Amount you entered", text: $model.amount).keyboardType(.decimalPad)
                        Picker("Amount unit", selection: $model.amountUnit) { ForEach(AmountUnit.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden()
                    }
                    TextField("Syringe units per mL (e.g. 100)", text: $model.scale).keyboardType(.decimalPad)
                    Button("Calculate entered values") { model.calculate() }
                }
                if let c = model.concentration, let v = model.volume, let units = model.syringeUnits {
                    Section("Calculated result") {
                        RecordRow(label: "Concentration", value: "\(c) mg/mL")
                        RecordRow(label: "Volume", value: "\(v) mL")
                        RecordRow(label: "Syringe units", value: units)
                    }
                    Section { Text("Results correspond to the values present when Calculate was pressed. Recalculate after editing.").font(.footnote).foregroundStyle(Theme.muted) }
                }
                Section { Text("Arithmetic only. This calculator never infers or recommends a dose, dilution, or administration technique.").font(.footnote).foregroundStyle(Theme.muted) }
            }.paperList().doneKeyboard().navigationTitle("Calculator").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .alert("Check entered values", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) { Button("OK") { model.error = nil } } message: { Text(model.error ?? "") }
        }
    }
}

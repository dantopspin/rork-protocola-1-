import SwiftUI

struct VialEditorView: View {
    let vial: VialRecord?

    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: VialDraft
    @State private var saving = false

    init(vial: VialRecord? = nil) {
        self.vial = vial
        _draft = State(
            initialValue:
                vial.map(VialDraft.init)
                ?? VialDraft()
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                labelValuesSection

                if let concentration {
                    Section {
                        RecordRow(
                            label: "Concentration",
                            value:
                                concentration
                                + " mg/mL"
                        )
                    } header: {
                        Text("Calculated from recorded values")
                    } footer: {
                        Text(
                            "Arithmetic only. This is calculated from the vial amount and diluent you entered."
                        )
                    }
                }

                if let vial {
                    correctionSection(vial)
                }

                Section {
                    Text(
                        "Protocola never infers vial strength. After the first recorded entry uses this vial, its compound and original strength are retained to protect historical calculations."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .paperList()
            .doneKeyboard()
            .navigationTitle(
                vial == nil
                    ? "Record vial"
                    : "Edit vial"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(saving)
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    if saving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            save()
                        }
                    }
                }
            }
            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension VialEditorView {

    var labelValuesSection: some View {
        Section {
            TextField(
                "Vial name",
                text: $draft.name
            )

            TextField(
                "Compound",
                text: $draft.compound
            )

            HStack {
                TextField(
                    "Original amount",
                    text: $draft.amount
                )
                .keyboardType(.decimalPad)

                Picker(
                    "Unit",
                    selection: $draft.unit
                ) {
                    Text("mg")
                        .tag(AmountUnit.mg)

                    Text("mcg")
                        .tag(AmountUnit.mcg)
                }
                .labelsHidden()
            }

            TextField(
                "Diluent volume (mL)",
                text: $draft.diluent
            )
            .keyboardType(.decimalPad)

            TextField(
                "Batch (optional)",
                text: $draft.batch
            )

            TextField(
                "Supplier / clinic (optional)",
                text: $draft.supplier
            )

            TextField(
                "Storage notes (optional)",
                text: $draft.notes,
                axis: .vertical
            )

            Toggle(
                "Record expiry / discard date",
                isOn: $draft.hasExpiry
            )

            if draft.hasExpiry {
                DatePicker(
                    "Date",
                    selection: $draft.expiry,
                    displayedComponents: .date
                )
            }

        } header: {
            Text("Label values")

        } footer: {
            Text(
                "Record the values printed on the vial or provided in your existing instructions."
            )
        }
    }


    func correctionSection(
        _ vial: VialRecord
    ) -> some View {
        Section {
            RecordRow(
                label: "Current estimate",
                value:
                    DoseCalculator.text(
                        store.balances[
                            vial.id
                        ] ?? 0
                    )
                    + " mg"
            )

            TextField(
                "Correct remaining balance (mg)",
                text:
                    $draft.correctedBalance
            )
            .keyboardType(.decimalPad)

        } header: {
            Text("Manual correction")

        } footer: {
            Text(
                "Leave blank to keep the current estimate. A correction is recorded as an adjustment; later entry corrections and deletions still reconcile the balance."
            )
        }
    }
}


// MARK: - Derived values

private extension VialEditorView {

    var concentration: String? {
        do {
            let amount =
                try DoseCalculator.parse(
                    draft.amount,
                    label: "Vial amount"
                )

            let diluent =
                try DoseCalculator.parse(
                    draft.diluent,
                    label: "Diluent volume"
                )

            let value =
                try DoseCalculator
                    .concentration(
                        vialAmount: amount,
                        unit: draft.unit,
                        diluentMl: diluent
                    )

            return DoseCalculator.text(value)

        } catch {
            return nil
        }
    }
}


// MARK: - Actions

private extension VialEditorView {

    func save() {
        guard !saving else {
            return
        }

        saving = true

        if store.saveVial(
            draft,
            id: vial?.id
        ) {
            Haptics.success()
            dismiss()
        }

        saving = false
    }
}

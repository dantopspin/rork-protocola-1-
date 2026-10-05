import SwiftUI

struct CalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model =
        CalculatorViewModel()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                modeSection(model)
                vialSection(model)

                switch model.mode {
                case .forward:
                    amountSection(model)

                    if let concentration =
                        model.concentration,
                       let volume =
                        model.volume,
                       let units =
                        model.syringeUnits {
                        resultSection(
                            concentration:
                                concentration,
                            volume: volume,
                            units: units
                        )
                    }

                case .reverse:
                    reverseSection(model)

                    if let diluent =
                        model.reverseDiluent,
                       let concentration =
                        model.reverseConcentration {
                        reverseResultSection(
                            diluent: diluent,
                            concentration:
                                concentration
                        )
                    }
                }

                Section {
                    Text(
                        "Arithmetic only. Protocola converts the explicit values you enter. It does not recommend a dose, dilution, or administration technique."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
            }
            .listStyle(.plain)
            .paperList()
            .scrollContentBackground(.hidden)
            .doneKeyboard()
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Check entered values",
                isPresented: Binding(
                    get: {
                        model.error != nil
                    },
                    set: {
                        if !$0 {
                            model.error = nil
                        }
                    }
                )
            ) {
                Button("OK") {
                    model.error = nil
                }
            } message: {
                Text(model.error ?? "")
            }
        }
    }
}


// MARK: - Sections

private extension CalculatorView {

    func modeSection(
        _ model: CalculatorViewModel
    ) -> some View {
        Section {
            Picker(
                "Calculation direction",
                selection:
                    $model.mode
            ) {
                ForEach(
                    CalculatorViewModel
                        .Mode
                        .allCases
                ) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

        } footer: {
            Text(
                model.mode == .reverse
                ? "Solves the diluent volume that matches the dose and draw you enter."
                : "Converts a recorded dose into a draw volume and syringe units."
            )
        }
    }


    func vialSection(
        _ model: CalculatorViewModel
    ) -> some View {
        Section {
            HStack {
                TextField(
                    "Vial amount",
                    text:
                        $model.vialAmount
                )
                .keyboardType(.decimalPad)
                .font(Theme.metricCompact)

                Picker(
                    "Mass unit",
                    selection:
                        $model.vialUnit
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
                text: $model.diluent
            )
            .keyboardType(.decimalPad)
            .font(Theme.metricCompact)

        } header: {
            Eyebrow(text: "Vial values")

        } footer: {
            Text(
                model.mode == .forward
                ? "Use the values already recorded on your vial or instructions."
                : "The vial amount is the total compound recorded on the label."
            )
        }
    }


    /// Quick U-40 / U-100 syringe scales; custom input stays available.
    func syringePresets(
        _ model: CalculatorViewModel
    ) -> some View {
        HStack(spacing: Theme.spaceS) {
            ForEach(
                [40, 100],
                id: \.self
            ) { value in
                Button(String(value)) {
                    model.scale = String(value)
                    Haptics.selection()
                }
                .buttonStyle(
                    TrackingCompactButtonStyle()
                )
            }

            Text("Common scales")
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
        }
    }


    func amountSection(
        _ model: CalculatorViewModel
    ) -> some View {
        Section {
            HStack {
                TextField(
                    "Amount to convert",
                    text: $model.amount
                )
                .keyboardType(.decimalPad)
                .font(Theme.metricCompact)

                Picker(
                    "Amount unit",
                    selection:
                        $model.amountUnit
                ) {
                    ForEach(
                        AmountUnit.allCases
                    ) {
                        Text($0.rawValue)
                            .tag($0)
                    }
                }
                .labelsHidden()
            }

            TextField(
                "Syringe scale (units/mL)",
                text: $model.scale
            )
            .keyboardType(.decimalPad)
            .font(Theme.metricCompact)

            syringePresets(model)

            Button {
                model.calculate()
                Haptics.selection()
            } label: {
                Text("Calculate")
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )

        } header: {
            Eyebrow(
                text: "Value to convert"
            )
        }
    }


    func reverseSection(
        _ model: CalculatorViewModel
    ) -> some View {
        Section {
            HStack {
                TextField(
                    "Dose",
                    text: $model.targetDose
                )
                .keyboardType(.decimalPad)
                .font(Theme.metricCompact)

                Picker(
                    "Dose unit",
                    selection:
                        $model.targetDoseUnit
                ) {
                    ForEach(
                        AmountUnit.allCases
                    ) {
                        Text($0.rawValue)
                            .tag($0)
                    }
                }
                .labelsHidden()
            }

            TextField(
                "Target draw (syringe units)",
                text: $model.targetDraw
            )
            .keyboardType(.decimalPad)
            .font(Theme.metricCompact)

            TextField(
                "Syringe scale (units/mL)",
                text: $model.scale
            )
            .keyboardType(.decimalPad)
            .font(Theme.metricCompact)

            syringePresets(model)

            Button {
                model.calculate()
                Haptics.selection()
            } label: {
                Text("Calculate")
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )

        } header: {
            Eyebrow(
                text: "Target dose and draw"
            )

        } footer: {
            Text(
                "The diluent volume is solved so the recorded dose measures as the draw you enter on the syringe scale you enter."
            )
        }
    }


    func resultSection(
        concentration: String,
        volume: String,
        units: String
    ) -> some View {
        Section {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                Eyebrow(
                    text:
                        "Calculated draw volume"
                )

                Text(volume + " mL")
                    .font(Theme.metricLarge)
                    .foregroundStyle(
                        Theme.ink
                    )
                    .monospacedDigit()

                Text(
                    units
                    + " syringe units"
                )
                .font(Theme.label)
                .foregroundStyle(
                    Theme.teal
                )
                .monospacedDigit()
            }
            .padding(
                .vertical,
                Theme.spaceS
            )

            RecordRow(
                label: "Concentration",
                value:
                    concentration
                    + " mg/mL"
            )

            RecordRow(
                label: "Volume",
                value:
                    volume
                    + " mL"
            )

            RecordRow(
                label: "Syringe units",
                value: units
            )

        } header: {
            Eyebrow(
                text: "Calculated result"
            )
        }
    }


    func reverseResultSection(
        diluent: String,
        concentration: String
    ) -> some View {
        Section {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                Eyebrow(
                    text:
                        "Calculated diluent volume"
                )

                Text(diluent + " mL")
                    .font(Theme.metricLarge)
                    .foregroundStyle(
                        Theme.ink
                    )
                    .monospacedDigit()

                Text(
                    concentration
                    + " mg/mL"
                )
                .font(Theme.label)
                .foregroundStyle(
                    Theme.teal
                )
                .monospacedDigit()
            }
            .padding(
                .vertical,
                Theme.spaceS
            )

            RecordRow(
                label: "Diluent volume",
                value:
                    diluent
                    + " mL"
            )

            RecordRow(
                label:
                    "Resulting concentration",
                value:
                    concentration
                    + " mg/mL"
            )

        } header: {
            Eyebrow(
                text: "Calculated result"
            )

        } footer: {
            Text(
                "Concentration is derived in mg/mL from the values you enter."
            )
        }
    }
}

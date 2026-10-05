import SwiftUI

struct CalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model =
        CalculatorViewModel()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                vialSection(model)
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

    func vialSection(
        _ model: CalculatorViewModel
    ) -> some View {
        Section {
            HStack {
                TextField(
                    "Vial amount",
                    text:
                        Binding(
                            get: {
                                model.vialAmount
                            },
                            set: {
                                model.vialAmount = $0
                            }
                        )
                )
                .keyboardType(.decimalPad)
                .font(Theme.metricCompact)

                Picker(
                    "Mass unit",
                    selection:
                        Binding(
                            get: {
                                model.vialUnit
                            },
                            set: {
                                model.vialUnit = $0
                            }
                        )
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
                text:
                    Binding(
                        get: {
                            model.diluent
                        },
                        set: {
                            model.diluent = $0
                        }
                    )
            )
            .keyboardType(.decimalPad)
            .font(Theme.metricCompact)

        } header: {
            Eyebrow(text: "Vial values")

        } footer: {
            Text(
                "Use the values already recorded on your vial or instructions."
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
                    text:
                        Binding(
                            get: {
                                model.amount
                            },
                            set: {
                                model.amount = $0
                            }
                        )
                )
                .keyboardType(.decimalPad)
                .font(Theme.metricCompact)

                Picker(
                    "Amount unit",
                    selection:
                        Binding(
                            get: {
                                model.amountUnit
                            },
                            set: {
                                model.amountUnit = $0
                            }
                        )
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
                text:
                    Binding(
                        get: {
                            model.scale
                        },
                        set: {
                            model.scale = $0
                        }
                    )
            )
            .keyboardType(.decimalPad)
            .font(Theme.metricCompact)

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
}

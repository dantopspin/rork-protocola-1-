import SwiftUI

struct DoseEditorView: View {
    let revision: ScheduleRevision?
    let occurrence: ScheduledEntry?
    let correcting: DoseLog?

    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DoseDraft
    @State private var addVial = false

    init(
        revision: ScheduleRevision,
        occurrence: ScheduledEntry? = nil,
        prefill: DoseDraft? = nil
    ) {
        self.revision = revision
        self.occurrence = occurrence
        correcting = nil

        _draft = State(
            initialValue:
                prefill
                ?? DoseDraft(revision: revision)
        )
    }

    init(correcting: DoseLog) {
        revision = nil
        occurrence = nil
        self.correcting = correcting

        _draft = State(
            initialValue:
                DoseDraft(log: correcting)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                entrySection
                vialSection

                if let conversion {
                    conversionSection(conversion)
                }

                injectionSiteSection
                symptomsSection

                if correcting != nil {
                    correctionNotice
                }
            }
            .paperList()
            .doneKeyboard()
            .navigationTitle(
                correcting == nil
                    ? "Log entry"
                    : "Correct entry"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .sheet(isPresented: $addVial) {
                VialEditorView()
            }
            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension DoseEditorView {

    var entrySection: some View {
        Section {
            Text(
                correcting?.compoundName
                ?? revision?.compoundName
                ?? "Entry"
            )
            .font(.title2.weight(.semibold))

            if let occurrence {
                RecordRow(
                    label: "Scheduled",
                    value:
                        occurrence.at.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                )
            }

            Picker(
                "Status",
                selection: $draft.status
            ) {
                ForEach(
                    [
                        "Logged",
                        "Skipped",
                        "Partial",
                        "Delayed"
                    ],
                    id: \.self
                ) {
                    Text($0)
                        .tag($0)
                }
            }

            if draft.status != "Skipped" {
                HStack {
                    TextField(
                        "Actual amount",
                        text: $draft.amount
                    )
                    .keyboardType(.decimalPad)

                    Picker(
                        "Unit",
                        selection: $draft.unit
                    ) {
                        ForEach(AmountUnit.allCases) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    .labelsHidden()
                }

                TextField(
                    "Syringe scale (units/mL)",
                    text: $draft.unitsPerMl
                )
                .keyboardType(.decimalPad)
            }

            DatePicker(
                "Recorded time",
                selection: $draft.loggedAt,
                in: ...Date.now
            )

        } header: {
            Text("Entry as recorded")
        } footer: {
            Text(
                "Values reflect your own records, not an administration recommendation."
            )
        }
    }


    @ViewBuilder
    var vialSection: some View {
        Section {
            if let correcting {
                RecordRow(
                    label: "Recorded vial",
                    value: correcting.vialName
                )

                Text(
                    "The original vial and concentration snapshot are retained when correcting this entry."
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)

            } else {
                Picker(
                    "Vial",
                    selection: $draft.vialID
                ) {
                    Text("No vial")
                        .tag(nil as UUID?)

                    ForEach(matchingVials) {
                        Text($0.name)
                            .tag(Optional($0.id))
                    }
                }

                if matchingVials.isEmpty {
                    Button {
                        addVial = true
                    } label: {
                        Label(
                            "Add a vial for \(revision?.compoundName ?? "this compound")",
                            systemImage: "plus"
                        )
                    }
                }
            }

        } header: {
            Text("Vial")
        } footer: {
            if correcting == nil {
                Text(
                    draft.vialID == nil
                        ? "A vial is optional. Without one, Protocola records the entry but cannot reconcile vial balance or calculate volume."
                        : "The selected vial provides the recorded concentration used for inventory and conversion."
                )
            }
        }
    }


    func conversionSection(
        _ conversion: DoseConversionPreview
    ) -> some View {
        Section {
            RecordRow(
                label: "Concentration",
                value:
                    conversion.concentration
                    + " mg/mL"
            )

            RecordRow(
                label: "Calculated volume",
                value:
                    conversion.volume
                    + " mL"
            )

            RecordRow(
                label: "Syringe units",
                value: conversion.units
            )

        } header: {
            Text("Calculated from recorded values")
        } footer: {
            Text(
                "Arithmetic only. Protocola converts the amount, vial concentration, and syringe scale you entered. It does not choose or recommend a dose."
            )
        }
    }


    var injectionSiteSection: some View {
        Section("Injection site") {
            TextField(
                "Site (optional)",
                text: $draft.site
            )

            if !recentSites.isEmpty {
                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {
                    HStack(
                        spacing: Theme.spaceXS
                    ) {
                        ForEach(
                            recentSites,
                            id: \.self
                        ) { site in
                            Button(site) {
                                draft.site = site
                            }
                            .buttonStyle(.bordered)
                            .tint(
                                draft.site
                                    .caseInsensitiveCompare(site)
                                    == .orderedSame
                                ? Theme.teal
                                : Theme.ink
                            )
                            .controlSize(.small)
                        }
                    }
                }
            }

            Text(
                recentSites.isEmpty
                    ? "Record the site you used. Nothing is preselected or recommended."
                    : "Tap a recently recorded site to fill it. Nothing is preselected or recommended."
            )
            .font(Theme.caption)
            .foregroundStyle(.secondary)
        }
    }


    var symptomsSection: some View {
        Section("Symptoms and notes") {
            TextField(
                "Symptoms (optional)",
                text: $draft.symptoms
            )

            if !draft.symptoms.isEmpty {
                Stepper(
                    "Severity: \(draft.severity) / 10",
                    value: $draft.severity,
                    in: 1...10
                )
            }

            TextField(
                "Notes (optional)",
                text: $draft.notes,
                axis: .vertical
            )
        }
    }


    var correctionNotice: some View {
        Section {
            Text(
                "Saving reconciles the vial balance with the corrected amount. Scheduled values remain the original historical snapshot."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Derived values

private extension DoseEditorView {

    var matchingVials: [VialRecord] {
        guard let compound =
            revision?.compoundName
        else {
            return []
        }

        return store.vials.filter {
            !$0.isArchived
            && $0.compoundName
                .caseInsensitiveCompare(
                    compound
                )
                == .orderedSame
        }
    }


    var conversion: DoseConversionPreview? {
        guard draft.status != "Skipped" else {
            return nil
        }

        do {
            let amount =
                try DoseCalculator.parse(
                    draft.amount,
                    label: "Amount"
                )

            let scale =
                try DoseCalculator.parse(
                    draft.unitsPerMl,
                    label: "Syringe scale"
                )

            let concentration: Decimal?

            if let correcting {
                concentration =
                    correcting.concentration
            } else if let vialID =
                        draft.vialID {
                concentration =
                    store.vial(vialID)?
                        .concentration
            } else {
                concentration = nil
            }

            guard let concentration,
                  concentration > 0
            else {
                return nil
            }

            let volume =
                try DoseCalculator.volume(
                    amount: amount,
                    unit: draft.unit,
                    concentration:
                        concentration,
                    unitsPerMl: scale
                )

            return DoseConversionPreview(
                concentration:
                    DoseCalculator.text(
                        concentration
                    ),
                volume:
                    DoseCalculator.text(
                        volume
                    ),
                units:
                    DoseCalculator.text(
                        volume * scale
                    )
            )

        } catch {
            return nil
        }
    }


    /// The user's own distinct recorded sites, most recent first.
    /// Convenience fill only; nothing is recommended.
    var recentSites: [String] {
        var seen = Set<String>()
        var sites: [String] = []

        for log in store.logs
            where !log.site.isEmpty {
            if seen.insert(
                log.site.lowercased()
            ).inserted {
                sites.append(log.site)

                if sites.count == 6 {
                    break
                }
            }
        }

        return sites
    }
}


// MARK: - Actions

private extension DoseEditorView {

    func save() {
        let corrects = correcting != nil

        if store.saveDose(
            draft,
            revision: revision,
            occurrence: occurrence,
            correcting: correcting
        ) {
            // Creating a log is already covered by Today's recorded-count
            // feedback; only a correction needs its own cue.
            if corrects {
                Haptics.success()
            }

            dismiss()
        }
    }
}


private struct DoseConversionPreview {
    let concentration: String
    let volume: String
    let units: String
}

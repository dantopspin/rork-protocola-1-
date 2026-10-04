import SwiftUI

struct ProtocolEditorView: View {
    let record: ProtocolRecord?
    let revision: ScheduleRevision?
    let onboarding: Bool

    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ProtocolDraft
    @State private var addVial = false
    @State private var saving = false

    init(
        record: ProtocolRecord? = nil,
        revision: ScheduleRevision? = nil,
        onboarding: Bool = false,
        prefersReminders: Bool = false
    ) {
        self.record = record
        self.revision = revision
        self.onboarding = onboarding

        if let record,
           let revision {
            _draft = State(
                initialValue:
                    ProtocolDraft(
                        protocolRecord: record,
                        revision: revision
                    )
            )

        } else {
            var value = ProtocolDraft()
            value.reminders = prefersReminders

            if let record {
                value.name = record.name
                value.source =
                    record.instructionSource
                value.notes = record.notes
            }

            _draft = State(
                initialValue: value
            )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                instructionsSection
                scheduleSection
                vialAndSiteSection

                if revision != nil {
                    Section {
                        Text(
                            "Changes apply from now onward. Past scheduled entries and logs remain unchanged."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .paperList()
            .doneKeyboard()
            .navigationTitle(title)
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
            .sheet(isPresented: $addVial) {
                VialEditorView()
            }
            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension ProtocolEditorView {

    var instructionsSection: some View {
        Section {
            TextField(
                "Protocol name",
                text: $draft.name
            )
            .accessibilityIdentifier(
                "protocolName"
            )

            TextField(
                "Compound name",
                text: $draft.compound
            )
            .accessibilityIdentifier(
                "compoundName"
            )

            HStack {
                TextField(
                    "Scheduled amount",
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

            Picker(
                "Instruction source",
                selection: $draft.source
            ) {
                ForEach(
                    instructionSources,
                    id: \.self
                ) {
                    Text($0)
                        .tag($0)
                }
            }

            TextField(
                "Notes (optional)",
                text: $draft.notes,
                axis: .vertical
            )

        } header: {
            Text("Recorded instructions")

        } footer: {
            Text(
                "Enter values from instructions you already have. Protocola does not generate a dose or schedule."
            )
        }
    }


    var scheduleSection: some View {
        Section("Recorded schedule") {
            DatePicker(
                "Start date",
                selection: $draft.start,
                displayedComponents: .date
            )

            Picker(
                "Frequency",
                selection: $draft.kind
            ) {
                ForEach(
                    ScheduleConfig.Kind.allCases
                ) {
                    Text(
                        ScheduleDisplay
                            .kindLabel($0)
                    )
                    .tag($0)
                }
            }

            if draft.kind == .everyNDays {
                Stepper(
                    "Every \(draft.interval) "
                    + (
                        draft.interval == 1
                        ? "day"
                        : "days"
                    ),
                    value: $draft.interval,
                    in: 1...365
                )
            }

            if [
                .weekly,
                .weekdays,
                .timesPerWeek
            ]
            .contains(draft.kind) {
                weekdayControls

                Text(
                    "Choose the days already present in your instructions. Protocola does not distribute entries across the week."
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)
            }

            if draft.kind != .asRecorded {
                scheduledTimes

                Toggle(
                    "Local reminders",
                    isOn: $draft.reminders
                )
                .disabled(store.isDemo)

                Text(
                    "Times use this iPhone's current time zone."
                )
                .font(Theme.caption)
                .foregroundStyle(.secondary)
            }
        }
    }


    var weekdayControls: some View {
        ForEach(
            1...7,
            id: \.self
        ) { day in
            Toggle(
                Calendar.current
                    .weekdaySymbols[
                        day - 1
                    ],
                isOn: Binding(
                    get: {
                        draft.weekdays
                            .contains(day)
                    },
                    set: { enabled in
                        if enabled {
                            if draft.kind
                                == .weekly {
                                draft.weekdays =
                                    [day]
                            } else {
                                draft.weekdays
                                    .insert(day)
                            }
                        } else {
                            draft.weekdays
                                .remove(day)
                        }
                    }
                )
            )
        }
    }


    var scheduledTimes: some View {
        Group {
            ForEach(
                $draft.times
            ) { $time in
                HStack(
                    spacing: Theme.spaceS
                ) {
                    DatePicker(
                        "Time",
                        selection: $time.date,
                        displayedComponents:
                            .hourAndMinute
                    )
                    .environment(
                        \.timeZone,
                        TimeZone(
                            identifier:
                                draft.timeZoneID
                        )
                        ?? .current
                    )

                    if draft.times.count > 1 {
                        Button(
                            role: .destructive
                        ) {
                            removeTime(time.id)
                        } label: {
                            Image(
                                systemName:
                                    "minus.circle"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "Remove time"
                        )
                    }
                }
            }

            Button {
                draft.times.append(
                    RecordedTime()
                )
            } label: {
                Label(
                    "Add time",
                    systemImage: "plus"
                )
            }
        }
    }


    var vialAndSiteSection: some View {
        Section {
            Picker(
                "Vial",
                selection: $draft.vialID
            ) {
                Text("Not selected")
                    .tag(nil as UUID?)

                ForEach(availableVials) {
                    Text(
                        $0.name
                        + " · "
                        + $0.compoundName
                    )
                    .tag(Optional($0.id))
                }
            }

            Button {
                addVial = true
            } label: {
                Label(
                    "Add vial",
                    systemImage: "plus"
                )
            }

            TextField(
                "Configured site (optional)",
                text: $draft.site
            )

        } header: {
            Text("Vial and site")

        } footer: {
            Text(
                "A vial is optional. Leave the site blank to choose and record it only when logging."
            )
        }
    }
}


// MARK: - Derived values

private extension ProtocolEditorView {

    var title: String {
        if revision != nil {
            return "Edit protocol"
        }

        return
            onboarding
            ? "Set up your protocol"
            : "Record protocol"
    }


    var instructionSources: [String] {
        [
            "Personal record",
            "Prescriber instructions",
            "Clinic instructions",
            "Product label",
            "Imported from another tracker",
            "Other",
            "Illustrative demo — not instructions"
        ]
    }


    var availableVials: [VialRecord] {
        let active =
            store.vials.filter {
                !$0.isArchived
            }

        let compound =
            draft.compound
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !compound.isEmpty else {
            return active
        }

        return active.filter {
            $0.compoundName
                .caseInsensitiveCompare(
                    compound
                )
                == .orderedSame
        }
    }
}


// MARK: - Actions

private extension ProtocolEditorView {

    func removeTime(
        _ id: UUID
    ) {
        guard draft.times.count > 1 else {
            return
        }

        draft.times.removeAll {
            $0.id == id
        }
    }


    func save() {
        guard record.map({
            store.canEdit($0.id)
        })
        ?? store.canCreateProtocol
        else {
            store.requestPaywall(.secondProtocol)
            return
        }

        saving = true

        Task {
            if draft.reminders,
               !store.isDemo {
                _ =
                    await store
                        .notifications
                        .requestPermission()
            }

            if store.saveProtocol(
                draft,
                protocolID: record?.id,
                compoundID:
                    revision?.compoundID
            ) {
                if onboarding {
                    store.completeOnboarding()
                }

                Haptics.success()
                dismiss()
            }

            saving = false
        }
    }
}

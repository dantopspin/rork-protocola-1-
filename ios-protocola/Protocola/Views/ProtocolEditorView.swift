import SwiftUI
import UserNotifications

struct ProtocolEditorView: View {
    let record: ProtocolRecord?
    let revision: ScheduleRevision?
    let onboarding: Bool
    let planningFuture: Bool
    let editingPlanned: Bool

    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ProtocolDraft
    @State private var initialSnapshot: String?
    @State private var confirmDiscard = false

    private var hasUnsavedChanges: Bool {
        initialSnapshot.map { $0 != String(describing: draft) } ?? false
    }
    @State private var addVial = false
    @State private var saving = false
    @State private var askingPermission = false
    @State private var permissionExplained = false
    @State private var effectiveDate: Date

    init(
        record: ProtocolRecord? = nil,
        revision: ScheduleRevision? = nil,
        onboarding: Bool = false,
        prefersReminders: Bool = false,
        planningFuture: Bool = false,
        editingPlanned: Bool = false
    ) {
        self.record = record
        self.revision = revision
        self.onboarding = onboarding
        self.planningFuture =
            planningFuture
        self.editingPlanned =
            editingPlanned

        let tomorrow =
            Calendar.current.date(
                byAdding: .day,
                value: 1,
                to:
                    Calendar.current
                        .startOfDay(
                            for: .now
                        )
            ) ?? Date.now
                .addingTimeInterval(
                    86_400
                )

        _effectiveDate =
            State(
                initialValue:
                    editingPlanned
                    ? (
                        revision?
                            .effectiveFrom
                        ?? tomorrow
                    )
                    : tomorrow
            )

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
            // Clinic instructions are most often written in mg.
            value.unit = .mg
            value.reminders =
                prefersReminders

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
                if planningFuture {
                    futureChangeSection
                }

                instructionsSection
                scheduleSection

                if draft.route
                    .usesInjectionSite {
                    vialAndSiteSection
                }

                if planningFuture {
                    Section {
                        Text(
                            "This planned revision takes effect on the selected date. Existing history remains unchanged, and you can edit or cancel the plan before it becomes effective."
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }

                } else if revision != nil {
                    Section {
                        Text(
                            "Changes apply from now onward. Past schedules and recorded entries remain unchanged."
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }
                }
            }
            .listStyle(.plain)
            .paperList()
            .scrollContentBackground(.hidden)
            .doneKeyboard()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(
                .inline
            )
            .discardGuard(
                hasChanges: hasUnsavedChanges,
                confirming: $confirmDiscard
            ) {
                dismiss()
            }
            .onAppear {
                if initialSnapshot == nil {
                    initialSnapshot = String(describing: draft)
                }
            }
            .toolbar {
                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            confirmDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(saving)
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
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
            .sheet(
                isPresented: $askingPermission,
                onDismiss: {
                    // Continue the save whatever the answer; the protocol
                    // records the reminder choice and delivery follows the
                    // system setting.
                    permissionExplained = true
                    save()
                }
            ) {
                NotificationPermissionSheet(
                    context: .reminders
                ) {
                    askingPermission = false
                }
            }
            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension ProtocolEditorView {

    var futureChangeSection:
        some View {
        Section {
            DatePicker(
                "Effective date",
                selection:
                    $effectiveDate,
                in:
                    minimumFutureDate...,
                displayedComponents:
                    .date
            )

        } header: {
            Eyebrow(text: "Future change")
        } footer: { FormFooter {
            Text(
                "Choose when these recorded instructions should become effective. This is scheduling of your own record, not a recommendation."
            )
        }
}
    }


    var instructionsSection: some View {
        Section {
            TextField(
                "Protocol name",
                text: $draft.name
            )
            .accessibilityIdentifier(
                "protocolName"
            )
            .disabled(planningFuture)

            TextField(
                "Compound name",
                text: $draft.compound
            )
            .accessibilityIdentifier(
                "compoundName"
            )
            .disabled(planningFuture)

            TextField(
                "Amount",
                text: $draft.amount
            )
            .keyboardType(.decimalPad)

            // A visible, labelled row: the unit is as important as the number.
            Picker(
                "Unit",
                selection: $draft.unit
            ) {
                ForEach(
                    AmountUnit.allCases
                ) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }

            Picker(
                "Route",
                selection: $draft.route
            ) {
                ForEach(
                    AdministrationRoute
                        .allCases
                ) {
                    Text($0.rawValue)
                        .tag($0)
                }
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
            .disabled(planningFuture)

            TextField(
                "Notes (optional)",
                text: $draft.notes,
                axis: .vertical
            )
            .disabled(planningFuture)

        } header: {
            Eyebrow(text: "Recorded instructions")
        } footer: { FormFooter {
            Text(
                "Enter values from instructions you already have. Protocola records them; it does not generate a dose, route, or schedule."
            )
        }
}
    }


    var scheduleSection: some View {
        Section {
            DatePicker(
                planningFuture
                    ? "Schedule anchor"
                    : "Start date",
                selection: $draft.start,
                displayedComponents: .date
            )

            Picker(
                "Frequency",
                selection: $draft.kind
            ) {
                ForEach(
                    ScheduleConfig.Kind
                        .allCases
                ) {
                    Text(
                        ScheduleDisplay
                            .kindLabel($0)
                    )
                    .tag($0)
                }
            }

            if draft.kind
                == .everyNDays {
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
            }

            if draft.kind
                != .asRecorded {
                scheduledTimes

                Toggle(
                    "Use ON / OFF cycle",
                    isOn:
                        $draft.cycleEnabled
                )

                if draft.cycleEnabled {
                    Stepper(
                        "ON · \(draft.cycleOnDays) "
                        + (
                            draft.cycleOnDays == 1
                            ? "day"
                            : "days"
                        ),
                        value:
                            $draft.cycleOnDays,
                        in: 1...3650
                    )

                    Stepper(
                        "OFF · \(draft.cycleOffDays) "
                        + (
                            draft.cycleOffDays == 1
                            ? "day"
                            : "days"
                        ),
                        value:
                            $draft.cycleOffDays,
                        in: 1...3650
                    )
                }

                Toggle(
                    "Follow this iPhone's time zone",
                    isOn: $draft.followsDeviceTimeZone
                )

                Toggle(
                    "Local reminders",
                    isOn: $draft.reminders
                )
                .disabled(store.isDemo)
            }

        } header: {
            Eyebrow(text: "Recorded schedule")
        } footer: { FormFooter {
            if draft.kind == .asRecorded {
                Text(
                    "As needed creates no automatic scheduled entries. Log an entry whenever you need to record one."
                )
            } else if draft.cycleEnabled {
                Text(
                    "The cycle starts on the recorded start date. Scheduled entries are created only during ON days and resume automatically after each OFF period."
                )
            } else {
                Text(
                    draft.followsDeviceTimeZone
                    ? "Times follow this iPhone's time zone, so a time you recorded stays the same local time when you travel."
                    : "Times stay in "
                        + (
                            TimeZone(identifier: draft.timeZoneID)?
                                .localizedName(for: .generic, locale: .current)
                            ?? draft.timeZoneID
                        )
                        + " when you travel."
                )
            }
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
                "Default site (optional)",
                text: $draft.site
            )

        } header: {
            Eyebrow(text: "Injection context")
        } footer: { FormFooter {
            Text(
                "A vial is optional. Leave the site blank to record the actual site only when logging."
            )
        }
}
    }
}


// MARK: - Derived values

private extension ProtocolEditorView {

    var title: String {
        if planningFuture {
            return
                editingPlanned
                ? "Edit planned change"
                : "Plan future change"
        }

        if revision != nil {
            return "Edit protocol"
        }

        return
            onboarding
            ? "Set up your protocol"
            : "Record protocol"
    }


    var minimumFutureDate: Date {
        Calendar.current.date(
            byAdding: .day,
            value: 1,
            to:
                Calendar.current
                    .startOfDay(
                        for: .now
                    )
        ) ?? Date.now
            .addingTimeInterval(
                86_400
            )
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
                    in:
                        .whitespacesAndNewlines
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
        guard
            draft.times.count > 1
        else {
            return
        }

        draft.times.removeAll {
            $0.id == id
        }
    }


    func save() {
        guard
            record.map({
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
               draft.kind != .asRecorded,
               !store.isDemo {
                // Explain reminders before iOS shows its one-time prompt.
                // The sheet runs the system request itself; after "Not now"
                // the status stays undetermined and the save goes ahead
                // without prompting.
                if !permissionExplained,
                   await store
                    .notifications
                    .authorizationStatus()
                    == .notDetermined {
                    saving = false
                    askingPermission = true
                    return
                }
            }

            let saved: Bool

            if planningFuture,
               let record,
               let revision {
                saved =
                    store
                        .savePlannedProtocolChange(
                            draft,
                            protocolID:
                                record.id,
                            compoundID:
                                revision
                                    .compoundID,
                            plannedRevisionID:
                                editingPlanned
                                ? revision.id
                                : nil,
                            effectiveFrom:
                                effectiveDate
                        )

            } else {
                saved =
                    store.saveProtocol(
                        draft,
                        protocolID:
                            record?.id,
                        compoundID:
                            revision?
                                .compoundID
                    )
            }

            if saved {
                if onboarding {
                    store
                        .completeOnboarding()
                }

                dismiss()
            }

            saving = false
        }
    }
}

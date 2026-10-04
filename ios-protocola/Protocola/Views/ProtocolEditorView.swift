import SwiftUI

struct ProtocolEditorView: View {
    let record: ProtocolRecord?
    let revision: ScheduleRevision?
    let onboarding: Bool
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProtocolDraft
    @State private var addVial: Bool = false
    @State private var saving: Bool = false
    @State private var paywall: Bool = false
    init(record: ProtocolRecord? = nil, revision: ScheduleRevision? = nil, onboarding: Bool = false, prefersReminders: Bool = false) {
        self.record = record; self.revision = revision; self.onboarding = onboarding
        if let record, let revision { _draft = State(initialValue: ProtocolDraft(protocolRecord: record, revision: revision)) }
        else { var value = ProtocolDraft(); value.reminders = prefersReminders; if let record { value.name = record.name; value.source = record.instructionSource; value.notes = record.notes }; _draft = State(initialValue: value) }
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Protocol name", text: $draft.name).accessibilityIdentifier("protocolName")
                    TextField("Compound name", text: $draft.compound).accessibilityIdentifier("compoundName")
                    HStack {
                        TextField("Scheduled amount", text: $draft.amount).keyboardType(.decimalPad)
                        Picker("Unit", selection: $draft.unit) { ForEach(AmountUnit.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden()
                    }
                    Picker("Instruction source", selection: $draft.source) {
                        ForEach(["Personal record", "Prescriber instructions", "Clinic instructions", "Product label", "Imported from another tracker", "Other", "Illustrative demo — not instructions"], id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                } header: { Text("Existing instructions") } footer: { Text("Enter values from instructions you already have. No dose or schedule is generated.") }
                Section("Recorded schedule") {
                    DatePicker("Start date", selection: $draft.start, displayedComponents: .date)
                    Picker("Frequency", selection: $draft.kind) { ForEach(ScheduleConfig.Kind.allCases) { Text($0.rawValue).tag($0) } }
                    if draft.kind == .everyNDays { Stepper("Every \(draft.interval) days", value: $draft.interval, in: 1...365) }
                    if [.weekly, .weekdays, .timesPerWeek].contains(draft.kind) {
                        ForEach(1...7, id: \.self) { day in
                            Toggle(Calendar.current.weekdaySymbols[day - 1], isOn: Binding(get: { draft.weekdays.contains(day) }, set: { enabled in
                                if enabled { if draft.kind == .weekly { draft.weekdays = [day] } else { draft.weekdays.insert(day) } } else { draft.weekdays.remove(day) }
                            }))
                        }
                        Text("Choose days explicitly; Protocola does not distribute doses across the week.").font(.caption).foregroundStyle(Theme.muted)
                    }
                    if draft.kind != .asRecorded {
                        ForEach($draft.times) { $time in
                            DatePicker("Recorded time", selection: $time.date, displayedComponents: .hourAndMinute)
                                .environment(\.timeZone, TimeZone(identifier: draft.timeZoneID) ?? .current)
                        }
                        HStack { Button("Add time") { draft.times.append(RecordedTime()) }; Spacer(); if draft.times.count > 1 { Button("Remove last") { draft.times.removeLast() } } }
                        Text("Times use this iPhone's current time zone.").font(.caption).foregroundStyle(Theme.muted)
                        Toggle("Local reminders", isOn: $draft.reminders).disabled(store.isDemo)
                    }
                }
                Section("Vial and site") {
                    Picker("Vial", selection: $draft.vialID) {
                        Text("Not selected").tag(nil as UUID?)
                        ForEach(store.vials.filter { !$0.isArchived }) { Text("\($0.name) · \($0.compoundName)").tag(Optional($0.id)) }
                    }
                    Button("Add vial") { addVial = true }
                    TextField("Configured site (optional)", text: $draft.site)
                    Text("Leave site blank to choose and record it only when logging.").font(.caption).foregroundStyle(Theme.muted)
                }
                if revision != nil { Section { Text("Changes apply from now onward. Past scheduled entries and logs remain unchanged.").font(.footnote).foregroundStyle(Theme.muted) } }
            }.paperList().doneKeyboard().navigationTitle(revision == nil ? (onboarding ? "Set up your protocol" : "Record protocol") : "Edit protocol").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(saving) }
                }
                .sheet(isPresented: $addVial) { VialEditorView() }
                .fullScreenCover(isPresented: $paywall) { PaywallView(reason: .secondProtocol) }
                .trackingErrors()
        }
    }
    private func save() {
        guard record.map({ store.canEdit($0.id) }) ?? store.canCreateProtocol else { paywall = true; return }
        saving = true
        Task {
            if draft.reminders && !store.isDemo { _ = await store.notifications.requestPermission() }
            if store.saveProtocol(draft, protocolID: record?.id, compoundID: revision?.compoundID) {
                if onboarding { store.completeOnboarding() }
                dismiss()
            }
            saving = false
        }
    }
}

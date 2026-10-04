import SwiftUI

struct DoseEditorView: View {
    let revision: ScheduleRevision?
    let occurrence: ScheduledEntry?
    let correcting: DoseLog?
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DoseDraft
    init(revision: ScheduleRevision, occurrence: ScheduledEntry? = nil, prefill: DoseDraft? = nil) { self.revision = revision; self.occurrence = occurrence; correcting = nil; _draft = State(initialValue: prefill ?? DoseDraft(revision: revision)) }
    init(correcting: DoseLog) { revision = nil; occurrence = nil; self.correcting = correcting; _draft = State(initialValue: DoseDraft(log: correcting)) }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(correcting?.compoundName ?? revision?.compoundName ?? "Entry").font(.title2.weight(.semibold))
                    if let occurrence { RecordRow(label: "Scheduled", value: occurrence.at.formatted(date: .abbreviated, time: .shortened)) }
                    Picker("Status", selection: $draft.status) { ForEach(["Logged", "Skipped", "Partial", "Delayed"], id: \.self) { Text($0).tag($0) } }
                    if draft.status != "Skipped" {
                        HStack {
                            TextField("Actual amount", text: $draft.amount).keyboardType(.decimalPad)
                            Picker("Unit", selection: $draft.unit) { ForEach(AmountUnit.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden()
                        }
                        TextField("Syringe units per mL", text: $draft.unitsPerMl).keyboardType(.decimalPad)
                    }
                    DatePicker("Recorded time", selection: $draft.loggedAt, in: ...Date.now)
                } header: { Text("Entry as recorded") } footer: { Text("Values reflect your own records, not an administration recommendation.") }
                Section("Vial") {
                    if let correcting { RecordRow(label: "Recorded vial", value: correcting.vialName); Text("Original vial and concentration are retained when correcting an entry.").font(.caption).foregroundStyle(Theme.muted) }
                    else {
                        Picker("Vial", selection: $draft.vialID) {
                            Text("No vial").tag(nil as UUID?)
                            ForEach(store.vials.filter { !$0.isArchived && $0.compoundName.caseInsensitiveCompare(revision?.compoundName ?? "") == .orderedSame }) { Text($0.name).tag(Optional($0.id)) }
                        }
                    }
                }
                Section("Injection site") {
                    TextField("Site (optional)", text: $draft.site)
                    if !recentSites.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.spaceXS) {
                                ForEach(recentSites, id: \.self) { site in
                                    Button(site) { draft.site = site }
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, Theme.spaceS).padding(.vertical, Theme.spaceXS)
                                        .foregroundStyle(Theme.ink)
                                        .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusRow))
                                        .inkBorder(cornerRadius: Theme.radiusRow)
                                        .frame(minHeight: 44)
                                }
                            }
                        }
                    }
                    Text(recentSites.isEmpty ? "Choose the site you used. Nothing is preselected or recommended." : "Your recently recorded sites, tap to fill. Nothing is preselected or recommended.").font(.caption).foregroundStyle(Theme.muted)
                }
                Section("Symptoms and notes") {
                    TextField("Symptoms (optional)", text: $draft.symptoms)
                    if !draft.symptoms.isEmpty { Stepper("Severity: \(draft.severity) / 10", value: $draft.severity, in: 1...10) }
                    TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                }
                if correcting != nil { Section { Text("Saving reconciles the vial balance with the corrected amount. Scheduled values remain the original snapshot.").font(.footnote).foregroundStyle(Theme.muted) } }
            }.paperList().doneKeyboard().navigationTitle(correcting == nil ? "Log entry" : "Correct entry").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { if store.saveDose(draft, revision: revision, occurrence: occurrence, correcting: correcting) { dismiss() } } }
                }.trackingErrors()
        }
    }

    /// The user's own distinct recorded sites, most recent first; convenience fill only.
    private var recentSites: [String] {
        var seen = Set<String>(); var sites: [String] = []
        for log in store.logs where !log.site.isEmpty {
            if seen.insert(log.site.lowercased()).inserted { sites.append(log.site); if sites.count == 6 { break } }
        }
        return sites
    }
}

import SwiftUI

struct LabListView: View {
    let protocolID: UUID?

    @Environment(TrackingStore.self)
    private var store

    @State private var adding = false

    init(
        protocolID: UUID? = nil
    ) {
        self.protocolID = protocolID
    }

    private var records:
        [LabRecord] {
        store.labs.filter {
            protocolID == nil
            || $0.protocolID
                == protocolID
        }
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                if records.isEmpty {
                    TrackingEmptyState(
                        icon: "testtube.2",
                        title:
                            "No labs recorded",
                        message:
                            "Add results you already have to keep them with your protocol history.",
                        actionTitle:
                            "Add lab"
                    ) {
                        adding = true
                    }

                } else {
                    EditorialSection(
                        "Recorded labs"
                    ) {
                        ForEach(
                            Array(
                                records
                                    .enumerated()
                            ),
                            id: \.element.id
                        ) { index, lab in
                            NavigationLink {
                                LabDetailView(
                                    labID:
                                        lab.id
                                )
                            } label: {
                                labRow(lab)
                            }
                            .buttonStyle(
                                TrackingRowButtonStyle()
                            )
                            .trackingStagger(
                                index: index
                            )

                            if index
                                < records.count - 1 {
                                EditorialRule()
                            }
                        }
                    }
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .trackingScrollChrome()
        .background(Theme.paper)
        .navigationTitle("Labs")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {
            ToolbarItem(
                placement:
                    .topBarTrailing
            ) {
                if !records.isEmpty {
                    Button(
                        "Add lab",
                        systemImage: "plus"
                    ) {
                        adding = true
                    }
                }
            }
        }
        .sheet(
            isPresented: $adding
        ) {
            LabEditorView(
                protocolID:
                    protocolID
            )
        }
        .trackingErrors()
    }


    func labRow(
        _ lab: LabRecord
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceM
        ) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(lab.marker)
                    .font(
                        Theme.cardTitle
                    )
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(
                    lab.collectedAt
                        .formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
                .monospacedDigit()
            }

            Spacer()

            Text(lab.displayValue)
                .font(
                    Theme.metricCompact
                )
                .foregroundStyle(
                    Theme.ink
                )
                .monospacedDigit()

            Image(
                systemName:
                    "chevron.right"
            )
            .font(Theme.micro)
            .foregroundStyle(
                Theme.textSecondary
            )
            .accessibilityHidden(true)
        }
        .padding(
            .vertical,
            Theme.rowPadding
        )
        .frame(
            minHeight:
                Theme.minimumTapTarget
        )
        .contentShape(Rectangle())
    }
}


struct LabDetailView: View {
    let labID: UUID

    @Environment(TrackingStore.self)
    private var store
    @Environment(\.dismiss)
    private var dismiss

    @State private var editing = false
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let lab =
                store.lab(labID) {
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing:
                            Theme.sectionGap
                    ) {
                        resultSection(lab)
                        contextSection(lab)
                    }
                    .screenPadding()
                    .padding(
                        .bottom,
                        Theme.spaceXL
                    )
                }
                .trackingScrollChrome()
                .background(Theme.paper)
                .navigationTitle(
                    lab.marker
                )
                .navigationBarTitleDisplayMode(
                    .inline
                )
                .toolbar {
                    ToolbarItem(
                        placement:
                            .topBarTrailing
                    ) {
                        Menu {
                            Button {
                                editing = true
                            } label: {
                                Label(
                                    "Edit lab",
                                    systemImage:
                                        "pencil"
                                )
                            }

                            Divider()

                            Button(
                                role:
                                    .destructive
                            ) {
                                confirmDelete =
                                    true
                            } label: {
                                Label(
                                    "Delete lab",
                                    systemImage:
                                        "trash"
                                )
                            }
                        } label: {
                            Label(
                                "Lab actions",
                                systemImage:
                                    "ellipsis.circle"
                            )
                        }
                    }
                }
                .sheet(
                    isPresented:
                        $editing
                ) {
                    LabEditorView(
                        lab: lab
                    )
                }
                .confirmationDialog(
                    "Delete this lab record?",
                    isPresented:
                        $confirmDelete,
                    titleVisibility:
                        .visible
                ) {
                    Button(
                        "Delete lab",
                        role: .destructive
                    ) {
                        if store
                            .deleteLab(lab) {
                            dismiss()
                        }
                    }

                    Button(
                        "Cancel",
                        role: .cancel
                    ) {}
                } message: {
                    Text(
                        "This removes the recorded lab result from Protocola."
                    )
                }

            } else {
                TrackingEmptyState(
                    icon: "testtube.2",
                    title:
                        "Lab unavailable",
                    message:
                        "This lab record is no longer available."
                )
                .screenPadding()
            }
        }
        .trackingErrors()
    }


    func resultSection(
        _ lab: LabRecord
    ) -> some View {
        EditorialSection("Result") {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(lab.displayValue)
                    .font(Theme.metricLarge)
                    .foregroundStyle(
                        Theme.ink
                    )
                    .monospacedDigit()

                Text(
                    lab.collectedAt
                        .formatted(
                            date: .long,
                            time: .omitted
                        )
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
                .monospacedDigit()
            }

            if let range =
                lab.referenceRangeText {
                RecordRow(
                    label:
                        "Recorded reference",
                    value: range
                )
            }
        }
    }


    func contextSection(
        _ lab: LabRecord
    ) -> some View {
        EditorialSection("Context") {
            RecordRow(
                label: "Protocol",
                value:
                    protocolName(
                        lab.protocolID
                    )
            )

            if !lab.notes.isEmpty {
                Text(lab.notes)
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.ink
                    )
            }

            Text(
                "Protocola records the result and reference range you enter. It does not interpret whether a value is normal or abnormal."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    func protocolName(
        _ id: UUID?
    ) -> String {
        guard let id else {
            return "Not linked"
        }

        return store.protocols.first {
            $0.id == id
        }?.name
        ?? "Unavailable"
    }
}


struct LabEditorView: View {
    let lab: LabRecord?

    @Environment(TrackingStore.self)
    private var store
    @Environment(\.dismiss)
    private var dismiss

    @State private var draft:
        LabDraft

    init(
        protocolID: UUID? = nil,
        lab: LabRecord? = nil
    ) {
        self.lab = lab

        _draft =
            State(
                initialValue:
                    lab.map {
                        LabDraft(
                            lab: $0
                        )
                    }
                    ?? LabDraft(
                        protocolID:
                            protocolID
                    )
            )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Collected",
                        selection:
                            $draft.collectedAt,
                        in: ...Date.now,
                        displayedComponents:
                            .date
                    )
                } header: {
            Eyebrow(text: "Date")
        }

                Section {
                    TextField(
                        "Marker",
                        text: $draft.marker
                    )

                    HStack {
                        TextField(
                            "Value",
                            text:
                                $draft.value
                        )
                        .keyboardType(
                            .numbersAndPunctuation
                        )

                        TextField(
                            "Unit",
                            text:
                                $draft.unit
                        )
                        .multilineTextAlignment(
                            .trailing
                        )
                    }
                } header: {
            Eyebrow(text: "Result")
        }

                Section {
                    HStack {
                        TextField(
                            "Low",
                            text:
                                $draft
                                    .referenceLow
                        )
                        .keyboardType(
                            .numbersAndPunctuation
                        )

                        TextField(
                            "High",
                            text:
                                $draft
                                    .referenceHigh
                        )
                        .keyboardType(
                            .numbersAndPunctuation
                        )
                    }
                } header: {
            Eyebrow(text: "Reference range")
        } footer: { FormFooter {
                    Text(
                        "Optional. Enter the range shown by your lab source; Protocola does not generate one."
                    )
                }
}

                Section {
                    Picker(
                        "Protocol",
                        selection:
                            $draft.protocolID
                    ) {
                        Text("Not linked")
                            .tag(
                                nil as UUID?
                            )

                        ForEach(
                            store.protocols
                        ) { record in
                            Text(
                                record.name
                            )
                            .tag(
                                Optional(
                                    record.id
                                )
                            )
                        }
                    }

                    TextField(
                        "Notes (optional)",
                        text: $draft.notes,
                        axis: .vertical
                    )
                } header: {
            Eyebrow(text: "Context")
        }
            }
            .listStyle(.plain)
            .paperList()
            .scrollContentBackground(
                .hidden
            )
            .doneKeyboard()
            .navigationTitle(
                lab == nil
                ? "Add Lab"
                : "Edit Lab"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Save") {
                        if store.saveLab(
                            draft,
                            id: lab?.id
                        ) {
                            Haptics.success()
                            dismiss()
                        }
                    }
                }
            }
            .trackingErrors()
        }
    }
}

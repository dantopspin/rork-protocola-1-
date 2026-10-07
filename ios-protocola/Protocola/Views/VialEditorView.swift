import SwiftUI
import PhotosUI
import UIKit

struct VialEditorView: View {
    let vial: VialRecord?

    @Environment(TrackingStore.self)
    private var store
    @Environment(\.dismiss)
    private var dismiss

    @State private var draft: VialDraft
    @State private var initialSnapshot: String?
    @State private var confirmDiscard = false

    private var hasUnsavedChanges: Bool {
        initialSnapshot.map { $0 != String(describing: draft) } ?? false
    }
    @State private var saving = false
    @State private var photoItem:
        PhotosPickerItem?

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
                lifecycleSection
                photoSection

                if let vial {
                    correctionSection(vial)
                }

                Section {
                    Text(
                        "Protocola never infers vial strength or lifecycle dates. After the first recorded entry uses this vial, its compound and original strength are retained to protect historical calculations."
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
            .navigationTitle(
                vial == nil
                    ? "Record vial"
                    : "Edit vial"
            )
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
            .task(id: photoItem) {
                await loadSelectedPhoto()
            }
            .trackingErrors()
        }
    }
}

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
                "Diluent volume (mL, optional)",
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
            Eyebrow(text: "Label values")
        } footer: { FormFooter {
            Text(
                "Record the values printed on the vial or provided in your existing instructions."
            )
        }
}
    }

    var lifecycleSection: some View {
        Section {
            Picker(
                "State",
                selection: $draft.state
            ) {
                ForEach(
                    VialLifecycleState
                        .allCases
                ) { state in
                    Text(state.rawValue)
                        .tag(state)
                }
            }

            Toggle(
                "Record reconstitution date",
                isOn:
                    $draft
                        .hasReconstitutedDate
            )

            if draft.hasReconstitutedDate {
                DatePicker(
                    "Reconstituted",
                    selection:
                        $draft.reconstitutedAt,
                    in: ...Date.now,
                    displayedComponents: .date
                )
            }

            Toggle(
                "Record opened date",
                isOn:
                    $draft.hasOpenedDate
            )

            if draft.hasOpenedDate {
                DatePicker(
                    "Opened",
                    selection:
                        $draft.openedAt,
                    in: ...Date.now,
                    displayedComponents: .date
                )
            }

        } header: {
            Eyebrow(text: "Lifecycle")
        } footer: { FormFooter {
            Text(
                "State and dates are your own inventory records. Protocola does not infer when a vial should be opened, reconstituted, or discarded."
            )
        }
}
    }

    var photoSection: some View {
        Section {
            if let data = draft.photoData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight:
                            Theme.vialPhotoHeight
                    )
                    .clipShape(
                        .rect(
                            cornerRadius:
                                Theme.radiusRow
                        )
                    )
            }

            PhotosPicker(
                selection: $photoItem,
                matching: .images
            ) {
                Label(
                    draft.photoData == nil
                        ? "Attach reference photo"
                        : "Replace reference photo",
                    systemImage: "photo"
                )
            }

            if draft.photoData != nil {
                Button(
                    "Remove photo",
                    role: .destructive
                ) {
                    draft.photoData = nil
                    photoItem = nil
                }
            }
        } header: {
            Eyebrow(text: "Reference photo")
        } footer: { FormFooter {
            Text(
                "Optional. The photo stays with this local vial record and is not interpreted as dosing guidance."
            )
        }
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
            Eyebrow(text: "Manual correction")
        } footer: { FormFooter {
            Text(
                "Leave blank to keep the current estimate. A correction is recorded as an adjustment; later entry corrections and deletions still reconcile the balance."
            )
        }
}
    }
}

private extension VialEditorView {

    func save() {
        guard !saving else { return }
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

    func loadSelectedPhoto() async {
        guard let photoItem,
              let data =
                try? await photoItem
                    .loadTransferable(
                        type: Data.self
                    )
        else {
            return
        }

        if let image =
            UIImage(data: data),
           let normalized =
            image.jpegData(
                compressionQuality: 0.82
            ) {
            draft.photoData =
                normalized
        } else {
            draft.photoData = data
        }
    }
}

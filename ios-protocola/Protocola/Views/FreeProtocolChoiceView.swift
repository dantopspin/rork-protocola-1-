import SwiftUI

struct FreeProtocolChoiceView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var activeProtocols: [ProtocolRecord] {
        store.protocols.filter {
            $0.status == "Active"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(
                        "Free includes one actively tracked protocol. Choose which one stays editable and available for logging. All other protocols and their history remain on this iPhone as read-only records."
                    )
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
                }

                Section("Track on Free") {
                    ForEach(activeProtocols) {
                        record in
                        Button {
                            store.chooseFreeProtocol(
                                record.id
                            )
                            dismiss()
                        } label: {
                            HStack(
                                spacing: Theme.spaceM
                            ) {
                                VStack(
                                    alignment: .leading,
                                    spacing: Theme.spaceXXS
                                ) {
                                    Text(record.name)
                                        .foregroundStyle(
                                            Theme.ink
                                        )

                                    if let revision =
                                        store
                                            .currentRevisions(
                                                record.id
                                            )
                                            .first {
                                        Text(
                                            revision.compoundName
                                            + " · "
                                            + revision.amountText
                                            + " "
                                            + revision.unitText
                                        )
                                        .font(Theme.body)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                    }
                                }

                                Spacer()

                                if store
                                    .selectedFreeProtocolID
                                    == record.id {
                                    Image(
                                        systemName:
                                            "checkmark.circle.fill"
                                    )
                                    .foregroundStyle(
                                        Theme.teal
                                    )
                                }
                            }
                            .frame(minHeight: Theme.minimumTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .paperList()
            .navigationTitle(
                "Choose a protocol"
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
            }
            .trackingErrors()
        }
    }
}

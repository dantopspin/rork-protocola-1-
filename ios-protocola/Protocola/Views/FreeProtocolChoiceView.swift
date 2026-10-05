import SwiftUI

struct FreeProtocolChoiceView: View {
    @Environment(TrackingStore.self)
    private var store

    @Environment(\.dismiss)
    private var dismiss

    private var activeProtocols:
        [ProtocolRecord] {
        store.protocols.filter {
            $0.status == "Active"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXL
                ) {
                    Text(
                        "Free includes one actively tracked protocol. Choose which one stays editable and available for logging. All other protocols and their history remain on this iPhone as read-only records."
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )

                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceS
                    ) {
                        Eyebrow(
                            text: "Track on Free"
                        )

                        Rectangle()
                            .fill(
                                Theme.hairline
                            )
                            .frame(
                                height:
                                    Theme.ruleThickness
                            )

                        ForEach(
                            Array(
                                activeProtocols
                                    .enumerated()
                            ),
                            id: \.element.id
                        ) { index, record in
                            Button {
                                store
                                    .chooseFreeProtocol(
                                        record.id
                                    )
                                Haptics.selection()
                                dismiss()
                            } label: {
                                HStack(
                                    spacing:
                                        Theme.spaceM
                                ) {
                                    VStack(
                                        alignment:
                                            .leading,
                                        spacing:
                                            Theme.spaceXXS
                                    ) {
                                        Text(
                                            record.name
                                        )
                                        .font(
                                            Theme
                                                .sectionTitle
                                        )
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
                                                revision
                                                    .compoundName
                                                + " · "
                                                + revision
                                                    .amountText
                                                + " "
                                                + revision
                                                    .unitText
                                            )
                                            .font(
                                                Theme.body
                                            )
                                            .foregroundStyle(
                                                Theme
                                                    .textSecondary
                                            )
                                        }
                                    }

                                    Spacer()

                                    if store
                                        .selectedFreeProtocolID
                                        == record.id {
                                        Text("Selected")
                                            .font(
                                                Theme.micro
                                            )
                                            .foregroundStyle(
                                                Theme.teal
                                            )
                                    } else {
                                        Image(
                                            systemName:
                                                "chevron.right"
                                        )
                                        .font(
                                            Theme.micro
                                        )
                                        .foregroundStyle(
                                            Theme.muted
                                        )
                                    }
                                }
                                .padding(
                                    .vertical,
                                    Theme.spaceM
                                )
                                .contentShape(
                                    Rectangle()
                                )
                            }
                            .buttonStyle(.plain)

                            if index
                                < activeProtocols
                                    .count - 1 {
                                Rectangle()
                                    .fill(
                                        Theme.hairline
                                    )
                                    .frame(
                                        height:
                                            Theme
                                                .ruleThickness
                                    )
                            }
                        }

                        Rectangle()
                            .fill(
                                Theme.hairline
                            )
                            .frame(
                                height:
                                    Theme.ruleThickness
                            )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceS
                    ) {
                        Eyebrow(
                            text: "Need more than one?"
                        )

                        Button {
                            Haptics.selection()
                            store
                                .requestPaywall(
                                    .secondProtocol
                                )
                        } label: {
                            Label(
                                "Unlock unlimited protocols",
                                systemImage:
                                    "lock.open"
                            )
                        }
                        .buttonStyle(
                            TrackingSecondaryButtonStyle()
                        )
                    }
                }
                .screenPadding()
                .padding(
                    .bottom,
                    Theme.spaceXL
                )
            }
            .scrollIndicators(.hidden)
            .background(Theme.paper)
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
            // Presented as a sheet itself, so the paywall needs a sink here
            // to appear on top of the protocol choice sheet.
            .sheet(
                item:
                    Binding(
                        get: {
                            store.pendingPaywall
                        },
                        set: {
                            if $0 == nil {
                                store
                                    .dismissPaywall()
                            }
                        }
                    )
            ) { reason in
                PaywallView(reason: reason)
            }
        }
    }
}

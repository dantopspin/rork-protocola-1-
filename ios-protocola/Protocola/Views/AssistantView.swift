import SwiftUI

struct AssistantView: View {
    @Environment(TrackingStore.self)
    private var store

    @Environment(\.dismiss)
    private var dismiss

    @State private var model =
        AssistantViewModel()
    @State private var protocolID: UUID?
    @State private var scope =
        "Since last change"
    @State private var viewData = false

    private var selected:
        ProtocolRecord? {
        store.protocols.first {
            $0.id == protocolID
        } ?? store.protocols.first
    }

    private var start: Date {
        if scope == "Last month" {
            return Calendar.current.date(
                byAdding: .month,
                value: -1,
                to:
                    Calendar.current
                        .dateInterval(
                            of: .month,
                            for: .now
                        )?
                        .start
                    ?? .now
            ) ?? .now
        }

        if scope == "From the beginning" {
            return selected?.createdAt
                ?? .now
        }

        return store.events.first {
            $0.protocolID
                == selected?.id
            && $0.isChangeAnchor
            && $0.title
                != "Protocol created"
        }?.at
        ?? selected?.createdAt
        ?? .now
    }

    private var end: Date {
        scope == "Last month"
        ? (
            Calendar.current
                .dateInterval(
                    of: .month,
                    for: .now
                )?
                .start
            ?? .now
        )
        : .now
    }

    private var records:
        [TimelineRecord] {
        TimelineRecord.build(
            logs: store.logs,
            events: store.events,
            includeMetadata: false
        )
        .filter {
            $0.protocolID
                == selected?.id
            && $0.at >= start
            && $0.at < end
        }
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                timelineSection
                    .disabled(
                        model.isSending
                    )

                questionSection(model)

                if !store.aiSharing {
                    sharingConsentSection
                }

                actionSection(model)

                if let answer =
                    model.answer {
                    answerSection(answer)
                    supportingRecordsSection
                }
            }
            .listStyle(.plain)
            .paperList()
            .scrollContentBackground(.hidden)
            .doneKeyboard()
            .navigationTitle(
                "Ask Protocola"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        model.cancel()
                        dismiss()
                    }
                }
            }
            .onAppear {
                protocolID =
                    selected?.id
            }
            .sheet(
                isPresented: $viewData
            ) {
                sharedDataSheet(model)
            }
            .alert(
                "Ask Protocola unavailable",
                isPresented:
                    Binding(
                        get: {
                            model.error
                                != nil
                        },
                        set: {
                            if !$0 {
                                model.error =
                                    nil
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
            .onDisappear {
                model.cancel()
            }
            .trackingRoutes()
        }
    }
}


private extension AssistantView {

    var timelineSection:
        some View {
        Section {
            Picker(
                "Protocol",
                selection: $protocolID
            ) {
                ForEach(
                    store.protocols
                ) {
                    Text($0.name)
                        .tag(
                            Optional($0.id)
                        )
                }
            }

            Picker(
                "Dates",
                selection: $scope
            ) {
                ForEach(
                    [
                        "Since last change",
                        "Last month",
                        "From the beginning"
                    ],
                    id: \.self
                ) {
                    Text($0)
                        .tag($0)
                }
            }

            Text(
                start.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
                + " – "
                + end.formatted(
                    date: .abbreviated,
                    time: .shortened
                )
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
            .monospacedDigit()

        } header: {
            Eyebrow(text: "Timeline")
        }
    }


    func questionSection(
        _ model: AssistantViewModel
    ) -> some View {
        Section {
            Button(
                "What changed last month?"
            ) {
                scope = "Last month"
                model.question =
                    "What changed last month?"
            }

            Button(
                "What did I record after my last change?"
            ) {
                scope =
                    "Since last change"
                model.question =
                    "What did I record after my last change?"
            }

            Button(
                "Summarize this protocol from the beginning."
            ) {
                scope =
                    "From the beginning"
                model.question =
                    "Summarize this protocol from the beginning."
            }

            TextField(
                "Question about your timeline",
                text: $model.question,
                axis: .vertical
            )
            .font(Theme.body)

            Text(
                "Recorded events only. No medical advice or causal conclusions."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )

        } header: {
            Eyebrow(
                text:
                    "Ask about recorded events"
            )
        }
    }


    var sharingConsentSection:
        some View {
        Section {
            Text(
                "When you ask, your typed question and scoped compound, amount, schedule, status, site, and symptom records go to a network AI service. Private notes, protocol names, vial labels, suppliers, labs, and hidden audit metadata are excluded from automatic sharing."
            )
            .font(Theme.body)

            Button(
                "Allow sharing for Ask Protocola"
            ) {
                store.setAISharing(true)
            }
            .buttonStyle(
                TrackingSecondaryButtonStyle()
            )

        } header: {
            Eyebrow(
                text:
                    "Before your first question"
            )

        } footer: { FormFooter {
            Text(
                "AI can make mistakes. Avoid typing information you do not want sent."
            )
        }
}
    }


    func actionSection(
        _ model: AssistantViewModel
    ) -> some View {
        Section {
            Button("View shared data") {
                viewData = true
            }

            Button {
                if store.isPremium {
                    model.send(
                        records: records,
                        sharingAllowed:
                            store.aiSharing,
                        isPro: true
                    )
                } else {
                    store.requestPaywall(
                        .ask
                    )
                }
            } label: {
                if model.isSending {
                    ProgressView(
                        "Reading timeline…"
                    )
                } else {
                    Text("Ask Protocola")
                }
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )
            .disabled(
                !store.aiSharing
                || model.isSending
                || records.isEmpty
                || model.question
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty
            )

        } footer: { FormFooter {
            Text(
                "Sharing remains enabled until you turn it off in Settings. Nothing is sent in the background."
            )
        }
}
    }


    func answerSection(
        _ answer: String
    ) -> some View {
        Section {
            Text(answer)
                .font(Theme.body)
                .textSelection(.enabled)

            Text(
                "Verify against the cited records. AI may be incorrect."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )

        } header: {
            Eyebrow(
                text:
                    "Timeline summary · AI-generated"
            )
        }
    }


    var supportingRecordsSection:
        some View {
        Section {
            ForEach(
                Array(
                    model
                        .sentReferences
                        .enumerated()
                ),
                id: \.element.id
            ) { index, record in
                if let log = record.log {
                    NavigationLink(
                        value:
                            TrackingRoute
                                .logDetail(
                                    log.id
                                )
                    ) {
                        Text(
                            "[T"
                            + String(
                                index + 1
                            )
                            + "] "
                            + record.title
                            + " · "
                            + record.at
                                .formatted()
                        )
                    }

                } else if let event =
                    record.event {
                    NavigationLink {
                        EventDetailView(
                            event: event
                        )
                    } label: {
                        Text(
                            "[T"
                            + String(
                                index + 1
                            )
                            + "] "
                            + event.title
                            + " · "
                            + event.at
                                .formatted()
                        )
                    }
                }
            }

        } header: {
            Eyebrow(
                text:
                    "Supporting records · sent scope"
            )
        }
    }


    func sharedDataSheet(
        _ model: AssistantViewModel
    ) -> some View {
        NavigationStack {
            ScrollView {
                Text(
                    (
                        model.answer != nil
                        ? model.sentContext
                        : nil
                    )?.text
                    ?? AssistantViewModel
                        .timelineContext(
                            records
                        )
                        .text
                )
                .font(
                    Theme.caption
                        .monospaced()
                )
                .textSelection(.enabled)
                .screenPadding()
            }
            .background(Theme.paper)
            .navigationTitle(
                "Shared data"
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        viewData = false
                    }
                }
            }
        }
    }
}

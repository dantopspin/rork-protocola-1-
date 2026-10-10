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
    @FocusState private var inputFocused: Bool

    private static let suggestions = [
        ("What changed last month?", "Last month"),
        ("What did I record after my last change?", "Since last change"),
        ("Summarize this protocol from the beginning.", "From the beginning")
    ]

    private static let scopes = [
        "Since last change",
        "Last month",
        "From the beginning"
    ]

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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceM
                    ) {
                        scopeBar

                        if !store.aiSharing {
                            consentCard
                        }

                        if model.messages.isEmpty {
                            emptyConversation(model)
                        }

                        ForEach(model.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }

                        if model.isSending {
                            typingBubble
                                .id("typing")
                        }

                        Color.clear
                            .frame(height: Theme.ruleThickness)
                            .id("bottom")
                    }
                    .screenPadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .scrollIndicators(.hidden)
                // Drag down or tap anywhere in the conversation to put the
                // keyboard away.
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        inputFocused = false
                    }
                )
                .onChange(of: model.messages.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: model.isSending) {
                    scrollToBottom(proxy)
                }
                .onChange(of: inputFocused) { _, focused in
                    if focused { scrollToBottom(proxy) }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer(model)
            }
            .background(Theme.paper)
            .navigationTitle("Ask Protocola")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        model.cancel()
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            model.reset()
                        } label: {
                            Label("New conversation", systemImage: "square.and.pencil")
                        }
                        .disabled(model.messages.isEmpty)

                        Button {
                            viewData = true
                        } label: {
                            Label("View shared data", systemImage: "doc.text.magnifyingglass")
                        }
                    } label: {
                        Label("Conversation options", systemImage: "ellipsis")
                    }
                }
            }
            .onAppear {
                protocolID = selected?.id
            }
            .sheet(isPresented: $viewData) {
                sharedDataSheet(model)
            }
            // Presented as a sheet itself, so the paywall needs a sink here
            // to appear on top of the conversation.
            .sheet(
                item:
                    Binding(
                        get: { store.pendingPaywall },
                        set: { if $0 == nil { store.dismissPaywall() } }
                    )
            ) { reason in
                PaywallView(reason: reason)
            }
            .alert(
                "Ask Protocola unavailable",
                isPresented:
                    Binding(
                        get: { model.error != nil },
                        set: { if !$0 { model.error = nil } }
                    )
            ) {
                Button("OK") { model.error = nil }
            } message: {
                Text(model.error ?? "")
            }
            .onDisappear {
                model.cancel()
            }
            .trackingRoutes()
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(model.isSending)
    }
}


private extension AssistantView {

    func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(Theme.stateSpring) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    /// Which protocol and dates the conversation reads.
    var scopeBar: some View {
        HStack(spacing: Theme.spaceXS) {
            if store.protocols.count > 1 {
                Menu {
                    Picker("Protocol", selection: $protocolID) {
                        ForEach(store.protocols) {
                            Text($0.name).tag(Optional($0.id))
                        }
                    }
                } label: {
                    scopeChip(selected?.name ?? "Protocol", icon: "list.bullet.rectangle")
                }
            }

            Menu {
                Picker("Dates", selection: $scope) {
                    ForEach(Self.scopes, id: \.self) {
                        Text($0).tag($0)
                    }
                }
            } label: {
                scopeChip(scope, icon: "calendar")
            }
            .disabled(model.isSending)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .contain)
    }

    func scopeChip(_ text: String, icon: String) -> some View {
        HStack(spacing: Theme.spaceXXS) {
            Image(systemName: icon)
                .font(Theme.micro)
                .accessibilityHidden(true)
            Text(text)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(Theme.micro)
                .accessibilityHidden(true)
        }
        .font(Theme.chipLabel)
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, Theme.spaceS)
        .frame(minHeight: Theme.minimumTapTarget)
        .background(Theme.surface, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Theme.hairline, lineWidth: Theme.ruleThickness)
        )
    }

    var consentCard: some View {
        VStack(alignment: .leading, spacing: Theme.spaceS) {
            Label("Before your first question", systemImage: "lock.shield")
                .font(Theme.label)
                .foregroundStyle(Theme.ink)

            Text(
                "When you ask, your typed question and scoped compound, amount, schedule, status, site, and symptom records are sent through "
                + AIService.processorDescription
                + ". Private notes, protocol names, vial labels, suppliers, labs, and hidden audit metadata are excluded. AI can make mistakes; avoid typing anything you don't want sent."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)

            Button("Allow sharing for Ask Protocola") {
                store.setAISharing(true)
            }
            .buttonStyle(TrackingSecondaryButtonStyle())
        }
        .padding(Theme.cardInset)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusCard))
        .quietElevation()
    }

    func emptyConversation(_ model: AssistantViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.spaceS) {
            Text("Ask about your recorded history")
                .font(Theme.serifTitle)
                .foregroundStyle(Theme.ink)

            Text(
                rangeText
                + ". Recorded events only. No medical advice or causal conclusions."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
            .monospacedDigit()

            ForEach(Self.suggestions, id: \.0) { suggestion in
                Button {
                    scope = suggestion.1
                    model.question = suggestion.0
                    inputFocused = true
                } label: {
                    HStack {
                        Text(suggestion.0)
                            .font(Theme.subheadline)
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: Theme.spaceXS)
                        Image(systemName: "arrow.up.left")
                            .font(Theme.micro)
                            .foregroundStyle(Theme.textTertiary)
                            .accessibilityHidden(true)
                    }
                    .padding(Theme.spaceS)
                    .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusRow))
                }
                .buttonStyle(TrackingCardButtonStyle())
                .accessibilityHint("Puts this question in the message field.")
            }
        }
        .padding(.top, Theme.spaceS)
    }

    var rangeText: String {
        start.formatted(date: .abbreviated, time: .omitted)
        + " – "
        + end.formatted(date: .abbreviated, time: .omitted)
    }

    @ViewBuilder
    func bubble(_ message: AssistantViewModel.Message) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: Theme.spaceXXL)
                Text(message.text)
                    .font(Theme.body)
                    .foregroundStyle(Theme.onDarkPrimary)
                    .padding(.horizontal, Theme.spaceS)
                    .padding(.vertical, Theme.spaceXS)
                    .background(
                        Theme.accentFill,
                        in: RoundedRectangle(cornerRadius: Theme.radiusRow, style: .continuous)
                    )
                    .textSelection(.enabled)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You: " + message.text)

        case .assistant:
            VStack(alignment: .leading, spacing: Theme.spaceXS) {
                Text(message.text)
                    .font(Theme.body)
                    .foregroundStyle(Theme.ink)
                    .textSelection(.enabled)

                HStack(spacing: Theme.spaceXS) {
                    Text("AI-generated · verify against your records")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer(minLength: Theme.spaceXS)
                    if message.id == model.messages.last?.id,
                       !model.sentReferences.isEmpty {
                        Button("Records used") {
                            viewData = true
                        }
                        .font(Theme.caption)
                        .foregroundStyle(Theme.teal)
                        .buttonStyle(TrackingCardButtonStyle())
                    }
                }
            }
            .padding(Theme.spaceS)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.surface,
                in: RoundedRectangle(cornerRadius: Theme.radiusRow, style: .continuous)
            )
            .padding(.trailing, Theme.spaceL)
            .accessibilityElement(children: .combine)
        }
    }

    var typingBubble: some View {
        HStack(spacing: Theme.spaceXS) {
            ProgressView()
            Text("Reading your records…")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.spaceS)
        .background(
            Theme.surface,
            in: RoundedRectangle(cornerRadius: Theme.radiusRow, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    func composer(_ model: AssistantViewModel) -> some View {
        @Bindable var model = model
        let trimmed = model.question.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSend =
            store.aiSharing
            && !model.isSending
            && !records.isEmpty
            && !trimmed.isEmpty

        return VStack(spacing: Theme.spaceXXS) {
            HStack(alignment: .bottom, spacing: Theme.spaceXS) {
                // Grows to five lines, then scrolls, so long questions stay
                // fully visible above the keyboard.
                TextField(
                    "Ask about your records",
                    text: $model.question,
                    axis: .vertical
                )
                .font(Theme.body)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, Theme.spaceS)
                .padding(.vertical, Theme.spaceXS)
                .frame(minHeight: Theme.minimumTapTarget)
                .background(
                    Theme.surface,
                    in: RoundedRectangle(cornerRadius: Theme.radiusRow, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusRow, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: Theme.ruleThickness)
                )
                .disabled(model.isSending)

                Button {
                    send(model)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(Theme.label)
                        .foregroundStyle(Theme.onDarkPrimary)
                        .frame(
                            width: Theme.minimumTapTarget,
                            height: Theme.minimumTapTarget
                        )
                        .background(
                            canSend ? Theme.accentFill : Theme.inactiveFill,
                            in: Circle()
                        )
                }
                .buttonStyle(TrackingCardButtonStyle())
                .disabled(!canSend)
                .accessibilityLabel("Send question")
            }

            if records.isEmpty {
                Text("No records in this range yet. Pick a wider range above.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, Theme.pageInset)
        .padding(.vertical, Theme.spaceS)
        .background(Theme.paper)
    }

    func send(_ model: AssistantViewModel) {
        guard store.isPremium else {
            inputFocused = false
            store.requestPaywall(.ask)
            return
        }
        model.send(
            records: records,
            sharingAllowed: store.aiSharing,
            isPro: true
        )
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

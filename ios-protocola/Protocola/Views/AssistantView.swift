import SwiftUI

struct AssistantView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model: AssistantViewModel = AssistantViewModel()
    @State private var protocolID: UUID?
    @State private var scope: String = "Since last change"
    @State private var viewData: Bool = false
    private var selected: ProtocolRecord? { store.protocols.first { $0.id == protocolID } ?? store.protocols.first }
    private var start: Date {
        if scope == "Last month" { return Calendar.current.date(byAdding: .month, value: -1, to: Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now) ?? .now }
        if scope == "From the beginning" { return selected?.createdAt ?? .now }
        return store.events.first { $0.protocolID == selected?.id && $0.isChangeAnchor && $0.title != "Protocol created" }?.at ?? selected?.createdAt ?? .now
    }
    private var end: Date { scope == "Last month" ? (Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now) : .now }
    private var records: [TimelineRecord] { TimelineRecord.build(logs: store.logs, events: store.events, includeMetadata: true).filter { $0.protocolID == selected?.id && $0.at >= start && $0.at < end } }
    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section("Your timeline") {
                    Picker("Protocol", selection: $protocolID) { ForEach(store.protocols) { Text($0.name).tag(Optional($0.id)) } }
                    Picker("Dates", selection: $scope) { ForEach(["Since last change", "Last month", "From the beginning"], id: \.self) { Text($0).tag($0) } }
                    Text("\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .abbreviated, time: .shortened)) (end excluded)").font(Theme.caption).foregroundStyle(Theme.muted)
                }.disabled(model.isSending)
                Section("Ask about recorded events") {
                    Button("What changed last month?") { scope = "Last month"; model.question = "What changed last month?" }
                    Button("What did I record after my last change?") { scope = "Since last change"; model.question = "What did I record after my last change?" }
                    Button("Summarize this protocol from the beginning.") { scope = "From the beginning"; model.question = "Summarize this protocol from the beginning." }
                    TextField("Question about your timeline", text: $model.question, axis: .vertical)
                    Text("Recorded events only. No medical advice or causal conclusions.").font(Theme.caption).foregroundStyle(Theme.muted)
                }
                if !store.aiSharing {
                    Section("Before your first question") {
                        Text("When you ask, your typed question and scoped compound, amount, schedule, status, site, and symptom records go to a network AI service. Private notes, protocol names, vial labels, and suppliers are excluded from automatic sharing. AI can make mistakes; avoid typing information you do not want sent.").font(Theme.body)
                        Button("Allow sharing for Ask Protocola") { store.setAISharing(true) }
                    }
                }
                Section {
                    Button("View shared data") { viewData = true }
                    Button {
                        if store.isPremium {
                            model.send(records: records, sharingAllowed: store.aiSharing, isPro: true)
                        } else {
                            store.requestPaywall(.ask)
                        }
                    } label: {
                        if model.isSending {
                            ProgressView("Reading timeline…")
                        } else {
                            Label("Ask Protocola", systemImage: "text.bubble")
                        }
                    }
                    .disabled(!store.aiSharing || model.isSending || records.isEmpty || model.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: { Text("Sharing remains enabled until you turn it off in Settings. No per-question confirmation; nothing is sent in the background.") }
                if let answer = model.answer {
                    Section("Timeline summary · AI-generated") { Text(answer).textSelection(.enabled); Text("Verify against the cited records. AI may be incorrect.").font(Theme.caption).foregroundStyle(Theme.muted) }
                    Section("Supporting records · sent scope") {
                        ForEach(Array(model.sentReferences.enumerated()), id: \.element.id) { index, record in
                            if let log = record.log { NavigationLink(value: TrackingRoute.logDetail(log.id)) { Text("[T\(index + 1)] \(record.title) · \(record.at.formatted())") } }
                            else if let event = record.event { NavigationLink { EventDetailView(event: event) } label: { Text("[T\(index + 1)] \(event.title) · \(event.at.formatted())") } }
                        }
                    }
                }
            }.paperList()
            .scrollContentBackground(.hidden).doneKeyboard().navigationTitle("Ask Protocola").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { model.cancel(); dismiss() } } }
                .onAppear { protocolID = selected?.id }
                .sheet(isPresented: $viewData) {
                    NavigationStack { ScrollView { Text((model.answer != nil ? model.sentContext : nil)?.text ?? AssistantViewModel.timelineContext(records).text).font(Theme.caption.monospaced()).textSelection(.enabled).screenPadding() }.background(Theme.paper).navigationTitle("Shared data").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { viewData = false } } } }
                }
                .alert("Ask Protocola unavailable", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) { Button("OK") { model.error = nil } } message: { Text(model.error ?? "") }
                .onDisappear { model.cancel() }.trackingRoutes()
        }
    }
}

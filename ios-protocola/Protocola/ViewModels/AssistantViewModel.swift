import Foundation
import Observation

@MainActor @Observable final class AssistantViewModel {
    /// Ask Protocola gathers the most recent records automatically; the user never hand-picks entries.
    static let recordLimit = 30
    var question: String = ""
    private(set) var answer: String?
    private(set) var isSending: Bool = false
    var error: String?
    private var task: Task<Void, Never>?

    /// Builds the record projection sent to the AI: the most recent entries with their
    /// structured tracked fields. Notes, protocol names, vial labels and supplier details never leave the device.
    static func automaticContext(_ logs: [DoseLog], limit: Int = recordLimit) -> AIRecordContext {
        let lines = logs.prefix(limit).enumerated().map { index, log -> String in
            var line = "[D\(index + 1)] \(log.loggedAt.ISO8601Format()) · \(log.compoundName) · \(log.status)"
            line += " · actual \(log.actualAmountText) \(log.unitText) · scheduled \(log.scheduledAmountText) \(log.scheduledUnitText)"
            if !log.site.isEmpty { line += " · site: \(log.site)" }
            if !log.symptoms.isEmpty { line += " · symptoms: \(log.symptoms.prefix(300)) · severity \(log.symptomSeverity)/10" }
            return line
        }
        return AIRecordContext(lines: lines)
    }

    private(set) var sentReferences: [TimelineRecord] = []
    private(set) var sentContext: AIRecordContext?
    static func timelineContext(_ records: [TimelineRecord], limit: Int = 150) -> AIRecordContext {
        let lines = records.prefix(limit).enumerated().map { index, record in
            if let log = record.log {
                let data = automaticContext([log], limit: 1).text.replacingOccurrences(of: "[D1]", with: "[T\(index + 1)]")
                return String(data.prefix(1500))
            }
            let changes = record.event?.changes.filter { !$0.isPrivate }.map(\.description).joined(separator: "; ") ?? ""
            return "[T\(index + 1)] \(record.at.ISO8601Format()) · \(record.category) · \(record.title) · \(changes.isEmpty ? "Older event: detailed shared values unavailable" : String(changes.prefix(1500)))"
        }
        let coverage = "Coverage: \(min(records.count, limit)) of \(records.count) scoped timeline records included. \(records.count > limit ? "Incomplete coverage: only the most recent records are supplied; do not claim a complete history." : "All retained records in the scope supplied; older previous values may be unavailable.")"
        return AIRecordContext(lines: [coverage] + lines)
    }
    func send(records: [TimelineRecord], sharingAllowed: Bool, isPro: Bool) {
        guard isPro, sharingAllowed, !isSending else { error = "Pro and record sharing are required for Ask Protocola."; return }
        sentReferences = Array(records.prefix(150))
        let context = Self.timelineContext(records)
        sentContext = context
        send(context: context, sharingAllowed: sharingAllowed)
    }
    func previewText(_ logs: [DoseLog]) -> String { Self.automaticContext(logs).text }

    func send(logs: [DoseLog], sharingAllowed: Bool) {
        send(context: Self.automaticContext(logs), sharingAllowed: sharingAllowed)
    }
    private func send(context: AIRecordContext, sharingAllowed: Bool) {
        guard sharingAllowed, !isSending else { error = "Enable record sharing before asking."; return }
        isSending = true; answer = nil
        let question = self.question
        task = Task {
            defer { isSending = false }
            do {
                let result = try await AIService().ask(question: question, context: context)
                try Task.checkCancellation(); answer = result
            } catch is CancellationError { }
            catch { if !Task.isCancelled { self.error = (error as? TrackingError)?.errorDescription ?? "Ask Protocola could not be reached. Your records remain on this iPhone." } }
        }
    }
    func cancel() { task?.cancel(); task = nil }
}

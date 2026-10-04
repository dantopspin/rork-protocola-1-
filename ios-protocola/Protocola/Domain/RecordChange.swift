import Foundation

/// Immutable previous/new values attached to a historical event.
nonisolated struct RecordChange: Codable, Equatable, Identifiable, Sendable {
    let field: String
    let before: String
    let after: String
    var id: String { field }
    var isMeaningful: Bool { ["Amount", "Unit", "Compound", "Schedule", "Status"].contains(field) }
    var isPrivate: Bool { ["Name", "Source", "Notes", "Vial", "Supplier", "Batch", "Storage notes"].contains(field) }
    var description: String { "\(field): \(before.isEmpty ? "Not recorded" : before) → \(after.isEmpty ? "Not recorded" : after)" }

    static func between(_ before: [String: String], _ after: [String: String]) -> [RecordChange] {
        Set(before.keys).union(after.keys).sorted().compactMap { field in
            let old = before[field] ?? ""
            let new = after[field] ?? ""
            return old == new ? nil : RecordChange(field: field, before: old, after: new)
        }
    }
}

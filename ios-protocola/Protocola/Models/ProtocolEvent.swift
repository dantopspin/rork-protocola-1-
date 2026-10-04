import Foundation
import SwiftData

@Model final class ProtocolEvent {
    @Attribute(.unique) var id: UUID
    var protocolID: UUID?
    var title: String
    var detail: String
    var at: Date
    var changesData: Data?
    var categoryText: String?
    var changes: [RecordChange] { changesData.flatMap { try? JSONDecoder().decode([RecordChange].self, from: $0) } ?? [] }
    var category: String {
        if let categoryText { return categoryText }
        if title.hasPrefix("Vial") { return "Vial" }
        if title.hasPrefix("Dose") { return "Correction" }
        return "Protocol"
    }
    var isChangeAnchor: Bool {
        category == "Protocol" && (changes.contains(where: \.isMeaningful) || (changesData == nil && title != "Protocol created"))
    }
    var showsInTimeline: Bool { category != "Metadata" }
    func recordChanges(_ values: [RecordChange], category: String) throws {
        changesData = try JSONEncoder().encode(values); categoryText = category
        detail = values.map(\.description).joined(separator: "\n")
    }
    init(protocolID: UUID?, title: String, detail: String, at: Date = .now) { id = UUID(); self.protocolID = protocolID; self.title = title; self.detail = detail; self.at = at }
}

import Foundation
import SwiftData

@Model final class ProtocolRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var status: String
    var instructionSource: String
    var notes: String
    var createdAt: Date
    init(name: String, instructionSource: String, notes: String = "", createdAt: Date = .now) {
        id = UUID(); self.name = name; status = "Active"; self.instructionSource = instructionSource; self.notes = notes; self.createdAt = createdAt
    }
}

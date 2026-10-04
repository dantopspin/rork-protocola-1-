import Foundation
import SwiftData

@Model final class CompoundRecord {
    @Attribute(.unique) var id: UUID
    var protocolID: UUID
    var name: String
    init(protocolID: UUID, name: String) { id = UUID(); self.protocolID = protocolID; self.name = name }
}

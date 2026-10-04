import Foundation
import SwiftData

@Model final class InventoryAdjustment {
    @Attribute(.unique) var id: UUID
    var vialID: UUID
    var deltaMgText: String
    var recordedAt: Date
    init(vialID: UUID, deltaMg: Decimal) { id = UUID(); self.vialID = vialID; deltaMgText = DoseCalculator.text(deltaMg); recordedAt = .now }
    var deltaMg: Decimal { Decimal(string: deltaMgText) ?? 0 }
}

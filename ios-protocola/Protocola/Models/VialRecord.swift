import Foundation
import SwiftData

@Model final class VialRecord {
    @Attribute(.unique) var id: UUID
    var compoundName: String
    var name: String
    var originalMgText: String
    var diluentMlText: String
    var batch: String
    var supplier: String
    var storageNotes: String
    var expiry: Date?
    var reconstitutedAt: Date?
    var isArchived: Bool
    var createdAt: Date
    init(name: String, compoundName: String, originalMg: Decimal, diluentMl: Decimal, batch: String = "", supplier: String = "", storageNotes: String = "", expiry: Date? = nil) {
        id = UUID(); self.name = name; self.compoundName = compoundName; originalMgText = DoseCalculator.text(originalMg); diluentMlText = DoseCalculator.text(diluentMl)
        self.batch = batch; self.supplier = supplier; self.storageNotes = storageNotes; self.expiry = expiry; reconstitutedAt = .now; isArchived = false; createdAt = .now
    }
    var originalMg: Decimal { Decimal(string: originalMgText) ?? 0 }
    var diluentMl: Decimal { Decimal(string: diluentMlText) ?? 0 }
    var concentration: Decimal? { try? DoseCalculator.concentration(vialAmount: originalMg, unit: .mg, diluentMl: diluentMl) }
}

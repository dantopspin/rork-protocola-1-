import Foundation
import SwiftData

@Model final class ScheduleRevision {
    @Attribute(.unique) var id: UUID
    var compoundID: UUID
    var protocolID: UUID
    var protocolName: String
    var compoundName: String
    var amountText: String
    var unitText: String
    var vialID: UUID?
    var configuredSite: String?
    var configData: Data
    var effectiveFrom: Date
    var effectiveUntil: Date?
    var enabled: Bool
    var reminders: Bool
    init(compound: CompoundRecord, protocolName: String, amount: Decimal, unit: AmountUnit, vialID: UUID?, config: ScheduleConfig, effectiveFrom: Date, enabled: Bool = true, reminders: Bool = false, configuredSite: String? = nil) throws {
        id = UUID(); compoundID = compound.id; protocolID = compound.protocolID; self.protocolName = protocolName; compoundName = compound.name
        amountText = DoseCalculator.text(amount); unitText = unit.rawValue; self.vialID = vialID; self.configuredSite = configuredSite
        configData = try JSONEncoder().encode(config); self.effectiveFrom = effectiveFrom; self.enabled = enabled; self.reminders = reminders
    }
    var config: ScheduleConfig? { try? JSONDecoder().decode(ScheduleConfig.self, from: configData) }
    var amount: Decimal { Decimal(string: amountText) ?? 0 }
    var unit: AmountUnit { AmountUnit(rawValue: unitText) ?? .mg }
}

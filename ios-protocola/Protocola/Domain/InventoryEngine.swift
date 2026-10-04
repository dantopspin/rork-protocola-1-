import Foundation

nonisolated enum InventoryEngine {
    static func balance(originalMg: Decimal, adjustmentsMg: [Decimal], consumptionsMg: [Decimal]) throws -> Decimal {
        guard originalMg >= 0, consumptionsMg.allSatisfy({ $0 >= 0 && !$0.isNaN }) else { throw TrackingError.invalidInput("Invalid inventory amount.") }
        let result = adjustmentsMg.reduce(originalMg, +) - consumptionsMg.reduce(0, +)
        guard result >= 0 else { throw TrackingError.insufficientInventory }
        return result
    }
    /// Replace the old consumption, not the entire ledger. Deletion supplies zero replacement.
    static func reconcile(currentMg: Decimal, oldConsumptionMg: Decimal, newConsumptionMg: Decimal) throws -> Decimal {
        guard currentMg >= 0, oldConsumptionMg >= 0, newConsumptionMg >= 0 else { throw TrackingError.invalidInput("Invalid inventory amount.") }
        let result = currentMg + oldConsumptionMg - newConsumptionMg
        guard result >= 0 else { throw TrackingError.insufficientInventory }
        return result
    }
}

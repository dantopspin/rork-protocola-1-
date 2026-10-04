import Foundation

nonisolated enum TrackingError: Error, LocalizedError, Sendable {
    case invalidInput(String)
    case insufficientInventory
    case duplicateEntry
    case missingRecord
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message): return message
        case .insufficientInventory: return "This entry exceeds the recorded vial balance. Correct the vial balance or the entered amount before saving."
        case .duplicateEntry: return "This scheduled entry is already recorded. Correct it in History instead."
        case .missingRecord: return "This record is no longer available. Please reopen the screen."
        }
    }
}

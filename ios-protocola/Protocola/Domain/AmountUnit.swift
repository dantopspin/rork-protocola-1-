import Foundation

nonisolated enum AmountUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case mg, mcg, mL, units
    var id: String { rawValue }
}

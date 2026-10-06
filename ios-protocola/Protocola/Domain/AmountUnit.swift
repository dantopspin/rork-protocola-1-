import Foundation

nonisolated enum AmountUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case mg, mcg, mL, units
    /// International units, as labelled on some vials. IU cannot be converted
    /// to mass without a compound-specific factor, so IU entries never draw
    /// down a vial's mg balance.
    case iu = "IU"
    var id: String { rawValue }
}

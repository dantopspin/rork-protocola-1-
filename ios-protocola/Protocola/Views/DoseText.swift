import Foundation

/// One spelling for every dose shown outside a hero metric:
/// "Compound · 250 mcg". Render it with `.monospacedDigit()`.
enum DoseText {
    static func amount(
        _ amount: String,
        _ unit: String
    ) -> String {
        amount + " " + unit
    }

    static func line(
        compound: String,
        amount: String,
        unit: String
    ) -> String {
        compound + " · " + Self.amount(amount, unit)
    }
}

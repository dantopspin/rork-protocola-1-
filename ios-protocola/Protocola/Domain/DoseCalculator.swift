import Foundation

/// Exact conversions from explicit recorded inputs; no suggested doses or defaults.
nonisolated enum DoseCalculator {
    static func parse(_ text: String, label: String, allowZero: Bool = false) throws -> Decimal {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let separator = Locale.current.decimalSeparator ?? "."
        let canonical = clean.replacingOccurrences(of: separator, with: ".")
        guard canonical.range(of: "^[0-9]+(?:\\.[0-9]{1,12})?$", options: .regularExpression) != nil,
              let value = Decimal(string: canonical, locale: Locale(identifier: "en_US_POSIX")),
              !value.isNaN, value <= Decimal(1_000_000_000), allowZero ? value >= 0 : value > 0 else {
            throw TrackingError.invalidInput("Enter a valid \(label.lowercased())\(allowZero ? " (zero or greater)" : " greater than zero").")
        }
        return value
    }
    static func massMg(_ amount: Decimal, unit: AmountUnit, concentration: Decimal? = nil, unitsPerMl: Decimal? = nil) throws -> Decimal {
        guard !amount.isNaN, amount >= 0 else { throw TrackingError.invalidInput("Amount cannot be negative.") }
        switch unit {
        case .mg: return amount
        case .mcg: return amount / 1000
        case .mL:
            guard let concentration, concentration > 0 else { throw TrackingError.invalidInput("Record the vial concentration before converting volume.") }
            return amount * concentration
        case .iu:
            throw TrackingError.invalidInput("IU can't be converted to mg. Log IU entries without a vial, or record this dose in mg or mcg to track the vial balance.")
        case .units:
            guard let concentration, concentration > 0, let unitsPerMl, unitsPerMl > 0 else { throw TrackingError.invalidInput("Record concentration and syringe scale before converting units.") }
            return amount / unitsPerMl * concentration
        }
    }
    static func concentration(vialAmount: Decimal, unit: AmountUnit, diluentMl: Decimal) throws -> Decimal {
        guard [.mg, .mcg].contains(unit), vialAmount > 0, diluentMl > 0 else { throw TrackingError.invalidInput("Vial mass and diluent volume must be greater than zero.") }
        return try massMg(vialAmount, unit: unit) / diluentMl
    }
    static func volume(amount: Decimal, unit: AmountUnit, concentration: Decimal, unitsPerMl: Decimal) throws -> Decimal {
        guard concentration > 0, unitsPerMl > 0, amount > 0 else { throw TrackingError.invalidInput("Enter positive amount, concentration, and syringe scale.") }
        return try massMg(amount, unit: unit, concentration: concentration, unitsPerMl: unitsPerMl) / concentration
    }

    static func text(_ number: Decimal) -> String { NSDecimalNumber(decimal: number).stringValue }
}



// MARK: - Estimated remaining amount

nonisolated
enum EstimatedLevelEngine {

    struct DoseInput:
        Equatable,
        Sendable {
        let at: Date
        let massMg: Double
    }


    struct Sample:
        Identifiable,
        Equatable,
        Sendable {
        let at: Date
        let estimatedMg: Double

        var id: Date {
            at
        }
    }


    static func estimatedRemaining(
        at date: Date,
        doses: [DoseInput],
        halfLifeHours: Double
    ) -> Double {
        guard halfLifeHours > 0 else {
            return 0
        }

        return doses.reduce(0) {
            total,
            dose in

            guard
                dose.massMg > 0,
                dose.at <= date
            else {
                return total
            }

            let elapsedHours =
                date
                    .timeIntervalSince(
                        dose.at
                    )
                / 3_600

            let remainingFraction =
                pow(
                    0.5,
                    elapsedHours
                    / halfLifeHours
                )

            return
                total
                + dose.massMg
                * remainingFraction
        }
    }


    static func samples(
        doses: [DoseInput],
        halfLifeHours: Double,
        start: Date,
        end: Date,
        stepHours: Double
    ) -> [Sample] {
        guard
            end > start,
            halfLifeHours > 0,
            stepHours > 0
        else {
            return []
        }

        let step =
            stepHours * 3_600
        var date = start
        var output:
            [Sample] = []
        var safety = 0

        while date < end
            && safety < 2_000 {
            output.append(
                Sample(
                    at: date,
                    estimatedMg:
                        estimatedRemaining(
                            at: date,
                            doses: doses,
                            halfLifeHours:
                                halfLifeHours
                        )
                )
            )

            date =
                date.addingTimeInterval(
                    step
                )
            safety += 1
        }

        output.append(
            Sample(
                at: end,
                estimatedMg:
                    estimatedRemaining(
                        at: end,
                        doses: doses,
                        halfLifeHours:
                            halfLifeHours
                    )
            )
        )

        return output
    }
}

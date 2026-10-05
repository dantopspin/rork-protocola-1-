import Foundation
import Observation

@MainActor @Observable final class CalculatorViewModel {

    /// Direction of the arithmetic. Both modes convert only the explicit
    /// values the user enters; neither suggests a dose or a preparation.
    enum Mode: String, CaseIterable, Identifiable {
        case forward = "Draw for a dose"
        case reverse = "Diluent for a draw"

        var id: String { rawValue }
    }

    var mode: Mode = .forward

    // Shared vial inputs.
    var vialAmount: String = ""
    var vialUnit: AmountUnit = .mg
    var diluent: String = ""

    // Forward mode: dose → draw.
    var amount: String = ""
    var amountUnit: AmountUnit = .mcg
    var scale: String = ""

    // Reverse mode: dose + draw → diluent. The syringe scale is shared.
    var targetDose: String = ""
    var targetDoseUnit: AmountUnit = .mg
    var targetDraw: String = ""

    private(set) var concentration: String?
    private(set) var volume: String?
    private(set) var syringeUnits: String?

    private(set) var reverseDiluent: String?
    private(set) var reverseConcentration: String?

    var error: String?

    func calculate() {
        concentration = nil
        volume = nil
        syringeUnits = nil
        reverseDiluent = nil
        reverseConcentration = nil

        do {
            switch mode {
            case .forward:
                try calculateForward()

            case .reverse:
                try calculateReverse()
            }

        } catch {
            self.error = error.localizedDescription
        }
    }


    private func calculateForward() throws {
        let vial = try DoseCalculator.parse(vialAmount, label: "Vial amount")
        let ml = try DoseCalculator.parse(diluent, label: "Diluent")
        let target = try DoseCalculator.parse(amount, label: "Entered amount")
        let units = try DoseCalculator.parse(scale, label: "Syringe scale")
        let c = try DoseCalculator.concentration(vialAmount: vial, unit: vialUnit, diluentMl: ml)
        let v = try DoseCalculator.volume(amount: target, unit: amountUnit, concentration: c, unitsPerMl: units)
        concentration = DoseCalculator.text(c)
        volume = DoseCalculator.text(v)
        syringeUnits = DoseCalculator.text(v * units)
    }


    private func calculateReverse() throws {
        let vial = try DoseCalculator.parse(vialAmount, label: "Vial amount")
        let dose = try DoseCalculator.parse(targetDose, label: "Dose")
        let draw = try DoseCalculator.parse(targetDraw, label: "Draw")
        let units = try DoseCalculator.parse(scale, label: "Syringe scale")

        let result = try DoseCalculator.diluentForTarget(
            vialAmount: vial,
            vialUnit: vialUnit,
            dose: dose,
            doseUnit: targetDoseUnit,
            drawUnits: draw,
            scale: units
        )

        reverseDiluent = DoseCalculator.text(result.diluentMl)
        reverseConcentration = DoseCalculator.text(result.concentration)
    }
}

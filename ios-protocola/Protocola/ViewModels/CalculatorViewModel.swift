import Foundation
import Observation

@MainActor @Observable final class CalculatorViewModel {
    var vialAmount: String = ""
    var vialUnit: AmountUnit = .mg
    var diluent: String = ""
    var amount: String = ""
    var amountUnit: AmountUnit = .mcg
    var scale: String = ""
    private(set) var concentration: String?
    private(set) var volume: String?
    private(set) var syringeUnits: String?
    var error: String?
    func calculate() {
        concentration = nil; volume = nil; syringeUnits = nil
        do {
            let vial = try DoseCalculator.parse(vialAmount, label: "Vial amount")
            let ml = try DoseCalculator.parse(diluent, label: "Diluent")
            let target = try DoseCalculator.parse(amount, label: "Entered amount")
            let units = try DoseCalculator.parse(scale, label: "Syringe scale")
            let c = try DoseCalculator.concentration(vialAmount: vial, unit: vialUnit, diluentMl: ml)
            let v = try DoseCalculator.volume(amount: target, unit: amountUnit, concentration: c, unitsPerMl: units)
            concentration = DoseCalculator.text(c); volume = DoseCalculator.text(v); syringeUnits = DoseCalculator.text(v * units)
        } catch { self.error = error.localizedDescription }
    }
}

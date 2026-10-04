import Foundation

struct VialDraft {
    var name: String = ""
    var compound: String = ""
    var amount: String = ""
    var unit: AmountUnit = .mg
    var diluent: String = ""
    var batch: String = ""
    var supplier: String = ""
    var notes: String = ""
    var hasExpiry: Bool = false
    var expiry: Date = .now
    var correctedBalance: String = ""
    init() {}
    init(vial: VialRecord) { name = vial.name; compound = vial.compoundName; amount = vial.originalMgText; diluent = vial.diluentMlText; batch = vial.batch; supplier = vial.supplier; notes = vial.storageNotes; hasExpiry = vial.expiry != nil; expiry = vial.expiry ?? .now }
}

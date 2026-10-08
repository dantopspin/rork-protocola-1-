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
    var hasReconstitutedDate: Bool = false
    var reconstitutedAt: Date = .now
    var hasOpenedDate: Bool = false
    var openedAt: Date = .now
    var state:
        VialLifecycleState = .active
    var photoData: Data?
    /// Nil keeps the automatic colour.
    var capColor: VialCapColor?
    var correctedBalance: String = ""

    init() {}

    init(vial: VialRecord) {
        name = vial.name
        compound = vial.compoundName
        amount = vial.originalMgText
        diluent = vial.diluentMlText
        batch = vial.batch
        supplier = vial.supplier
        notes = vial.storageNotes
        hasExpiry = vial.expiry != nil
        expiry = vial.expiry ?? .now
        hasReconstitutedDate =
            vial.reconstitutedAt != nil
        reconstitutedAt =
            vial.reconstitutedAt ?? .now
        hasOpenedDate =
            vial.openedAt != nil
        openedAt =
            vial.openedAt ?? .now
        state = vial.lifecycleState
        photoData = vial.photoData
        capColor =
            vial.capColorRawValue
                .flatMap(VialCapColor.init(rawValue:))
    }
}

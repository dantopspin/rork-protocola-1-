import Foundation

struct LabDraft {
    var protocolID: UUID?
    var marker = ""
    var value = ""
    var unit = ""
    var referenceLow = ""
    var referenceHigh = ""
    var notes = ""
    var collectedAt = Date.now

    init(
        protocolID: UUID? = nil
    ) {
        self.protocolID = protocolID
    }

    init(
        lab: LabRecord
    ) {
        protocolID = lab.protocolID
        marker = lab.marker
        value = lab.valueText
        unit = lab.unit
        referenceLow =
            lab.referenceLowText ?? ""
        referenceHigh =
            lab.referenceHighText ?? ""
        notes = lab.notes
        collectedAt = lab.collectedAt
    }
}

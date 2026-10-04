import Foundation

struct DoseDraft {
    var amount: String = ""
    var unit: AmountUnit = .mcg
    var vialID: UUID?
    var unitsPerMl: String = "100"
    var status: String = "Logged"
    var site: String = ""
    var symptoms: String = ""
    var severity: Int = 1
    var notes: String = ""
    var loggedAt: Date = .now
    init(revision: ScheduleRevision) { amount = revision.amountText; unit = revision.unit; vialID = revision.vialID }

    /// Repeat-last prefill for the Today quick action. Dose values always come from the
    /// current scheduled revision — never from history. Only the vial and its recorded
    /// syringe scale may be reused, and only when the schedule leaves the vial open and
    /// the candidate vial is still active for the same compound. Site, symptoms, and
    /// notes stay blank; the draft always passes through the editor before saving.
    static func repeatLast(revision: ScheduleRevision, last: DoseLog?, candidateVial: VialRecord?) -> DoseDraft {
        var draft = DoseDraft(revision: revision)
        guard draft.vialID == nil, let last, let candidate = candidateVial, !candidate.isArchived,
              candidate.compoundName.caseInsensitiveCompare(revision.compoundName) == .orderedSame else { return draft }
        draft.vialID = candidate.id
        draft.unitsPerMl = last.unitsPerMlText
        return draft
    }
    init(log: DoseLog) {
        amount = log.actualAmountText; unit = log.unit; vialID = log.vialID; unitsPerMl = log.unitsPerMlText; status = log.status; site = log.site; symptoms = log.symptoms; severity = log.symptomSeverity; notes = log.notes; loggedAt = log.loggedAt
    }
}

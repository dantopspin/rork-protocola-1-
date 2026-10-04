import Foundation
import SwiftData

/// Names, scheduled amount, route, concentration, and syringe scale are
/// independent historical snapshots.
@Model final class DoseLog {
    @Attribute(.unique) var id: UUID
    var compoundID: UUID
    var protocolID: UUID
    var occurrenceID: String?
    var scheduledAt: Date?
    var protocolName: String
    var compoundName: String
    var scheduledAmountText: String
    var scheduledUnitText: String

    /// Route is preserved with the log so future protocol edits cannot rewrite it.
    var routeText: String = AdministrationRoute.injection.rawValue

    var actualAmountText: String
    var unitText: String
    var vialID: UUID?
    var vialName: String
    var concentrationText: String?
    var unitsPerMlText: String
    var consumptionMgText: String
    var volumeMlText: String?
    var status: String
    var site: String
    var symptoms: String
    var symptomSeverity: Int
    var notes: String
    var loggedAt: Date
    var createdAt: Date
    var correctedAt: Date?

    init(
        revision: ScheduleRevision,
        occurrenceID: String?,
        scheduledAt: Date?,
        amount: Decimal,
        unit: AmountUnit,
        vial: VialRecord?,
        scale: Decimal,
        consumption: Decimal,
        volume: Decimal?,
        status: String,
        site: String,
        symptoms: String,
        severity: Int,
        notes: String,
        loggedAt: Date
    ) {
        id = UUID()
        compoundID =
            revision.compoundID
        protocolID =
            revision.protocolID
        self.occurrenceID =
            occurrenceID
        self.scheduledAt =
            scheduledAt
        protocolName =
            revision.protocolName
        compoundName =
            revision.compoundName
        scheduledAmountText =
            revision.amountText
        scheduledUnitText =
            revision.unitText
        routeText =
            revision.routeText
        actualAmountText =
            DoseCalculator.text(
                amount
            )
        unitText = unit.rawValue
        vialID = vial?.id
        vialName =
            vial?.name
            ?? "Not recorded"
        concentrationText =
            vial?.concentration
                .map(
                    DoseCalculator.text
                )
        unitsPerMlText =
            DoseCalculator.text(scale)
        consumptionMgText =
            DoseCalculator.text(
                consumption
            )
        volumeMlText =
            volume.map(
                DoseCalculator.text
            )
        self.status = status
        self.site = site
        self.symptoms = symptoms
        symptomSeverity = severity
        self.notes = notes
        self.loggedAt = loggedAt
        createdAt = .now
    }

    var actualAmount: Decimal {
        Decimal(
            string: actualAmountText
        ) ?? 0
    }

    var consumptionMg: Decimal {
        Decimal(
            string: consumptionMgText
        ) ?? 0
    }

    var concentration: Decimal? {
        concentrationText.flatMap {
            Decimal(string: $0)
        }
    }

    var unit: AmountUnit {
        AmountUnit(
            rawValue: unitText
        ) ?? .mg
    }

    var unitsPerMl: Decimal {
        Decimal(
            string: unitsPerMlText
        ) ?? 100
    }

    var route: AdministrationRoute {
        AdministrationRoute(
            rawValue: routeText
        ) ?? .injection
    }
}

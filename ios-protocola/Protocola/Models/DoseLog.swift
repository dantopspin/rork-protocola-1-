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
    var routeRawValue: String?

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
        routeRawValue =
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

    var routeText: String {
        route.rawValue
    }

    var route: AdministrationRoute {
        AdministrationRoute(
            rawValue: routeRawValue
                ?? ""
        ) ?? .injection
    }
}


enum InjectionBodyFace: String, CaseIterable, Identifiable {
    case front = "Front"
    case back = "Back"

    var id: String { rawValue }
}

/// Canonical injection-site labels used for structured history and the body map.
/// The raw value is persisted in DoseLog.site so existing stores require no schema
/// migration. Older/custom free-text labels remain readable and editable.
enum InjectionSite: String, CaseIterable, Identifiable, Hashable {
    case leftUpperArm = "Left upper arm"
    case rightUpperArm = "Right upper arm"
    case leftAbdomen = "Left abdomen"
    case rightAbdomen = "Right abdomen"
    case leftThigh = "Left thigh"
    case rightThigh = "Right thigh"
    case leftGlute = "Left glute"
    case rightGlute = "Right glute"

    var id: String { rawValue }

    var bodyFace: InjectionBodyFace {
        switch self {
        case .leftGlute, .rightGlute:
            return .back
        default:
            return .front
        }
    }

    /// Normalized coordinates within the body-map canvas.
    var normalizedX: Double {
        switch self {
        case .leftUpperArm: return 0.29
        case .rightUpperArm: return 0.71
        case .leftAbdomen: return 0.44
        case .rightAbdomen: return 0.56
        case .leftThigh: return 0.43
        case .rightThigh: return 0.57
        case .leftGlute: return 0.44
        case .rightGlute: return 0.56
        }
    }

    var normalizedY: Double {
        switch self {
        case .leftUpperArm, .rightUpperArm:
            return 0.31
        case .leftAbdomen, .rightAbdomen:
            return 0.47
        case .leftGlute, .rightGlute:
            return 0.55
        case .leftThigh, .rightThigh:
            return 0.71
        }
    }

    static func match(_ storedValue: String) -> InjectionSite? {
        let key = normalize(storedValue)
        guard !key.isEmpty else { return nil }

        return allCases.first {
            normalize($0.rawValue) == key
        }
    }

    static func recentUses(
        from logs: [DoseLog]
    ) -> [InjectionSiteUse] {
        var latest:
            [InjectionSite: InjectionSiteUse] = [:]

        for log in logs.sorted(by: {
            $0.loggedAt > $1.loggedAt
        }) where log.route.usesInjectionSite
            && log.status != "Skipped" {
            guard let site =
                    match(log.site),
                  latest[site] == nil
            else {
                continue
            }

            latest[site] =
                InjectionSiteUse(
                    site: site,
                    lastUsedAt:
                        log.loggedAt,
                    compoundName:
                        log.compoundName,
                    protocolName:
                        log.protocolName
                )
        }

        return latest.values.sorted {
            $0.lastUsedAt > $1.lastUsedAt
        }
    }

    private static func normalize(
        _ value: String
    ) -> String {
        value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
            .replacingOccurrences(
                of: "-",
                with: " "
            )
            .split(whereSeparator: {
                $0.isWhitespace
            })
            .joined(separator: " ")
    }
}

struct InjectionSiteUse: Identifiable, Equatable {
    let site: InjectionSite
    let lastUsedAt: Date
    let compoundName: String
    let protocolName: String

    var id: InjectionSite {
        site
    }
}

import Foundation

enum LabComparisonEngine {

    struct Pair: Identifiable {
        let marker: String
        let unit: String
        let beforeValue: String
        let beforeAt: Date
        let afterValue: String
        let afterAt: Date

        var id: String {
            marker.lowercased()
            + "|"
            + unit.lowercased()
        }

        var valueText: String {
            beforeValue
            + " → "
            + afterValue
            + (unit.isEmpty ? "" : " " + unit)
        }
    }


    static func pairs(
        labs: [LabRecord],
        protocolID: UUID,
        change: Date,
        beforePeriod: AnalysisPeriod,
        afterPeriod: AnalysisPeriod
    ) -> [Pair] {
        let relevant =
            labs.filter {
                $0.protocolID == protocolID
            }

        let groups =
            Dictionary(
                grouping: relevant
            ) { lab in
                normalized(lab.marker)
                + "|"
                + normalized(lab.unit)
            }

        return groups.compactMap {
            _, records in

            let before =
                records
                    .filter {
                        $0.collectedAt < change
                        && beforePeriod
                            .contains(
                                $0.collectedAt
                            )
                    }
                    .max {
                        $0.collectedAt
                            < $1.collectedAt
                    }

            let after =
                records
                    .filter {
                        $0.collectedAt >= change
                        && afterPeriod
                            .contains(
                                $0.collectedAt
                            )
                    }
                    .min {
                        $0.collectedAt
                            < $1.collectedAt
                    }

            guard
                let before,
                let after
            else {
                return nil
            }

            return Pair(
                marker: after.marker,
                unit: after.unit,
                beforeValue:
                    before.valueText,
                beforeAt:
                    before.collectedAt,
                afterValue:
                    after.valueText,
                afterAt:
                    after.collectedAt
            )
        }
        .sorted {
            $0.marker
                .localizedCaseInsensitiveCompare(
                    $1.marker
                ) == .orderedAscending
        }
    }


    private static func normalized(
        _ value: String
    ) -> String {
        value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
    }
}

import Foundation

@MainActor enum ExportService {
    static func historyCSV(
        _ logs: [DoseLog]
    ) throws -> URL {
        let header = [
            "id",
            "recorded_at",
            "protocol",
            "compound",
            "route",
            "scheduled_amount",
            "scheduled_unit",
            "actual_amount",
            "unit",
            "vial",
            "concentration_mg_ml",
            "status",
            "site",
            "symptoms",
            "severity",
            "notes"
        ]

        let rows =
            logs.map { log in
                [
                    log.id.uuidString,
                    log.loggedAt
                        .ISO8601Format(),
                    log.protocolName,
                    log.compoundName,
                    log.routeText,
                    log.scheduledAmountText,
                    log.scheduledUnitText,
                    log.actualAmountText,
                    log.unitText,
                    log.vialName,
                    log.concentrationText
                        ?? "",
                    log.status,
                    log.site,
                    log.symptoms,
                    String(
                        log.symptomSeverity
                    ),
                    log.notes
                ]
            }

        let csv =
            ([header] + rows)
                .map {
                    $0.map(escape)
                        .joined(
                            separator: ","
                        )
                }
                .joined(
                    separator: "\r\n"
                )

        let url =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "Protocola-history-\(UUID().uuidString).csv"
                )

        try csv.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        return url
    }

    static func labsCSV(
        _ labs: [LabRecord]
    ) throws -> URL {
        let header = [
            "id",
            "collected_at",
            "protocol_id",
            "marker",
            "value",
            "unit",
            "reference_low",
            "reference_high",
            "notes"
        ]

        let rows =
            labs.map { lab in
                [
                    lab.id.uuidString,
                    lab.collectedAt
                        .ISO8601Format(),
                    lab.protocolID?
                        .uuidString
                        ?? "",
                    lab.marker,
                    lab.valueText,
                    lab.unit,
                    lab.referenceLowText
                        ?? "",
                    lab.referenceHighText
                        ?? "",
                    lab.notes
                ]
            }

        let csv =
            ([header] + rows)
                .map {
                    $0.map(escape)
                        .joined(
                            separator: ","
                        )
                }
                .joined(
                    separator: "\r\n"
                )

        let url =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    "Protocola-labs-\(UUID().uuidString).csv"
                )

        try csv.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        return url
    }


    private static func escape(
        _ value: String
    ) -> String {
        let safe =
            [
                "=",
                "+",
                "-",
                "@",
                "\t",
                "\r"
            ]
            .contains(
                String(value.prefix(1))
            )
            ? "'" + value
            : value

        return
            "\"" +
            safe.replacingOccurrences(
                of: "\"",
                with: "\"\""
            )
            + "\""
    }
}

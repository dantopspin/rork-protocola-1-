import Foundation

@MainActor enum ExportService {
    static func historyCSV(
        _ logs: [DoseLog]
    ) throws -> URL {
        let header = [
            "id",
            "protocol_id",
            "compound_id",
            "occurrence_id",
            "scheduled_at",
            "recorded_at",
            "created_at",
            "corrected_at",
            "protocol",
            "compound",
            "route",
            "scheduled_amount",
            "scheduled_unit",
            "actual_amount",
            "unit",
            "vial_id",
            "vial",
            "concentration_mg_ml",
            "syringe_units_per_ml",
            "volume_ml",
            "consumption_mg",
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
                    log.protocolID.uuidString,
                    log.compoundID.uuidString,
                    log.occurrenceID ?? "",
                    log.scheduledAt?
                        .ISO8601Format()
                        ?? "",
                    log.loggedAt
                        .ISO8601Format(),
                    log.createdAt
                        .ISO8601Format(),
                    log.correctedAt?
                        .ISO8601Format()
                        ?? "",
                    log.protocolName,
                    log.compoundName,
                    log.routeText,
                    log.scheduledAmountText,
                    log.scheduledUnitText,
                    log.actualAmountText,
                    log.unitText,
                    log.vialID?
                        .uuidString
                        ?? "",
                    log.vialName,
                    log.concentrationText
                        ?? "",
                    log.unitsPerMlText,
                    log.volumeMlText
                        ?? "",
                    log.consumptionMgText,
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
            "notes",
            "created_at",
            "updated_at"
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
                    lab.notes,
                    lab.createdAt
                        .ISO8601Format(),
                    lab.updatedAt
                        .ISO8601Format()
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


    static func protocolsCSV(
        _ protocols: [ProtocolRecord]
    ) throws -> URL {
        try writeCSV(
            name: "protocols",
            header: [
                "id",
                "name",
                "status",
                "instruction_source",
                "notes",
                "created_at"
            ],
            rows:
                protocols.map {
                    [
                        $0.id.uuidString,
                        $0.name,
                        $0.status,
                        $0.instructionSource,
                        $0.notes,
                        $0.createdAt.ISO8601Format()
                    ]
                }
        )
    }


    static func compoundsCSV(
        _ compounds: [CompoundRecord]
    ) throws -> URL {
        try writeCSV(
            name: "compounds",
            header: [
                "id",
                "protocol_id",
                "name",
                "reference_half_life_hours",
                "reference_half_life_source"
            ],
            rows:
                compounds.map {
                    [
                        $0.id.uuidString,
                        $0.protocolID.uuidString,
                        $0.name,
                        $0.referenceHalfLifeHoursText
                            ?? "",
                        $0.referenceHalfLifeSource
                            ?? ""
                    ]
                }
        )
    }


    static func scheduleRevisionsCSV(
        _ revisions: [ScheduleRevision]
    ) throws -> URL {
        try writeCSV(
            name: "schedule-revisions",
            header: [
                "id",
                "protocol_id",
                "compound_id",
                "protocol_name",
                "compound_name",
                "amount",
                "unit",
                "route",
                "vial_id",
                "configured_site",
                "schedule",
                "schedule_kind",
                "schedule_weekdays",
                "schedule_interval",
                "schedule_minutes",
                "schedule_anchor",
                "schedule_timezone",
                "cycle_on_days",
                "cycle_off_days",
                "effective_from",
                "effective_until",
                "enabled",
                "reminders"
            ],
            rows:
                revisions.map {
                    [
                        $0.id.uuidString,
                        $0.protocolID.uuidString,
                        $0.compoundID.uuidString,
                        $0.protocolName,
                        $0.compoundName,
                        $0.amountText,
                        $0.unitText,
                        $0.routeText,
                        $0.vialID?.uuidString
                            ?? "",
                        $0.configuredSite ?? "",
                        $0.config.map(
                            ScheduleDisplay.summary
                        ) ?? "",
                        $0.config?.kind.rawValue
                            ?? "",
                        $0.config?.weekdays
                            .map(String.init)
                            .joined(
                                separator: "|"
                            )
                            ?? "",
                        $0.config.map {
                            String($0.interval)
                        } ?? "",
                        $0.config?.minutes
                            .map(String.init)
                            .joined(
                                separator: "|"
                            )
                            ?? "",
                        $0.config?.anchor
                            .ISO8601Format()
                            ?? "",
                        $0.config?.timeZoneID
                            ?? "",
                        $0.config?.cycleOnDays
                            .map(String.init)
                            ?? "",
                        $0.config?.cycleOffDays
                            .map(String.init)
                            ?? "",
                        $0.effectiveFrom
                            .ISO8601Format(),
                        $0.effectiveUntil?
                            .ISO8601Format()
                            ?? "",
                        String($0.enabled),
                        String($0.reminders)
                    ]
                }
        )
    }


    static func vialsCSV(
        _ vials: [VialRecord],
        balances: [UUID: Decimal]
    ) throws -> URL {
        try writeCSV(
            name: "vials",
            header: [
                "id",
                "name",
                "compound",
                "original_mg",
                "diluent_ml",
                "concentration_mg_ml",
                "recorded_balance_mg",
                "batch",
                "supplier",
                "storage_notes",
                "expiry",
                "reconstituted_at",
                "opened_at",
                "state",
                "photo_base64",
                "created_at"
            ],
            rows:
                vials.map { vial in
                    [
                        vial.id.uuidString,
                        vial.name,
                        vial.compoundName,
                        vial.originalMgText,
                        vial.diluentMlText,
                        vial.concentration.map(
                            DoseCalculator.text
                        ) ?? "",
                        balances[vial.id].map(
                            DoseCalculator.text
                        ) ?? "",
                        vial.batch,
                        vial.supplier,
                        vial.storageNotes,
                        vial.expiry?
                            .ISO8601Format()
                            ?? "",
                        vial.reconstitutedAt?
                            .ISO8601Format()
                            ?? "",
                        vial.openedAt?
                            .ISO8601Format()
                            ?? "",
                        vial.lifecycleState.rawValue,
                        vial.photoData.map {
                            "base64:"
                            + $0.base64EncodedString()
                        } ?? "",
                        vial.createdAt
                            .ISO8601Format()
                    ]
                }
        )
    }


    static func inventoryCSV(
        _ adjustments:
            [InventoryAdjustment]
    ) throws -> URL {
        try writeCSV(
            name: "inventory-ledger",
            header: [
                "id",
                "vial_id",
                "delta_mg",
                "recorded_at"
            ],
            rows:
                adjustments.map {
                    [
                        $0.id.uuidString,
                        $0.vialID.uuidString,
                        $0.deltaMgText,
                        $0.recordedAt
                            .ISO8601Format()
                    ]
                }
        )
    }


    static func eventsCSV(
        _ events: [ProtocolEvent]
    ) throws -> URL {
        let rows =
            try events.map { event in
                let changesData =
                    try JSONEncoder()
                        .encode(
                            event.changes
                        )
                let changesJSON =
                    String(
                        data: changesData,
                        encoding: .utf8
                    ) ?? "[]"

                return [
                    event.id.uuidString,
                    event.protocolID?
                        .uuidString
                        ?? "",
                    event.title,
                    event.category,
                    event.detail,
                    changesJSON,
                    event.at.ISO8601Format()
                ]
            }

        return try writeCSV(
            name: "protocol-events",
            header: [
                "id",
                "protocol_id",
                "title",
                "category",
                "detail",
                "changes_json",
                "recorded_at"
            ],
            rows: rows
        )
    }


    private static func writeCSV(
        name: String,
        header: [String],
        rows: [[String]]
    ) throws -> URL {
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
                    "Protocola-"
                    + name
                    + ".csv"
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

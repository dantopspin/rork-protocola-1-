import Foundation
import SwiftData

@MainActor final class TrackingRepository {
    let context: ModelContext
    init(container: ModelContainer) { context = ModelContext(container); context.autosaveEnabled = false }
    func all<T: PersistentModel>(_ type: T.Type) throws -> [T] { try context.fetch(FetchDescriptor<T>()) }
    func transaction(_ operation: () throws -> Void) throws {
        do { try operation(); try context.save() } catch { context.rollback(); throw error }
    }
    func preferences() throws -> PreferencesRecord {
        if let preference = try all(PreferencesRecord.self).first { return preference }
        let preference = PreferencesRecord(); context.insert(preference); try context.save(); return preference
    }
    func balance(_ vial: VialRecord) throws -> Decimal {
        let amounts = try all(DoseLog.self).filter { $0.vialID == vial.id }.map(\.consumptionMg)
        let adjustments = try all(InventoryAdjustment.self).filter { $0.vialID == vial.id }.map(\.deltaMg)
        return try InventoryEngine.balance(originalMg: vial.originalMg, adjustmentsMg: adjustments, consumptionsMg: amounts)
    }
    func saveProtocol(_ draft: ProtocolDraft, protocolID: UUID?, compoundID: UUID?, now: Date = .now) throws {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let compoundName = draft.compound.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !compoundName.isEmpty else { throw TrackingError.invalidInput("Enter a protocol name and compound.") }
        let amount = try DoseCalculator.parse(draft.amount, label: "Amount")
        let config = try draft.config()
        let protocols = try all(ProtocolRecord.self)
        let compounds = try all(CompoundRecord.self)
        let revisions = try all(ScheduleRevision.self)
        let recordedVialID =
            draft.route.usesInjectionSite
            ? draft.vialID
            : nil
        let vial = try all(VialRecord.self).first { $0.id == recordedVialID }
        if let vial, vial.isArchived || vial.compoundName.caseInsensitiveCompare(compoundName) != .orderedSame { throw TrackingError.invalidInput("Choose an available vial for this compound.") }
        if recordedVialID != nil && vial == nil { throw TrackingError.missingRecord }
        let existing = protocols.first { $0.id == protocolID }
        let priorRevision =
            revisions
                .filter {
                    $0.compoundID == compoundID
                    && $0.isEffective(at: now)
                }
                .max {
                    $0.effectiveFrom
                    < $1.effectiveFrom
                }
        var before = existing.map { ProtocolSnapshot.values(record: $0, revision: priorRevision) } ?? [:]
        var after = ProtocolSnapshot.values(draft: draft, name: name, compound: compoundName, amount: amount, config: config, status: existing?.status ?? "Active")
        let vialRecords = try all(VialRecord.self)
        for values in [priorRevision?.vialID, recordedVialID].compactMap({ $0 }) {
            let label = vialRecords.first { $0.id == values }?.name ?? "Retained vial"
            if before["Vial"] == values.uuidString { before["Vial"] = "\(label) (\(values.uuidString))" }
            if after["Vial"] == values.uuidString { after["Vial"] = "\(label) (\(values.uuidString))" }
        }
        let changes = RecordChange.between(before, after)
        if existing != nil && compoundID != nil && changes.isEmpty { return }
        try transaction {
            let record: ProtocolRecord
            if let protocolID {
                guard let found = protocols.first(where: { $0.id == protocolID }) else { throw TrackingError.missingRecord }
                record = found
            } else { record = ProtocolRecord(name: name, instructionSource: draft.source, createdAt: draft.start); context.insert(record) }
            record.name = name; record.instructionSource = draft.source; record.notes = draft.notes
            let compound: CompoundRecord
            if let compoundID {
                guard let found = compounds.first(where: { $0.id == compoundID && $0.protocolID == record.id }) else { throw TrackingError.missingRecord }
                compound = found; compound.name = compoundName
            } else { compound = CompoundRecord(protocolID: record.id, name: compoundName); context.insert(compound) }
            let needsRevision =
                compoundID == nil
                || changes.contains {
                    [
                        "Amount",
                        "Unit",
                        "Route",
                        "Compound",
                        "Schedule",
                        "Vial",
                        "Site",
                        "Reminders",
                        "Name"
                    ]
                    .contains($0.field)
                }

            if needsRevision {
                let nextFuture =
                    revisions
                        .filter {
                            $0.compoundID
                                == compound.id
                            && $0.effectiveFrom
                                > now
                        }
                        .min {
                            $0.effectiveFrom
                                < $1.effectiveFrom
                        }

                for current in revisions
                    where current.compoundID
                        == compound.id
                    && current
                        .isEffective(
                            at: now
                        ) {
                    current.effectiveUntil = now
                }

                let from =
                    protocolID == nil
                    ? Calendar.current
                        .startOfDay(
                            for: draft.start
                        )
                    : now

                let newRevision =
                    try ScheduleRevision(
                        compound: compound,
                        protocolName: name,
                        amount: amount,
                        unit: draft.unit,
                        route: draft.route,
                        vialID: recordedVialID,
                        config: config,
                        effectiveFrom: from,
                        enabled:
                            record.status
                                == "Active",
                        reminders:
                            draft.reminders
                            && draft.kind
                                != .asRecorded,
                        configuredSite:
                            draft.route
                                .usesInjectionSite
                            && !draft.site.isEmpty
                            ? draft.site
                            : nil
                    )

                if protocolID != nil {
                    newRevision
                        .effectiveUntil =
                        nextFuture?
                            .effectiveFrom
                }

                context.insert(
                    newRevision
                )

                for future in revisions
                    where future.compoundID
                        == compound.id
                    && future.effectiveFrom
                        > now {
                    future.protocolName = name
                    future.compoundName =
                        compoundName
                }
            }

            if changes.contains(
                where: {
                    $0.field == "Name"
                }
            ),
               protocolID != nil {
                let otherCompoundIDs =
                    Set(
                        revisions
                            .filter {
                                $0.protocolID
                                    == record.id
                                && $0.compoundID
                                    != compound.id
                            }
                            .map(\.compoundID)
                    )

                for otherID
                    in otherCompoundIDs {
                    let currentOther =
                        revisions
                            .filter {
                                $0.compoundID
                                    == otherID
                                && $0.isEffective(
                                    at: now
                                )
                            }
                            .max {
                                $0.effectiveFrom
                                    < $1.effectiveFrom
                            }

                    let otherCompound =
                        compounds.first {
                            $0.id == otherID
                        }

                    guard
                        let old = currentOther,
                        let oldConfig =
                            old.config,
                        let other =
                            otherCompound
                    else {
                        continue
                    }

                    let nextFuture =
                        revisions
                            .filter {
                                $0.compoundID
                                    == otherID
                                && $0.effectiveFrom
                                    > now
                            }
                            .min {
                                $0.effectiveFrom
                                    < $1.effectiveFrom
                            }

                    old.effectiveUntil = now

                    let replacement =
                        try ScheduleRevision(
                            compound: other,
                            protocolName: name,
                            amount: old.amount,
                            unit: old.unit,
                            route: old.route,
                            vialID: old.vialID,
                            config: oldConfig,
                            effectiveFrom: now,
                            enabled: old.enabled,
                            reminders:
                                old.reminders,
                            configuredSite:
                                old.configuredSite
                        )

                    replacement.effectiveUntil =
                        nextFuture?
                            .effectiveFrom

                    context.insert(
                        replacement
                    )

                    for future in revisions
                        where future.compoundID
                            == otherID
                        && future.effectiveFrom
                            > now {
                        future.protocolName =
                            name
                    }
                }
            }
            let main = changes.filter { !["Vial", "Site"].contains($0.field) }
            let category = protocolID == nil || main.contains(where: \.isMeaningful) ? "Protocol" : "Metadata"
            if !main.isEmpty {
                let event = ProtocolEvent(protocolID: record.id, title: protocolID == nil ? "Protocol created" : "Protocol changed", detail: "", at: now)
                try event.recordChanges(main, category: category); context.insert(event)
            }
            for field in ["Vial", "Site"] {
                let values = changes.filter { $0.field == field }
                if !values.isEmpty {
                    let event = ProtocolEvent(protocolID: record.id, title: "\(field) changed", detail: "", at: now)
                    try event.recordChanges(values, category: field); context.insert(event)
                }
            }
        }
    }
    func changeStatus(
        _ record: ProtocolRecord,
        to status: String,
        now: Date = .now
    ) throws {
        let revisions =
            try all(
                ScheduleRevision.self
            )
            .filter {
                $0.protocolID == record.id
            }
        let compounds =
            try all(CompoundRecord.self)

        guard record.status != status else {
            return
        }

        let previousStatus =
            record.status

        try transaction {
            record.status = status

            let current =
                revisions.filter {
                    $0.isEffective(at: now)
                }

            for old in current {
                guard
                    let config = old.config,
                    let compound =
                        compounds.first(
                            where: {
                                $0.id
                                    == old.compoundID
                            }
                        )
                else {
                    throw TrackingError
                        .missingRecord
                }

                let nextFuture =
                    revisions
                        .filter {
                            $0.compoundID
                                == old.compoundID
                            && $0.effectiveFrom
                                > now
                        }
                        .min {
                            $0.effectiveFrom
                                < $1.effectiveFrom
                        }

                old.effectiveUntil = now

                let next =
                    try ScheduleRevision(
                        compound: compound,
                        protocolName:
                            record.name,
                        amount: old.amount,
                        unit: old.unit,
                        route: old.route,
                        vialID: old.vialID,
                        config: config,
                        effectiveFrom: now,
                        enabled:
                            status == "Active",
                        reminders:
                            old.reminders,
                        configuredSite:
                            old.configuredSite
                    )

                next.effectiveUntil =
                    nextFuture?
                        .effectiveFrom

                context.insert(next)
            }

            for future in revisions
                where future.effectiveFrom
                    > now {
                future.enabled =
                    status == "Active"
            }

            let event =
                ProtocolEvent(
                    protocolID: record.id,
                    title:
                        "Protocol "
                        + status.lowercased(),
                    detail: "",
                    at: now
                )

            try event.recordChanges(
                [
                    RecordChange(
                        field: "Status",
                        before:
                            previousStatus,
                        after: status
                    )
                ],
                category: "Protocol"
            )

            context.insert(event)
        }
    }


    func savePlannedProtocolChange(
        _ draft: ProtocolDraft,
        protocolID: UUID,
        compoundID: UUID,
        plannedRevisionID: UUID?,
        effectiveFrom: Date,
        now: Date = .now
    ) throws {
        guard effectiveFrom > now else {
            throw TrackingError.invalidInput(
                "Choose a future effective date."
            )
        }

        let protocols =
            try all(ProtocolRecord.self)
        let compounds =
            try all(CompoundRecord.self)
        let revisions =
            try all(ScheduleRevision.self)
        let vials =
            try all(VialRecord.self)

        guard
            let record =
                protocols.first(
                    where: {
                        $0.id == protocolID
                    }
                ),
            let compound =
                compounds.first(
                    where: {
                        $0.id == compoundID
                        && $0.protocolID
                            == protocolID
                    }
                )
        else {
            throw TrackingError
                .missingRecord
        }

        let amount =
            try DoseCalculator.parse(
                draft.amount,
                label: "Amount"
            )
        let config =
            try draft.config()
        let recordedVialID =
            draft.route
                .usesInjectionSite
            ? draft.vialID
            : nil
        let vial =
            vials.first {
                $0.id == recordedVialID
            }

        if let vial,
           (
                vial.isArchived
                || vial.compoundName
                    .caseInsensitiveCompare(
                        compound.name
                    )
                    != .orderedSame
           ) {
            throw TrackingError.invalidInput(
                "Choose an available vial for this compound."
            )
        }

        if recordedVialID != nil
            && vial == nil {
            throw TrackingError
                .missingRecord
        }

        var chain =
            revisions
                .filter {
                    $0.compoundID
                        == compoundID
                }
                .sorted {
                    $0.effectiveFrom
                        < $1.effectiveFrom
                }

        let target =
            plannedRevisionID.flatMap {
                id in
                chain.first {
                    $0.id == id
                }
            }

        if plannedRevisionID != nil
            && target == nil {
            throw TrackingError
                .missingRecord
        }

        if let target,
           !target.isPlanned(after: now) {
            throw TrackingError.invalidInput(
                "Only a future planned change can be edited."
            )
        }

        if chain.contains(
            where: {
                $0.id != target?.id
                && abs(
                    $0.effectiveFrom
                        .timeIntervalSince(
                            effectiveFrom
                        )
                ) < 1
            }
        ) {
            throw TrackingError.invalidInput(
                "A planned revision already starts at this time."
            )
        }

        let before =
            target.map {
                ProtocolSnapshot.values(
                    record: record,
                    revision: $0
                )
            } ?? [:]

        var after =
            ProtocolSnapshot.values(
                draft: draft,
                name: record.name,
                compound: compound.name,
                amount: amount,
                config: config,
                status: record.status
            )

        after["Effective from"] =
            effectiveFrom
                .ISO8601Format()

        try transaction {
            if let target {
                let oldIndex =
                    chain.firstIndex {
                        $0.id == target.id
                    }!

                let oldPredecessor =
                    oldIndex > 0
                    ? chain[oldIndex - 1]
                    : nil
                let oldSuccessor =
                    chain.indices
                        .contains(
                            oldIndex + 1
                        )
                    ? chain[oldIndex + 1]
                    : nil

                oldPredecessor?
                    .effectiveUntil =
                    oldSuccessor?
                        .effectiveFrom

                chain.removeAll {
                    $0.id == target.id
                }

                let predecessor =
                    chain
                        .filter {
                            $0.effectiveFrom
                                < effectiveFrom
                        }
                        .max {
                            $0.effectiveFrom
                                < $1.effectiveFrom
                        }
                let successor =
                    chain
                        .filter {
                            $0.effectiveFrom
                                > effectiveFrom
                        }
                        .min {
                            $0.effectiveFrom
                                < $1.effectiveFrom
                        }

                guard let predecessor else {
                    throw TrackingError
                        .invalidInput(
                            "A planned change needs an existing earlier revision."
                        )
                }

                predecessor.effectiveUntil =
                    effectiveFrom

                target.protocolName =
                    record.name
                target.compoundName =
                    compound.name
                target.amountText =
                    DoseCalculator.text(
                        amount
                    )
                target.unitText =
                    draft.unit.rawValue
                target.routeRawValue =
                    draft.route.rawValue
                target.vialID =
                    recordedVialID
                target.configData =
                    try JSONEncoder()
                        .encode(config)
                target.effectiveFrom =
                    effectiveFrom
                target.effectiveUntil =
                    successor?
                        .effectiveFrom
                target.enabled =
                    record.status
                        == "Active"
                target.reminders =
                    draft.reminders
                    && draft.kind
                        != .asRecorded
                target.configuredSite =
                    draft.route
                        .usesInjectionSite
                    && !draft.site.isEmpty
                    ? draft.site
                    : nil

            } else {
                let predecessor =
                    chain
                        .filter {
                            $0.effectiveFrom
                                < effectiveFrom
                        }
                        .max {
                            $0.effectiveFrom
                                < $1.effectiveFrom
                        }
                let successor =
                    chain
                        .filter {
                            $0.effectiveFrom
                                > effectiveFrom
                        }
                        .min {
                            $0.effectiveFrom
                                < $1.effectiveFrom
                        }

                guard let predecessor else {
                    throw TrackingError
                        .invalidInput(
                            "A planned change needs an existing earlier revision."
                        )
                }

                predecessor.effectiveUntil =
                    effectiveFrom

                let planned =
                    try ScheduleRevision(
                        compound: compound,
                        protocolName:
                            record.name,
                        amount: amount,
                        unit: draft.unit,
                        route: draft.route,
                        vialID:
                            recordedVialID,
                        config: config,
                        effectiveFrom:
                            effectiveFrom,
                        enabled:
                            record.status
                                == "Active",
                        reminders:
                            draft.reminders
                            && draft.kind
                                != .asRecorded,
                        configuredSite:
                            draft.route
                                .usesInjectionSite
                            && !draft.site.isEmpty
                            ? draft.site
                            : nil
                    )

                planned.effectiveUntil =
                    successor?
                        .effectiveFrom

                context.insert(planned)
            }

            var changes =
                RecordChange.between(
                    before,
                    after
                )

            if target == nil {
                changes.append(
                    RecordChange(
                        field:
                            "Effective from",
                        before: "",
                        after:
                            effectiveFrom
                                .formatted(
                                    date:
                                        .abbreviated,
                                    time:
                                        .omitted
                                )
                    )
                )
            }

            let event =
                ProtocolEvent(
                    protocolID:
                        protocolID,
                    title:
                        target == nil
                        ? "Future change planned"
                        : "Planned change updated",
                    detail: "",
                    at: now
                )

            try event.recordChanges(
                changes,
                category: "Protocol"
            )
            context.insert(event)
        }
    }


    func cancelPlannedRevision(
        _ revisionID: UUID,
        now: Date = .now
    ) throws {
        let revisions =
            try all(
                ScheduleRevision.self
            )

        guard
            let target =
                revisions.first(
                    where: {
                        $0.id == revisionID
                    }
                ),
            target.isPlanned(
                after: now
            )
        else {
            throw TrackingError
                .invalidInput(
                    "Only a future planned change can be cancelled."
                )
        }

        let chain =
            revisions
                .filter {
                    $0.compoundID
                        == target.compoundID
                    && $0.id
                        != target.id
                }
                .sorted {
                    $0.effectiveFrom
                        < $1.effectiveFrom
                }

        let predecessor =
            chain
                .filter {
                    $0.effectiveFrom
                        < target
                            .effectiveFrom
                }
                .max {
                    $0.effectiveFrom
                        < $1.effectiveFrom
                }
        let successor =
            chain
                .filter {
                    $0.effectiveFrom
                        > target
                            .effectiveFrom
                }
                .min {
                    $0.effectiveFrom
                        < $1.effectiveFrom
                }

        guard let predecessor else {
            throw TrackingError
                .invalidInput(
                    "The first revision cannot be cancelled as a planned change."
                )
        }

        try transaction {
            predecessor.effectiveUntil =
                successor?
                    .effectiveFrom

            let event =
                ProtocolEvent(
                    protocolID:
                        target.protocolID,
                    title:
                        "Planned change cancelled",
                    detail: "",
                    at: now
                )

            try event.recordChanges(
                [
                    RecordChange(
                        field:
                            "Effective from",
                        before:
                            target
                                .effectiveFrom
                                .formatted(
                                    date:
                                        .abbreviated,
                                    time:
                                        .omitted
                                ),
                        after: "Cancelled"
                    )
                ],
                category: "Protocol"
            )

            context.insert(event)
            context.delete(target)
        }
    }
    func saveCompoundHalfLife(
        compoundID: UUID,
        hoursText: String,
        source: String
    ) throws {
        let compounds =
            try all(CompoundRecord.self)

        guard
            let compound =
                compounds.first(
                    where: {
                        $0.id == compoundID
                    }
                )
        else {
            throw TrackingError
                .missingRecord
        }

        let cleanHours =
            hoursText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
        let cleanSource =
            source
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let hours: Decimal?

        if cleanHours.isEmpty {
            hours = nil
        } else {
            let parsed =
                try DoseCalculator.parse(
                    cleanHours,
                    label:
                        "Reference half-life"
                )

            guard parsed <= 100_000 else {
                throw TrackingError
                    .invalidInput(
                        "Enter a reference half-life of 100,000 hours or less."
                    )
            }

            hours = parsed
        }

        let before = [
            "Reference half-life":
                compound
                    .referenceHalfLifeHoursText
                ?? "",
            "Reference source":
                compound
                    .referenceHalfLifeSource
                ?? ""
        ]

        let after = [
            "Reference half-life":
                hours.map(
                    DoseCalculator.text
                ) ?? "",
            "Reference source":
                hours == nil
                ? ""
                : cleanSource
        ]

        let changes =
            RecordChange.between(
                before,
                after
            )

        guard !changes.isEmpty else {
            return
        }

        try transaction {
            compound
                .referenceHalfLifeHoursText =
                hours.map(
                    DoseCalculator.text
                )
            compound
                .referenceHalfLifeSource =
                hours == nil
                || cleanSource.isEmpty
                ? nil
                : cleanSource

            let event =
                ProtocolEvent(
                    protocolID:
                        compound.protocolID,
                    title:
                        "Estimated-level reference updated",
                    detail: ""
                )

            try event.recordChanges(
                changes,
                category: "Metadata"
            )

            context.insert(event)
        }
    }


    func saveVial(
        _ draft: VialDraft,
        id: UUID?,
        now: Date = .now
    ) throws {
        guard !draft.name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty,
              !draft.compound
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            throw TrackingError.invalidInput(
                "Enter a vial name and compound."
            )
        }

        let amount =
            try DoseCalculator.massMg(
                DoseCalculator.parse(
                    draft.amount,
                    label: "Vial amount"
                ),
                unit: draft.unit
            )
        let diluent =
            try DoseCalculator.parse(
                draft.diluent,
                label: "Diluent"
            )

        let reconstitutedAt =
            draft.hasReconstitutedDate
            ? draft.reconstitutedAt
            : nil
        let openedAt =
            draft.hasOpenedDate
            ? draft.openedAt
            : nil

        if let reconstitutedAt,
           reconstitutedAt > now {
            throw TrackingError.invalidInput(
                "Reconstitution date cannot be in the future."
            )
        }

        if let openedAt,
           openedAt > now {
            throw TrackingError.invalidInput(
                "Opened date cannot be in the future."
            )
        }

        let existing =
            try all(VialRecord.self)
                .first {
                    $0.id == id
                }
        let logs = try all(DoseLog.self)

        if id != nil && existing == nil {
            throw TrackingError.missingRecord
        }

        if let existing,
           logs.contains(
                where: {
                    $0.vialID == existing.id
                }
           ),
           (
                existing.originalMg != amount
                || existing.diluentMl != diluent
                || existing.compoundName
                    != draft.compound
           ) {
            throw TrackingError.invalidInput(
                "Vial strength and compound are locked after a dose is recorded. Adjust the remaining balance instead."
            )
        }

        let prior =
            try existing.map {
                try balance($0)
            }
        let updatedBase =
            (prior ?? amount)
            + (
                existing.map {
                    amount - $0.originalMg
                } ?? 0
            )
        let correction =
            draft.correctedBalance.isEmpty
            ? nil
            : try DoseCalculator.parse(
                draft.correctedBalance,
                label: "Remaining mg",
                allowZero: true
            )

        let before =
            existing.map {
                [
                    "Name": $0.name,
                    "Compound": $0.compoundName,
                    "Amount": $0.originalMgText,
                    "Diluent": $0.diluentMlText,
                    "Batch": $0.batch,
                    "Supplier": $0.supplier,
                    "Storage notes":
                        $0.storageNotes,
                    "Expiry":
                        $0.expiry?
                            .ISO8601Format()
                        ?? "",
                    "Reconstituted":
                        $0.reconstitutedAt?
                            .ISO8601Format()
                        ?? "",
                    "Opened":
                        $0.openedAt?
                            .ISO8601Format()
                        ?? "",
                    "State":
                        $0.lifecycleState
                            .rawValue,
                    "Photo":
                        $0.photoData == nil
                        ? "None"
                        : "Attached",
                    "Balance":
                        prior.map(
                            DoseCalculator.text
                        ) ?? ""
                ]
            } ?? [:]

        let after = [
            "Name": draft.name,
            "Compound": draft.compound,
            "Amount":
                DoseCalculator.text(amount),
            "Diluent":
                DoseCalculator.text(diluent),
            "Batch": draft.batch,
            "Supplier": draft.supplier,
            "Storage notes": draft.notes,
            "Expiry":
                draft.hasExpiry
                ? draft.expiry.ISO8601Format()
                : "",
            "Reconstituted":
                reconstitutedAt?
                    .ISO8601Format()
                ?? "",
            "Opened":
                openedAt?
                    .ISO8601Format()
                ?? "",
            "State": draft.state.rawValue,
            "Photo":
                draft.photoData == nil
                ? "None"
                : "Attached",
            "Balance":
                DoseCalculator.text(
                    correction ?? updatedBase
                )
        ]

        let changes =
            RecordChange.between(
                before,
                after
            )

        if existing != nil
            && changes.isEmpty {
            return
        }

        try transaction {
            let vial =
                existing
                ?? VialRecord(
                    name: draft.name,
                    compoundName:
                        draft.compound,
                    originalMg: amount,
                    diluentMl: diluent
                )

            if existing == nil {
                context.insert(vial)
            }

            vial.name = draft.name
            vial.compoundName = draft.compound
            vial.originalMgText =
                DoseCalculator.text(amount)
            vial.diluentMlText =
                DoseCalculator.text(diluent)
            vial.batch = draft.batch
            vial.supplier = draft.supplier
            vial.storageNotes = draft.notes
            vial.expiry =
                draft.hasExpiry
                ? draft.expiry
                : nil
            vial.reconstitutedAt =
                reconstitutedAt
            vial.openedAt = openedAt
            vial.lifecycleState = draft.state
            vial.photoData = draft.photoData

            if let correction {
                context.insert(
                    InventoryAdjustment(
                        vialID: vial.id,
                        deltaMg:
                            correction
                            - updatedBase
                    )
                )
            }

            let event =
                ProtocolEvent(
                    protocolID: nil,
                    title:
                        existing == nil
                        ? "Vial added"
                        : "Vial updated",
                    detail: ""
                )
            try event.recordChanges(
                changes,
                category: "Vial"
            )
            context.insert(event)
        }
    }
    func saveDose(_ draft: DoseDraft, revision: ScheduleRevision?, occurrence: ScheduledEntry?, correcting: DoseLog?, now: Date = .now) throws {
        guard ["Logged", "Skipped", "Partial", "Delayed"].contains(draft.status), draft.loggedAt <= now else { throw TrackingError.invalidInput("Choose a valid status and a recorded time that is not in the future.") }
        let amount = draft.status == "Skipped" ? Decimal.zero : try DoseCalculator.parse(draft.amount, label: "Actual amount")
        let scale = try DoseCalculator.parse(draft.unitsPerMl, label: "Syringe scale")
        let route =
            correcting?.route
            ?? revision?.route
            ?? .injection
        let recordedSite =
            route.usesInjectionSite
            ? draft.site
            : ""
        let vials = try all(VialRecord.self)
        let vialID =
            route.usesInjectionSite
            ? (
                correcting?.vialID
                ?? draft.vialID
            )
            : nil
        let vial = vials.first { $0.id == vialID }
        if vialID != nil && vial == nil { throw TrackingError.missingRecord }
        if correcting == nil, let vial, vial.isArchived { throw TrackingError.invalidInput("Select an available vial.") }
        let concentration = correcting != nil ? correcting?.concentration : vial?.concentration
        let consumption = draft.status == "Skipped" || vial == nil ? Decimal.zero : try DoseCalculator.massMg(amount, unit: draft.unit, concentration: concentration, unitsPerMl: scale)
        let volume: Decimal?
        if draft.status == "Skipped" { volume = nil }
        else if draft.unit == .mL { volume = amount }
        else if draft.unit == .units { volume = amount / scale }
        else { volume = concentration.flatMap { try? DoseCalculator.volume(amount: amount, unit: draft.unit, concentration: $0, unitsPerMl: scale) } }
        if let vial { _ = try InventoryEngine.reconcile(currentMg: balance(vial), oldConsumptionMg: correcting?.consumptionMg ?? 0, newConsumptionMg: consumption) }
        let logs = try all(DoseLog.self)
        if let correcting, !logs.contains(where: { $0.id == correcting.id }) { throw TrackingError.missingRecord }
        if correcting == nil, let occurrence, logs.contains(where: { $0.occurrenceID == occurrence.id }) { throw TrackingError.duplicateEntry }
        if correcting == nil, let revision, let vial, vial.compoundName.caseInsensitiveCompare(revision.compoundName) != .orderedSame { throw TrackingError.invalidInput("The selected vial must match the recorded compound.") }
        try transaction {
            if let log = correcting {
                let before = ["Amount": log.actualAmountText, "Unit": log.unitText, "Status": log.status, "Site": log.site, "Symptoms": log.symptoms, "Severity": String(log.symptomSeverity), "Notes": log.notes, "Recorded time": log.loggedAt.ISO8601Format()]
                log.actualAmountText = DoseCalculator.text(amount); log.unitText = draft.unit.rawValue; log.status = draft.status
                log.consumptionMgText = DoseCalculator.text(consumption); log.volumeMlText = volume.map(DoseCalculator.text); log.unitsPerMlText = DoseCalculator.text(scale)
                log.site = recordedSite; log.symptoms = draft.symptoms; log.symptomSeverity = draft.severity; log.notes = draft.notes; log.loggedAt = draft.loggedAt; log.correctedAt = now
                let after = ["Amount": log.actualAmountText, "Unit": log.unitText, "Status": log.status, "Site": log.site, "Symptoms": log.symptoms, "Severity": String(log.symptomSeverity), "Notes": log.notes, "Recorded time": log.loggedAt.ISO8601Format()]
                let event = ProtocolEvent(protocolID: log.protocolID, title: "Dose corrected", detail: "", at: now)
                try event.recordChanges(RecordChange.between(before, after), category: "Correction"); context.insert(event)
            } else {
                guard let revision else { throw TrackingError.missingRecord }
                context.insert(DoseLog(revision: revision, occurrenceID: occurrence?.id, scheduledAt: occurrence?.at, amount: amount, unit: draft.unit, vial: vial, scale: scale, consumption: consumption, volume: volume, status: draft.status, site: recordedSite, symptoms: draft.symptoms, severity: draft.severity, notes: draft.notes, loggedAt: draft.loggedAt))
            }
        }
    }
    func deleteDose(_ log: DoseLog) throws {
        guard try all(DoseLog.self).contains(where: { $0.id == log.id }) else { throw TrackingError.missingRecord }
        if let vial = try all(VialRecord.self).first(where: { $0.id == log.vialID }) { _ = try InventoryEngine.reconcile(currentMg: balance(vial), oldConsumptionMg: log.consumptionMg, newConsumptionMg: 0) }
        try transaction {
            let event = ProtocolEvent(protocolID: log.protocolID, title: "Dose deleted", detail: "")
            let snapshot = ["Compound": log.compoundName, "Amount": log.actualAmountText, "Unit": log.unitText, "Status": log.status, "Site": log.site, "Symptoms": log.symptoms, "Severity": String(log.symptomSeverity), "Notes": log.notes, "Recorded time": log.loggedAt.ISO8601Format()]
            try event.recordChanges(RecordChange.between(snapshot, [:]), category: "Correction"); context.insert(event)
            context.delete(log)
        }
    }
    func clear() throws {
        try transaction {
            try all(DoseLog.self).forEach(context.delete); try all(ScheduleRevision.self).forEach(context.delete); try all(CompoundRecord.self).forEach(context.delete)
            try all(ProtocolRecord.self).forEach(context.delete); try all(InventoryAdjustment.self).forEach(context.delete); try all(VialRecord.self).forEach(context.delete)
            try all(ProtocolEvent.self).forEach(context.delete); try all(PreferencesRecord.self).forEach(context.delete)
        }
    }
}

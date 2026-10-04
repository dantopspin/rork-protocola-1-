import Foundation

/// Deterministic consistency for a period: a scheduled entry counts as recorded when a log
/// exists and its status is not Skipped. Corrections replace the log, so an entry counts once.
struct InsightsSummary {
    struct Day: Identifiable { let date: Date; let scheduled: Int; let recorded: Int; var id: Date { date } }
    struct Site: Identifiable { let name: String; let count: Int; var id: String { name } }
    struct Symptom: Identifiable { let id: UUID; let date: Date; let name: String; let severity: Int }
    let days: [Day]
    let sites: [Site]
    let symptoms: [Symptom]
    let scheduled: Int
    let recorded: Int
    let percentage: String
    var fullyRecorded: Bool { scheduled > 0 && recorded == scheduled }
    init(store: TrackingStore, window: Int, now: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(window - 1), to: today) ?? today
        self.init(store: store, period: AnalysisPeriod(start: start, end: now), protocolID: nil)
    }
    init(store: TrackingStore, period: AnalysisPeriod, protocolID: UUID?) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: period.start)
        let window = max(1, (calendar.dateComponents([.day], from: start, to: period.end).day ?? 0) + 1)
        let entries = store.entries(start: period.start, end: period.end).filter { protocolID == nil || $0.revision.protocolID == protocolID }
        days = (0..<window).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let inDay = entries.filter { calendar.isDate($0.at, inSameDayAs: day) }
            return Day(date: day, scheduled: inDay.count, recorded: inDay.filter { $0.log != nil && $0.log?.status != "Skipped" }.count)
        }
        scheduled = entries.count; recorded = entries.filter { $0.log != nil && $0.log?.status != "Skipped" }.count
        percentage = scheduled == 0 ? "—" : "\(recorded * 100 / scheduled)%"
        let logs = store.logs.filter { period.contains($0.loggedAt) && (protocolID == nil || $0.protocolID == protocolID) }
        sites = Dictionary(grouping: logs.filter { !$0.site.isEmpty && $0.status != "Skipped" }, by: \.site).map { Site(name: $0.key, count: $0.value.count) }.sorted { $0.name < $1.name }
        symptoms = logs.filter { !$0.symptoms.isEmpty }.map { Symptom(id: $0.id, date: $0.loggedAt, name: $0.symptoms, severity: $0.symptomSeverity) }
    }
}



// MARK: - Protocol evolution

struct ProtocolEvolutionSummary {

    struct Metrics {
        let scheduled: Int
        let recordedScheduled: Int
        let loggedEntries: Int
        let skippedEntries: Int
        let partialEntries: Int
        let delayedEntries: Int
        let observations: Int

        var percentageValue: Int? {
            guard scheduled > 0 else {
                return nil
            }

            return
                recordedScheduled
                * 100
                / scheduled
        }

        var percentage: String {
            percentageValue.map {
                String($0) + "%"
            } ?? "—"
        }
    }


    struct Comparison {
        let change: ProtocolEvent
        let beforePeriod: AnalysisPeriod
        let afterPeriod: AnalysisPeriod
        let before: Metrics
        let after: Metrics

        var consistencyDelta:
            Int? {
            guard
                let beforeValue =
                    before.percentageValue,
                let afterValue =
                    after.percentageValue
            else {
                return nil
            }

            return
                afterValue - beforeValue
        }
    }


    struct SinceLastChange {
        let change: ProtocolEvent
        let period: AnalysisPeriod
        let metrics: Metrics
        let days: Int
    }


    struct CycleRun:
        Identifiable {
        let id: String
        let revisionID: UUID
        let compoundName: String
        let startedAt: Date
        let endedAt: Date
        let scheduled: Int
        let recorded: Int
        let isRestart: Bool
        let isCurrent: Bool

        var percentage: String {
            guard scheduled > 0 else {
                return "—"
            }

            return
                String(
                    recorded
                    * 100
                    / scheduled
                )
                + "%"
        }
    }


    let latestChange:
        ProtocolEvent?
    let sinceLastChange:
        SinceLastChange?
    let comparison:
        Comparison?
    let cycleRuns:
        [CycleRun]


    @MainActor
    init(
        store: TrackingStore,
        protocolID: UUID,
        now: Date = .now
    ) {
        let changes =
            store.events
                .filter {
                    $0.protocolID
                        == protocolID
                    && $0.isChangeAnchor
                    && $0.title
                        != "Protocol created"
                    && $0.at <= now
                }
                .sorted {
                    $0.at > $1.at
                }

        latestChange =
            changes.first

        if let change =
            changes.first {
            let sincePeriod =
                AnalysisPeriod(
                    start: change.at,
                    end: now
                )

            let days =
                max(
                    0,
                    Calendar.current
                        .dateComponents(
                            [.day],
                            from:
                                Calendar.current
                                    .startOfDay(
                                        for:
                                            change.at
                                    ),
                            to:
                                Calendar.current
                                    .startOfDay(
                                        for: now
                                    )
                        )
                        .day ?? 0
                )

            sinceLastChange =
                SinceLastChange(
                    change: change,
                    period: sincePeriod,
                    metrics:
                        Self.metrics(
                            store: store,
                            period:
                                sincePeriod,
                            protocolID:
                                protocolID
                        ),
                    days: days
                )

            let periods =
                AnalysisPeriod
                    .comparison(
                        change:
                            change.at,
                        now: now
                    )

            comparison =
                Comparison(
                    change: change,
                    beforePeriod:
                        periods.before,
                    afterPeriod:
                        periods.after,
                    before:
                        Self.metrics(
                            store: store,
                            period:
                                periods.before,
                            protocolID:
                                protocolID
                        ),
                    after:
                        Self.metrics(
                            store: store,
                            period:
                                periods.after,
                            protocolID:
                                protocolID
                        )
                )

        } else {
            sinceLastChange = nil
            comparison = nil
        }

        cycleRuns =
            Self.buildCycleRuns(
                store: store,
                protocolID: protocolID,
                now: now
            )
    }


    @MainActor
    private static func metrics(
        store: TrackingStore,
        period: AnalysisPeriod,
        protocolID: UUID
    ) -> Metrics {
        let entries =
            store.entries(
                start: period.start,
                end: period.end
            )
            .filter {
                $0.revision
                    .protocolID
                    == protocolID
            }

        let logs =
            store.logs.filter {
                $0.protocolID
                    == protocolID
                && period.contains(
                    $0.loggedAt
                )
            }

        let recordedScheduled =
            entries.filter {
                $0.log != nil
                && $0.log?.status
                    != "Skipped"
            }
            .count

        return Metrics(
            scheduled: entries.count,
            recordedScheduled:
                recordedScheduled,
            loggedEntries:
                logs.filter {
                    $0.status
                        != "Skipped"
                }
                .count,
            skippedEntries:
                logs.filter {
                    $0.status
                        == "Skipped"
                }
                .count,
            partialEntries:
                logs.filter {
                    $0.status
                        == "Partial"
                }
                .count,
            delayedEntries:
                logs.filter {
                    $0.status
                        == "Delayed"
                }
                .count,
            observations:
                logs.filter {
                    !$0.symptoms.isEmpty
                }
                .count
        )
    }


    @MainActor
    private static func buildCycleRuns(
        store: TrackingStore,
        protocolID: UUID,
        now: Date
    ) -> [CycleRun] {
        var runs:
            [CycleRun] = []

        for revision in store.revisions
            where revision.protocolID
                == protocolID
                && revision.enabled {
            guard
                let config =
                    revision.config,
                let onDays =
                    config.cycleOnDays,
                let offDays =
                    config.cycleOffDays,
                onDays > 0,
                offDays > 0
            else {
                continue
            }

            let revisionEnd =
                min(
                    revision.effectiveUntil
                        ?? now,
                    now
                )

            guard
                revision.effectiveFrom
                    < revisionEnd
            else {
                continue
            }

            var calendar =
                Calendar(
                    identifier:
                        .gregorian
                )

            calendar.timeZone =
                TimeZone(
                    identifier:
                        config.timeZoneID
                ) ?? .current

            let anchor =
                calendar.startOfDay(
                    for: config.anchor
                )
            let revisionStart =
                calendar.startOfDay(
                    for:
                        revision
                            .effectiveFrom
                )
            let elapsed =
                max(
                    0,
                    calendar
                        .dateComponents(
                            [.day],
                            from: anchor,
                            to: revisionStart
                        )
                        .day ?? 0
                )
            let cycleLength =
                onDays + offDays

            var index =
                max(
                    0,
                    elapsed
                    / cycleLength
                    - 1
                )
            var safety = 0

            while safety < 512 {
                guard
                    let cycleStart =
                        calendar.date(
                            byAdding: .day,
                            value:
                                index
                                * cycleLength,
                            to: anchor
                        ),
                    let onEnd =
                        calendar.date(
                            byAdding: .day,
                            value: onDays,
                            to: cycleStart
                        )
                else {
                    break
                }

                if cycleStart
                    >= revisionEnd {
                    break
                }

                if onEnd
                    > revision
                        .effectiveFrom {
                    let segmentStart =
                        max(
                            cycleStart,
                            revision
                                .effectiveFrom
                        )
                    let segmentEnd =
                        min(
                            onEnd,
                            revisionEnd
                        )

                    if segmentStart
                        < segmentEnd {
                        let entries =
                            store.entries(
                                start:
                                    segmentStart,
                                end:
                                    segmentEnd
                            )
                            .filter {
                                $0.revision.id
                                    == revision.id
                            }

                        let recorded =
                            entries.filter {
                                $0.log != nil
                                && $0.log?
                                    .status
                                    != "Skipped"
                            }
                            .count

                        runs.append(
                            CycleRun(
                                id:
                                    revision.id
                                        .uuidString
                                    + ":"
                                    + String(
                                        Int(
                                            segmentStart
                                                .timeIntervalSince1970
                                        )
                                    ),
                                revisionID:
                                    revision.id,
                                compoundName:
                                    revision
                                        .compoundName,
                                startedAt:
                                    segmentStart,
                                endedAt:
                                    segmentEnd,
                                scheduled:
                                    entries.count,
                                recorded:
                                    recorded,
                                isRestart:
                                    index > 0
                                    && cycleStart
                                        >= revision
                                            .effectiveFrom,
                                isCurrent:
                                    revision
                                        .isEffective(
                                            at: now
                                        )
                                    && cycleStart
                                        <= now
                                    && onEnd
                                        > now
                            )
                        )
                    }
                }

                index += 1
                safety += 1
            }
        }

        return Array(
            runs
                .sorted {
                    $0.startedAt
                        > $1.startedAt
                }
                .prefix(24)
        )
    }
}

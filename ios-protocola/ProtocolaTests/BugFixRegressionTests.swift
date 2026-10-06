import Foundation
import Testing
import SwiftData
import UserNotifications
@testable import Protocola

@MainActor
struct BugFixRegressionTests {

    private func repository() throws -> TrackingRepository {
        TrackingRepository(
            container: try LocalPersistence.container(inMemory: true)
        )
    }

    private func labDraft(_ value: String) -> LabDraft {
        var draft = LabDraft()
        draft.marker = "Marker"
        draft.value = value
        draft.collectedAt = Date.now.addingTimeInterval(-3_600)
        return draft
    }

    // Lab values used Decimal(string:), which keeps a numeric prefix and drops
    // the rest ("12abc" -> 12).
    @Test
    func labValueRejectsTrailingGarbage() throws {
        let repo = try repository()

        #expect(throws: TrackingError.self) {
            try repo.saveLab(labDraft("12abc"), id: nil)
        }
        #expect(try repo.all(LabRecord.self).isEmpty)
    }

    @Test
    func labValueAcceptsSignedAndLeadingDotValues() throws {
        let repo = try repository()

        try repo.saveLab(labDraft("-2.5"), id: nil)
        try repo.saveLab(labDraft(".5"), id: nil)

        let values = Set(try repo.all(LabRecord.self).map(\.valueText))
        #expect(values == ["-2.5", "0.5"])
    }

    // A protocol recorded with a future start date has only a planned first
    // revision. Editing it used to fail with "needs an existing earlier
    // revision", locking the protocol until its start date.
    @Test
    func futureStartProtocolFirstRevisionIsEditable() throws {
        let repo = try repository()
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        var draft = ProtocolDraft()
        draft.name = "Later"
        draft.compound = "Compound"
        draft.amount = "1"
        draft.unit = .mg
        draft.kind = .daily
        draft.timeZoneID = "UTC"
        draft.start = now.addingTimeInterval(5 * 86_400)

        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil, now: now)

        let record = try #require(repo.all(ProtocolRecord.self).first)
        let compound = try #require(repo.all(CompoundRecord.self).first)
        let first = try #require(repo.all(ScheduleRevision.self).first)
        #expect(first.isPlanned(after: now))

        var edit = ProtocolDraft(protocolRecord: record, revision: first)
        edit.amount = "2"

        try repo.savePlannedProtocolChange(
            edit,
            protocolID: record.id,
            compoundID: compound.id,
            plannedRevisionID: first.id,
            effectiveFrom: first.effectiveFrom,
            now: now
        )

        let revisions = try repo.all(ScheduleRevision.self)
        #expect(revisions.count == 1)
        #expect(revisions.first?.amountText == "2")
        #expect(revisions.first?.effectiveUntil == nil)
    }

    @Test
    func plannedChangeWithoutPredecessorStillRejected() throws {
        let repo = try repository()
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        var draft = ProtocolDraft()
        draft.name = "Now"
        draft.compound = "Compound"
        draft.amount = "1"
        draft.unit = .mg
        draft.timeZoneID = "UTC"
        draft.start = now.addingTimeInterval(5 * 86_400)
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil, now: now)

        let record = try #require(repo.all(ProtocolRecord.self).first)
        let compound = try #require(repo.all(CompoundRecord.self).first)
        let first = try #require(repo.all(ScheduleRevision.self).first)

        // A brand-new plan dated before the first revision has no predecessor.
        #expect(throws: TrackingError.self) {
            try repo.savePlannedProtocolChange(
                ProtocolDraft(protocolRecord: record, revision: first),
                protocolID: record.id,
                compoundID: compound.id,
                plannedRevisionID: nil,
                effectiveFrom: now.addingTimeInterval(86_400),
                now: now
            )
        }
    }

    // The CSV formula guard prefixed every value starting with "-", turning
    // negative inventory deltas and lab values into text.
    @Test
    func csvKeepsSignedNumbersNumericButGuardsFormulas() {
        #expect(ExportService.escape("-0.5") == "\"-0.5\"")
        #expect(ExportService.escape("-2") == "\"-2\"")
        #expect(ExportService.escape("=SUM(A1)") == "\"'=SUM(A1)\"")
        #expect(ExportService.escape("-cmd") == "\"'-cmd\"")
        #expect(ExportService.escape("@x") == "\"'@x\"")
    }

    @Test
    func wholeCountFloorsFullPrecisionQuotients() {
        #expect(TrackingStore.wholeCount(Decimal(10) / Decimal(3)) == 3)
        #expect(TrackingStore.wholeCount(Decimal(2) / Decimal(3)) == 0)
        #expect(TrackingStore.wholeCount(Decimal(40)) == 40)
        #expect(TrackingStore.wholeCount(Decimal(-1)) == 0)
    }

    @Test
    func notificationAuthorizationDeliveryStatesAreExplicit() {
        #expect(
            NotificationService
                .allowsDelivery(
                    .authorized
                )
        )
        #expect(
            NotificationService
                .allowsDelivery(
                    .provisional
                )
        )
        #expect(
            NotificationService
                .allowsDelivery(
                    .ephemeral
                )
        )
        #expect(
            !NotificationService
                .allowsDelivery(
                    .notDetermined
                )
        )
        #expect(
            !NotificationService
                .allowsDelivery(
                    .denied
                )
        )
    }


    // Cycle-restart notices were delivered at midnight of the restart day.
    @Test
    func cycleRestartNoticeIsEveningBefore() throws {
        let config = ScheduleConfig(
            kind: .daily,
            weekdays: [],
            interval: 1,
            minutes: [480],
            anchor: Date(timeIntervalSince1970: 1_800_000_000),
            timeZoneID: "UTC",
            cycleOnDays: 2,
            cycleOffDays: 2
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let restart = calendar.startOfDay(
            for: Date(timeIntervalSince1970: 1_800_400_000)
        )
        let now =
            restart.addingTimeInterval(
                -2 * 86_400
            )

        let notice = try #require(
            CycleDisplay.restartNoticeDate(
                config,
                restart: restart,
                now: now
            )
        )

        #expect(notice < restart)
        #expect(restart.timeIntervalSince(notice) == 4 * 3_600)
        #expect(calendar.component(.hour, from: notice) == 20)
    }


    @Test
    func cycleRestartNoticeFallsForwardAfterEightPM() throws {
        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: "UTC")!

        let restart =
            try #require(
                calendar.date(
                    from:
                        DateComponents(
                            year: 2027,
                            month: 1,
                            day: 16
                        )
                )
            )
        let now =
            try #require(
                calendar.date(
                    from:
                        DateComponents(
                            year: 2027,
                            month: 1,
                            day: 15,
                            hour: 21,
                            minute: 17
                        )
                )
            )

        let config =
            ScheduleConfig(
                kind: .daily,
                weekdays: [],
                interval: 1,
                minutes: [480],
                anchor: now,
                timeZoneID: "UTC",
                cycleOnDays: 2,
                cycleOffDays: 2
            )

        let notice =
            try #require(
                CycleDisplay
                    .restartNoticeDate(
                        config,
                        restart: restart,
                        now: now
                    )
            )

        #expect(notice > now)
        #expect(notice < restart)
        #expect(
            calendar.component(
                .hour,
                from: notice
            ) == 22
        )
        #expect(
            calendar.component(
                .minute,
                from: notice
            ) == 0
        )
    }
}

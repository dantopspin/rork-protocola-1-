import Foundation
import Testing
import SwiftData
@testable import Protocola

@MainActor
struct ComponentIntegrationTests {

    @Test
    func heatmapCountsExcludeSkippedAndGroupByDay() throws {
        let repo = TrackingRepository(
            container: try LocalPersistence.container(inMemory: true)
        )

        var draft = ProtocolDraft()
        draft.name = "P"
        draft.compound = "C"
        draft.amount = "1"
        draft.unit = .mg
        draft.kind = .asRecorded
        try repo.saveProtocol(draft, protocolID: nil, compoundID: nil)

        let revision = try #require(repo.all(ScheduleRevision.self).first)
        let now = Date.now

        var morning = DoseDraft(revision: revision)
        morning.loggedAt = now.addingTimeInterval(-60)
        try repo.saveDose(morning, revision: revision, occurrence: nil, correcting: nil)

        var again = DoseDraft(revision: revision)
        again.loggedAt = now.addingTimeInterval(-30)
        try repo.saveDose(again, revision: revision, occurrence: nil, correcting: nil)

        var skipped = DoseDraft(revision: revision)
        skipped.status = "Skipped"
        skipped.loggedAt = now.addingTimeInterval(-10)
        try repo.saveDose(skipped, revision: revision, occurrence: nil, correcting: nil)

        let counts = RecordedEntriesHeatmap.counts(
            try repo.all(DoseLog.self)
        )

        let day = Calendar.current.startOfDay(for: now.addingTimeInterval(-60))
        let dayOfLast = Calendar.current.startOfDay(for: now.addingTimeInterval(-30))

        #expect(counts.values.reduce(0, +) == 2)
        if day == dayOfLast {
            #expect(counts[day] == 2)
        }
    }
}

@MainActor
struct HeatmapGridTests {

    @Test
    func levelsScaleToBusiestDay() {
        #expect(RecordedEntriesHeatmap.level(count: 0, maximum: 4) == 0)
        #expect(RecordedEntriesHeatmap.level(count: 1, maximum: 4) == 1)
        #expect(RecordedEntriesHeatmap.level(count: 2, maximum: 4) == 2)
        #expect(RecordedEntriesHeatmap.level(count: 4, maximum: 4) == 4)
        #expect(RecordedEntriesHeatmap.level(count: 1, maximum: 1) == 4)
        #expect(RecordedEntriesHeatmap.level(count: 5, maximum: 0) == 0)
    }

    @Test
    func gridCoversWholeWeeksEndingThisWeek() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let today = calendar.startOfDay(for: now)
        let old = calendar.date(byAdding: .day, value: -400, to: today)!

        let grid = HeatmapGrid(
            counts: [today: 2, old: 9],
            weeks: 20,
            now: now,
            calendar: calendar
        )

        #expect(grid.days.count == 140)
        #expect(calendar.component(.weekday, from: try #require(grid.days.first)) == 2)
        #expect(grid.days.contains(today))
        // Out-of-range days are ignored, so they never set the scale.
        #expect(grid.maximum == 2)
        #expect(grid.count(on: today) == 2)
        #expect(grid.shift(today, by: 1) == nil)
        #expect(grid.shift(today, by: -1) != nil)
    }
}

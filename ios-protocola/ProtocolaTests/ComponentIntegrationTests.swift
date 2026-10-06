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

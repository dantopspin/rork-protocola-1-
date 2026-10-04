import Foundation

struct ScheduledEntry: Identifiable {
    let id: String
    let revision: ScheduleRevision
    let at: Date
    let log: DoseLog?
}

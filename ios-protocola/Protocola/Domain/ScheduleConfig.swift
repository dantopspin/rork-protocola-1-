import Foundation

nonisolated struct ScheduleConfig: Codable, Equatable, Sendable {
    enum Kind: String, Codable, CaseIterable, Identifiable, Sendable {
        case daily = "Daily", weekdays = "Specific weekdays", everyNDays = "Every number of days", weekly = "Weekly", timesPerWeek = "Multiple times per week", asRecorded = "As recorded"
        var id: String { rawValue }
    }
    var kind: Kind
    var weekdays: [Int]
    var interval: Int
    var minutes: [Int]
    var anchor: Date
    var timeZoneID: String
    func validate() throws {
        guard interval > 0, interval <= 365, minutes.allSatisfy({ (0..<1440).contains($0) }), Set(minutes).count == minutes.count else { throw TrackingError.invalidInput("Check the interval and recorded times.") }
        if kind != .asRecorded && minutes.isEmpty { throw TrackingError.invalidInput("Enter at least one scheduled time.") }
        if [.weekdays, .weekly, .timesPerWeek].contains(kind) {
            guard !weekdays.isEmpty, weekdays.allSatisfy({ (1...7).contains($0) }), kind != .weekly || weekdays.count == 1 else { throw TrackingError.invalidInput("Choose the weekdays in your existing schedule.") }
        }
    }
}

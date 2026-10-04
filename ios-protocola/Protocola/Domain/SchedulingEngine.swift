import Foundation

nonisolated enum SchedulingEngine {
    /// Half-open effective intervals keep prior schedules intact and avoid duplicate transitions.
    static func occurrences(config: ScheduleConfig, effectiveFrom: Date, effectiveUntil: Date?, start: Date, end: Date) -> [Date] {
        guard (try? config.validate()) != nil, config.kind != .asRecorded, start < end else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: config.timeZoneID) ?? .current
        var day = calendar.startOfDay(for: max(start, effectiveFrom))
        let stop = min(end, effectiveUntil ?? end)
        var result: [Date] = []
        while day < stop {
            let difference = calendar.dateComponents([.day], from: calendar.startOfDay(for: config.anchor), to: day).day ?? -1
            let weekday = calendar.component(.weekday, from: day)
            let scheduled: Bool
            switch config.kind {
            case .daily: scheduled = difference >= 0
            case .weekly, .weekdays, .timesPerWeek: scheduled = difference >= 0 && config.weekdays.contains(weekday)
            case .everyNDays: scheduled = difference >= 0 && difference % config.interval == 0
            case .asRecorded: scheduled = false
            }
            if scheduled {
                for minute in config.minutes.sorted() {
                    // Use the next valid wall-clock time through DST gaps; only first repeated time.
                    if let at = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: day, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward), at >= start, at >= effectiveFrom, at < stop {
                        result.append(at)
                    }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day), next > day else { break }
            day = next
        }
        return Array(Set(result)).sorted()
    }
    static func occurrenceKey(compoundID: UUID, revisionID: UUID, at: Date) -> String {
        "\(compoundID.uuidString):\(revisionID.uuidString):\(Int(at.timeIntervalSince1970))"
    }
}

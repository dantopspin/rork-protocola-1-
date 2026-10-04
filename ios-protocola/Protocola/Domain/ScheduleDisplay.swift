import Foundation

enum ScheduleDisplay {

    static func kindLabel(
        _ kind: ScheduleConfig.Kind
    ) -> String {
        switch kind {
        case .daily:
            return "Daily"

        case .weekdays:
            return "Specific weekdays"

        case .everyNDays:
            return "Every N days"

        case .weekly:
            return "Weekly"

        case .timesPerWeek:
            return "Multiple times per week"

        case .asRecorded:
            return "As recorded"
        }
    }

    static func summary(
        _ config: ScheduleConfig
    ) -> String {
        if config.kind == .asRecorded {
            return "As recorded"
        }

        let times =
            config.minutes
                .sorted()
                .map {
                    timeText(
                        minute: $0,
                        timeZoneID:
                            config.timeZoneID
                    )
                }
                .joined(separator: ", ")

        switch config.kind {
        case .daily:
            return
                times.isEmpty
                ? "Daily"
                : "Daily at " + times

        case .weekly:
            let day =
                config.weekdays.first
                    .map(weekdayName)
                ?? "Weekly"

            return
                times.isEmpty
                ? day
                : day + " at " + times

        case .weekdays,
             .timesPerWeek:
            let days =
                config.weekdays
                    .sorted()
                    .map(weekdayShort)
                    .joined(separator: ", ")

            return
                days
                + (
                    times.isEmpty
                    ? ""
                    : " · " + times
                )

        case .everyNDays:
            return
                "Every "
                + String(config.interval)
                + (
                    config.interval == 1
                    ? " day"
                    : " days"
                )
                + (
                    times.isEmpty
                    ? ""
                    : " · " + times
                )

        case .asRecorded:
            return "As recorded"
        }
    }


    static func timeText(
        minute: Int,
        timeZoneID: String
    ) -> String {
        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            TimeZone(identifier: timeZoneID)
            ?? .current

        let date =
            calendar.date(
                bySettingHour:
                    minute / 60,
                minute:
                    minute % 60,
                second: 0,
                of: .now
            )
            ?? .now

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }


    private static func weekdayName(
        _ value: Int
    ) -> String {
        let names =
            Calendar.current.weekdaySymbols

        guard (1...7).contains(value) else {
            return "Weekly"
        }

        return names[value - 1]
    }


    private static func weekdayShort(
        _ value: Int
    ) -> String {
        let names =
            Calendar.current
                .shortWeekdaySymbols

        guard (1...7).contains(value) else {
            return "—"
        }

        return names[value - 1]
    }
}

import Foundation

enum CycleDisplay {

    static func nextRestart(
        _ config: ScheduleConfig,
        after date: Date = .now
    ) -> Date? {
        guard
            let phase =
                config.cyclePhase(at: date),
            let offDays =
                config.cycleOffDays
        else {
            return nil
        }

        switch phase.state {
        case .off:
            return
                phase.nextTransition > date
                ? phase.nextTransition
                : nil

        case .on:
            var calendar =
                Calendar(
                    identifier:
                        .gregorian
                )

            calendar.timeZone =
                config.timeZone

            guard
                let restart =
                    calendar.date(
                        byAdding: .day,
                        value: offDays,
                        to:
                            phase.nextTransition
                    ),
                restart > date
            else {
                return nil
            }

            return restart
        }
    }


    /// Delivery time for a cycle-restart notice. `nextRestart` is the start
    /// of the restart day (midnight in the schedule's time zone), which is
    /// not a sensible moment for a sounding notification, so the notice is
    /// delivered at 20:00 on the evening before the cycle resumes.
    static func restartNoticeDate(
        _ config: ScheduleConfig,
        restart: Date
    ) -> Date? {
        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            config.timeZone

        guard
            let dayBefore =
                calendar.date(
                    byAdding: .day,
                    value: -1,
                    to:
                        calendar.startOfDay(
                            for: restart
                        )
                )
        else {
            return nil
        }

        return calendar.date(
            bySettingHour: 20,
            minute: 0,
            second: 0,
            of: dayBefore
        )
    }


    static func status(
        _ config: ScheduleConfig,
        at date: Date = .now
    ) -> String? {
        guard
            let phase =
                config.cyclePhase(at: date)
        else {
            return nil
        }

        switch phase.state {
        case .on:
            return
                "ON · day "
                + String(phase.day)
                + " of "
                + String(phase.totalDays)

        case .off:
            var calendar =
                Calendar(identifier: .gregorian)

            calendar.timeZone =
                config.timeZone

            let today =
                calendar.startOfDay(
                    for: date
                )

            let restart =
                calendar.startOfDay(
                    for:
                        phase.nextTransition
                )

            let days =
                max(
                    0,
                    calendar
                        .dateComponents(
                            [.day],
                            from: today,
                            to: restart
                        )
                        .day ?? 0
                )

            if days == 0 {
                return "OFF · resumes today"
            }

            return
                "OFF · resumes in "
                + String(days)
                + (
                    days == 1
                    ? " day"
                    : " days"
                )
        }
    }
}

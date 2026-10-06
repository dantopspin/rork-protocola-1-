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
                TimeZone(
                    identifier:
                        config.timeZoneID
                ) ?? .current

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


    /// Delivery time for a cycle-restart notice. The preferred slot is
    /// 20:00 on the evening before the cycle resumes. If Protocola is opened
    /// after that slot but before midnight, use the next stable whole-hour
    /// slot that still leaves a small buffer before the restart. This keeps
    /// the reminder future-dated without moving it on every app resync.
    static func restartNoticeDate(
        _ config: ScheduleConfig,
        restart: Date,
        now: Date = .now
    ) -> Date? {
        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            TimeZone(
                identifier:
                    config.timeZoneID
            ) ?? .current

        let restartDay =
            calendar.startOfDay(
                for: restart
            )

        guard
            now < restartDay,
            let dayBefore =
                calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: restartDay
                ),
            let preferred =
                calendar.date(
                    bySettingHour: 20,
                    minute: 0,
                    second: 0,
                    of: dayBefore
                )
        else {
            return nil
        }

        if preferred > now {
            return preferred
        }

        let deadline =
            restartDay
                .addingTimeInterval(
                    -5 * 60
                )

        guard deadline > now else {
            return nil
        }

        if let hour =
            calendar.dateInterval(
                of: .hour,
                for: now
            )?.end,
           hour <= deadline {
            return hour
        }

        return deadline
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
                TimeZone(
                    identifier:
                        config.timeZoneID
                ) ?? .current

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

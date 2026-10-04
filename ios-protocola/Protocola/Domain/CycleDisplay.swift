import Foundation

enum CycleDisplay {

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

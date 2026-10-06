import Foundation

nonisolated struct ScheduleConfig: Codable, Equatable, Sendable {

    enum Kind: String, Codable, CaseIterable, Identifiable, Sendable {
        case daily = "Daily"
        case weekdays = "Specific weekdays"
        case everyNDays = "Every number of days"
        case weekly = "Weekly"
        case timesPerWeek = "Multiple times per week"
        /// Legacy raw value retained so existing encoded schedules keep decoding.
        /// The user-facing label is "As needed".
        case asRecorded = "As recorded"

        var id: String { rawValue }
    }

    struct CyclePhase: Equatable, Sendable {
        enum State: Equatable, Sendable {
            case on
            case off
        }

        let state: State
        let day: Int
        let totalDays: Int
        let nextTransition: Date
    }

    var kind: Kind
    var weekdays: [Int]
    var interval: Int
    var minutes: [Int]
    var anchor: Date
    var timeZoneID: String

    /// Optional ON/OFF cycle stored inside the revision's encoded schedule,
    /// avoiding a separate persistence object and preserving old revisions.
    var cycleOnDays: Int? = nil
    var cycleOffDays: Int? = nil

    /// When true, times are wall-clock times in whatever time zone the iPhone
    /// is in (8:00 PM stays 8:00 PM when travelling). When false or absent
    /// (every schedule recorded before this option), times stay in
    /// `timeZoneID`.
    var followsDeviceTimeZone: Bool? = nil

    /// The zone this schedule's times are read in right now.
    var timeZone: TimeZone {
        followsDeviceTimeZone == true
            ? .current
            : TimeZone(identifier: timeZoneID) ?? .current
    }

    var hasCycle: Bool {
        guard
            let on = cycleOnDays,
            let off = cycleOffDays
        else {
            return false
        }

        return on > 0 && off > 0
    }

    func validate() throws {
        guard
            interval > 0,
            interval <= 365,
            minutes.allSatisfy({
                (0..<1440).contains($0)
            }),
            Set(minutes).count == minutes.count
        else {
            throw TrackingError.invalidInput(
                "Check the interval and recorded times."
            )
        }

        if kind != .asRecorded && minutes.isEmpty {
            throw TrackingError.invalidInput(
                "Enter at least one scheduled time."
            )
        }

        if [
            .weekdays,
            .weekly,
            .timesPerWeek
        ]
        .contains(kind) {
            guard
                !weekdays.isEmpty,
                weekdays.allSatisfy({
                    (1...7).contains($0)
                }),
                kind != .weekly
                    || weekdays.count == 1
            else {
                throw TrackingError.invalidInput(
                    "Choose the weekdays in your existing schedule."
                )
            }
        }

        if cycleOnDays != nil
            || cycleOffDays != nil {
            guard
                let on = cycleOnDays,
                let off = cycleOffDays,
                on > 0,
                off > 0,
                on <= 3650,
                off <= 3650
            else {
                throw TrackingError.invalidInput(
                    "Check the ON and OFF cycle durations."
                )
            }
        }
    }


    func cyclePhase(
        at date: Date
    ) -> CyclePhase? {
        guard
            let on = cycleOnDays,
            let off = cycleOffDays,
            on > 0,
            off > 0
        else {
            return nil
        }

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone = timeZone

        let start =
            calendar.startOfDay(
                for: anchor
            )

        let day =
            calendar.startOfDay(
                for: date
            )

        let elapsed =
            calendar.dateComponents(
                [.day],
                from: start,
                to: day
            ).day ?? 0

        guard elapsed >= 0 else {
            return nil
        }

        let length = on + off
        let offset = elapsed % length

        if offset < on {
            let transition =
                calendar.date(
                    byAdding: .day,
                    value: on - offset,
                    to: day
                ) ?? day

            return CyclePhase(
                state: .on,
                day: offset + 1,
                totalDays: on,
                nextTransition:
                    transition
            )
        }

        let offOffset =
            offset - on

        let transition =
            calendar.date(
                byAdding: .day,
                value: off - offOffset,
                to: day
            ) ?? day

        return CyclePhase(
            state: .off,
            day: offOffset + 1,
            totalDays: off,
            nextTransition:
                transition
        )
    }


    func isCycleActive(
        at date: Date
    ) -> Bool {
        cyclePhase(at: date)?
            .state != .off
    }
}

import Foundation

struct ProtocolDraft {
    var name: String = ""
    var compound: String = ""
    var amount: String = ""
    var unit: AmountUnit = .mcg
    var route: AdministrationRoute = .injection
    var kind: ScheduleConfig.Kind = .daily
    var weekdays: Set<Int> = []
    var interval: Int = 2
    var times: [RecordedTime] = [RecordedTime()]
    var start: Date = .now
    var source: String = "Personal record"
    var notes: String = ""
    var vialID: UUID?
    var reminders: Bool = false
    var site: String = ""
    var cycleEnabled: Bool = false
    var cycleOnDays: Int = 56
    var cycleOffDays: Int = 28
    var timeZoneID: String = TimeZone.current.identifier

    func config() throws -> ScheduleConfig {
        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            TimeZone(
                identifier: timeZoneID
            ) ?? .current

        let value =
            ScheduleConfig(
                kind: kind,
                weekdays:
                    weekdays.sorted(),
                interval: interval,
                minutes:
                    kind == .asRecorded
                    ? []
                    : times.map {
                        calendar.component(
                            .hour,
                            from: $0.date
                        ) * 60
                        + calendar.component(
                            .minute,
                            from: $0.date
                        )
                    },
                anchor: start,
                timeZoneID: timeZoneID,
                cycleOnDays:
                    cycleEnabled
                    && kind != .asRecorded
                    ? cycleOnDays
                    : nil,
                cycleOffDays:
                    cycleEnabled
                    && kind != .asRecorded
                    ? cycleOffDays
                    : nil
            )

        try value.validate()
        return value
    }

    init() {}

    init(
        protocolRecord: ProtocolRecord,
        revision: ScheduleRevision
    ) {
        name = protocolRecord.name
        compound = revision.compoundName
        amount = revision.amountText
        unit = revision.unit
        route = revision.route
        source =
            protocolRecord.instructionSource
        notes = protocolRecord.notes
        vialID = revision.vialID
        reminders = revision.reminders
        site =
            revision.configuredSite
            ?? ""

        if let config = revision.config {
            kind = config.kind
            weekdays =
                Set(config.weekdays)
            interval = config.interval
            start = config.anchor
            timeZoneID =
                config.timeZoneID
            cycleEnabled =
                config.hasCycle
            cycleOnDays =
                config.cycleOnDays
                ?? 56
            cycleOffDays =
                config.cycleOffDays
                ?? 28

            var calendar =
                Calendar(identifier: .gregorian)

            calendar.timeZone =
                TimeZone(
                    identifier:
                        config.timeZoneID
                ) ?? .current

            times =
                config.minutes
                    .compactMap {
                        calendar.date(
                            bySettingHour:
                                $0 / 60,
                            minute:
                                $0 % 60,
                            second: 0,
                            of: .now
                        )
                        .map {
                            RecordedTime(
                                date: $0
                            )
                        }
                    }

            if times.isEmpty {
                times = [
                    RecordedTime()
                ]
            }
        }
    }
}

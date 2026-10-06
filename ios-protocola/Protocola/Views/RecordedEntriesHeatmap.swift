import SwiftUI

/// Calendar of recorded (non-skipped) entries per day for one protocol.
///
/// Columns are weeks (oldest leading), rows are weekdays in the calendar's
/// order. Tap a day, or use VoiceOver's adjustable action, to read it.
///
/// There is deliberately no streak: many protocols are not daily (every N
/// days, weekdays, ON/OFF cycles, as needed), so a consecutive-day count
/// would read as a target Protocola does not set.
struct RecordedEntriesHeatmap: View {
    let logs: [DoseLog]

    static let weeks = 20

    @State private var width: CGFloat = 0
    @State private var selected: Date?

    var body: some View {
        let grid = HeatmapGrid(
            counts: Self.counts(logs),
            weeks: Self.weeks
        )
        let metrics = Metrics(
            width: width,
            weeks: Self.weeks
        )

        return EditorialSection(
            "Recorded entries"
        ) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceS
            ) {
                Canvas { context, _ in
                    draw(
                        grid,
                        metrics: metrics,
                        in: &context
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: metrics.height,
                    maxHeight: metrics.height
                )
                .onGeometryChange(
                    for: CGFloat.self
                ) { proxy in
                    proxy.size.width
                } action: { newWidth in
                    width = newWidth
                }
                .contentShape(.rect)
                .onTapGesture { location in
                    guard
                        let day = grid.day(
                            at: metrics.index(at: location)
                        ),
                        day <= grid.today
                    else {
                        return
                    }

                    selected =
                        selected == day ? nil : day
                }
                .accessibilityElement()
                .accessibilityLabel(
                    "Recorded entries, last \(Self.weeks) weeks"
                )
                .accessibilityValue(
                    accessibilityValue(grid)
                )
                .accessibilityAdjustableAction { direction in
                    moveSelection(
                        direction,
                        in: grid
                    )
                }

                HStack(
                    alignment: .center,
                    spacing: Theme.spaceXS
                ) {
                    Text(rangeLabel(grid))
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()

                    Spacer(minLength: Theme.spaceXS)

                    legend(metrics)
                }

                if let selected {
                    RecordRow(
                        label: selected.formatted(
                            .dateTime
                                .weekday(.abbreviated)
                                .day()
                                .month(.abbreviated)
                        ),
                        value: Self.entriesText(
                            grid.count(on: selected)
                        )
                    )
                    .transition(.opacity)
                } else {
                    Text(
                        "Darker days have more recorded entries. Skipped entries are not counted."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            .trackingStateAnimation(value: selected)
        }
    }
}


// MARK: - Data

extension RecordedEntriesHeatmap {

    /// Entries per local day. Skipped entries record that nothing was
    /// administered, so they are excluded.
    static func counts(
        _ logs: [DoseLog],
        calendar: Calendar = .current
    ) -> [Date: Int] {
        logs
            .filter {
                $0.status != "Skipped"
            }
            .reduce(into: [:]) { result, log in
                result[
                    calendar.startOfDay(
                        for: log.loggedAt
                    ),
                    default: 0
                ] += 1
            }
    }

    /// Level 0 (none) to 4 (busiest day in view), relative to the maximum.
    static func level(
        count: Int,
        maximum: Int
    ) -> Int {
        guard count > 0, maximum > 0 else {
            return 0
        }

        return min(
            4,
            max(
                1,
                Int(
                    (
                        Double(count) * 4
                        / Double(maximum)
                    )
                    .rounded(.up)
                )
            )
        )
    }

    static func entriesText(
        _ count: Int
    ) -> String {
        switch count {
        case 0:
            "No recorded entries"
        case 1:
            "1 entry"
        default:
            "\(count) entries"
        }
    }
}


/// Week-column grid of days ending with the week that contains today.
struct HeatmapGrid {
    let counts: [Date: Int]
    let days: [Date]
    let today: Date
    let maximum: Int
    private let calendar: Calendar

    init(
        counts: [Date: Int],
        weeks: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        self.calendar = calendar
        today = calendar.startOfDay(for: now)

        let weekStart =
            calendar.dateInterval(
                of: .weekOfYear,
                for: today
            )?.start ?? today
        let first =
            calendar.date(
                byAdding: .day,
                value: -7 * (max(weeks, 1) - 1),
                to: weekStart
            ) ?? weekStart

        days = (0..<(max(weeks, 1) * 7)).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: first
            )
        }

        let visible = Set(days)
        self.counts = counts.filter {
            visible.contains($0.key)
        }
        maximum = self.counts.values.max() ?? 0
    }

    func day(at index: Int?) -> Date? {
        guard let index, days.indices.contains(index) else {
            return nil
        }

        return days[index]
    }

    func count(on day: Date) -> Int {
        counts[calendar.startOfDay(for: day)] ?? 0
    }

    func level(at index: Int) -> Int {
        RecordedEntriesHeatmap.level(
            count: counts[days[index]] ?? 0,
            maximum: maximum
        )
    }

    func shift(_ day: Date, by value: Int) -> Date? {
        guard
            let moved = calendar.date(
                byAdding: .day,
                value: value,
                to: day
            ),
            let first = days.first,
            moved >= first,
            moved <= today
        else {
            return nil
        }

        return moved
    }
}


// MARK: - Layout and drawing

private extension RecordedEntriesHeatmap {

    struct Metrics {
        let weeks: Int
        let cell: CGFloat
        let gap = Theme.heatmapGap

        init(width: CGFloat, weeks: Int) {
            self.weeks = weeks
            let fit =
                (width - CGFloat(weeks - 1) * Theme.heatmapGap)
                / CGFloat(weeks)
            cell = min(
                max(fit, Theme.heatmapCellMin),
                Theme.heatmapCellMax
            )
        }

        var stride: CGFloat { cell + gap }
        var height: CGFloat { 7 * stride - gap }

        func rect(index: Int) -> CGRect {
            CGRect(
                x: CGFloat(index / 7) * stride,
                y: CGFloat(index % 7) * stride,
                width: cell,
                height: cell
            )
        }

        func index(at point: CGPoint) -> Int? {
            let column = Int(point.x / stride)
            let row = Int(point.y / stride)
            guard
                point.x >= 0,
                point.y >= 0,
                column < weeks,
                row < 7
            else {
                return nil
            }

            return column * 7 + row
        }
    }


    static func fill(level: Int) -> Color {
        switch level {
        case 0:
            Theme.line
        case 1...3:
            Theme.teal.opacity(
                Theme.heatmapLevelOpacities[level - 1]
            )
        default:
            Theme.teal
        }
    }


    func draw(
        _ grid: HeatmapGrid,
        metrics: Metrics,
        in context: inout GraphicsContext
    ) {
        for index in grid.days.indices {
            let day = grid.days[index]

            // Days after today in the current week stay blank.
            guard day <= grid.today else {
                continue
            }

            let rect = metrics.rect(index: index)
            let shape = Path(
                roundedRect: rect,
                cornerRadius: Theme.radiusCard
            )

            context.fill(
                shape,
                with: .color(
                    Self.fill(
                        level: grid.level(at: index)
                    )
                )
            )

            if day == selected || day == grid.today {
                context.stroke(
                    shape,
                    with: .color(
                        day == selected
                            ? Theme.ink
                            : Theme.controlBorder
                    ),
                    lineWidth: Theme.ruleThickness
                )
            }
        }
    }


    func legend(
        _ metrics: Metrics
    ) -> some View {
        HStack(spacing: Theme.spaceXXS) {
            Text("Less")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)

            ForEach(0...4, id: \.self) { level in
                Rectangle()
                    .fill(Self.fill(level: level))
                    .frame(
                        width: metrics.cell,
                        height: metrics.cell
                    )
            }

            Text("More")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityHidden(true)
    }


    func rangeLabel(
        _ grid: HeatmapGrid
    ) -> String {
        guard let first = grid.days.first else {
            return ""
        }

        let style = Date.FormatStyle
            .dateTime
            .day()
            .month(.abbreviated)

        return first.formatted(style)
            + " – "
            + grid.today.formatted(style)
    }


    func accessibilityValue(
        _ grid: HeatmapGrid
    ) -> String {
        if let selected {
            return selected.formatted(
                date: .complete,
                time: .omitted
            )
            + ", "
            + Self.entriesText(
                grid.count(on: selected)
            )
        }

        let total = grid.counts.values.reduce(0, +)
        return Self.entriesText(total)
            + " on "
            + String(grid.counts.count)
            + (grid.counts.count == 1 ? " day" : " days")
            + ". Swipe up or down to read individual days."
    }


    func moveSelection(
        _ direction: AccessibilityAdjustmentDirection,
        in grid: HeatmapGrid
    ) {
        let start = selected ?? grid.today

        switch direction {
        case .increment:
            selected =
                selected == nil
                ? start
                : grid.shift(start, by: 1) ?? start
        case .decrement:
            selected =
                selected == nil
                ? start
                : grid.shift(start, by: -1) ?? start
        @unknown default:
            break
        }
    }
}

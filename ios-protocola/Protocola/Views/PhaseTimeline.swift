import SwiftUI

/// Recorded schedule changes as phases: a coloured dot on a line, the
/// phase label, compound, amount and schedule, and the date range.
/// Phases take colours in order; the label and status chip carry the
/// meaning, never colour alone.
struct PhaseTimeline: View {
    /// Newest first.
    let revisions: [ScheduleRevision]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
        ForEach(
            Array(revisions.enumerated()),
            id: \.element.id
        ) { index, revision in
            let tint =
                Theme.phaseTint(revisions.count - index)

            HStack(
                alignment: .top,
                spacing: Theme.spaceS
            ) {
                VStack(spacing: Theme.spaceXXS) {
                    Circle()
                        .fill(tint)
                        .frame(
                            width: Theme.spaceS,
                            height: Theme.spaceS
                        )
                        .padding(.top, Theme.spaceXXS)

                    if index < revisions.count - 1 {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(width: Theme.ruleThickness)
                            .frame(maxHeight: .infinity)
                    }
                }
                .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
                    HStack(
                        alignment: .firstTextBaseline
                    ) {
                        Text(
                            "Phase \(revisions.count - index)"
                        )
                        .font(Theme.sectionLabel)
                        .foregroundStyle(tint)

                        if let length = Self.lengthText(revision) {
                            Text(length)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.textSecondary)
                                .monospacedDigit()
                        }

                        Spacer()

                        StatusBadge(
                            text: Self.stateLabel(revision)
                        )
                    }

                    Text(revision.compoundName)
                        .font(Theme.cardTitle)
                        .foregroundStyle(Theme.ink)

                    Text(
                        DoseText.amount(
                            revision.amountText,
                            revision.unitText
                        )
                        + " · "
                        + (
                            revision.config
                                .map(ScheduleDisplay.summary)
                            ?? "Schedule not available"
                        )
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()

                    HStack(spacing: Theme.spaceXS) {
                        Image(systemName: "calendar")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .accessibilityHidden(true)

                        Text(Self.effectiveLabel(revision))
                            .font(Theme.caption)
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                    }
                    .padding(Theme.spaceS)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        tint.opacity(Theme.statusFillOpacity),
                        in: .rect(cornerRadius: Theme.radiusField)
                    )
                }
                .padding(.bottom, Theme.spaceS)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
        }
        }
    }


    static func stateLabel(
        _ revision: ScheduleRevision
    ) -> String {
        switch revision.temporalState() {
        case .historical:
            return "Past"
        case .current:
            return "Current"
        case .planned:
            return "Planned"
        }
    }


    static func effectiveLabel(
        _ revision: ScheduleRevision
    ) -> String {
        let start =
            revision.effectiveFrom
                .formatted(
                    date: .abbreviated,
                    time: .omitted
                )

        if let end =
            revision.effectiveUntil {
            return
                start
                + " – "
                + end.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
        }

        return
            revision.isPlanned()
            ? "From " + start
            : start + " – present"
    }


    /// "4 weeks" for a finished or bounded phase, "4 weeks so far" for the
    /// current one, nil for an open-ended planned phase.
    static func lengthText(
        _ revision: ScheduleRevision
    ) -> String? {
        let planned = revision.isPlanned()
        guard let end =
            revision.effectiveUntil
            ?? (planned ? nil : Date.now)
        else {
            return nil
        }
        let days =
            max(
                1,
                Calendar.current.dateComponents(
                    [.day],
                    from: revision.effectiveFrom,
                    to: end
                ).day ?? 0
            )
        let text =
            days >= 14
            ? String(days / 7) + " weeks"
            : String(days) + (days == 1 ? " day" : " days")
        return revision.effectiveUntil == nil && !planned
            ? text + " so far"
            : text
    }
}

import SwiftUI

struct EventDetailView: View {
    let event: ProtocolEvent

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                headerBlock

                if event.changes.isEmpty {
                    retainedRecord
                } else {
                    ForEach(
                        event.changes
                    ) { change in
                        changeBlock(change)
                    }
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
        .background(Theme.paper)
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


private extension EventDetailView {

    var headerBlock: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Eyebrow(text: event.category)

            Text(
                event.at.formatted(
                    date: .long,
                    time: .shortened
                )
            )
            .font(Theme.metricCompact)
            .foregroundStyle(
                Theme.ink
            )
            .monospacedDigit()

            EditorialRule()
        }
    }


    var retainedRecord: some View {
        EditorialSection(
            "Retained record"
        ) {
            Text(event.detail)
                .font(Theme.body)
                .foregroundStyle(
                    Theme.ink
                )

            Text(
                "This older event does not contain structured previous values."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    func changeBlock(
        _ change: RecordChange
    ) -> some View {
        EditorialSection(
            change.field
        ) {
            RecordRow(
                label: "Previous",
                value:
                    change.before
                        .isEmpty
                    ? "Not recorded"
                    : change.before
            )

            RecordRow(
                label: "New",
                value:
                    change.after
                        .isEmpty
                    ? "Not recorded"
                    : change.after
            )
        }
    }


}

import SwiftUI
import Charts
import HealthKit

/// Weight from Apple Health beside recorded entries. Read-only, Pro.
/// Shown side by side only: Protocola never claims a dose caused a change.
struct HealthWeightCard: View {
    let period: AnalysisPeriod
    let logs: [DoseLog]

    @Environment(TrackingStore.self) private var store
    @AppStorage("protocola.healthConnected") private var connected = false
    @State private var samples: [HealthWeightService.Sample] = []
    @State private var unitLabel = "kg"
    @State private var loading = false

    private let health = HealthWeightService.shared

    var body: some View {
        if health.isAvailable, !store.isDemo {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceS
            ) {
                HStack(spacing: Theme.spaceXS) {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(Theme.teal)
                        .accessibilityHidden(true)

                    Text("Weight from Apple Health")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)
                }

                if connected && store.isPremium {
                    connectedContent
                } else {
                    Text(
                        "See weight you record in Apple Health beside your entries. Protocola only reads it and never writes to Health."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textSecondary)

                    Button("Connect Apple Health") {
                        connect()
                    }
                    .buttonStyle(TrackingCompactButtonStyle(prominent: true))
                }
            }
            .padding(Theme.cardInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.surface,
                in: .rect(cornerRadius: Theme.radiusCard)
            )
            .quietElevation()
            .task(id: period.start) {
                await load()
            }
        }
    }

    @ViewBuilder
    private var connectedContent: some View {
        if samples.isEmpty {
            Text(
                loading
                ? "Reading Apple Health…"
                : "No weight in Apple Health for this period. If you expected some, check Protocola's access in the Health app."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
        } else {
            if let last = samples.last {
                Text(
                    last.value.formatted(.number.precision(.fractionLength(1)))
                    + " " + unitLabel
                )
                .font(Theme.metricCompact)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            }

            Chart {
                ForEach(logs.filter { $0.status != "Skipped" }) { log in
                    RuleMark(x: .value("Entry", log.loggedAt))
                        .foregroundStyle(Theme.inactiveFill)
                }

                ForEach(samples) { sample in
                    LineMark(
                        x: .value("Date", sample.date),
                        y: .value("Weight", sample.value)
                    )
                    .foregroundStyle(Theme.teal)

                    PointMark(
                        x: .value("Date", sample.date),
                        y: .value("Weight", sample.value)
                    )
                    .foregroundStyle(Theme.teal)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: Theme.iconTileSize * 2.5)
            .accessibilityLabel(
                "Weight chart with \(samples.count) readings and \(logs.count) recorded entries"
            )

            Text(
                "Line: weight from Apple Health. Grey marks: your recorded entries. Shown side by side only; Protocola doesn't infer cause."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
        }
    }

    private func connect() {
        guard store.isPremium else {
            store.requestPaywall(.health)
            return
        }
        Task {
            if await health.requestAccess() {
                connected = true
                await load()
            }
        }
    }

    private func load() async {
        guard connected, store.isPremium else { return }
        loading = true
        let unit = await health.preferredUnit()
        unitLabel = unit == .pound() ? "lb" : "kg"
        samples =
            await health.samples(
                from: period.start,
                to: period.end,
                unit: unit
            )
        loading = false
    }
}

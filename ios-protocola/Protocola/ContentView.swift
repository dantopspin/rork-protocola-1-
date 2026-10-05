import SwiftUI

struct ContentView: View {
    @Environment(TrackingStore.self)
    private var store

    @State private var tab = 0
    @State private var choosingProtocol = false

    var body: some View {
        Group {
            if !store.onboarded {
                OnboardingView()
            } else {
                TabView(selection: $tab) {
                    Tab(
                        "Today",
                        systemImage: "sun.max",
                        value: 0
                    ) {
                        NavigationStack {
                            TodayView()
                        }
                    }

                    Tab(
                        "Protocols",
                        systemImage:
                            "list.bullet.rectangle",
                        value: 1
                    ) {
                        NavigationStack {
                            ProtocolsView()
                        }
                    }

                    Tab(
                        "History",
                        systemImage:
                            "clock.arrow.circlepath",
                        value: 2
                    ) {
                        NavigationStack {
                            HistoryView()
                        }
                    }

                    Tab(
                        "Insights",
                        systemImage:
                            "chart.xyaxis.line",
                        value: 3
                    ) {
                        NavigationStack {
                            InsightsView {
                                tab = 0
                            }
                        }
                    }
                }
                .safeAreaInset(
                    edge: .top,
                    spacing: 0
                ) {
                    if store.isDemo {
                        demoBanner
                    }
                }
            }
        }
        .font(Theme.body)
        .tint(Theme.ink)
        // Clinical Editorial Instrument v3 is intentionally light-only.
        .preferredColorScheme(.light)
        .onAppear {
            choosingProtocol =
                store.needsProtocolChoice
        }
        .onChange(
            of: store.needsProtocolChoice
        ) { _, needs in
            choosingProtocol = needs
        }
        .sheet(
            isPresented: $choosingProtocol
        ) {
            FreeProtocolChoiceView()
        }
        // One central sink: locked features and paywall deep links route here.
        .sheet(
            item:
                Binding(
                    get: {
                        store.pendingPaywall
                    },
                    set: {
                        if $0 == nil {
                            store.dismissPaywall()
                        }
                    }
                )
        ) { reason in
            PaywallView(reason: reason)
        }
        .onOpenURL { url in
            guard
                url.scheme == "protocola",
                url.host == "paywall",
                let reason =
                    PaywallReason(
                        rawValue:
                            url.lastPathComponent
                    )
            else {
                return
            }

            store.requestPaywall(reason)
        }
    }


    private var demoBanner: some View {
        HStack(spacing: Theme.spaceS) {
            Label(
                "Demo · sample records",
                systemImage: "eye"
            )

            Spacer()

            Button("Exit") {
                store.exitDemo()
            }
        }
        .font(Theme.caption)
        .foregroundStyle(Theme.ink)
        .padding(
            .horizontal,
            Theme.spaceM
        )
        .padding(
            .vertical,
            Theme.spaceXS
        )
        .background(Theme.subtleFill)
    }
}

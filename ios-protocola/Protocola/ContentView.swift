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
                        // Content keeps the ink tint; only the tab bar is green.
                        .tint(Theme.ink)
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
                        // Content keeps the ink tint; only the tab bar is green.
                        .tint(Theme.ink)
                    }

                    Tab(
                        "Vials",
                        systemImage: "testtube.2",
                        value: 4
                    ) {
                        NavigationStack {
                            InventoryView()
                        }
                        .tint(Theme.ink)
                    }

                    Tab(
                        "History",
                        systemImage:
                            "clock.arrow.circlepath",
                        value: 2
                    ) {
                        NavigationStack {
                            HistoryView {
                                tab = 3
                            }
                        }
                        // Content keeps the ink tint; only the tab bar is green.
                        .tint(Theme.ink)
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
                        // Content keeps the ink tint; only the tab bar is green.
                        .tint(Theme.ink)
                    }
                }
                .tint(Theme.teal)
            }
        }
        .font(Theme.body)
        .tint(Theme.ink)
        // Light and Dark Mode: every Theme colour adapts to the appearance.
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
}


/// "Demo · sample records" with Exit. Shown as `DemoBannerCard` at the top
/// of every tab's content.
struct DemoBanner: View {
    @Environment(TrackingStore.self) private var store

    var body: some View {
        HStack(spacing: Theme.spaceS) {
            // One line at every text size so the banner never eats the
            // top of the screen.
            ViewThatFits(in: .horizontal) {
                Label(
                    "Demo · sample records",
                    systemImage: "eye"
                )

                Label("Demo", systemImage: "eye")
            }
            .lineLimit(1)

            Spacer()

            Button("Exit") {
                store.exitDemo()
            }
            .minimumTapTarget()
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
        // Opaque so scrolled content never shows through the banner.
        .background(Theme.paper)
    }
}

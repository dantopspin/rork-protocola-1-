import SwiftUI

struct ContentView: View {
    @Environment(TrackingStore.self) private var store
    @State private var tab: Int = 0
    @State private var choosingProtocol: Bool = false
    var body: some View {
        Group {
            if !store.onboarded { OnboardingView() }
            else {
                TabView(selection: $tab) {
                    Tab("Today", systemImage: "sun.max", value: 0) { NavigationStack { TodayView() } }
                    Tab("Protocols", systemImage: "list.bullet.rectangle", value: 1) { NavigationStack { ProtocolsView() } }
                    Tab("History", systemImage: "clock.arrow.circlepath", value: 2) { NavigationStack { HistoryView() } }
                    Tab("Insights", systemImage: "chart.xyaxis.line", value: 3) { NavigationStack { InsightsView() } }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    if store.isDemo {
                        HStack { Label("Demo · sample records", systemImage: "eye"); Spacer(); Button("Exit") { store.exitDemo() } }
                            .font(.caption).padding(.horizontal, Theme.spaceM).padding(.vertical, Theme.spaceXS).background(Theme.ink.opacity(0.06))
                    }
                }
            }
        }
        .font(Theme.body)
        .tint(Theme.ink)
        .preferredColorScheme(.light)
        .onAppear { choosingProtocol = store.needsProtocolChoice }
        .onChange(of: store.needsProtocolChoice) { _, needs in choosingProtocol = needs }
        .sheet(isPresented: $choosingProtocol) { FreeProtocolChoiceView() }
        // Only explicit attempts to use Pro functionality present this paywall.
        .fullScreenCover(isPresented: Binding(
            get: { store.pendingPaywall },
            set: { if !$0 { store.dismissPaywall() } }
        )) { PaywallView(reason: .secondProtocol) }
    }
}

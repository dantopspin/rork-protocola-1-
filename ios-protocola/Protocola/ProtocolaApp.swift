import SwiftUI
import SwiftData

@main
struct ProtocolaApp: App {
    @State private var store: TrackingStore?
    @State private var purchases = StoreService()
    @State private var loadError: Bool = false

    @Environment(\.scenePhase) private var scenePhase

    // Purchases.configure(withAPIKey:) is added once the RevenueCat
    // public SDK key is available to the iOS build.

    var body: some Scene {
        WindowGroup {
            Group {
                if let store {
                    ContentView()
                        .environment(store)

                } else if loadError {
                    ContentUnavailableView {
                        Label(
                            "Records could not be opened",
                            systemImage:
                                "externaldrive.badge.exclamationmark"
                        )
                    } description: {
                        Text(
                            "Your local data has not been deleted. "
                            + "Try opening it again."
                        )
                    } actions: {
                        Button("Try again") {
                            openStore()
                        }
                    }

                } else {
                    ProgressView("Opening Protocola…")
                        .task {
                            openStore()
                        }
                }
            }
            .environment(purchases)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    store?.refresh()
                    store?.resyncReminders()

                    Task {
                        await purchases.syncEntitlements()
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for:
                        UIApplication
                            .significantTimeChangeNotification
                )
            ) { _ in
                store?.refresh()
                store?.resyncReminders()
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else {
                    return
                }

                var lastDay =
                    Calendar.current.startOfDay(
                        for: .now
                    )

                while !Task.isCancelled {
                    do {
                        try await Task.sleep(
                            for: .seconds(60)
                        )
                    } catch {
                        return
                    }

                    store?.refreshDay()

                    let day =
                        Calendar.current.startOfDay(
                            for: .now
                        )

                    if day != lastDay {
                        store?.resyncReminders()
                        lastDay = day
                    }
                }
            }
        }
    }


    private func openStore() {
        do {
            let opened = try TrackingStore(
                container:
                    try LocalPersistence.container()
            )

            #if DEBUG
            // Deterministic fresh-install state for UI tests only.
            // Release/TestFlight builds can never trigger this path.
            if ProcessInfo.processInfo.arguments.contains(
                "-ui-testing-reset"
            ) {
                opened.clearData()
            }
            #endif

            purchases.bind(to: opened)
            store = opened
            loadError = false

        } catch {
            loadError = true
        }
    }
}

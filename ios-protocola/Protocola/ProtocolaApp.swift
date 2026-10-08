import SwiftUI
import SwiftData
import RevenueCat

@main
struct ProtocolaApp: App {
    @UIApplicationDelegateAdaptor(ProtocolaAppDelegate.self)
    private var appDelegate
    @State private var store: TrackingStore?
    @State private var purchases = StoreService()
    @State private var loadError: Bool = false

    @Environment(\.scenePhase) private var scenePhase

    init() {
        ProtocolaAppearance.configure()
        configurePurchases()
    }

    /// UI tests can force Dark Mode to capture both appearances. Release
    /// builds always follow the system setting.
    static var forcedAppearance: ColorScheme? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-dark") {
            return .dark
        }
        #endif
        return nil
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let store {
                    AppLockGate {
                        ContentView()
                            .environment(store)
                    }

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
            .font(Theme.body)
            .tint(Theme.ink)
            .preferredColorScheme(Self.forcedAppearance)
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


    /// Configures RevenueCat once at launch: development builds use the
    /// Test Store key, release builds use the production App Store key.
    /// The identifiers are public client keys (see `RevenueCatSDKKey`); when
    /// configuration is absent — e.g. an unconfigured CI build — StoreService
    /// reports purchases as unavailable and guards every SDK entry point, so
    /// core tracking is unaffected.
    private func configurePurchases() {
        #if DEBUG
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: RevenueCatSDKKey.test)
        #else
        Purchases.configure(withAPIKey: RevenueCatSDKKey.production)
        #endif
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

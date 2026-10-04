import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("protocola.appLockEnabled")
    private var appLockEnabled = false

    @State private var tab = 0
    @State private var choosingProtocol = false

    @State private var unlocked = false
    @State private var authenticating = false
    @State private var authenticationError: String?

    var body: some View {
        Group {
            if shouldShowLock {
                AppLockView(
                    errorMessage: authenticationError,
                    isAuthenticating: authenticating,
                    unlock: authenticate
                )

            } else if !store.onboarded {
                OnboardingView()

            } else {
                mainTabs
            }
        }
        .tint(Theme.teal)
        .preferredColorScheme(.light)
        .onAppear {
            choosingProtocol =
                store.needsProtocolChoice

            if appLockEnabled,
               store.onboarded {
                unlocked = false
                authenticate()
            }
        }
        .onChange(
            of: store.needsProtocolChoice
        ) { _, needs in
            choosingProtocol = needs
        }
        .onChange(
            of: appLockEnabled
        ) { _, enabled in
            if !enabled {
                unlocked = true
                authenticationError = nil
            }
        }
        .onChange(
            of: scenePhase
        ) { _, phase in
            guard appLockEnabled,
                  store.onboarded
            else {
                return
            }

            switch phase {
            case .active:
                if !unlocked,
                   !authenticating {
                    authenticate()
                }

            case .inactive, .background:
                if !authenticating {
                    unlocked = false
                    authenticationError = nil
                }

            @unknown default:
                break
            }
        }
        .sheet(
            isPresented: $choosingProtocol
        ) {
            FreeProtocolChoiceView()
        }
        // Only explicit attempts to use Pro functionality present this paywall.
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    store.pendingPaywall
                },
                set: {
                    if !$0 {
                        store.dismissPaywall()
                    }
                }
            )
        ) {
            PaywallView(
                reason: .secondProtocol
            )
        }
    }
}


// MARK: - Main app

private extension ContentView {

    var mainTabs: some View {
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
                    InsightsView()
                }
            }
        }
        .safeAreaInset(
            edge: .top,
            spacing: 0
        ) {
            if store.isDemo {
                HStack {
                    Label(
                        "Demo · sample records",
                        systemImage: "eye"
                    )

                    Spacer()

                    Button("Exit") {
                        store.exitDemo()
                    }
                }
                .font(.caption)
                .padding(
                    .horizontal,
                    Theme.spaceM
                )
                .padding(
                    .vertical,
                    Theme.spaceXS
                )
                .background(
                    Theme.ink.opacity(0.06)
                )
            }
        }
    }


    var shouldShowLock: Bool {
        appLockEnabled
        && store.onboarded
        && !unlocked
    }
}


// MARK: - Authentication

private extension ContentView {

    func authenticate() {
        guard appLockEnabled,
              store.onboarded,
              !authenticating
        else {
            return
        }

        authenticating = true
        authenticationError = nil

        Task {
            let context = LAContext()
            context.localizedCancelTitle =
                "Cancel"

            var policyError: NSError?

            guard context.canEvaluatePolicy(
                .deviceOwnerAuthentication,
                error: &policyError
            ) else {
                authenticationError =
                    "Face ID or device passcode is not available on this device."
                authenticating = false
                return
            }

            do {
                let success =
                    try await context
                        .evaluatePolicy(
                            .deviceOwnerAuthentication,
                            localizedReason:
                                "Unlock Protocola to view your local records."
                        )

                if success {
                    unlocked = true
                    authenticationError = nil
                }

            } catch let error as LAError {
                switch error.code {
                case .userCancel,
                     .appCancel,
                     .systemCancel:
                    authenticationError = nil

                default:
                    authenticationError =
                        "Protocola could not be unlocked. Try again."
                }

            } catch {
                authenticationError =
                    "Protocola could not be unlocked. Try again."
            }

            authenticating = false
        }
    }
}

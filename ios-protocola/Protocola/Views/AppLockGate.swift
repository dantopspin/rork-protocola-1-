import LocalAuthentication
import SwiftUI

/// Optional App Lock: Face ID, Touch ID or the device passcode before any
/// record is shown. The preference is a device convenience, not a record, so
/// it lives in UserDefaults rather than the SwiftData store.
enum AppLock {
    static let key = "protocola.appLock"

    /// Runs the system prompt; passcode is the fallback when biometrics fail.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}


/// Covers the app until unlocked, and while it is in the app switcher.
struct AppLockGate<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @AppStorage(AppLock.key) private var enabled = false
    @Environment(\.scenePhase) private var phase
    @State private var unlocked = false
    @State private var authenticating = false

    private var covered: Bool {
        enabled && (!unlocked || phase != .active)
    }

    var body: some View {
        ZStack {
            content()

            if covered {
                lockScreen
                    .transition(.opacity)
            }
        }
        .task {
            if enabled { await unlock() }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .background {
                unlocked = false
            } else if newPhase == .active, enabled, !unlocked {
                Task { await unlock() }
            }
        }
    }

    private var lockScreen: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceL
        ) {
            Spacer()

            Image(systemName: "lock")
                .font(Theme.pageTitle)
                .foregroundStyle(Theme.teal)
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                Text("Protocola is locked")
                    .font(Theme.modalTitle)
                    .foregroundStyle(Theme.ink)

                Text("Your records stay hidden until you unlock.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
            }

            if phase == .active {
                Button("Unlock") {
                    Task { await unlock() }
                }
                .buttonStyle(TrackingPrimaryButtonStyle())
                .disabled(authenticating)
            }

            Spacer()
        }
        .padding(Theme.pageInset)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
        .background(Theme.paper)
    }

    private func unlock() async {
        guard !authenticating, phase == .active else { return }
        // No passcode on this device: nothing can unlock, so never trap the
        // person outside their records.
        guard LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            unlocked = true
            return
        }
        authenticating = true
        let granted = await AppLock.authenticate(
            reason: "Unlock your Protocola records."
        )
        authenticating = false
        if granted { unlocked = true }
    }
}

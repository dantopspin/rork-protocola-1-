import SwiftUI
import LocalAuthentication

/// Native Settings for Protocola.
///
/// System navigation, lists, toggles, sheets, and destructive confirmation
/// remain native. Protocola's visual identity stays in the content layer.
struct SettingsView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(StoreService.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("protocola.appLockEnabled")
    private var appLockEnabled = false

    @State private var paywall: PaywallReason?
    @State private var document: LegalDocument?

    @State private var exportURL: URL?
    @State private var shareCSV = false

    @State private var confirmClear = false
    @State private var configuringAppLock = false
    @State private var appLockMessage: String?

    var body: some View {
        NavigationStack {
            List {
                proSection
                preferencesSection
                dataPrivacySection
                supportSection
                legalSection
                dangerZoneSection
            }
            .paperList()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(item: $paywall) {
                reason in
                PaywallView(reason: reason)
            }
            .sheet(item: $document) {
                document in
                LegalDocumentView(
                    document: document
                )
            }
            .sheet(isPresented: $shareCSV) {
                if let exportURL {
                    ActivityView(
                        items: [exportURL]
                    )
                }
            }
            .confirmationDialog(
                "Clear all Protocola data?",
                isPresented: $confirmClear,
                titleVisibility: .visible
            ) {
                Button(
                    "Clear All Data",
                    role: .destructive
                ) {
                    store.clearData()
                    dismiss()
                }

                Button(
                    "Cancel",
                    role: .cancel
                ) {}
            } message: {
                Text(
                    "This permanently removes your protocols, recorded entries, "
                    + "inventory, symptoms, and other local data from this iPhone. "
                    + "This cannot be undone. Your Pro subscription, if active, "
                    + "will not be cancelled."
                )
            }
            .alert(
                "Purchase unavailable",
                isPresented: Binding(
                    get: {
                        purchases.error != nil
                    },
                    set: {
                        if !$0 {
                            purchases.error = nil
                        }
                    }
                )
            ) {
                Button("OK") {
                    purchases.error = nil
                }
            } message: {
                Text(
                    purchases.error ?? ""
                )
            }
            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension SettingsView {

    @ViewBuilder
    var proSection: some View {
        Section {
            HStack(
                spacing: Theme.spaceS
            ) {
                Image(
                    systemName:
                        store.isPremium
                        ? "checkmark.seal.fill"
                        : "sparkles"
                )
                .foregroundStyle(
                    store.isPremium
                        ? Theme.teal
                        : Theme.ink
                )

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Protocola Pro")
                        .foregroundStyle(
                            Theme.ink
                        )

                    Text(
                        store.isPremium
                            ? "Active"
                            : "Free plan"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                if !store.isPremium {
                    Button("Upgrade") {
                        paywall = .pro
                    }
                    .fontWeight(.semibold)
                }
            }

            if store.isPremium {
                Button {
                    manageSubscription()
                } label: {
                    Label(
                        "Manage Subscription",
                        systemImage: "creditcard"
                    )
                }
            }

            Button {
                Task {
                    await purchases.restore()
                }
            } label: {
                HStack {
                    Label(
                        "Restore Purchases",
                        systemImage:
                            "arrow.clockwise"
                    )

                    Spacer()

                    if purchases.isRestoring {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(
                purchases.isRestoring
                    || purchases.isPurchasing
            )

        } header: {
            Text("Protocola Pro")

        } footer: {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                if !store.isPremium {
                    Text(
                        "Free includes core tracking for one active protocol. "
                        + "Pro unlocks unlimited active protocols, Ask Protocola, "
                        + "advanced comparisons, and Visit Summaries."
                    )
                }

                if let notice =
                    purchases.lastNotice {
                    Text(notice)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }
        }
    }


    var preferencesSection: some View {
        Section {
            Button {
                openNotificationSettings()
            } label: {
                HStack(
                    spacing: Theme.spaceS
                ) {
                    Label(
                        "Notifications",
                        systemImage: "bell"
                    )

                    Spacer()

                    Text("System Settings")
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                }
            }
            .foregroundStyle(Theme.ink)

            Toggle(
                isOn: Binding(
                    get: {
                        appLockEnabled
                    },
                    set: {
                        updateAppLock($0)
                    }
                )
            ) {
                Label(
                    "App Lock",
                    systemImage: "faceid"
                )
            }
            .disabled(
                configuringAppLock
                    || !canLockApp
            )

        } header: {
            Text("Preferences")

        } footer: {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {
                Text(
                    store.notifications.status
                )

                Text(
                    canLockApp
                        ? "App Lock uses Face ID or your device passcode to protect local Protocola records. Biometric data never leaves iOS."
                        : "App Lock requires Face ID, Touch ID, or a device passcode."
                )

                if configuringAppLock {
                    Text(
                        "Confirm your identity to enable App Lock."
                    )
                }

                if let appLockMessage {
                    Text(appLockMessage)
                }
            }
        }
    }


    var dataPrivacySection: some View {
        Section {
            Button {
                document =
                    LegalContent.aiDataUse
            } label: {
                Label(
                    "AI & Data Use",
                    systemImage: "lock.shield"
                )
            }

            Button {
                exportData()
            } label: {
                Label(
                    "Export My Data",
                    systemImage:
                        "square.and.arrow.up"
                )
            }

        } header: {
            Text("Data & Privacy")

        } footer: {
            Text(
                "Your core records are stored on this iPhone. "
                + "Relevant information leaves the device only when required "
                + "for a feature you choose to use, such as Ask Protocola."
            )
        }
    }


    var supportSection: some View {
        Section("Support") {
            Button {
                contactSupport()
            } label: {
                Label(
                    "Contact Support",
                    systemImage: "envelope"
                )
            }
        }
    }


    var legalSection: some View {
        Section("Legal") {
            Button("Privacy Policy") {
                document =
                    LegalContent.privacy
            }

            Button("Terms of Use") {
                document =
                    LegalContent.terms
            }

            Button("Medical Disclaimer") {
                document =
                    LegalContent
                        .medicalDisclaimer
            }
        }
    }


    var dangerZoneSection: some View {
        Section {
            Button(
                role: .destructive
            ) {
                confirmClear = true
            } label: {
                Label(
                    "Clear All Data",
                    systemImage: "trash"
                )
            }

        } header: {
            Text("Danger Zone")

        } footer: {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceS
            ) {
                Text(
                    "Permanently removes all local Protocola records from "
                    + "this iPhone. This does not cancel an active subscription."
                )

                Text(appVersionText)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    .padding(
                        .top,
                        Theme.spaceXXS
                    )
            }
        }
    }
}


// MARK: - App Lock

private extension SettingsView {

    var canLockApp: Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        )
    }


    func updateAppLock(
        _ enabled: Bool
    ) {
        appLockMessage = nil

        guard enabled else {
            appLockEnabled = false
            return
        }

        guard !configuringAppLock else {
            return
        }

        configuringAppLock = true

        Task {
            let context = LAContext()

            var policyError: NSError?

            guard context.canEvaluatePolicy(
                .deviceOwnerAuthentication,
                error: &policyError
            ) else {
                configuringAppLock = false
                appLockEnabled = false
                appLockMessage =
                    "App Lock is unavailable on this device."
                return
            }

            do {
                let success =
                    try await context
                        .evaluatePolicy(
                            .deviceOwnerAuthentication,
                            localizedReason:
                                "Confirm your identity to enable Protocola App Lock."
                        )

                appLockEnabled = success

                if success {
                    appLockMessage =
                        "App Lock is enabled."
                }

            } catch let error as LAError {
                appLockEnabled = false

                switch error.code {
                case .userCancel,
                     .appCancel,
                     .systemCancel:
                    appLockMessage = nil

                default:
                    appLockMessage =
                        "App Lock could not be enabled. Try again."
                }

            } catch {
                appLockEnabled = false
                appLockMessage =
                    "App Lock could not be enabled. Try again."
            }

            configuringAppLock = false
        }
    }
}


// MARK: - Actions

private extension SettingsView {

    func openNotificationSettings() {
        guard let url = URL(
            string:
                UIApplication
                    .openSettingsURLString
        ) else {
            return
        }

        openURL(url)
    }


    func exportData() {
        do {
            exportURL =
                try ExportService
                    .historyCSV(store.logs)

            shareCSV = true

        } catch {
            store.error =
                "Your export could not be prepared. Please try again."
        }
    }


    func contactSupport() {
        var components =
            URLComponents()

        components.scheme = "mailto"
        components.path =
            "taskalidaniyal@gmail.com"

        components.queryItems = [
            URLQueryItem(
                name: "subject",
                value:
                    "Protocola Support"
            ),

            URLQueryItem(
                name: "body",
                value:
                    """
                    Hi,

                    I need help with Protocola.

                    App version: \(appVersionText)

                    Issue:

                    """
            )
        ]

        guard let url =
            components.url
        else {
            return
        }

        openURL(url)
    }


    func manageSubscription() {
        if let url =
            purchases.managementURL {
            openURL(url)
            return
        }

        guard let fallback =
            URL(
                string:
                    "https://apps.apple.com/account/subscriptions"
            )
        else {
            return
        }

        openURL(fallback)
    }


    var appVersionText: String {
        let version =
            Bundle.main.object(
                forInfoDictionaryKey:
                    "CFBundleShortVersionString"
            ) as? String
            ?? "1.0"

        let build =
            Bundle.main.object(
                forInfoDictionaryKey:
                    "CFBundleVersion"
            ) as? String
            ?? "1"

        return
            "Protocola "
            + version
            + " ("
            + build
            + ")"
    }
}

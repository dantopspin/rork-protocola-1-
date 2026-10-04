import SwiftUI
import RevenueCat

/// Release-ready Settings for Protocola.
///
/// Structure:
/// Protocola Pro
/// Preferences
/// Data & Privacy
/// Support
/// Legal
/// Danger Zone
struct SettingsView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var paywall: PaywallReason?
    @State private var document: LegalDocument?

    @State private var exportURL: URL?
    @State private var shareCSV = false

    @State private var confirmClear = false

    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showRestoreAlert = false

    var body: some View {
        NavigationStack {
            List {
                proSection
                .listRowBackground(Color.white)

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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }

            // MARK: - Paywall

            .fullScreenCover(item: $paywall) { reason in
                PaywallView(reason: reason)
            }

            // MARK: - Legal

            .sheet(item: $document) { document in
                LegalDocumentView(document: document)
            }

            // MARK: - Export

            .sheet(isPresented: $shareCSV) {
                if let exportURL {
                    ActivityView(items: [exportURL])
                }
            }

            // MARK: - Clear Data

            .confirmationDialog(
                "Clear all Protocola data?",
                isPresented: $confirmClear,
                titleVisibility: .visible
            ) {
                Button("Clear All Data", role: .destructive) {
                    store.clearData()
                    dismiss()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    """
                    This permanently removes your protocols, recorded entries, \
                    inventory, symptoms, and other local data from this iPhone.

                    This cannot be undone. Your Pro subscription, if active, \
                    will not be cancelled.
                    """
                )
            }

            // MARK: - Restore Purchases Result

            .alert(
                "Restore Purchases",
                isPresented: $showRestoreAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }

            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension SettingsView {

    // MARK: Pro

    @ViewBuilder
    var proSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(
                    systemName: store.isPremium
                        ? "checkmark.seal.fill"
                        : "sparkles"
                )
                .foregroundStyle(
                    store.isPremium
                        ? Theme.teal
                        : Theme.ink
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Protocola Pro")
                        .foregroundStyle(Theme.ink)

                    Text(store.isPremium ? "Active" : "Free plan")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
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
                restorePurchases()
            } label: {
                HStack {
                    Label(
                        "Restore Purchases",
                        systemImage: "arrow.clockwise"
                    )

                    Spacer()

                    if isRestoring {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(isRestoring)

        } header: {
            Text("Protocola Pro")
        } footer: {
            if !store.isPremium {
                Text(
                    "Free includes core tracking for one active protocol. "
                    + "Pro unlocks unlimited active protocols, Ask Protocola, "
                    + "advanced comparisons, and Visit Summaries."
                )
            }
        }
    }


    // MARK: Preferences

    var preferencesSection: some View {
        Section("Preferences") {
            Button {
                openNotificationSettings()
            } label: {
                HStack(spacing: 12) {
                    Label(
                        "Notifications",
                        systemImage: "bell"
                    )

                    Spacer()

                    Text(store.notifications.status)
                        .foregroundStyle(Theme.muted)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            .foregroundStyle(Theme.ink)
        }
    }


    // MARK: Data & Privacy

    var dataPrivacySection: some View {
        Section {
            Button {
                document = LegalContent.aiDataUse
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
                    systemImage: "square.and.arrow.up"
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


    // MARK: Support

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


    // MARK: Legal

    var legalSection: some View {
        Section("Legal") {
            Button("Privacy Policy") {
                document = LegalContent.privacy
            }

            Button("Terms of Use") {
                document = LegalContent.terms
            }

            Button("Medical Disclaimer") {
                document = LegalContent.medicalDisclaimer
            }
        }
    }


    // MARK: Danger Zone

    var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
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
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    "Permanently removes all local Protocola records from "
                    + "this iPhone. This does not cancel an active subscription."
                )

                Text(appVersionText)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 6)
            }
        }
    }
}


// MARK: - Actions

private extension SettingsView {

    func openNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        openURL(url)
    }


    func exportData() {
        do {
            exportURL = try ExportService.historyCSV(store.logs)
            shareCSV = true
        } catch {
            store.error =
                "Your export could not be prepared. Please try again."
        }
    }


    func contactSupport() {
        var components = URLComponents()

        components.scheme = "mailto"
        components.path = "taskalidaniyal@gmail.com"

        components.queryItems = [
            URLQueryItem(
                name: "subject",
                value: "Protocola Support"
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

        guard let url = components.url else {
            return
        }

        openURL(url)
    }


    func manageSubscription() {
        guard let url = URL(
            string: "https://apps.apple.com/account/subscriptions"
        ) else {
            return
        }

        openURL(url)
    }


    func restorePurchases() {
        guard !isRestoring else {
            return
        }

        isRestoring = true

        Purchases.shared.restorePurchases { customerInfo, error in
            DispatchQueue.main.async {
                isRestoring = false

                if let error {
                    restoreMessage =
                        "Purchases could not be restored. "
                        + error.localizedDescription

                    showRestoreAlert = true
                    return
                }

                let hasPro =
                    customerInfo?
                        .entitlements["pro"]?
                        .isActive == true

                if hasPro {
                    restoreMessage =
                        "Your Protocola Pro subscription was restored."
                } else {
                    restoreMessage =
                        "No active Protocola Pro subscription was found "
                        + "for this Apple ID."
                }

                showRestoreAlert = true
            }
        }
    }


    var appVersionText: String {
        let version =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? "1.0"

        let build =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String ?? "1"

        return "Protocola \(version) (\(build))"
    }
}
import SwiftUI

/// Native Settings for Protocola.
///
/// Keep system navigation, lists, rows, sheets, and destructive confirmation
/// native. Protocola's visual identity stays in the content layer through
/// typography and the shared Theme tokens.
struct SettingsView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(StoreService.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var document: LegalDocument?

    @State private var exportURLs: [URL] = []
    @State private var shareCSV = false

    @State private var confirmClear = false

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
            .listStyle(.plain)
            .paperList()
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $document) { document in
                LegalDocumentView(document: document)
            }
            .sheet(
                isPresented: $shareCSV,
                onDismiss:
                    cleanupExportFiles
            ) {
                if !exportURLs.isEmpty {
                    ActivityView(
                        items: exportURLs
                    )
                }
            }
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
                    This permanently removes your protocols, recorded entries, inventory, symptoms, and other local data from this iPhone.

                    This cannot be undone. Your Pro subscription, if active, will not be cancelled.
                    """
                )
            }
            .alert(
                purchases.alert?.title ?? "",
                isPresented: Binding(
                    get: { purchases.alert != nil && store.pendingPaywall == nil },
                    set: { if !$0 { purchases.alert = nil } }
                ),
                presenting: purchases.alert
            ) { _ in
                Button("OK") {
                    purchases.alert = nil
                }
            } message: { alert in
                Text(alert.message)
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
            HStack(spacing: Theme.spaceS) {
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

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Protocola Pro")
                        .foregroundStyle(Theme.ink)

                    Text(store.isPremium ? "Active" : "Free plan")
                        .font(Theme.body)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()

                if !store.isPremium {
                    Button("Upgrade") {
                        store.requestPaywall(.pro)
                    }
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)
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
                        systemImage: "arrow.clockwise"
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
            Eyebrow(text: "Protocola Pro")
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

                if let notice = purchases.lastNotice {
                    Text(notice)
                        .foregroundStyle(Theme.muted)
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
                    alignment: .center,
                    spacing: Theme.spaceS
                ) {
                    VStack(
                        alignment: .leading,
                        spacing:
                            Theme.spaceXXS
                    ) {
                        Label(
                            "Notifications",
                            systemImage: "bell"
                        )

                        Text(
                            store.notifications
                                .status
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.muted
                        )
                        .lineLimit(2)
                    }

                    Spacer(
                        minLength:
                            Theme.spaceS
                    )

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(Theme.micro)
                    .foregroundStyle(
                        Theme.muted
                    )
                    .accessibilityHidden(
                        true
                    )
                }
                .contentShape(
                    Rectangle()
                )
            }
            .foregroundStyle(Theme.ink)

            Toggle(isOn: Binding(
                get: { store.inventoryAlerts },
                set: { enabled in
                    Task {
                        await store.setInventoryAlerts(enabled)
                    }
                }
            )) {
                Label(
                    "Inventory alerts",
                    systemImage: "shippingbox"
                )
            }
        } header: {
            Eyebrow(text: "Preferences")

        } footer: {
            Text(
                "Optional reminders built from your recorded balance, schedule, and the expiry date you entered. Protocola never estimates an expiry date."
            )
        }
    }


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
            .disabled(
                !hasExportableData
            )

        } header: {
            Eyebrow(text: "Data & Privacy")
        } footer: {
            Text(
                "Your core records are stored on this iPhone. "
                + "Export My Data creates portable CSV copies of your protocols, schedules, entries, vial and inventory records, audit events, and labs. "
                + "Relevant information leaves the device only when required for a feature you choose to use, such as Ask Protocola."
            )
        }
    }


    var supportSection: some View {
        Section {
            Button {
                contactSupport()
            } label: {
                Label(
                    "Contact Support",
                    systemImage: "envelope"
                )
            }
        } header: {
            Eyebrow(text: "Support")
        }
    }


    var legalSection: some View {
        Section {
            Button("Privacy Policy") {
                document = LegalContent.privacy
            }

            Button("Terms of Use") {
                document = LegalContent.terms
            }

            Button("Medical Disclaimer") {
                document = LegalContent.medicalDisclaimer
            }
        } header: {
            Eyebrow(text: "Legal")
        }
    }


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
            Eyebrow(text: "Danger Zone")
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
                    .font(Theme.caption)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, Theme.spaceXXS)
            }
        }
    }
}


// MARK: - Actions

private extension SettingsView {

    var hasExportableData: Bool {
        !store.protocols.isEmpty
        || !store.compounds.isEmpty
        || !store.revisions.isEmpty
        || !store.logs.isEmpty
        || !store.vials.isEmpty
        || !store.inventoryAdjustments
            .isEmpty
        || !store.events.isEmpty
        || !store.labs.isEmpty
    }


    func openNotificationSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        openURL(url)
    }


    func exportData() {
        cleanupExportFiles()

        do {
            var urls = [
                try ExportService
                    .protocolsCSV(
                        store.protocols
                    ),
                try ExportService
                    .compoundsCSV(
                        store.compounds
                    ),
                try ExportService
                    .scheduleRevisionsCSV(
                        store.revisions
                    ),
                try ExportService
                    .historyCSV(
                        store.logs
                    ),
                try ExportService
                    .vialsCSV(
                        store.vials,
                        balances:
                            store.balances
                    ),
                try ExportService
                    .inventoryCSV(
                        store
                            .inventoryAdjustments
                    ),
                try ExportService
                    .eventsCSV(
                        store.events
                    )
            ]

            if !store.labs.isEmpty {
                urls.append(
                    try ExportService
                        .labsCSV(
                            store.labs
                        )
                )
            }

            exportURLs = urls
            shareCSV = true

        } catch {
            store.error =
                "Your export could not be prepared. Please try again."
        }
    }


    func cleanupExportFiles() {
        for url in exportURLs {
            try? FileManager.default
                .removeItem(at: url)
        }

        exportURLs = []
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
        if let url = purchases.managementURL {
            openURL(url)
            return
        }

        guard let fallback = URL(
            string: "https://apps.apple.com/account/subscriptions"
        ) else {
            return
        }

        openURL(fallback)
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

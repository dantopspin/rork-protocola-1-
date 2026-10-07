import Foundation
import Observation
import RevenueCat
import UIKit

/// Bridges RevenueCat to TrackingStore access. Only the single `pro`
/// entitlement grants Pro.
///
/// Configuration happens once at launch in ProtocolaApp.configurePurchases(),
/// using the bundled public SDK key (`RevenueCatSDKKey`).
///
/// A failed refresh retains the last verified state, so an offline launch never
/// fakes expiry. All RevenueCat entry points are guarded so an unconfigured
/// development build cannot accidentally access Purchases.shared.
@MainActor
@Observable
final class StoreService {
    static let entitlementName = "pro"

    private(set) var offerings: [Package] = []
    private(set) var isLoading: Bool = false
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false
    private(set) var lastNotice: String?
    private(set) var managementURL: URL?

    var alert: PurchaseAlert?

    private weak var store: TrackingStore?
    private var started = false

    var isConfigured: Bool {
        Purchases.isConfigured
    }


    /// Called once the local store exists.
    func bind(to store: TrackingStore) {
        self.store = store
        start()
    }


    private func start() {
        guard Purchases.isConfigured else {
            offerings = []
            lastNotice =
                "Subscriptions are not configured in this build. "
                + "Core tracking is unaffected."
            return
        }

        guard !started else {
            return
        }

        started = true
        lastNotice = nil

        // Seed the last verified entitlement from the Keychain so premium
        // features render immediately after relaunch; the RevenueCat stream
        // confirms or corrects this state within moments.
        if let cached =
            EntitlementCache.read(),
           cached.grantsAccess() {
            store?.receiveEntitlements(
                [Self.entitlementName]
            )
        }

        Task { [weak self] in
            for await info in
                Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }

        Task {
            await loadOfferings()
        }

        Task {
            await syncEntitlements()
        }
    }


    func apply(_ info: CustomerInfo) {
        managementURL =
            info.managementURL

        let activeEntitlements = Set(
            info.entitlements.active.keys
        )

        let pro =
            info.entitlements[
                Self.entitlementName
            ]

        EntitlementCache.write(
            active:
                pro?.isActive == true,
            expirationDate:
                pro?.expirationDate
        )

        if pro?.isActive == true {
            lastNotice = nil
        }

        store?.receiveEntitlements(
            activeEntitlements
        )
    }


    func loadOfferings() async {
        guard Purchases.isConfigured else {
            offerings = []
            lastNotice =
                "Subscriptions are not configured in this build. "
                + "Core tracking is unaffected."
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let offerings =
                try await Purchases.shared.offerings()

            self.offerings =
                offerings.current?
                    .availablePackages
                ?? []

            if self.offerings.isEmpty {
                lastNotice =
                    "Plans are not published yet. "
                    + "Core tracking is unaffected."
            } else {
                lastNotice = nil
            }

        } catch {
            lastNotice =
                "Plans could not be loaded. "
                + "Check your connection and try again."
        }
    }


    /// Recovers the catalog when a paywall opens without one — during a slow
    /// launch fetch or after an offline start. No-op when plans are already
    /// loaded or a fetch is in flight.
    func ensureOfferingsLoaded() async {
        guard
            offerings.isEmpty,
            !isLoading
        else {
            return
        }

        await loadOfferings()
    }


    /// Explicit foreground refresh. A network failure keeps the previous
    /// verified entitlement state.
    func syncEntitlements() async {
        guard Purchases.isConfigured else {
            return
        }

        do {
            apply(
                try await
                    Purchases.shared.customerInfo()
            )
        } catch {
            // Retain last verified state.
        }
    }


    func purchase(_ package: Package) async {
        guard Purchases.isConfigured else {
            alert = .unavailable
            return
        }

        guard !isPurchasing else {
            return
        }

        isPurchasing = true

        defer {
            isPurchasing = false
        }

        do {
            let result =
                try await Purchases.shared.purchase(
                    package: package
                )

            guard !result.userCancelled else {
                alert = .purchaseCancelled
                return
            }

            apply(result.customerInfo)

        } catch ErrorCode.paymentPendingError {
            lastNotice =
                "Your purchase is awaiting approval. "
                + "Pro unlocks when it completes."

        } catch ErrorCode.purchaseCancelledError {
            alert = .purchaseCancelled

        } catch {
            self.alert = .purchaseFailed
        }
    }


    func restore() async {
        guard Purchases.isConfigured else {
            alert = .unavailable
            return
        }

        guard !isRestoring else {
            return
        }

        isRestoring = true

        defer {
            isRestoring = false
        }

        do {
            let info =
                try await
                    Purchases.shared.restorePurchases()

            apply(info)

            // The outcome is always surfaced as a native alert with a
            // success haptic, so restoring on a new device is explicit —
            // not a quiet string only visible inside the paywall.
            if info.entitlements[
                Self.entitlementName
            ]?.isActive == true {
                Haptics.success()
                alert = .restored
            } else {
                alert = .nothingToRestore
            }

        } catch {
            self.alert = .restoreFailed
        }
    }
}

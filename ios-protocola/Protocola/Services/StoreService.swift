import Foundation
import Observation
import RevenueCat

/// Bridges RevenueCat to TrackingStore access. Only the single `pro` entitlement grants Pro.
/// A failed refresh retains the last verified state, so an offline launch never fakes expiry.
@MainActor @Observable final class StoreService {
    static let entitlementName = "pro"
    private(set) var offerings: [Package] = []
    private(set) var isLoading: Bool = false
    private(set) var isPurchasing: Bool = false
    private(set) var isRestoring: Bool = false
    private(set) var lastNotice: String?
    private(set) var managementURL: URL?
    var error: String?
    private weak var store: TrackingStore?
    private var started = false

    /// Called once the local store exists; all RevenueCat access stays guarded.
    func bind(to store: TrackingStore) {
        self.store = store
        start()
    }

    private func start() {
        guard Purchases.isConfigured, !started else { return }
        started = true
        Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
        Task { await loadOfferings() }
        Task { await syncEntitlements() }
    }

    func apply(_ info: CustomerInfo) {
        if let url = info.managementURL { managementURL = url }
        store?.receiveEntitlements(Set(info.entitlements.active.keys))
    }

    func loadOfferings() async {
        guard Purchases.isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings.current?.availablePackages ?? []
            if self.offerings.isEmpty { lastNotice = "Plans are not published yet. Core tracking is unaffected." }
        } catch {
            lastNotice = "Plans could not be loaded. Check your connection and try again."
        }
    }

    /// Explicit foreground refresh; a network failure keeps the previous verified state.
    func syncEntitlements() async {
        guard Purchases.isConfigured else { return }
        do { apply(try await Purchases.shared.customerInfo()) } catch { /* retain last verified state */ }
    }

    func purchase(_ package: Package) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return }
            apply(result.customerInfo)
        } catch ErrorCode.paymentPendingError {
            lastNotice = "Your purchase is awaiting approval. Pro unlocks when it completes."
        } catch ErrorCode.purchaseCancelledError {
            // StoreKit cancellation is not an error.
        } catch {
            self.error = "The purchase could not be completed. Please try again."
        }
    }

    func restore() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            lastNotice = info.entitlements[Self.entitlementName]?.isActive == true ? "Pro restored." : "No active Pro purchase found for this Apple ID."
        } catch {
            self.error = "Purchases could not be restored. Please try again."
        }
    }
}

import Foundation

/// A single native alert surfaced by the subscription flow, so purchase
/// failures and cancellations always explain themselves clearly instead of
/// failing silently.
struct PurchaseAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String

    /// The purchase sheet was dismissed before completing. No charge was made.
    static let purchaseCancelled = PurchaseAlert(
        title: "Purchase cancelled",
        message: "No charge was made. You can subscribe anytime."
    )

    /// The purchase attempt failed.
    static let purchaseFailed = PurchaseAlert(
        title: "Purchase failed",
        message: "The purchase could not be completed. You have not been charged. Please try again."
    )

    /// Restoring could not reach the App Store.
    static let restoreFailed = PurchaseAlert(
        title: "Restore failed",
        message: "Purchases could not be restored. Check your connection and try again."
    )

    /// Restore reached the App Store and confirmed Pro.
    static let restored = PurchaseAlert(
        title: "Pro restored",
        message: "Your subscription is active on this device. All Pro features are unlocked."
    )

    /// Restore succeeded, but this Apple ID has no active Pro purchase.
    static let nothingToRestore = PurchaseAlert(
        title: "Nothing to restore",
        message: "No active Pro purchase was found for this Apple ID."
    )

    /// Purchases are not wired up in this build (sandbox or CI).
    static let unavailable = PurchaseAlert(
        title: "Subscriptions unavailable",
        message: "Subscriptions are not configured in this build. Core tracking is unaffected."
    )
}

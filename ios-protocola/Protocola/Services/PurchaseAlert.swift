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
        message: "The purchase could not be completed. Please try again."
    )

    /// Restoring could not reach the App Store.
    static let restoreFailed = PurchaseAlert(
        title: "Restore failed",
        message: "Purchases could not be restored. Check your connection and try again."
    )

    /// Purchases are not wired up in this build (sandbox or CI).
    static let unavailable = PurchaseAlert(
        title: "Subscriptions unavailable",
        message: "Subscriptions are not configured in this build. Core tracking is unaffected."
    )
}

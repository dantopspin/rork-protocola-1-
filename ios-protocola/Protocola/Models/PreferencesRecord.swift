import Foundation
import SwiftData

@Model final class PreferencesRecord {
    @Attribute(.unique) var id: UUID
    var onboarded: Bool
    var disclaimerAccepted: Bool
    var aiSharing: Bool
    var premium: Bool
    var selectedFreeProtocolID: UUID?
    var paywallSeen: Bool
    /// Manual display order for Today's entries as occurrence keys. Stale keys
    /// (a new day, an edited schedule) stop matching and fall back to time order.
    var todayOrder: [String] = []
    /// Optional inventory notifications (low recorded balance, projected
    /// depletion, user-entered expiry approaching). Additive persisted property
    /// with a default, so existing stores migrate without data loss.
    var inventoryAlerts: Bool = false
    init() { id = UUID(); onboarded = false; disclaimerAccepted = false; aiSharing = false; premium = false; paywallSeen = false }
}

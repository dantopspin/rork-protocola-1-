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
    init() { id = UUID(); onboarded = false; disclaimerAccepted = false; aiSharing = false; premium = false; paywallSeen = false }
}

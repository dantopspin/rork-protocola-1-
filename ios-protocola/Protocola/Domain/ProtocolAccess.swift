import Foundation

/// Access restrictions never mutate protocol status or historical schedules.
nonisolated enum ProtocolAccess {
    static func allowedIDs(isPro: Bool, activeIDs: Set<UUID>, selectedID: UUID?) -> Set<UUID> {
        if isPro || activeIDs.count <= 1 { return activeIDs }
        guard let selectedID, activeIDs.contains(selectedID) else { return [] }
        return [selectedID]
    }
    static func canActivate(isPro: Bool, activeIDs: Set<UUID>, targetID: UUID?) -> Bool {
        isPro || activeIDs.isEmpty || targetID.map(activeIDs.contains) == true
    }
}

/// A failed refresh preserves prior verified access; missing/inactive pro removes it.
nonisolated struct EntitlementAccess: Equatable, Sendable {
    private(set) var isPro: Bool = false
    mutating func receive(activeEntitlements: Set<String>?) {
        guard let activeEntitlements else { return }
        isPro = activeEntitlements.contains("pro")
    }
}

import Foundation
import Security

/// Keychain-backed cache of the last verified `pro` entitlement state.
///
/// Written only from verified `CustomerInfo` in `StoreService.apply`, and read
/// once at launch so premium features render immediately after a restart —
/// before RevenueCat's first network round-trip confirms or corrects the
/// state. The Keychain survives reinstalls on the same device, which is the
/// behavior users expect from a paid subscription.
enum EntitlementCache {

    private static let service = "app.protocola.entitlement"
    private static let account = "pro"

    /// Returns the last verified Pro state, or nil when nothing was cached.
    static func read() -> Bool? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data,
              let flag = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return flag == "1"
    }


    /// Persists the verified state. A failure here is non-fatal: the next
    /// RevenueCat refresh restores the correct state anyway.
    static func write(_ active: Bool) {
        let data = Data((active ? "1" : "0").utf8)
        let value = data as CFData

        let update: [String: Any] = [
            kSecValueData as String: value
        ]

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            update as CFDictionary
        )

        guard updateStatus == errSecItemNotFound else {
            return
        }

        var add = baseQuery
        add[kSecValueData as String] = value
        add[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlock

        SecItemAdd(add as CFDictionary, nil)
    }


    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

import Foundation
import Security

/// Keychain-backed cache of the last verified RevenueCat entitlement.
///
/// The cache is only a cold-launch optimization. RevenueCat remains the source
/// of truth. A cached subscription that has a known expiration in the past
/// never unlocks Pro, and a legacy cache without verification metadata is not
/// trusted to grant access indefinitely while offline.
enum EntitlementCache {

    struct Record: Codable, Equatable {
        let active: Bool
        let expirationDate: Date?
        let verifiedAt: Date

        func grantsAccess(
            at date: Date = .now
        ) -> Bool {
            guard active else {
                return false
            }

            if let expirationDate {
                return expirationDate > date
            }

            // RevenueCat uses nil expiration for non-expiring entitlements.
            return true
        }
    }

    private static let service =
        "app.protocola.entitlement"
    private static let account = "pro"


    /// Returns the last verified record. Legacy boolean-only values are
    /// deliberately ignored because they cannot prove whether a subscription
    /// has since expired.
    static func read() -> Record? {
        var query = baseQuery
        query[kSecReturnData as String] =
            kCFBooleanTrue
        query[kSecMatchLimit as String] =
            kSecMatchLimitOne

        var result: AnyObject?
        let status =
            SecItemCopyMatching(
                query as CFDictionary,
                &result
            )

        guard
            status == errSecSuccess,
            let data = result as? Data
        else {
            return nil
        }

        return try? JSONDecoder()
            .decode(
                Record.self,
                from: data
            )
    }


    /// Persists only state verified by RevenueCat.
    ///
    /// Keychain failure is intentionally non-fatal: the live RevenueCat refresh
    /// still supplies the authoritative entitlement state.
    static func write(
        active: Bool,
        expirationDate: Date?,
        verifiedAt: Date = .now
    ) {
        let record =
            Record(
                active: active,
                expirationDate:
                    expirationDate,
                verifiedAt: verifiedAt
            )

        guard
            let data = try? JSONEncoder()
                .encode(record)
        else {
            return
        }

        let value = data as CFData
        let update: [String: Any] = [
            kSecValueData as String:
                value
        ]

        let updateStatus =
            SecItemUpdate(
                baseQuery as CFDictionary,
                update as CFDictionary
            )

        guard
            updateStatus
                == errSecItemNotFound
        else {
            return
        }

        var add = baseQuery
        add[kSecValueData as String] =
            value
        add[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlock

        SecItemAdd(
            add as CFDictionary,
            nil
        )
    }


    private static var baseQuery:
        [String: Any] {
        [
            kSecClass as String:
                kSecClassGenericPassword,
            kSecAttrService as String:
                service,
            kSecAttrAccount as String:
                account
        ]
    }
}

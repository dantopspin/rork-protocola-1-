import Foundation

/// RevenueCat public SDK keys.
///
/// These are public client identifiers — RevenueCat designs them to be embedded
/// in the app bundle; they are not secrets. The same identifiers are registered
/// as `EXPO_PUBLIC_REVENUECAT_*` environment values, but builds whose generated
/// Config does not yet carry those entries (sandbox, CI) still need a working
/// key, so the app ships them bundled.
enum RevenueCatSDKKey {
    /// Test Store app (`app34884b3b7a`) — used by DEBUG builds.
    static let test = "test_kxHUbYtJHSYCsmrFBNZCslGlWFD"

    /// App Store app `app.rork.protocola` (`app6a1be6ec9d`) — used by release builds.
    static let production = "appl_xZTgzprGWBQRpdXqDWZxPHVZsGD"
}

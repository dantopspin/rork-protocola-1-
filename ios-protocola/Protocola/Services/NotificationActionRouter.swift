import Foundation
import UIKit
import UserNotifications

/// Log / Skip actions on scheduled-entry reminders.
///
/// The router is the notification center's delegate from launch, so an action
/// tapped while Protocola is not running still arrives. When the app's store
/// is open the action goes to it; otherwise a short-lived store is opened on
/// the same local database, the entry is recorded, and reminders are resynced.
@MainActor
final class NotificationActionRouter: NSObject, UNUserNotificationCenterDelegate {

    enum Action: String {
        case log = "protocola.entry.log"
        case skip = "protocola.entry.skip"
    }

    static let shared = NotificationActionRouter()
    static let entryCategory = "protocola.entry"
    static let entryIDKey = "entryID"

    /// Set by the open TrackingStore; nil while no store is open.
    var handler: ((String, Action) -> Void)?

    func install() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: Self.entryCategory,
                actions: [
                    UNNotificationAction(
                        identifier: Action.log.rawValue,
                        title: "Log",
                        // Records health data, so the phone must be unlocked.
                        options: [.authenticationRequired]
                    ),
                    UNNotificationAction(
                        identifier: Action.skip.rawValue,
                        title: "Skip",
                        options: [.authenticationRequired]
                    )
                ],
                intentIdentifiers: [],
                options: []
            )
        ])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionID = response.actionIdentifier
        let entryID =
            response.notification.request.content
                .userInfo[Self.entryIDKey] as? String

        guard
            let entryID,
            let action = Action(rawValue: actionID)
        else {
            return
        }

        await route(entryID, action)
    }

    private func route(_ entryID: String, _ action: Action) {
        if let handler {
            handler(entryID, action)
            return
        }

        // App launched in the background for this action: record it now so
        // the entry keeps the time the person actually acted.
        guard
            let container = try? LocalPersistence.container()
        else {
            return
        }

        let store = TrackingStore(container: container)
        if let cached = EntitlementCache.read(), cached.grantsAccess() {
            store.receiveEntitlements([StoreService.entitlementName])
        }
        store.handleNotificationAction(entryID, action)
        store.detachNotificationHandler()
    }
}


/// Launch hook: the notification delegate must exist before launch finishes.
final class ProtocolaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MainActor.assumeIsolated {
            NotificationActionRouter.shared.install()
        }
        return true
    }
}

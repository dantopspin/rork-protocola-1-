import Foundation

/// App identity constants used by About, Help, and support surfaces.
enum AppInfo {
    /// Replace with the final support inbox before release if it changes.
    static let supportEmail = "support@protocola.app"

    static var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    static var supportURL: URL {
        URL(string: "mailto:\(supportEmail)?subject=Protocola%20support")!
    }
}

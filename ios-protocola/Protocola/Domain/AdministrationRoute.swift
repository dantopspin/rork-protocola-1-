import Foundation

enum AdministrationRoute: String, CaseIterable, Identifiable, Codable, Sendable {
    case injection = "Injection"
    case oral = "Oral"
    case nasal = "Nasal"
    case topical = "Topical"
    case sublingual = "Sublingual"
    case other = "Other"

    var id: String { rawValue }

    var usesInjectionSite: Bool {
        self == .injection
    }
}

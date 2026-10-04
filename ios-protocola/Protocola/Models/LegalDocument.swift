import Foundation

/// One section of an in-app legal or explanatory document.
struct LegalSection: Identifiable {
    let heading: String
    let body: String
    var id: String { heading }
}

/// An in-app document (Privacy Policy, Terms of Use, Medical Disclaimer, AI data use).
/// Rendered by LegalDocumentView; no network or external destinations involved.
struct LegalDocument: Identifiable {
    let id: String
    let title: String
    let updated: String
    let sections: [LegalSection]
}

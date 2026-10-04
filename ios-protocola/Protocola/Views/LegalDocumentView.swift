import SwiftUI

/// In-app renderer for legal and disclosure documents, styled in Lab Light.
struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spaceL) {
                    Text("Last updated \(document.updated)").font(.caption).foregroundStyle(Theme.muted)
                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: Theme.spaceXS) {
                            Text(section.heading).font(.headline)
                            Text(section.body).font(.subheadline).foregroundStyle(Theme.muted)
                        }
                    }
                }
                .screenPadding()
            }
            .background(Theme.paper)
            .navigationTitle(document.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

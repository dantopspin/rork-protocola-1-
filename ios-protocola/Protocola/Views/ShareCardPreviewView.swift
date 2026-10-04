import SwiftUI

/// In-app preview of the progress card before the native share sheet.
struct ShareCardPreviewView: View {
    let data: ShareCardData?
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var sharing: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spaceL) {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .clipShape(.rect(cornerRadius: Theme.radiusCard))
                            .inkBorder(cornerRadius: Theme.radiusCard)
                        Button { sharing = true } label: { Label("Share", systemImage: "square.and.arrow.up") }
                            .buttonStyle(TrackingPrimaryButtonStyle())
                    } else if data != nil {
                        ProgressView("Preparing card…").frame(maxWidth: .infinity, minHeight: Theme.sharePreviewMinHeight)
                    } else {
                        TrackingEmptyState(icon: "calendar", title: "Nothing to share yet", message: "No scheduled entries in this period.")
                    }
                }.screenPadding().padding(.bottom, Theme.spaceS)
            }
            .background(Theme.paper)
            .navigationTitle("Progress card").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $sharing) { if let image { ActivityView(items: [image]) } }
            .task { render() }
        }
    }
    @MainActor private func render() {
        guard image == nil, let data else { return }
        let renderer = ImageRenderer(content: ShareCardView(data: data))
        renderer.scale = 2
        image = renderer.uiImage
    }
}

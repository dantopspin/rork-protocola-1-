import SwiftUI

/// In-app preview of the progress card before the native share sheet.
struct ShareCardPreviewView: View {
    let data: ShareCardData?

    @Environment(\.dismiss)
    private var dismiss

    @State private var image: UIImage?
    @State private var sharing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXL
                ) {
                    if let image {
                        Eyebrow(
                            text: "Preview"
                        )

                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(
                                height:
                                    Theme.ruleThickness
                            )

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth:
                                    .infinity
                            )

                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(
                                height:
                                    Theme.ruleThickness
                            )

                        Button {
                            sharing = true
                        } label: {
                            Label(
                                "Share progress card",
                                systemImage:
                                    "square.and.arrow.up"
                            )
                        }
                        .buttonStyle(
                            TrackingPrimaryButtonStyle()
                        )

                    } else if data != nil {
                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceM
                        ) {
                            Eyebrow(
                                text:
                                    "Preparing preview"
                            )

                            ProgressView(
                                "Rendering progress card…"
                            )
                            .font(Theme.body)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight:
                                Theme.sharePreviewMinHeight,
                            alignment: .leading
                        )

                    } else {
                        TrackingEmptyState(
                            icon: "calendar",
                            title:
                                "Nothing to share yet",
                            message:
                                "No scheduled entries are available in this period."
                        )
                    }
                }
                .screenPadding()
                .padding(
                    .bottom,
                    Theme.spaceXL
                )
            }
            .scrollIndicators(.hidden)
            .background(Theme.paper)
            .navigationTitle(
                "Progress card"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(
                isPresented: $sharing
            ) {
                if let image {
                    ActivityView(
                        items: [image]
                    )
                }
            }
            .task {
                render()
            }
        }
    }


    @MainActor
    private func render() {
        guard
            image == nil,
            let data
        else {
            return
        }

        let renderer =
            ImageRenderer(
                content:
                    ShareCardView(
                        data: data
                    )
            )

        renderer.scale = 2
        image = renderer.uiImage
    }
}

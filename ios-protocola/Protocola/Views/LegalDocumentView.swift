import SwiftUI

/// In-app renderer for legal and disclosure documents.
struct LegalDocumentView: View {
    let document: LegalDocument

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXL
                ) {
                    Eyebrow(
                        text:
                            "Last updated "
                            + document.updated
                    )

                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(
                            height:
                                Theme.ruleThickness
                        )

                    ForEach(
                        Array(
                            document.sections
                                .enumerated()
                        ),
                        id: \.element.id
                    ) { index, section in
                        VStack(
                            alignment: .leading,
                            spacing: Theme.spaceS
                        ) {
                            Text(
                                section.heading
                            )
                            .font(
                                Theme.sectionTitle
                            )
                            .foregroundStyle(
                                Theme.ink
                            )

                            Text(section.body)
                                .font(Theme.body)
                                .foregroundStyle(
                                    Theme
                                        .textSecondary
                                )
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }

                        if index
                            < document.sections
                                .count - 1 {
                            Rectangle()
                                .fill(
                                    Theme.hairline
                                )
                                .frame(
                                    height:
                                        Theme
                                            .ruleThickness
                                )
                        }
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
                document.title
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

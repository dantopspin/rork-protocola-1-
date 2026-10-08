import SwiftUI

/// Section label. Sentence case at Footnote Semibold, like native iOS
/// section headers; the uppercase, letter-spaced version read as a template.
struct Eyebrow: View {
    let text: String
    var onDark: Bool = false

    var body: some View {
        Text(text)
            .font(Theme.sectionLabel)
            .textCase(nil)
            .foregroundStyle(
                onDark
                    ? Theme.onDarkSecondary
                    : Theme.textSecondary
            )
            .accessibilityAddTraits(.isHeader)
    }
}

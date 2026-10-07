import SwiftUI

/// Section footers explain; they never outweigh the rows above them.
struct FormFooter<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
    }
}

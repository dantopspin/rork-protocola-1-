import SwiftUI

struct Eyebrow: View {
    let text: String
    var onDark: Bool = false

    var body: some View {
        Text(text)
            .font(Theme.micro)
            .foregroundStyle(
                onDark
                    ? Color.white.opacity(0.58)
                    : Theme.muted
            )
    }
}

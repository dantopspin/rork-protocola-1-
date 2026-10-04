import SwiftUI

struct Eyebrow: View {
    let text: String
    var onDark: Bool = false

    var body: some View {
        Text(text)
            .font(Theme.micro)
            .foregroundStyle(
                onDark
                    ? Theme.onDarkSecondary
                    : Theme.muted
            )
    }
}

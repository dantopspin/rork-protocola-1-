import SwiftUI

struct Eyebrow: View {
    let text: String
    var onDark: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(Theme.micro)
            .tracking(
                Theme.eyebrowTracking
            )
            .foregroundStyle(
                onDark
                    ? Theme.onDarkSecondary
                    : Theme.textSecondary
            )
    }
}

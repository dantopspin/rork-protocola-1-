import SwiftUI

struct Eyebrow: View {
    let text: String
    var onDark: Bool = false
    var body: some View {
        Text(text.uppercased()).font(.caption2.weight(.semibold)).tracking(1.4)
            .foregroundStyle(onDark ? Color.white.opacity(0.64) : Theme.muted)
    }
}

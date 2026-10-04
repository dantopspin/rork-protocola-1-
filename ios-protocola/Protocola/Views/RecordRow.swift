import SwiftUI

struct RecordRow: View {
    let label: String
    let value: String
    var onDark: Bool = false
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(onDark ? Color.white.opacity(0.64) : Theme.muted)
            Spacer(minLength: Theme.spaceM)
            Text(value)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .foregroundStyle(onDark ? Color.white : Theme.ink)
        }.font(.subheadline)
    }
}

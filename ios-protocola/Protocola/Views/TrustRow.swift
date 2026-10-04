import SwiftUI

/// Sparse statement row: muted symbol beside a short title and detail, divided by hairlines.
/// Shared by onboarding and the paywall so the pattern never drifts. The compact variant
/// tightens vertical padding for screens that must fit without scrolling.
struct TrustRow: View {
    let icon: String
    let title: String
    let detail: String
    var compact: Bool = false
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spaceS) {
            Image(systemName: icon).font(.body).foregroundStyle(Theme.muted).frame(width: 28)
            VStack(alignment: .leading, spacing: Theme.spaceXXS) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, compact ? Theme.spaceXS : Theme.spaceM)
    }
}

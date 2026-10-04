import SwiftUI

/// Status colored by meaning: recorded/active in teal, attention states in amber,
/// pending and inactive states (scheduled, skipped, paused, archived) in muted gray.
/// The capsule stays — compact semantic rounding matching system badge shapes.
struct StatusBadge: View {
    let text: String
    private var tint: Color {
        switch text {
        case "Logged", "Active", "Week recorded": Theme.teal
        case "Partial", "Delayed", "Low recorded balance", "Depleted": Theme.amber
        default: Theme.muted
        }
    }
    var body: some View {
        Text(text).font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 5).foregroundStyle(tint).background(tint.opacity(0.1), in: .capsule)
    }
}

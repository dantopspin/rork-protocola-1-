import SwiftUI

/// The single empty-state pattern: muted symbol, short title, one-line message, optional action.
/// Used identically on Today, Protocols, History, and Inventory.
struct TrackingEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    var body: some View {
        VStack(spacing: Theme.spaceS) {
            Image(systemName: icon).font(.title2).foregroundStyle(Theme.muted)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(TrackingSecondaryButtonStyle()).padding(.top, Theme.spaceXS)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spaceM)
    }
}

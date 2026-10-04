import SwiftUI

/// The standard editorial data card: white surface with a crisp 1pt soft-ink border.
/// Borders separate cards; the content layer uses no shadows.
struct TrackingCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM, content: content)
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.spaceL)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusCard))
            .inkBorder(cornerRadius: Theme.radiusCard)
    }
}

/// The single dark surface in the app — the Today hero. White content, no border:
/// the ink fill itself separates the card from the paper.
struct TrackingHeroCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM, content: content)
            .frame(maxWidth: .infinity, alignment: .leading).padding(Theme.spaceL)
            .background(Theme.ink, in: .rect(cornerRadius: Theme.radiusCard))
    }
}

/// A tappable card row with a trailing chevron, used for navigation targets outside lists.
struct TrackingNavLink<Label: View, Trailing: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @ViewBuilder var trailing: () -> Trailing
    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.action = action
        self.label = label
        self.trailing = trailing
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spaceS) {
                label()
                Spacer(minLength: Theme.spaceXS)
                trailing()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Theme.muted).accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .padding(Theme.spaceL)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusRow))
            .inkBorder(cornerRadius: Theme.radiusRow)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// Crisp 1pt border in the shared soft-ink tone — the editorial separation
    /// for content cards and interactive surfaces.
    func inkBorder(cornerRadius: CGFloat) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Theme.border, lineWidth: 1))
    }
}

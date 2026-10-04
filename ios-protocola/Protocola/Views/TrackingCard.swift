import SwiftUI

/// Standard content surface: warm white, sharp radius, quiet hairline.
/// Avoid nested cards unless the hierarchy truly needs them.
struct TrackingCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM,
            content: content
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(Theme.spaceM)
        .background(
            Theme.surface,
            in: .rect(
                cornerRadius:
                    Theme.radiusCard
            )
        )
        .inkBorder(
            cornerRadius:
                Theme.radiusCard
        )
    }
}


/// High-value dark surface. Use once per screen at most.
struct TrackingHeroCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM,
            content: content
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(Theme.spaceM)
        .background(
            Theme.ink,
            in: .rect(
                cornerRadius:
                    Theme.radiusCard
            )
        )
    }
}


/// Tappable custom row used outside native Lists.
struct TrackingNavLink<
    Label: View,
    Trailing: View
>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @ViewBuilder var trailing: () -> Trailing

    init(
        action: @escaping () -> Void,
        @ViewBuilder label:
            @escaping () -> Label,
        @ViewBuilder trailing:
            @escaping () -> Trailing =
                { EmptyView() }
    ) {
        self.action = action
        self.label = label
        self.trailing = trailing
    }

    var body: some View {
        Button(action: action) {
            HStack(
                spacing: Theme.spaceS
            ) {
                label()

                Spacer(
                    minLength:
                        Theme.spaceXS
                )

                trailing()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(Theme.micro)
                .foregroundStyle(
                    Theme.muted
                )
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .padding(Theme.spaceM)
            .background(
                Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusRow
                )
            )
            .inkBorder(
                cornerRadius:
                    Theme.radiusRow
            )
        }
        .buttonStyle(.plain)
    }
}


extension View {

    func inkBorder(
        cornerRadius: CGFloat
    ) -> some View {
        overlay {
            RoundedRectangle(
                cornerRadius: cornerRadius
            )
            .stroke(
                Theme.border,
                lineWidth: 1
            )
        }
    }

    /// Rare elevation for floating overlays, previews, and transient banners.
    func quietElevation() -> some View {
        shadow(
            color: Theme.shadow,
            radius: 8,
            y: 3
        )
    }
}

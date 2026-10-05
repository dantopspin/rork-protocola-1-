import SwiftUI


/// Shared top-level page header for the four primary tabs.
///
/// Main tabs own their large editorial title in content while the navigation
/// bar stays inline for real actions. This prevents large-title navigation
/// chrome from creating an empty band above the page.
struct PrimaryPageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXS
        ) {
            Text(title)
                .font(Theme.pageTitle)
                .foregroundStyle(Theme.ink)

            if let subtitle,
               !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}


/// Canonical search field for editorial timelines and registries.
struct TrackingSearchField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: Theme.spaceS) {
            Image(systemName: "magnifyingglass")
                .font(Theme.label)
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)

            TextField(
                prompt,
                text: $text
            )
            .font(Theme.body)
            .foregroundStyle(Theme.ink)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .padding(
            .horizontal,
            Theme.spaceS
        )
        .frame(
            minHeight:
                Theme.minimumTapTarget
        )
        .background(
            Theme.subtleFill,
            in: .rect(
                cornerRadius:
                    Theme.radiusField
            )
        )
        .inkBorder(
            cornerRadius:
                Theme.radiusField
        )
    }
}


/// Canonical rule used by editorial sections and record groups.
struct EditorialRule: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(
                height:
                    Theme.ruleThickness
            )
    }
}


/// Canonical section rhythm for technical records and focused sheets.
struct EditorialSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        @ViewBuilder content:
            @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            Eyebrow(text: title)
            EditorialRule()
            content()
            EditorialRule()
        }
    }
}


/// Editorial product surface. Sharp, flat, bordered, and intentionally quiet.
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
        .padding(Theme.cardInset)
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


/// Rare high-value editorial surface.
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
        .padding(Theme.heroInset)
        .background(
            Theme.darkSurface,
            in: .rect(
                cornerRadius:
                    Theme.radiusCard
            )
        )
    }
}


/// Tappable editorial row used outside native Lists.
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
            .padding(
                .vertical,
                Theme.spaceS
            )
            .frame(
                minHeight:
                    Theme.minimumTapTarget
            )
        }
        .buttonStyle(.plain)
        .overlay(
            alignment: .bottom
        ) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: Theme.ruleThickness)
        }
    }
}


extension View {

    func inkBorder(
        cornerRadius: CGFloat
    ) -> some View {
        overlay {
            RoundedRectangle(
                cornerRadius:
                    cornerRadius
            )
            .stroke(
                Theme.border,
                lineWidth:
                    Theme.ruleThickness
            )
        }
    }

    /// Reserved for true floating/transient UI only.
    func quietElevation() -> some View {
        shadow(
            color: Theme.shadow,
            radius: Theme.shadowRadius,
            y: Theme.shadowY
        )
    }
}

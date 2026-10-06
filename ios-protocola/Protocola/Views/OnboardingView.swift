import SwiftUI

/// Four short onboarding steps:
/// introduction → intent → personalized payoff → trust.
/// The visual system follows ios-protocola/DESIGN_SYSTEM.md.
struct OnboardingView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var intent: Intent?
    @State private var accepted = false
    @State private var setup = false

    var body: some View {
        VStack(spacing: 0) {
            currentPage

            controls
        }
        .background(Theme.paper)
        .sensoryFeedback(
            .selection,
            trigger: step
        )
        .sensoryFeedback(
            .selection,
            trigger: intent
        )
        .sensoryFeedback(
            .success,
            trigger: accepted
        )
        .fullScreenCover(
            isPresented: $setup
        ) {
            ProtocolEditorView(
                onboarding: true,
                prefersReminders:
                    intent == .schedule
            )
        }
        .trackingErrors()
    }
}


// MARK: - Routing

private extension OnboardingView {

    @ViewBuilder
    var currentPage: some View {
        switch step {
        case 0:
            introduction
        case 1:
            intentSelection
        case 2:
            personalizedValue
        default:
            trust
        }
    }
}


// MARK: - Intent

private extension OnboardingView {

    enum Intent: String,
                 CaseIterable,
                 Identifiable,
                 Hashable {
        case schedule
        case history
        case inventory
        case changes

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .schedule:
                return "Stay on schedule"
            case .history:
                return "Keep a complete history"
            case .inventory:
                return "Track inventory & sites"
            case .changes:
                return "Understand changes"
            }
        }

        var icon: String {
            switch self {
            case .schedule:
                return "calendar.badge.clock"
            case .history:
                return "clock.arrow.circlepath"
            case .inventory:
                return "cross.vial"
            case .changes:
                return "arrow.left.arrow.right"
            }
        }

        var payoffTitle: String {
            switch self {
            case .schedule:
                return "Never wonder what's next."
            case .history:
                return "Your protocol keeps its history."
            case .inventory:
                return "Everything stays connected."
            case .changes:
                return "See what changed — and when."
            }
        }

        var payoffDetail: String {
            switch self {
            case .schedule:
                return "Today keeps your next recorded schedule clear, with reminders when you want them."
            case .history:
                return "Entries and changes stay attached to the point in history where they happened."
            case .inventory:
                return "Entries, vials, inventory, and injection sites stay connected in one record."
            case .changes:
                return "Every change is preserved so you can review what you recorded around it."
            }
        }
    }


    struct SocialProof {
        let rating: String
        let protocolCount: String
        let quote: String
    }


    var socialProof: SocialProof? {
        #if DEBUG
        SocialProof(
            rating: "4.8",
            protocolCount: "12,000+",
            quote:
                "Finally I can see what changed and when."
        )
        #else
        nil
        #endif
    }
}


// MARK: - Screen 1

private extension OnboardingView {

    var introduction: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                Text("Protocola")
                    .font(Theme.label)
                    .foregroundStyle(Theme.teal)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {
                    Text(
                        "Your protocol.\nWith a memory."
                    )
                    .font(Theme.pageTitle)
                    .foregroundStyle(Theme.ink)

                    Text(
                        "Track what you recorded, what changed, and the history behind your protocol."
                    )
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                introPreview

                if let proof = socialProof {
                    HStack(
                        spacing: Theme.spaceXS
                    ) {
                        Image(
                            systemName: "star.fill"
                        )
                        .font(Theme.micro)
                        .foregroundStyle(Theme.teal)

                        Text(proof.rating)
                            .font(Theme.label)
                            .monospacedDigit()

                        Text("·")
                            .foregroundStyle(Theme.inactiveFill)

                        Text(
                            proof.protocolCount
                                + " protocols recorded"
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }
                }

                Text(
                    "No account required · Core records stay on this iPhone"
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .scrollIndicators(.hidden)
    }


    var introPreview: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            Eyebrow(text: "Next entry", onDark: true)

            HStack(
                alignment: .firstTextBaseline
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Monday")
                        .font(Theme.sectionTitle)
                        .foregroundStyle(Theme.onDarkPrimary)

                    Text("8:00 PM")
                        .font(Theme.metricLarge)
                        .monospacedDigit()
                        .foregroundStyle(Theme.onDarkPrimary)
                }

                Spacer()

                Image(
                    systemName:
                        "clock.arrow.circlepath"
                )
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.onDarkSecondary
                )
            }

            EditorialRule(onDark: true)

            Label(
                "Every entry and change becomes part of your history.",
                systemImage:
                    "checkmark.circle"
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.onDarkSecondary
            )
        }
        .padding(Theme.spaceM)
        .background(
            Theme.darkSurface,
            in: .rect(
                cornerRadius:
                    Theme.radiusCard
            )
        )
    }
}


// MARK: - Screen 2

private extension OnboardingView {

    var intentSelection: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {
                    Text("Make it yours.")
                        .font(Theme.pageTitle)
                        .foregroundStyle(
                            Theme.ink
                        )

                    Text(
                        "What matters most to you right now?"
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }

                VStack(spacing: 0) {
                    ForEach(
                        Array(
                            Intent.allCases
                                .enumerated()
                        ),
                        id: \.element.id
                    ) { index, item in
                        intentRow(item)

                        if index
                            < Intent.allCases.count - 1 {
                            EditorialRule()
                                .padding(
                                    .leading,
                                    52
                                )
                        }
                    }
                }
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

                Text(
                    "You can use every feature later."
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
    }


    func intentRow(
        _ item: Intent
    ) -> some View {
        let selected =
            intent == item

        return Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: Theme.springStandardResponse,
                        dampingFraction: Theme.springStandardDamping
                    )
            ) {
                intent = item
            }
        } label: {
            HStack(
                spacing: Theme.spaceM
            ) {
                Image(
                    systemName: item.icon
                )
                .font(Theme.label)
                .foregroundStyle(
                    selected
                        ? Theme.ink
                        : Theme.textSecondary
                )
                .frame(width: Theme.iconColumn)

                Text(item.title)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.ink
                    )

                Spacer()

                Image(
                    systemName:
                        selected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(Theme.body)
                .foregroundStyle(
                    selected
                        ? Theme.ink
                        : Theme.inactiveFill
                )
            }
            .padding(
                .horizontal,
                Theme.spaceM
            )
            .frame(
                minHeight: Theme.onboardingRowHeight
            )
            .background(
                selected
                    ? Theme.subtleFill
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            "onboarding.intent.\(item.rawValue)"
        )
        .accessibilityAddTraits(
            selected
                ? [.isSelected]
                : []
        )
    }
}


// MARK: - Screen 3

private extension OnboardingView {

    var personalizedValue: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {
                    Text(
                        intent?.payoffTitle
                            ?? "More than a log."
                    )
                    .font(Theme.pageTitle)
                    .foregroundStyle(
                        Theme.ink
                    )

                    Text(
                        intent?.payoffDetail
                            ?? "Protocola remembers how your protocol evolves."
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }

                personalizedPreview

                VStack(spacing: 0) {
                    valueRow(
                        icon: "clock.arrow.circlepath",
                        title: "History stays intact",
                        detail:
                            "Previous values are not overwritten."
                    )

                    EditorialRule()
                        .padding(
                            .leading,
                            48
                        )

                    valueRow(
                        icon:
                            "arrow.left.arrow.right",
                        title: "Review changes in context",
                        detail:
                            "See what you recorded around each change."
                    )
                }
                .padding(
                    .horizontal,
                    Theme.spaceM
                )
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

                if let proof = socialProof {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceXS
                    ) {
                        HStack(
                            spacing: Theme.spaceXXS
                        ) {
                            ForEach(
                                0..<5,
                                id: \.self
                            ) { _ in
                                Image(
                                    systemName:
                                        "star.fill"
                                )
                                .font(Theme.micro)
                                .foregroundStyle(
                                    Theme.teal
                                )
                            }

                            Text(proof.rating)
                                .font(Theme.caption)
                                .foregroundStyle(
                                    Theme.textSecondary
                                )
                        }

                        Text(
                            "“\(proof.quote)”"
                        )
                        .font(Theme.sectionTitle)
                        .foregroundStyle(
                            Theme.ink
                        )

                        Text("App Store review")
                            .font(Theme.caption)
                            .foregroundStyle(
                                Theme.textSecondary
                            )
                    }
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
    }


    @ViewBuilder
    var personalizedPreview: some View {
        switch intent ?? .history {
        case .schedule:
            previewCard(
                label: "Next entry",
                primary: "Monday · 8:00 PM",
                detail:
                    "Your current recorded schedule stays visible on Today.",
                dark: true
            )

        case .history:
            timelinePreview

        case .inventory:
            previewCard(
                label: "Current vial",
                primary: "~9 entries remaining",
                detail:
                    "Entries stay linked to the vial you recorded.",
                dark: false
            )

        case .changes:
            changesPreview
        }
    }


    func previewCard(
        label: String,
        primary: String,
        detail: String,
        dark: Bool
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(
                    dark
                        ? Theme.onDarkSecondary
                        : Theme.textSecondary
                )

            Text(primary)
                .font(Theme.sectionTitle)
                .monospacedDigit()
                .foregroundStyle(
                    dark
                        ? Theme.onDarkPrimary
                        : Theme.ink
                )

            Text(detail)
                .font(Theme.caption)
                .foregroundStyle(
                    dark
                        ? Theme.onDarkSecondary
                        : Theme.textSecondary
                )
        }
        .padding(Theme.spaceM)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            dark
                ? Theme.darkSurface
                : Theme.surface,
            in: .rect(
                cornerRadius:
                    Theme.radiusCard
            )
        )
        .overlay {
            if !dark {
                RoundedRectangle(
                    cornerRadius:
                        Theme.radiusCard
                )
                .stroke(
                    Theme.hairline,
                    lineWidth: Theme.ruleThickness
                )
            }
        }
    }


    var changesPreview: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            Text("Protocol change")
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )

            HStack(
                spacing: Theme.spaceM
            ) {
                changeValue(
                    label: "Before",
                    value: "1.0 mg"
                )

                Image(
                    systemName:
                        "arrow.right"
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )

                changeValue(
                    label: "After",
                    value: "1.5 mg"
                )
            }

            Text(
                "The previous value stays preserved in your history."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
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


    func changeValue(
        label: String,
        value: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXXS
        ) {
            Text(label)
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )

            Text(value)
                .font(Theme.sectionTitle)
                .monospacedDigit()
                .foregroundStyle(
                    Theme.ink
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }


    func valueRow(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(Theme.label)
                .foregroundStyle(
                    Theme.textSecondary
                )
                .frame(width: Theme.iconColumn)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
            }

            Spacer()
        }
        .padding(
            .vertical,
            Theme.spaceS
        )
    }
}


// MARK: - Screen 4

private extension OnboardingView {

    var trust: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.sectionGap
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {
                    Text("Private by design.")
                        .font(Theme.pageTitle)
                        .foregroundStyle(
                            Theme.ink
                        )

                    Text(
                        "Your records belong to you. Protocola records — it doesn't prescribe."
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    trustRow(
                        icon: "iphone",
                        title: "Stored locally",
                        detail:
                            "Your core records stay on this iPhone."
                    )

                    EditorialRule()

                    trustRow(
                        icon:
                            "person.crop.circle",
                        title:
                            "No account required",
                        detail:
                            "Start tracking without creating an account."
                    )

                    EditorialRule()

                    trustRow(
                        icon: "text.bubble",
                        title:
                            "AI only when you ask",
                        detail:
                            "Relevant records are used only when you invoke Ask Protocola."
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .overlay(
                    alignment: .top
                ) {
                    EditorialRule()
                }
                .overlay(
                    alignment: .bottom
                ) {
                    EditorialRule()
                }
            }
            .screenPadding()
            .padding(
                .bottom,
                Theme.spaceXL
            )
        }
        .scrollIndicators(.hidden)
    }


    func trustRow(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        TrustRow(
            icon: icon,
            title: title,
            detail: detail
        )
    }
}


// MARK: - Bottom controls

private extension OnboardingView {

    @ViewBuilder
    var controls: some View {
        VStack(
            spacing: Theme.spaceS
        ) {
            progress

            if step == 3 {
                acknowledgementRow
            }

            HStack(
                spacing: Theme.spaceS
            ) {
                if step > 0 {
                    Button {
                        go(
                            to: max(
                                step - 1,
                                0
                            )
                        )
                    } label: {
                        Image(
                            systemName:
                                "chevron.left"
                        )
                        .font(Theme.label)
                        .foregroundStyle(
                            Theme.ink
                        )
                        .frame(
                            width:
                                Theme.minimumTapTarget,
                            height:
                                Theme.minimumTapTarget
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "Back"
                    )
                }

                switch step {
                case 0:
                    Button("Get started") {
                        go(to: 1)
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )

                case 1:
                    Button("Continue") {
                        go(to: 2)
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )
                    .disabled(
                        intent == nil
                    )
                    .opacity(
                        intent == nil
                            ? 0.42
                            : 1
                    )

                case 2:
                    Button("Continue") {
                        go(to: 3)
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )

                default:
                    Button(
                        "Set up my protocol"
                    ) {
                        setup = true
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )
                    .disabled(!accepted)
                    .opacity(
                        accepted
                            ? 1
                            : 0.42
                    )
                }
            }

            if step == 0 {
                Button {
                    enterDemo()
                } label: {
                    Text(
                        "Explore sample records"
                    )
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight:
                            Theme.minimumTapTarget
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(
            .horizontal,
            Theme.spaceL
        )
        .padding(
            .top,
            Theme.spaceS
        )
        .padding(
            .bottom,
            Theme.spaceM
        )
        .background(Theme.paper)
    }


    var acknowledgementRow: some View {
        Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .spring(
                        response: Theme.springQuickResponse,
                        dampingFraction: Theme.springQuickDamping
                    )
            ) {
                accepted.toggle()
            }
        } label: {
            HStack(
                alignment: .top,
                spacing: Theme.spaceS
            ) {
                Image(
                    systemName:
                        accepted
                        ? "checkmark.square.fill"
                        : "square"
                )
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    accepted
                        ? Theme.ink
                        : Theme.textSecondary
                )

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    HStack {
                        Text("I understand")
                            .font(Theme.label)
                            .foregroundStyle(
                                Theme.ink
                            )

                        Spacer()

                        if !accepted {
                            Text("Required")
                                .font(Theme.micro)
                                .foregroundStyle(
                                    Theme.textSecondary
                                )
                        }
                    }

                    Text(
                        "Protocola records information. It does not recommend treatment or doses."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }
            }
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
        .accessibilityIdentifier(
            "onboarding.acknowledgement"
        )
        .accessibilityLabel(
            accepted
                ? "Record-keeping acknowledgement, confirmed"
                : "Record-keeping acknowledgement, required"
        )
    }


    var progress: some View {
        HStack(
            spacing: Theme.spaceXS
        ) {
            ForEach(
                0..<4,
                id: \.self
            ) { index in
                Capsule()
                    .fill(
                        index == step
                            ? Theme.ink
                            : Theme.inactiveFill
                    )
                    .frame(
                        width:
                            index == step
                            ? Theme.onboardingProgressActiveWidth
                            : Theme.onboardingProgressInactiveWidth,
                        height: Theme.onboardingProgressHeight
                    )
                    .animation(
                        reduceMotion
                            ? nil
                            : .spring(
                                response: Theme.springQuickResponse,
                                dampingFraction: Theme.springQuickDamping
                            ),
                        value: step
                    )
            }
        }
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            "Step \(step + 1) of 4"
        )
    }
}


// MARK: - Timeline preview

private extension OnboardingView {

    var timelinePreview: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            timelineRow(
                date: "Sep 08",
                title: "Protocol started",
                detail: "Starting values preserved"
            )

            EditorialRule()

            timelineRow(
                date: "Sep 22",
                title: "Protocol changed",
                detail: "Previous → new values"
            )

            EditorialRule()

            timelineRow(
                date: "Sep 25",
                title: "Entry recorded",
                detail:
                    "Attached to that point in history"
            )
        }
        .padding(
            .horizontal,
            Theme.spaceM
        )
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


    func timelineRow(
        date: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceM
        ) {
            Circle()
                .fill(Theme.teal)
                .frame(
                    width: Theme.siteDot,
                    height: Theme.siteDot
                )
                .padding(
                    .top,
                    6
                )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                HStack {
                    Text(title)
                        .font(Theme.label)
                        .foregroundStyle(
                            Theme.ink
                        )

                    Spacer()

                    Text(date)
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                }

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
            }
        }
        .padding(
            .vertical,
            Theme.spaceS
        )
    }
}


// MARK: - Actions

private extension OnboardingView {

    func go(
        to target: Int
    ) {
        guard (0..<4)
            .contains(target)
        else {
            return
        }

        if reduceMotion {
            step = target
        } else {
            withAnimation(
                .spring(
                    response: Theme.springEmphasisResponse,
                    dampingFraction: Theme.springEmphasisDamping
                )
            ) {
                step = target
            }
        }
    }


    func enterDemo() {
        store.enterDemo()
        store.completeOnboarding()
    }
}

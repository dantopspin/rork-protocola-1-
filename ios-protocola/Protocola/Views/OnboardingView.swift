import SwiftUI

/// Minimal conversion-focused onboarding:
///
/// 1. Introduction
/// 2. Intent
/// 3. Personalized value + social proof
/// 4. Trust + required acknowledgement
///
/// Then directly into the real ProtocolEditorView.
struct OnboardingView: View {

    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var intent: Intent?
    @State private var accepted = false
    @State private var setup = false

    // MARK: - Social proof
    //
    // Preview values.
    // Only ship these publicly if they are real and verifiable.

    private let appStoreRating = "4.8"
    private let protocolsRecorded = "12,000+"
    private let testimonial =
        "Finally I can see what changed and when."

    var body: some View {
        VStack(spacing: 0) {

            TabView(selection: $step) {

                introduction
                    .tag(0)

                intentSelection
                    .tag(1)

                personalizedValue
                    .tag(2)

                trust
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            controls
        }
        .background(Theme.paper)
        .sensoryFeedback(.selection, trigger: step)
        .sensoryFeedback(.selection, trigger: intent)
        .fullScreenCover(isPresented: $setup) {
            ProtocolEditorView(
                onboarding: true,
                prefersReminders: intent == .schedule
            )
        }
        .trackingErrors()
    }
}


// MARK: - Intent

private extension OnboardingView {

    enum Intent: String, CaseIterable, Identifiable {
        case schedule
        case history
        case inventory
        case changes

        var id: String { rawValue }

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
                return
                    "Today keeps your next scheduled entry clear, "
                    + "with reminders when you want them."

            case .history:
                return
                    "Entries and protocol changes stay attached "
                    + "to the history they belong to."

            case .inventory:
                return
                    "Entries, vials, inventory, and injection sites "
                    + "stay connected in one record."

            case .changes:
                return
                    "Every change is preserved so you can review "
                    + "what you recorded around it."
            }
        }
    }
}


// MARK: - 1. Introduction

private extension OnboardingView {

    var introduction: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {

                Text("PROTOCOLA")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.teal)

                Spacer()
                    .frame(height: Theme.spaceS)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceM
                ) {

                    Text("Your protocol.\nWith a memory.")
                        .font(.largeTitle.weight(.bold))
                        .tracking(-0.7)
                        .foregroundStyle(Theme.ink)

                    Text(
                        "Track what you recorded, what changed, "
                        + "and the history behind your protocol."
                    )
                    .font(.title3)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                introPreview

                socialProofStrip

                HStack(spacing: Theme.spaceXS) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(Theme.muted)

                    Text(
                        "Core records stay on this iPhone · No account"
                    )
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                }
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceXL)
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
            spacing: Theme.spaceL
        ) {

            HStack {
                Text("TODAY")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(
                        Color.white.opacity(0.58)
                    )

                Spacer()

                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(
                        Color.white.opacity(0.64)
                    )
            }

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXS
            ) {

                Text("Next entry")
                    .font(.subheadline)
                    .foregroundStyle(
                        Color.white.opacity(0.64)
                    )

                Text("Monday · 8:00 PM")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }

            Divider()
                .overlay(
                    Color.white.opacity(0.15)
                )

            HStack(spacing: Theme.spaceXS) {

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(
                        Color.white.opacity(0.9)
                    )

                Text(
                    "Every entry and change becomes part of your history."
                )
                .font(.caption)
                .foregroundStyle(
                    Color.white.opacity(0.72)
                )
            }
        }
        .padding(Theme.spaceL)
        .background(
            Theme.ink,
            in: RoundedRectangle(
                cornerRadius: Theme.radiusCard,
                style: .continuous
            )
        )
    }


    var socialProofStrip: some View {
        HStack(spacing: 0) {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.teal)

                    Text(appStoreRating)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                }

                Text("App Store")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            Rectangle()
                .fill(Theme.line)
                .frame(
                    width: 1,
                    height: 34
                )

            Spacer()

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(protocolsRecorded)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)

                Text("protocols recorded")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, Theme.spaceS)
        .background(
            Theme.surface,
            in: RoundedRectangle(
                cornerRadius: Theme.radiusRow,
                style: .continuous
            )
        )
        .inkBorder(
            cornerRadius: Theme.radiusRow
        )
    }
}


// MARK: - 2. Intent

private extension OnboardingView {

    var intentSelection: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {

                    Text("Make it yours.")
                        .font(.largeTitle.weight(.bold))
                        .tracking(-0.7)
                        .foregroundStyle(Theme.ink)

                    Text(
                        "What do you want Protocola "
                        + "to help with most?"
                    )
                    .font(.title3)
                    .foregroundStyle(Theme.muted)
                }

                VStack(spacing: Theme.spaceXS) {
                    ForEach(Intent.allCases) { item in
                        intentRow(item)
                    }
                }

                HStack(
                    alignment: .top,
                    spacing: Theme.spaceXS
                ) {

                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)

                    Text(
                        "We'll use this to emphasize "
                        + "what matters most to you."
                    )
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                }
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceXL)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .scrollIndicators(.hidden)
    }


    func intentRow(_ item: Intent) -> some View {
        let selected = intent == item

        return Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .snappy(duration: 0.2)
            ) {
                intent = item
            }
        } label: {

            HStack(spacing: Theme.spaceM) {

                Image(systemName: item.icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(
                        selected
                            ? Theme.teal
                            : Theme.ink
                    )
                    .frame(width: 28)

                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)

                Spacer()

                Image(
                    systemName:
                        selected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.body)
                .foregroundStyle(
                    selected
                        ? Theme.teal
                        : Theme.line
                )
            }
            .padding(Theme.spaceM)
            .frame(
                maxWidth: .infinity,
                minHeight: 54
            )
            .background(
                selected
                    ? Theme.tealTint
                    : Theme.surface,
                in: RoundedRectangle(
                    cornerRadius: Theme.radiusRow,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: Theme.radiusRow,
                    style: .continuous
                )
                .strokeBorder(
                    selected
                        ? Theme.teal.opacity(0.45)
                        : Theme.border,
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            selected
                ? [.isSelected]
                : []
        )
    }
}


// MARK: - 3. Personalized value

private extension OnboardingView {

    var personalizedValue: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {

                    Text(
                        intent?.payoffTitle
                            ?? "More than a log."
                    )
                    .font(.largeTitle.weight(.bold))
                    .tracking(-0.7)
                    .foregroundStyle(Theme.ink)

                    Text(
                        intent?.payoffDetail
                            ?? "Protocola remembers how your protocol evolves."
                    )
                    .font(.title3)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                timelinePreview

                socialProofCard
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceXL)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .scrollIndicators(.hidden)
    }


    var socialProofCard: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.teal)
                }

                Text(appStoreRating)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
                    .padding(.leading, 4)
            }

            Text("“\(testimonial)”")
                .font(.body.weight(.medium))
                .foregroundStyle(Theme.ink)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            HStack {

                Text("App Store review")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)

                Spacer()

                Text("\(protocolsRecorded) recorded")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(Theme.spaceM)
        .background(
            Theme.surface,
            in: RoundedRectangle(
                cornerRadius: Theme.radiusCard,
                style: .continuous
            )
        )
        .inkBorder(
            cornerRadius: Theme.radiusCard
        )
    }
}


// MARK: - 4. Trust

private extension OnboardingView {

    var trust: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceS
                ) {

                    Text("Private by design.")
                        .font(.largeTitle.weight(.bold))
                        .tracking(-0.7)
                        .foregroundStyle(Theme.ink)

                    Text(
                        "Your records belong to you. "
                        + "Protocola records — it doesn't prescribe."
                    )
                    .font(.title3)
                    .foregroundStyle(Theme.muted)
                }

                VStack(spacing: 0) {

                    trustRow(
                        icon: "iphone",
                        title: "Stored locally",
                        detail:
                            "Your core records stay "
                            + "on this iPhone."
                    )

                    Divider()

                    trustRow(
                        icon: "person.crop.circle.badge.questionmark",
                        title: "No account required",
                        detail:
                            "Start tracking without "
                            + "creating an account."
                    )

                    Divider()

                    trustRow(
                        icon: "text.bubble",
                        title: "AI only when you ask",
                        detail:
                            "Relevant records are used only "
                            + "when you invoke Ask Protocola."
                    )
                }
                .background(
                    Theme.surface,
                    in: RoundedRectangle(
                        cornerRadius: Theme.radiusCard,
                        style: .continuous
                    )
                )
                .inkBorder(
                    cornerRadius: Theme.radiusCard
                )
            }
            .screenPadding()
            .padding(.bottom, Theme.spaceXL)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .scrollIndicators(.hidden)
    }
}


// MARK: - Controls

private extension OnboardingView {

    @ViewBuilder
    var controls: some View {
        VStack(spacing: Theme.spaceS) {

            progress

            switch step {

            case 0:
                VStack(spacing: Theme.spaceXS) {

                    Button("Get started") {
                        go(to: 1)
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )

                    Button {
                        enterDemo()
                    } label: {
                        Text("Explore sample records")
                            .font(
                                .subheadline.weight(.medium)
                            )
                            .foregroundStyle(Theme.muted)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 44
                            )
                    }
                    .buttonStyle(.plain)
                }


            case 1:
                HStack(spacing: Theme.spaceS) {

                    backButton

                    Button("Continue") {
                        go(to: 2)
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )
                    .disabled(intent == nil)
                    .opacity(
                        intent == nil ? 0.45 : 1
                    )
                }


            case 2:
                HStack(spacing: Theme.spaceS) {

                    backButton

                    Button("Continue") {
                        go(to: 3)
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )
                }


            default:
                acknowledgementCard

                HStack(spacing: Theme.spaceS) {

                    backButton

                    Button("Set up my protocol") {
                        setup = true
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )
                    .disabled(!accepted)
                    .opacity(
                        accepted ? 1 : 0.45
                    )
                }
            }
        }
        .padding(.horizontal, Theme.spaceL)
        .padding(.top, Theme.spaceS)
        .padding(.bottom, Theme.spaceS)
        .background(Theme.paper)
    }


    var acknowledgementCard: some View {
        Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .snappy(duration: 0.2)
            ) {
                accepted.toggle()
            }
        } label: {

            HStack(
                alignment: .top,
                spacing: Theme.spaceM
            ) {

                Image(
                    systemName:
                        accepted
                        ? "checkmark.square.fill"
                        : "square"
                )
                .font(.title3)
                .foregroundStyle(
                    accepted
                        ? Theme.teal
                        : Theme.muted
                )

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {

                    HStack {
                        Text("I understand")
                            .font(
                                .subheadline.weight(.semibold)
                            )
                            .foregroundStyle(Theme.ink)

                        Spacer()

                        Text(
                            accepted
                                ? "Confirmed"
                                : "Required"
                        )
                        .font(
                            .caption2.weight(.semibold)
                        )
                        .foregroundStyle(
                            accepted
                                ? Theme.teal
                                : Theme.muted
                        )
                    }

                    Text(
                        "Protocola is a record-keeping tool. "
                        + "It does not prescribe treatment, "
                        + "recommend doses, or verify medical appropriateness."
                    )
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }
            .padding(Theme.spaceM)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                Theme.surface,
                in: RoundedRectangle(
                    cornerRadius: Theme.radiusRow,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: Theme.radiusRow,
                    style: .continuous
                )
                .strokeBorder(
                    accepted
                        ? Theme.teal.opacity(0.45)
                        : Theme.border,
                    lineWidth: 1
                )
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: Theme.radiusRow,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            accepted
                ? "Record-keeping acknowledgement, confirmed"
                : "Record-keeping acknowledgement, required"
        )
        .accessibilityAddTraits(
            accepted
                ? [.isSelected]
                : []
        )
    }


    var backButton: some View {
        Button {
            go(
                to: max(
                    step - 1,
                    0
                )
            )
        } label: {
            Image(systemName: "chevron.left")
                .frame(
                    minWidth: 50,
                    minHeight: 50
                )
        }
        .buttonStyle(
            TrackingSecondaryButtonStyle()
        )
        .frame(width: 56)
        .accessibilityLabel("Back")
    }


    var progress: some View {
        HStack(spacing: Theme.spaceXS) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= step
                            ? Theme.teal
                            : Theme.line
                    )
                    .frame(
                        width:
                            index == step
                            ? 22
                            : 7,
                        height: 7
                    )
                    .animation(
                        reduceMotion
                            ? nil
                            : .snappy(duration: 0.22),
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

            Text("YOUR HISTORY BUILDS OVER TIME")
                .font(
                    .caption2.weight(.semibold)
                )
                .tracking(1)
                .foregroundStyle(Theme.muted)
                .padding(
                    .bottom,
                    Theme.spaceM
                )

            timelineRow(
                date: "SEP 08",
                title: "Protocol started",
                detail: "Starting values preserved",
                icon: "circle.fill"
            )

            timelineDivider

            timelineRow(
                date: "SEP 22",
                title: "Protocol changed",
                detail: "Previous → new values",
                icon:
                    "arrow.triangle.2.circlepath"
            )

            timelineDivider

            timelineRow(
                date: "SEP 25",
                title: "Entry recorded",
                detail:
                    "Attached to that point "
                    + "in your history",
                icon: "checkmark.circle.fill"
            )
        }
        .padding(Theme.spaceM)
        .background(
            Theme.surface,
            in: RoundedRectangle(
                cornerRadius: Theme.radiusCard,
                style: .continuous
            )
        )
        .inkBorder(
            cornerRadius: Theme.radiusCard
        )
    }


    var timelineDivider: some View {
        Divider()
            .padding(.leading, 44)
            .padding(
                .vertical,
                Theme.spaceXS
            )
    }


    func timelineRow(
        date: String,
        title: String,
        detail: String,
        icon: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: Theme.spaceM
        ) {

            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .frame(
                    width: 24,
                    height: 24
                )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {

                HStack {

                    Text(title)
                        .font(
                            .subheadline.weight(
                                .semibold
                            )
                        )
                        .foregroundStyle(Theme.ink)

                    Spacer()

                    Text(date)
                        .font(
                            .caption.monospacedDigit()
                        )
                        .foregroundStyle(Theme.muted)
                }

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
    }
}


// MARK: - Trust rows

private extension OnboardingView {

    func trustRow(
        icon: String,
        title: String,
        detail: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: Theme.spaceM
        ) {

            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .frame(width: 28)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {

                Text(title)
                    .font(
                        .subheadline.weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(Theme.ink)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: 0)
        }
        .padding(
            .vertical,
            Theme.spaceM
        )
        .padding(
            .horizontal,
            Theme.spaceM
        )
    }
}


// MARK: - Navigation

private extension OnboardingView {

    func go(to target: Int) {
        guard (0..<4).contains(target) else {
            return
        }

        if reduceMotion {
            step = target
        } else {
            withAnimation(
                .snappy(duration: 0.25)
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
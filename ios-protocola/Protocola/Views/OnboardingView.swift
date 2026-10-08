import SwiftUI

/// Three short orientation steps:
/// welcome → product model → privacy and record-keeping boundary.
/// The first meaningful task is the real protocol editor.
struct OnboardingView: View {
    @Environment(TrackingStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let stepCount = 3
    private static let lastStep = stepCount - 1

    @State private var step = 0
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
            .success,
            trigger: accepted
        )
        .fullScreenCover(
            isPresented: $setup
        ) {
            ProtocolEditorView(
                onboarding: true,
                // Reminders are the core of daily tracking; the permission
                // sheet explains them before iOS asks, and "Not now" is kept.
                prefersReminders: true
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
            productModel
        default:
            trust
        }
    }
}


// MARK: - Welcome

private extension OnboardingView {

    var introduction: some View {
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
                        "Your peptide protocol,\nrecorded precisely."
                    )
                    .font(Theme.pageTitle)
                    .foregroundStyle(Theme.ink)

                    Text(
                        "Track what you're taking, what actually happened, and how your protocol changes over time."
                    )
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                nextEntryPreview

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


    var nextEntryPreview: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            Eyebrow(
                text: "Next entry",
                onDark: true
            )

            HStack(
                alignment: .firstTextBaseline
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Monday")
                        .font(Theme.sectionTitle)
                        .foregroundStyle(
                            Theme.onDarkPrimary
                        )

                    Text("8:00 PM")
                        .font(Theme.metricLarge)
                        .monospacedDigit()
                        .foregroundStyle(
                            Theme.onDarkPrimary
                        )
                }

                Spacer()
            }

            EditorialRule(onDark: true)

            Label(
                "Your schedule shows up on Today, ready to log.",
                systemImage: "checkmark.circle"
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
        .accessibilityElement(
            children: .combine
        )
    }
}


// MARK: - Product model

private extension OnboardingView {

    var productModel: some View {
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
                        "One record. Every change preserved."
                    )
                    .font(Theme.pageTitle)
                    .foregroundStyle(Theme.ink)

                    Text(
                        "Protocola follows a simple loop built around the protocol you already have."
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                }

                workflow

                Text(
                    "No lifestyle quiz. No treatment recommendations. Just the protocol and records you choose to enter."
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.textSecondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
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


    /// Three steps grouped by spacing alone: icon, title, one line.
    var workflow: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceL
        ) {
            workflowStep(
                icon: "calendar",
                title: "Plan",
                detail:
                    "Record the schedule and instructions you already have."
            )

            workflowStep(
                icon: "checkmark.circle",
                title: "Log",
                detail:
                    "Capture what actually happened without rewriting the plan."
            )

            workflowStep(
                icon:
                    "arrow.left.arrow.right",
                title: "Understand",
                detail:
                    "Review history and compare periods around recorded changes."
            )
        }
    }


    func workflowStep(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Theme.spaceS
        ) {
            Image(systemName: icon)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.teal)
                .frame(
                    width: Theme.iconColumn,
                    alignment: .leading
                )
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(Theme.ink)

                Text(detail)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(
                minLength: 0
            )
        }
        .accessibilityElement(
            children: .combine
        )
    }
}


// MARK: - Trust and boundary

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
                        .foregroundStyle(Theme.ink)

                    Text(
                        "Your records belong to you. Protocola records your protocol. It doesn't prescribe one."
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceL
                ) {
                    workflowStep(
                        icon: "iphone",
                        title: "Stored locally",
                        detail:
                            "Your core tracking records stay on this iPhone."
                    )

                    workflowStep(
                        icon:
                            "person.crop.circle",
                        title:
                            "No account required",
                        detail:
                            "Start tracking without creating a Protocola account."
                    )

                    workflowStep(
                        icon: "lock.shield",
                        title:
                            "Share only when you choose",
                        detail:
                            "Exports and network features are initiated by you; Ask Protocola record sharing is optional."
                    )
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


    var acknowledgementRow: some View {
        Button {
            withAnimation(
                reduceMotion
                    ? nil
                    : .spring(
                        response:
                            Theme.springQuickResponse,
                        dampingFraction:
                            Theme.springQuickDamping
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
                .font(Theme.modalTitle)
                .foregroundStyle(Theme.teal)

                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    HStack {
                        Text("I understand")
                            .font(Theme.sectionTitle)
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
                        "I will enter instructions I already have. Protocola organizes and compares my records. It does not recommend treatment or doses."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }
            .padding(.vertical, Theme.spaceS)
            .contentShape(Rectangle())
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
        .accessibilityAddTraits(
            accepted
                ? [.isSelected]
                : []
        )
    }
}


// MARK: - Bottom controls

private extension OnboardingView {

    var controls: some View {
        VStack(
            spacing: Theme.spaceS
        ) {
            // The one required step sits right above the button it unlocks,
            // styled as an action rather than as more information.
            if step == Self.lastStep {
                acknowledgementRow
            }

            progress

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
                        .foregroundStyle(Theme.ink)
                        .frame(
                            width:
                                Theme.minimumTapTarget,
                            height:
                                Theme.minimumTapTarget
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }

                if step < Self.lastStep {
                    Button(
                        step == 0
                            ? "Get started"
                            : "Continue"
                    ) {
                        go(
                            to: step + 1
                        )
                    }
                    .buttonStyle(
                        TrackingPrimaryButtonStyle()
                    )

                } else {
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
                            : Theme.pressedControlOpacity
                    )
                    .accessibilityIdentifier(
                        "onboarding.setupProtocol"
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


    var progress: some View {
        HStack(
            spacing: Theme.spaceXS
        ) {
            ForEach(
                0..<Self.stepCount,
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
                        height:
                            Theme.onboardingProgressHeight
                    )
                    .animation(
                        reduceMotion
                            ? nil
                            : .spring(
                                response:
                                    Theme.springQuickResponse,
                                dampingFraction:
                                    Theme.springQuickDamping
                            ),
                        value: step
                    )
            }
        }
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            "Step \(step + 1) of \(Self.stepCount)"
        )
    }
}


// MARK: - Actions

private extension OnboardingView {

    func go(
        to target: Int
    ) {
        guard
            (0..<Self.stepCount)
                .contains(target)
        else {
            return
        }

        if reduceMotion {
            step = target

        } else {
            withAnimation(
                .spring(
                    response:
                        Theme.springEmphasisResponse,
                    dampingFraction:
                        Theme.springEmphasisDamping
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

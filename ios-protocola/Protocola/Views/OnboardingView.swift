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
            .selection,
            trigger: accepted
        )
        .fullScreenCover(
            isPresented: $setup
        ) {
            ProtocolEditorView(
                onboarding: true,
                prefersReminders: false
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


// MARK: - Screen 1 · Welcome

private extension OnboardingView {

    var introduction: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXL
            ) {
                Text("Protocola")
                    .font(Theme.label)
                    .foregroundStyle(Theme.teal)

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
                    .foregroundStyle(Theme.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                nextEntryPreview

                HStack(
                    spacing: Theme.spaceXS
                ) {
                    Label(
                        "No account required",
                        systemImage: "person.crop.circle"
                    )

                    Text("·")
                        .foregroundStyle(Theme.line)

                    Text(
                        "Core records stay on this iPhone"
                    )
                }
                .font(Theme.caption)
                .foregroundStyle(Theme.muted)
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


    var nextEntryPreview: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            HStack(
                alignment: .firstTextBaseline
            ) {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Today")
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.onDarkSecondary
                        )

                    Text("Next entry")
                        .font(Theme.sectionTitle)
                        .foregroundStyle(
                            Theme.onDarkPrimary
                        )
                }

                Spacer()

                Image(
                    systemName:
                        "calendar.badge.clock"
                )
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    Theme.onDarkSecondary
                )
                .accessibilityHidden(true)
            }

            Divider()
                .overlay(
                    Theme.onDarkHairline
                )

            HStack(
                alignment: .firstTextBaseline
            ) {
                Text("Monday")
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.onDarkSecondary
                    )

                Spacer()

                Text("8:00 PM")
                    .font(Theme.metricCompact)
                    .monospacedDigit()
                    .foregroundStyle(
                        Theme.onDarkPrimary
                    )
            }

            Label(
                "Your recorded schedule becomes the control surface for Today.",
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
        .accessibilityElement(
            children: .combine
        )
    }
}


// MARK: - Screen 2 · Product model

private extension OnboardingView {

    var productModel: some View {
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
                        "One record. Every change preserved."
                    )
                    .font(Theme.pageTitle)
                    .foregroundStyle(Theme.ink)

                    Text(
                        "Protocola follows a simple loop built around the protocol you already have."
                    )
                    .font(Theme.body)
                    .foregroundStyle(Theme.muted)
                }

                workflow

                changePreview

                Text(
                    "No lifestyle quiz. No treatment recommendations. Just the protocol and records you choose to enter."
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.muted)
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


    var workflow: some View {
        VStack(spacing: 0) {
            workflowStep(
                number: "01",
                icon: "calendar",
                title: "Plan",
                detail:
                    "Record the schedule and instructions you already have."
            )

            EditorialRule()

            workflowStep(
                number: "02",
                icon: "checkmark.circle",
                title: "Log",
                detail:
                    "Capture what actually happened without rewriting the plan."
            )

            EditorialRule()

            workflowStep(
                number: "03",
                icon: "arrow.left.arrow.right",
                title: "Understand",
                detail:
                    "Review history and compare periods around recorded changes."
            )
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
    }


    func workflowStep(
        number: String,
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceM
        ) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(number)
                    .font(Theme.micro)
                    .monospacedDigit()
                    .foregroundStyle(
                        Theme.teal
                    )

                Image(systemName: icon)
                    .font(Theme.label)
                    .foregroundStyle(
                        Theme.muted
                    )
                    .accessibilityHidden(true)
            }
            .frame(
                width: Theme.iconColumn,
                alignment: .leading
            )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(title)
                    .font(Theme.sectionTitle)
                    .foregroundStyle(
                        Theme.ink
                    )

                Text(detail)
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(
                minLength:
                    Theme.spaceS
            )
        }
        .padding(Theme.spaceM)
        .accessibilityElement(
            children: .combine
        )
    }


    var changePreview: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceM
        ) {
            Text("Recorded change")
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )

            HStack(
                alignment: .center,
                spacing: Theme.spaceM
            ) {
                changeState(
                    label: "Before",
                    value: "Previous value"
                )

                Image(
                    systemName: "arrow.right"
                )
                .font(Theme.caption)
                .foregroundStyle(
                    Theme.muted
                )
                .accessibilityHidden(true)

                changeState(
                    label: "After",
                    value: "New value"
                )
            }

            Text(
                "The earlier record stays attached to the period where it was actually in effect."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.muted
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


    func changeState(
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
                    Theme.muted
                )

            Text(value)
                .font(Theme.label)
                .foregroundStyle(
                    Theme.ink
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}


// MARK: - Screen 3 · Trust and boundary

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
                        .font(Theme.pageTitle)
                        .foregroundStyle(
                            Theme.ink
                        )

                    Text(
                        "Your records belong to you. Protocola records your protocol — it doesn't prescribe one."
                    )
                    .font(Theme.body)
                    .foregroundStyle(
                        Theme.muted
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                VStack(spacing: 0) {
                    trustRow(
                        icon: "iphone",
                        title: "Stored locally",
                        detail:
                            "Your core tracking records stay on this iPhone."
                    )

                    EditorialRule()

                    trustRow(
                        icon:
                            "person.crop.circle",
                        title:
                            "No account required",
                        detail:
                            "Start tracking without creating a Protocola account."
                    )

                    EditorialRule()

                    trustRow(
                        icon: "lock.shield",
                        title:
                            "Share only when you choose",
                        detail:
                            "Exports and network features are initiated by you; Ask Protocola record sharing is optional."
                    )
                }
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

                acknowledgementRow
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
                .font(Theme.sectionTitle)
                .foregroundStyle(
                    accepted
                    ? Theme.ink
                    : Theme.muted
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
                                    Theme.muted
                                )
                        }
                    }

                    Text(
                        "I will enter instructions I already have. Protocola can organize, calculate, and compare my records, but it does not recommend treatment or doses."
                    )
                    .font(Theme.caption)
                    .foregroundStyle(
                        Theme.muted
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
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

    @ViewBuilder
    var controls: some View {
        VStack(
            spacing: Theme.spaceS
        ) {
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
                        Theme.muted
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
                            : Theme.line
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

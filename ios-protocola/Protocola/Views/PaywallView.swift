import SwiftUI
import RevenueCat


private enum PaywallDensity {
    case regular
    case compact
    case tight

    var sectionSpacing: CGFloat {
        switch self {
        case .regular:
            Theme.spaceM

        case .compact:
            Theme.spaceS

        case .tight:
            Theme.spaceXS
        }
    }

    var itemSpacing: CGFloat {
        switch self {
        case .regular:
            Theme.spaceS

        case .compact:
            Theme.spaceXS

        case .tight:
            Theme.spaceXXS
        }
    }

    var titleFont: Font {
        switch self {
        case .regular, .compact:
            Theme.pageTitle

        case .tight:
            Theme.modalTitle
        }
    }

    var supportingFont: Font {
        switch self {
        case .regular:
            Theme.body

        case .compact, .tight:
            Theme.caption
        }
    }

    var testimonialFont: Font {
        switch self {
        case .regular:
            Theme.body

        case .compact, .tight:
            Theme.caption
        }
    }

    var showsSupportingCopy: Bool {
        self != .tight
    }

    var showsBenefitDetails: Bool {
        self == .regular
    }

    var testimonialLineLimit: Int {
        switch self {
        case .regular:
            2

        case .compact, .tight:
            1
        }
    }

    var benefitPadding: CGFloat {
        switch self {
        case .regular:
            Theme.spaceXS

        case .compact:
            Theme.spaceXXS

        case .tight:
            Theme.spaceXXS
        }
    }

    var planPadding: CGFloat {
        switch self {
        case .regular:
            Theme.spaceS

        case .compact, .tight:
            Theme.spaceXS
        }
    }
}


/// Contextual, conversion-focused Pro paywall.
///
/// Standard iPhone layouts do not scroll. ViewThatFits progressively removes
/// secondary copy while preserving the offer, pricing, CTA, trust, restore,
/// free continuation, and legal links.
///
/// Accessibility Dynamic Type is allowed to scroll instead of shrinking text.
struct PaywallView: View {
    var reason: PaywallReason = .pro

    @Environment(TrackingStore.self)
    private var store

    @Environment(StoreService.self)
    private var purchases

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @State private var document: LegalDocument?
    @State private var showSuccess = false
    @State private var selectedPackageIdentifier: String?

    var body: some View {
        NavigationStack {
            Group {
                if showSuccess {
                    successContent
                } else {
                    adaptivePaywall
                }
            }
            .background(Theme.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showSuccess {
                    ToolbarItem(
                        placement: .cancellationAction
                    ) {
                        Button {
                            dismiss()
                        } label: {
                            Label(
                                "Close",
                                systemImage: "xmark"
                            )
                        }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Close")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .sheet(item: $document) {
            LegalDocumentView(document: $0)
        }
        .alert(
            purchases.alert?.title ?? "",
            isPresented: Binding(
                get: {
                    purchases.alert != nil
                },
                set: {
                    if !$0 {
                        purchases.alert = nil
                    }
                }
            ),
            presenting: purchases.alert
        ) { _ in
            Button("OK") {
                purchases.alert = nil
            }
        } message: { alert in
            Text(alert.message)
        }
        .onChange(of: store.isPremium) { _, active in
            if active {
                withAnimation(
                    reduceMotion
                        ? nil
                        : .easeOut(
                            duration:
                                Theme.motionStateDuration
                        )
                ) {
                    showSuccess = true
                }
            }
        }
        .sensoryFeedback(
            .success,
            trigger: store.isPremium
        ) { wasActive, active in
            active && !wasActive
        }
        .sensoryFeedback(
            .impact(weight: .light),
            trigger: purchases.isPurchasing
        ) { wasActive, active in
            active && !wasActive
        }
    }


    // MARK: - Adaptive layout

    @ViewBuilder
    private var adaptivePaywall: some View {
        if dynamicTypeSize.isAccessibility {
            ScrollView {
                paywallContent(
                    density: .regular
                )
                .padding(
                    .horizontal,
                    Theme.pageInset
                )
                .padding(
                    .vertical,
                    Theme.spaceM
                )
            }
            .scrollIndicators(.hidden)

        } else {
            ViewThatFits(
                in: .vertical
            ) {
                paywallContent(
                    density: .regular
                )

                paywallContent(
                    density: .compact
                )

                paywallContent(
                    density: .tight
                )
            }
            .padding(
                .horizontal,
                Theme.pageInset
            )
            .padding(
                .top,
                Theme.spaceXXS
            )
            .padding(
                .bottom,
                Theme.spaceXS
            )
        }
    }


    private func paywallContent(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: density.sectionSpacing
        ) {
            header(
                density: density
            )

            if let testimonial =
                PaywallTestimonial
                    .verified
                    .first {

                testimonialBlock(
                    testimonial,
                    density: density
                )
            }

            benefits(
                density: density
            )

            plansSection(
                density: density
            )

            purchaseSection(
                density: density
            )

            footer(
                density: density
            )
        }
    }


    // MARK: - Hero

    private func header(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: density.itemSpacing
        ) {
            Eyebrow(
                text: reason.eyebrow
            )

            Text(reason.headline)
                .font(
                    density.titleFont
                )
                .foregroundStyle(
                    Theme.ink
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            if density.showsSupportingCopy {
                Text(
                    reason.supportingCopy
                )
                .font(
                    density.supportingFont
                )
                .foregroundStyle(
                    Theme.textSecondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }


    // MARK: - Social proof

    private func testimonialBlock(
        _ testimonial: PaywallTestimonial,
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceXXS
        ) {
            Text(
                "“\(testimonial.quote)”"
            )
            .font(
                density.testimonialFont
            )
            .foregroundStyle(
                Theme.ink
            )
            .lineLimit(
                density.testimonialLineLimit
            )

            Text(
                testimonial.attribution
            )
            .font(
                Theme.micro
            )
            .foregroundStyle(
                Theme.textSecondary
            )
            .lineLimit(1)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .horizontal,
            Theme.spaceM
        )
        .padding(
            .vertical,
            density == .regular
                ? Theme.spaceS
                : Theme.spaceXS
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


    // MARK: - Benefits

    private func benefits(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            ForEach(
                reason.orderedBenefits
            ) { benefit in
                benefitRow(
                    benefit,
                    density: density
                )
            }
        }
    }


    private func benefitRow(
        _ benefit: PaywallBenefit,
        density: PaywallDensity
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceS
        ) {
            Image(
                systemName: benefit.icon
            )
            .font(
                Theme.label
            )
            .foregroundStyle(
                Theme.teal
            )
            .frame(
                width:
                    Theme.iconColumn
            )
            .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(
                    benefit.title
                )
                .font(
                    Theme.label
                )
                .foregroundStyle(
                    Theme.ink
                )

                if density.showsBenefitDetails {
                    Text(
                        benefit.detail
                    )
                    .font(
                        Theme.caption
                    )
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }

            Spacer(
                minLength:
                    Theme.spaceXS
            )
        }
        .padding(
            .vertical,
            density.benefitPadding
        )
    }


    // MARK: - Plans

    @ViewBuilder
    private func plansSection(
        density: PaywallDensity
    ) -> some View {
        if purchases.offerings.isEmpty {
            plansUnavailable(
                density: density
            )

        } else {
            HStack(
                spacing: density.itemSpacing
            ) {
                ForEach(
                    displayPackages,
                    id: \.identifier
                ) { package in
                    packageChoice(
                        package,
                        density: density
                    )
                }
            }
        }
    }


    private func plansUnavailable(
        density: PaywallDensity
    ) -> some View {
        HStack(
            spacing: Theme.spaceS
        ) {
            if purchases.isLoading {
                ProgressView()
                    .controlSize(
                        .small
                    )

                Text(
                    "Loading plans…"
                )
                .font(
                    Theme.caption
                )
                .foregroundStyle(
                    Theme.textSecondary
                )

            } else {
                Text(
                    "Plans unavailable"
                )
                .font(
                    Theme.caption
                )
                .foregroundStyle(
                    Theme.textSecondary
                )

                Spacer(
                    minLength:
                        Theme.spaceXS
                )

                Button(
                    "Try again"
                ) {
                    Task {
                        await purchases
                            .loadOfferings()
                    }
                }
                .font(
                    Theme.label
                )
                .foregroundStyle(
                    Theme.teal
                )
                .frame(
                    minHeight:
                        Theme.minimumTapTarget
                )
                .buttonStyle(
                    .plain
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            .horizontal,
            Theme.spaceS
        )
        .padding(
            .vertical,
            density.planPadding
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


    private func packageChoice(
        _ package: Package,
        density: PaywallDensity
    ) -> some View {
        let selected =
            selectedPackage?
                .identifier
            == package.identifier

        return Button {
            selectedPackageIdentifier =
                package.identifier
        } label: {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                HStack(
                    spacing: Theme.spaceXXS
                ) {
                    Text(
                        planTitle(
                            package
                        )
                    )
                    .font(
                        Theme.label
                    )
                    .foregroundStyle(
                        Theme.ink
                    )

                    Spacer(
                        minLength:
                            Theme.spaceXXS
                    )

                    if package
                        .packageType
                        == .annual,
                       let savings =
                        annualSavingsPercent {

                        Text(
                            "SAVE \(savings)%"
                        )
                        .font(
                            Theme.micro
                        )
                        .foregroundStyle(
                            Theme.teal
                        )
                        .lineLimit(1)
                    }
                }

                Text(
                    package
                        .storeProduct
                        .localizedPriceString
                )
                .font(
                    density == .tight
                        ? Theme.cardTitle
                        : Theme.sectionTitle
                )
                .foregroundStyle(
                    Theme.ink
                )
                .monospacedDigit()

                Text(
                    periodLabel(
                        package
                    )
                )
                .font(
                    Theme.micro
                )
                .foregroundStyle(
                    Theme.textSecondary
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(
                .horizontal,
                Theme.spaceS
            )
            .padding(
                .vertical,
                density.planPadding
            )
            .background(
                selected
                    ? Theme.tealTint
                    : Theme.surface,
                in: .rect(
                    cornerRadius:
                        Theme.radiusCard
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius:
                        Theme.radiusCard
                )
                .stroke(
                    selected
                        ? Theme.teal
                        : Theme.border,
                    lineWidth:
                        Theme.ruleThickness
                )
            }
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            accessibilityPlanLabel(
                package
            )
        )
        .accessibilityAddTraits(
            selected
                ? .isSelected
                : []
        )
    }


    // MARK: - Purchase CTA

    private func purchaseSection(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: density.itemSpacing
        ) {
            Button {
                guard
                    let package =
                        selectedPackage
                else {
                    return
                }

                Task {
                    await purchases.purchase(
                        package
                    )
                }
            } label: {
                HStack(
                    spacing: Theme.spaceXS
                ) {
                    if purchases.isPurchasing {
                        ProgressView()
                            .controlSize(
                                .small
                            )
                            .tint(
                                Theme.onDarkPrimary
                            )
                    }

                    Text(
                        purchaseButtonTitle
                    )
                    .font(
                        Theme.buttonLabel
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )
            .disabled(
                selectedPackage == nil
                    || purchases.isPurchasing
            )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(
                    "No free trial · Renews automatically until canceled."
                )
                .font(
                    Theme.micro
                )
                .foregroundStyle(
                    Theme.textSecondary
                )

                Text(
                    "Private by design · No ads"
                )
                .font(
                    Theme.micro
                )
                .foregroundStyle(
                    Theme.textSecondary
                )
            }

            if let notice =
                purchases.lastNotice {

                Text(
                    notice
                )
                .font(
                    Theme.micro
                )
                .foregroundStyle(
                    Theme.textSecondary
                )
                .lineLimit(
                    density == .tight
                        ? 1
                        : 2
                )
            }
        }
    }


    // MARK: - Footer

    private func footer(
        density: PaywallDensity
    ) -> some View {
        VStack(
            spacing: density.itemSpacing
        ) {
            Button(
                "Continue with Free"
            ) {
                dismiss()
            }
            .font(
                Theme.label
            )
            .foregroundStyle(
                Theme.textSecondary
            )
            .frame(
                maxWidth: .infinity,
                minHeight:
                    Theme.minimumTapTarget
            )
            .buttonStyle(
                .plain
            )

            HStack(
                spacing: Theme.spaceS
            ) {
                Button(
                    purchases.isRestoring
                        ? "Restoring…"
                        : "Restore"
                ) {
                    Task {
                        await purchases.restore()
                    }
                }
                .disabled(
                    purchases.isRestoring
                        || purchases.isPurchasing
                )

                Button(
                    "Privacy"
                ) {
                    document =
                        LegalContent.privacy
                }
                .accessibilityLabel(
                    "Privacy Policy"
                )

                Button(
                    "Terms"
                ) {
                    document =
                        LegalContent.terms
                }
                .accessibilityLabel(
                    "Terms of Use"
                )
            }
            .font(
                Theme.micro
            )
            .foregroundStyle(
                Theme.teal
            )
            .frame(
                maxWidth: .infinity
            )
        }
    }


    // MARK: - Package helpers

    private var monthlyPackage: Package? {
        purchases.offerings.first {
            $0.packageType == .monthly
        }
    }


    private var annualPackage: Package? {
        purchases.offerings.first {
            $0.packageType == .annual
        }
    }


    private var displayPackages: [Package] {
        var packages: [Package] = []

        if let monthlyPackage {
            packages.append(
                monthlyPackage
            )
        }

        if let annualPackage {
            packages.append(
                annualPackage
            )
        }

        if packages.isEmpty {
            return Array(
                purchases
                    .offerings
                    .prefix(2)
            )
        }

        return packages
    }


    /// Yearly is the default whenever it exists.
    private var selectedPackage: Package? {
        if let identifier =
            selectedPackageIdentifier,
           let explicit =
            purchases.offerings.first(
                where: {
                    $0.identifier
                    == identifier
                }
            ) {

            return explicit
        }

        return annualPackage
            ?? monthlyPackage
            ?? purchases.offerings.first
    }


    private func planTitle(
        _ package: Package
    ) -> String {
        switch package.packageType {
        case .monthly:
            "Monthly"

        case .annual:
            "Yearly"

        default:
            package
                .storeProduct
                .localizedTitle
        }
    }


    private func periodLabel(
        _ package: Package
    ) -> String {
        switch package.packageType {
        case .monthly:
            "per month"

        case .annual:
            "per year"

        default:
            ""
        }
    }


    private func accessibilityPlanLabel(
        _ package: Package
    ) -> String {
        let base =
            planTitle(package)
            + ", "
            + package
                .storeProduct
                .localizedPriceString
            + " "
            + periodLabel(package)

        if package.packageType == .annual,
           let savings =
            annualSavingsPercent {

            return
                base
                + ", save "
                + String(savings)
                + " percent"
        }

        return base
    }


    private var purchaseButtonTitle: String {
        guard
            let package =
                selectedPackage
        else {
            return "Unlock Pro"
        }

        let price =
            package
                .storeProduct
                .localizedPriceString

        switch package.packageType {
        case .monthly:
            return
                "Unlock Pro — "
                + price
                + "/month"

        case .annual:
            return
                "Unlock Pro — "
                + price
                + "/year"

        default:
            return
                "Unlock Pro — "
                + price
        }
    }


    private var annualSavingsPercent: Int? {
        guard
            let annual =
                annualPackage,
            let monthly =
                monthlyPackage
        else {
            return nil
        }

        let monthlyPrice =
            NSDecimalNumber(
                decimal:
                    monthly
                        .storeProduct
                        .price
            )
            .doubleValue

        let annualPrice =
            NSDecimalNumber(
                decimal:
                    annual
                        .storeProduct
                        .price
            )
            .doubleValue

        let annualizedMonthly =
            monthlyPrice * 12

        guard
            annualizedMonthly > 0
        else {
            return nil
        }

        let savings =
            1
            - (
                annualPrice
                / annualizedMonthly
            )

        guard savings > 0 else {
            return nil
        }

        return Int(
            (
                savings * 100
            )
            .rounded()
        )
    }


    // MARK: - Purchase success

    private var successContent: some View {
        VStack(
            spacing: Theme.spaceXL
        ) {
            Spacer(
                minLength: 0
            )

            VStack(
                spacing: Theme.spaceM
            ) {
                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .font(
                    .system(
                        size:
                            Theme
                                .paywallSuccessIconSize,
                        weight: .light
                    )
                )
                .foregroundStyle(
                    Theme.teal
                )
                .accessibilityHidden(
                    true
                )

                VStack(
                    spacing: Theme.spaceS
                ) {
                    Text(
                        "Welcome to Pro"
                    )
                    .font(
                        Theme.pageTitle
                    )
                    .foregroundStyle(
                        Theme.ink
                    )
                    .multilineTextAlignment(
                        .center
                    )

                    Text(
                        "Unlimited protocols, comparisons, level estimates, "
                        + "timeline questions, and Visit Summary PDF are unlocked."
                    )
                    .font(
                        Theme.body
                    )
                    .foregroundStyle(
                        Theme.textSecondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }
            }

            Spacer(
                minLength: 0
            )

            Button(
                "Continue"
            ) {
                dismiss()
            }
            .buttonStyle(
                TrackingPrimaryButtonStyle()
            )
        }
        .padding(
            .horizontal,
            Theme.pageInset
        )
        .padding(
            .vertical,
            Theme.spaceL
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            Theme.paper
        )
        .transition(
            .opacity
        )
    }
}
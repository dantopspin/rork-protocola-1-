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

    var showsSupportingCopy: Bool {
        self != .tight
    }

    var showsBenefitDetails: Bool {
        self == .regular
    }

    var showsFullProofPreview: Bool {
        self == .regular
    }

    var headlineFont: Font {
        switch self {
        case .regular, .compact:
            Theme.pageTitle

        case .tight:
            Theme.modalTitle
        }
    }

    var planVerticalPadding: CGFloat {
        switch self {
        case .regular:
            Theme.spaceS

        case .compact, .tight:
            Theme.spaceXS
        }
    }
}


/// Contextual, single-screen Pro purchase surface.
///
/// Normal Dynamic Type sizes use ViewThatFits to select the richest complete
/// layout that fits the available iPhone height without scrolling.
///
/// Accessibility Dynamic Type can scroll rather than shrinking text below a
/// comfortable reading size.
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
        Group {
            if showSuccess {
                successContent
            } else {
                adaptivePaywall
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .background(
            Theme.paper
        )
        .presentationDetents([
            .large
        ])
        .sheet(
            item: $document
        ) {
            LegalDocumentView(
                document: $0
            )
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
        .onChange(
            of: store.isPremium
        ) { _, active in
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
        .sensoryFeedback(
            .selection,
            trigger:
                selectedPackageIdentifier
        )
    }


    // MARK: - Adaptive layout

    @ViewBuilder
    private var adaptivePaywall: some View {
        if dynamicTypeSize >= .accessibility1 {
            ScrollView {
                paywallContent(
                    density: .regular
                )
                .padding(
                    .horizontal,
                    Theme.pageInset
                )
                .padding(
                    .top,
                    Theme.spaceM
                )
                .padding(
                    .bottom,
                    Theme.spaceL
                )
            }
            .scrollIndicators(
                .hidden
            )

        } else {
            GeometryReader { proxy in
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
                    Theme.spaceS
                )
                .padding(
                    .bottom,
                    Theme.spaceXS
                )
                .frame(
                    width:
                        proxy.size.width,
                    height:
                        proxy.size.height,
                    alignment: .top
                )
            }
        }
    }


    private func paywallContent(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: density.sectionSpacing
        ) {
            topBar

            hero(
                density: density
            )

            proofPreview(
                density: density
            )

            socialProof(
                density: density
            )

            benefits(
                density: density
            )

            plans(
                density: density
            )

            purchaseArea(
                density: density
            )

            footer(
                density: density
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
    }


    // MARK: - Top chrome

    private var topBar: some View {
        HStack(
            alignment: .center
        ) {
            Button {
                dismiss()
            } label: {
                Image(
                    systemName: "xmark"
                )
                .font(
                    Theme.modalTitle
                )
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
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "Close"
            )

            Spacer(
                minLength:
                    Theme.spaceM
            )

            Eyebrow(
                text:
                    reason.eyebrow
            )
        }
    }


    // MARK: - Hero

    private func hero(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: density.itemSpacing
        ) {
            Text(
                reason.headline
            )
            .font(
                density.headlineFont
            )
            .foregroundStyle(
                Theme.ink
            )
            .lineLimit(2)
            .minimumScaleFactor(
                0.88
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
                    Theme.body
                )
                .foregroundStyle(
                    Theme.textSecondary
                )
                .lineLimit(2)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }


    // MARK: - Product proof

    private func proofPreview(
        density: PaywallDensity
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: density.itemSpacing
        ) {
            if density.showsFullProofPreview {
                HStack {
                    Text(
                        "YOUR RECORD, CONNECTED"
                    )
                    .font(
                        Theme.micro
                    )
                    .foregroundStyle(
                        Theme.textSecondary
                    )

                    Spacer()

                    Text(
                        "PRO"
                    )
                    .font(
                        Theme.micro
                    )
                    .foregroundStyle(
                        Theme.teal
                    )
                }
            }

            HStack(
                spacing: Theme.spaceXS
            ) {
                proofPoint(
                    icon: "syringe",
                    label: "Dose"
                )

                proofConnector

                proofPoint(
                    icon: "arrow.triangle.2.circlepath",
                    label: "Change"
                )

                proofConnector

                proofPoint(
                    icon: "chart.xyaxis.line",
                    label: "Pattern"
                )

                proofConnector

                proofPoint(
                    icon: "doc.text",
                    label: "Summary"
                )
            }
        }
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
            in: RoundedRectangle(
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
                Theme.hairline,
                lineWidth:
                    Theme.ruleThickness
            )
        }
    }


    private func proofPoint(
        icon: String,
        label: String
    ) -> some View {
        VStack(
            spacing: Theme.spaceXXS
        ) {
            Image(
                systemName: icon
            )
            .font(
                Theme.label
            )
            .foregroundStyle(
                Theme.teal
            )
            .frame(
                width:
                    Theme.minimumTapTarget,
                height:
                    Theme.minimumTapTarget
            )

            Text(
                label
            )
            .font(
                Theme.micro
            )
            .foregroundStyle(
                Theme.textSecondary
            )
            .lineLimit(1)
            // Natural width so the connectors shrink instead of the label
            // ("Chan…", "Patt…" in the default-size screenshot).
            .fixedSize()
        }
    }


    private var proofConnector: some View {
    EditorialRule()
        .frame(
            maxWidth: .infinity
        )
}


    // MARK: - Social proof

    @ViewBuilder
    private func socialProof(
        density: PaywallDensity
    ) -> some View {
        if let testimonial =
            PaywallTestimonial
                .verified
                .first {

            testimonialView(
                testimonial,
                density: density
            )

        } else {
            fallbackTrustStrip(
                density: density
            )
        }
    }


    private func testimonialView(
        _ testimonial: PaywallTestimonial,
        density: PaywallDensity
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: Theme.spaceS
        ) {
            Image(
                systemName:
                    "quote.opening"
            )
            .font(
                Theme.label
            )
            .foregroundStyle(
                Theme.teal
            )
            .accessibilityHidden(
                true
            )

            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                Text(
                    testimonial.quote
                )
                .font(
                    Theme.label
                )
                .foregroundStyle(
                    Theme.ink
                )
                .lineLimit(
                    density == .regular
                        ? 2
                        : 1
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

            Spacer(
                minLength:
                    Theme.spaceXS
            )
        }
    }


    private func fallbackTrustStrip(
        density: PaywallDensity
    ) -> some View {
        HStack(
            spacing: Theme.spaceS
        ) {
            trustItem(
                icon:
                    "lock.shield",
                text:
                    "Private by design"
            )

            Spacer(
                minLength:
                    Theme.spaceXXS
            )

            trustItem(
                icon:
                    "rectangle.stack",
                text:
                    "Built around your record"
            )

            if density == .regular {
                Spacer(
                    minLength:
                        Theme.spaceXXS
                )

                trustItem(
                    icon:
                        "doc.badge.arrow.up",
                    text:
                        "Exportable summary"
                )
            }
        }
        .padding(
            .vertical,
            Theme.spaceXXS
        )
    }


    private func trustItem(
        icon: String,
        text: String
    ) -> some View {
        HStack(
            spacing: Theme.spaceXXS
        ) {
            Image(
                systemName: icon
            )
            .font(
                Theme.micro
            )
            .foregroundStyle(
                Theme.teal
            )

            Text(
                text
            )
            .font(
                Theme.micro
            )
            .foregroundStyle(
                Theme.textSecondary
            )
            .lineLimit(1)
        }
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
                systemName:
                    benefit.icon
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
            .accessibilityHidden(
                true
            )

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
                .lineLimit(1)

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
                    .lineLimit(1)
                }
            }

            Spacer(
                minLength:
                    Theme.spaceXS
            )
        }
        .padding(
            .vertical,
            density == .regular
                ? Theme.spaceXS
                : Theme.spaceXXS
        )
    }


    // MARK: - Plans

    @ViewBuilder
    private func plans(
        density: PaywallDensity
    ) -> some View {
        if purchases.offerings.isEmpty {
            unavailablePlans(
                density: density
            )

        } else {
            HStack(
                spacing:
                    Theme.spaceXS
            ) {
                ForEach(
                    displayPackages,
                    id: \.identifier
                ) { package in
                    planOption(
                        package,
                        density: density
                    )
                }
            }
        }
    }


    private func planOption(
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
                    spacing:
                        Theme.spaceXXS
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

                    if let badge = savingsBadge,
                       package.packageType == badge.packageType {

                        Text(
                            "SAVE \(badge.percent)%"
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
                    Theme.sectionTitle
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
                density.planVerticalPadding
            )
            .background(
                selected
                    ? Theme.tealTint
                    : Theme.surface,
                in: RoundedRectangle(
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
                        : Theme.hairline,
                    lineWidth:
                        Theme.ruleThickness
                )
            }
            .trackingStateAnimation(
                value: selected
            )
        }
        .buttonStyle(
            TrackingRowButtonStyle()
        )
        .accessibilityLabel(
            accessibilityPlanLabel(
                package
            )
        )
    }


    private func unavailablePlans(
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
                    "Plans could not be loaded."
                )
                .font(
                    Theme.caption
                )
                .foregroundStyle(
                    Theme.textSecondary
                )

                Spacer()

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
                .buttonStyle(
                    .plain
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .horizontal,
            Theme.spaceS
        )
        .padding(
            .vertical,
            density.planVerticalPadding
        )
        .background(
            Theme.surface,
            in: RoundedRectangle(
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
                Theme.hairline,
                lineWidth:
                    Theme.ruleThickness
            )
        }
    }


    // MARK: - Conversion area

    private func purchaseArea(
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
                    spacing:
                        Theme.spaceXS
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

            Text(
                "No free trial · Subscription renews automatically until canceled."
            )
            .font(
                Theme.micro
            )
            .foregroundStyle(
                Theme.textSecondary
            )
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
            .multilineTextAlignment(
                .center
            )
            .lineLimit(
                density == .tight
                    ? 1
                    : 2
            )

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
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                .multilineTextAlignment(
                    .center
                )
                .lineLimit(2)
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
                Button {
                    Task {
                        await purchases.restore()
                    }
                } label: {
                    // Discreet in-place spinner keeps the footer row stable
                    // while the restore transaction is in flight.
                    if purchases.isRestoring {
                        HStack(spacing: Theme.spaceXXS) {
                            ProgressView()
                                .controlSize(.mini)

                            Text("Restoring")
                        }
                    } else {
                        Text("Restore")
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

                Button(
                    "Terms"
                ) {
                    document =
                        LegalContent.terms
                }
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


    private var weeklyPackage: Package? {
        purchases.offerings.first {
            $0.packageType == .weekly
        }
    }


    private var displayPackages: [Package] {
        // The better-value plan sits on the right and is selected by
        // default; the cheaper entry plan sits on the left for contrast.
        if let monthlyPackage {
            if let annualPackage {
                return [monthlyPackage, annualPackage]
            }

            if let weeklyPackage {
                return [weeklyPackage, monthlyPackage]
            }

            return [monthlyPackage]
        }

        if let annualPackage {
            return [annualPackage]
        }

        return Array(
            purchases
                .offerings
                .prefix(2)
        )
    }


    /// Annual is the default whenever it exists.
    private var selectedPackage: Package? {
        if let identifier =
            selectedPackageIdentifier,
           let explicitPackage =
            purchases.offerings.first(
                where: {
                    $0.identifier
                    == identifier
                }
            ) {

            return explicitPackage
        }

        return annualPackage
            ?? monthlyPackage
            ?? purchases.offerings.first
    }


    private func planTitle(
        _ package: Package
    ) -> String {
        switch package.packageType {
        case .weekly:
            "Weekly"

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
        case .weekly:
            "per week"

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
        var value =
            planTitle(package)
            + ", "
            + package
                .storeProduct
                .localizedPriceString
            + " "
            + periodLabel(package)

        if let badge = savingsBadge,
           package.packageType == badge.packageType {

            value +=
                ", save "
                + String(badge.percent)
                + " percent"
        }

        return value
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
        case .weekly:
            return
                "Unlock Pro · "
                + price
                + "/week"

        case .monthly:
            return
                "Unlock Pro · "
                + price
                + "/month"

        case .annual:
            return
                "Unlock Pro · "
                + price
                + "/year"

        default:
            return
                "Unlock Pro · "
                + price
        }
    }


    /// Promotional badge for the better-value plan: annual against monthly,
    /// or monthly against weekly when no annual plan exists.
    private var savingsBadge: (
        packageType: PackageType,
        percent: Int
    )? {
        if let annual = annualPackage,
           let monthly = monthlyPackage {
            return savingsPercent(
                current: annual.storeProduct.price,
                reference: monthly.storeProduct.price,
                referencePeriods: 12
            )
            .map { (packageType: .annual, percent: $0) }
        }

        if let monthly = monthlyPackage,
           let weekly = weeklyPackage {
            // 52/12 average weeks per month, so weekly is compared against
            // its true monthly run rate.
            return savingsPercent(
                current: monthly.storeProduct.price,
                reference: weekly.storeProduct.price,
                referencePeriods: 52.0 / 12.0
            )
            .map { (packageType: .monthly, percent: $0) }
        }

        return nil
    }


    private func savingsPercent(
        current: Decimal,
        reference: Decimal,
        referencePeriods: Double
    ) -> Int? {
        let currentPrice =
            NSDecimalNumber(
                decimal: current
            )
            .doubleValue

        let referencePrice =
            NSDecimalNumber(
                decimal: reference
            )
            .doubleValue

        let referenceRunRate =
            referencePrice * referencePeriods

        guard
            referenceRunRate > 0
        else {
            return nil
        }

        let savings =
            1
            - currentPrice
                / referenceRunRate

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


    // MARK: - Success

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
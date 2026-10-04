import SwiftUI
import RevenueCat

/// Contextual, dismissible paywall.
///
/// Native navigation and toolbar behavior are left to SwiftUI so iOS 26 can
/// provide its current system materials and interaction treatment automatically.
/// Protocola's custom identity stays in the content layer.
struct PaywallView: View {
    var reason: PaywallReason = .pro

    @Environment(TrackingStore.self) private var store
    @Environment(StoreService.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    @State private var document: LegalDocument?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXL
                ) {
                    header
                    benefits
                    plans

                    Text(
                        "No free trial. Subscriptions renew automatically "
                        + "through your Apple ID until canceled in Apple Account settings."
                    )
                    .font(Theme.micro)
                    .foregroundStyle(Theme.muted)

                    if let notice = purchases.lastNotice {
                        Text(notice)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.muted)
                    }

                    Button("Continue on Free") {
                        dismiss()
                    }
                    .font(Theme.label)
                    .foregroundStyle(Theme.muted)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: Theme.minimumTapTarget
                    )
                    .buttonStyle(.plain)

                    linksRow
                }
                .screenPadding()
                .padding(.bottom, Theme.spaceXL)
            }
            .scrollIndicators(.hidden)
            .background(Theme.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Close")
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
                get: { purchases.alert != nil },
                set: { if !$0 { purchases.alert = nil } }
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
                dismiss()
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
        ) { wasActive, isActive in
            isActive && !wasActive
        }
    }


    // MARK: - Sections

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.spaceS
        ) {
            Eyebrow(text: reason.eyebrow)

            Text(reason.headline)
                .font(Theme.pageTitle)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
        }
    }


    private var benefits: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            ForEach(
                Array(reason.orderedBenefits.enumerated()),
                id: \.element.id
            ) { index, benefit in
                if index > 0 {
                    Divider()
                }

                TrustRow(
                    icon: benefit.icon,
                    title: benefit.title,
                    detail: benefit.detail,
                    compact: true
                )
            }
        }
        .overlay(
            alignment: .top
        ) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
        .overlay(
            alignment: .bottom
        ) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
    }


    @ViewBuilder
    private var plans: some View {
        if purchases.offerings.isEmpty {
            TrackingCard {
                if purchases.isLoading {
                    HStack(spacing: Theme.spaceS) {
                        ProgressView()

                        Text("Loading plans…")
                            .font(Theme.body)
                    }
                } else {
                    Text(
                        "Plans could not be loaded right now. "
                        + "Check your connection and try again. "
                        + "Core tracking is unaffected."
                    )
                    .font(Theme.body)
                    .foregroundStyle(Theme.muted)

                    Button("Try again") {
                        Task {
                            await purchases.loadOfferings()
                        }
                    }
                    .buttonStyle(
                        TrackingSecondaryButtonStyle()
                    )
                }
            }
        } else {
            VStack(spacing: Theme.spaceXS) {
                ForEach(
                    purchases.offerings,
                    id: \.identifier
                ) { package in
                    packageRow(package)
                }
            }
        }
    }


    private var linksRow: some View {
        VStack(spacing: Theme.spaceXS) {
            HStack(spacing: 0) {
                Button("Restore Purchases") {
                    Task {
                        await purchases.restore()
                    }
                }
                .foregroundStyle(Theme.teal)
                .disabled(
                    purchases.isRestoring
                        || purchases.isPurchasing
                )

                if purchases.isRestoring {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.leading, Theme.spaceXS)
                }

                if let url = purchases.managementURL {
                    Text("  ·  ")
                        .foregroundStyle(Theme.muted)

                    Link(
                        "Manage subscription",
                        destination: url
                    )
                    .foregroundStyle(Theme.teal)
                }
            }

            HStack(spacing: 0) {
                Button("Privacy Policy") {
                    document = LegalContent.privacy
                }

                Text("  ·  ")
                    .foregroundStyle(Theme.muted)

                Button("Terms of Use") {
                    document = LegalContent.terms
                }
            }
        }
        .font(Theme.caption)
        .frame(maxWidth: .infinity)
    }


    // MARK: - Components

    private func packageRow(_ package: Package) -> some View {
        HStack(spacing: Theme.spaceM) {
            VStack(
                alignment: .leading,
                spacing: Theme.spaceXXS
            ) {
                HStack(spacing: Theme.spaceXS) {
                    Text(package.storeProduct.localizedTitle)
                        .font(Theme.label)
                        .lineLimit(1)

                    if package.packageType == .annual {
                        bestValue
                    }
                }

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: Theme.spaceXS
                ) {
                    Text(
                        "\(package.storeProduct.localizedPriceString) "
                        + periodSuffix(package)
                    )
                    .font(Theme.caption)
                    .foregroundStyle(Theme.muted)
                    .monospacedDigit()

                    if package.packageType == .annual,
                       let savings = annualSavingsPercent {
                        rectTag("Save \(savings)%")
                    }
                }
            }

            Spacer(minLength: Theme.spaceXS)

            Button {
                Task {
                    await purchases.purchase(package)
                }
            } label: {
                Text(
                    purchases.isPurchasing
                        ? "…"
                        : "Subscribe"
                )
            }
            .buttonStyle(TrackingCompactButtonStyle(prominent: true))
            .tint(Theme.ink)
            .controlSize(.regular)
            .disabled(purchases.isPurchasing)
        }
        .padding(
            .vertical,
            Theme.spaceM
        )
        .overlay(
            alignment: .top
        ) {
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
        }
    }


    private var bestValue: some View {
        rectTag("Best value")
    }


    private func rectTag(
        _ text: String
    ) -> some View {
        Text(text)
            .font(Theme.micro)
            .foregroundStyle(Theme.ink)
            .padding(
                .horizontal,
                Theme.spaceXS
            )
            .padding(
                .vertical,
                Theme.spaceXXS
            )
            .background(
                Theme.neutralTint,
                in: .rect(
                    cornerRadius:
                        Theme.radiusBadge
                )
            )
            .inkBorder(
                cornerRadius:
                    Theme.radiusBadge
            )
    }


    private var annualSavingsPercent: Int? {
        guard
            let annual =
                purchases.offerings.first(
                    where: {
                        $0.packageType == .annual
                    }
                ),
            let monthly =
                purchases.offerings.first(
                    where: {
                        $0.packageType == .monthly
                    }
                )
        else {
            return nil
        }

        let monthlyPrice =
            NSDecimalNumber(
                decimal:
                    monthly.storeProduct.price
            )
            .doubleValue
        let annualPrice =
            NSDecimalNumber(
                decimal:
                    annual.storeProduct.price
            )
            .doubleValue

        guard monthlyPrice * 12 > 0 else {
            return nil
        }

        let savings =
            1
            - (
                annualPrice
                / (monthlyPrice * 12)
            )

        guard savings > 0 else {
            return nil
        }

        return Int(
            (savings * 100)
                .rounded()
        )
    }


    private func periodSuffix(_ package: Package) -> String {
        switch package.packageType {
        case .monthly:
            return "per month"

        case .annual:
            return "per year"

        default:
            return ""
        }
    }
}

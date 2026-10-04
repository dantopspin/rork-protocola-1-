import SwiftUI
import RevenueCat

/// Contextual, dismissible paywall presented as a full-screen modal. One compact column,
/// no scrolling: everything fits at once on any iPhone. The eyebrow, headline, and benefit
/// order adapt to why it opened, restating the feature the user just tried to use. Shows
/// real RevenueCat offerings with localized store prices; never fabricates prices and
/// never unlocks access without a verified purchase.
struct PaywallView: View {
    var reason: PaywallReason = .pro
    @Environment(TrackingStore.self) private var store
    @Environment(StoreService.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var document: LegalDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceS) {
            header
            benefits.staggered(2)
            Spacer(minLength: Theme.spaceXS)
            footer.staggered(3)
        }
        .screenPadding()
        .background(Theme.paper.ignoresSafeArea())
        .sheet(item: $document) { LegalDocumentView(document: $0) }
        .alert("Purchase unavailable", isPresented: Binding(get: { purchases.error != nil }, set: { if !$0 { purchases.error = nil } })) {
            Button("OK") { purchases.error = nil }
        } message: { Text(purchases.error ?? "") }
        .onChange(of: store.isPremium) { _, active in if active { dismiss() } }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.spaceS) {
            HStack {
                Eyebrow(text: reason.eyebrow).staggered(0)
                Spacer()
                closeButton
            }
            Text(reason.headline)
                .font(.largeTitle.weight(.semibold)).tracking(-1)
                .lineLimit(2).minimumScaleFactor(0.7)
                .staggered(1)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(reason.orderedBenefits.enumerated()), id: \.element.id) { index, benefit in
                if index > 0 { Divider() }
                TrustRow(icon: benefit.icon, title: benefit.title, detail: benefit.detail, compact: true)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: Theme.spaceS) {
            plans
            Text("No free trial. Subscriptions renew automatically through your Apple ID until canceled in Apple Account settings.")
                .font(.caption2).foregroundStyle(Theme.muted).padding(.top, Theme.spaceXXS)
            if let notice = purchases.lastNotice {
                Text(notice).font(.caption).foregroundStyle(Theme.teal)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            }
            Button("Continue on Free") { dismiss() }
                .font(.subheadline.weight(.medium)).foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.plain)
            linksRow
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: purchases.lastNotice)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: purchases.offerings.isEmpty)
    }

    @ViewBuilder
    private var plans: some View {
        if purchases.offerings.isEmpty {
            TrackingCard {
                if purchases.isLoading {
                    HStack(spacing: Theme.spaceS) { ProgressView(); Text("Loading plans…").font(.subheadline) }
                } else {
                    Text("Plans could not be loaded right now. Check your connection and try again. Core tracking is unaffected.").font(.subheadline)
                    Button("Try again") { Task { await purchases.loadOfferings() } }
                        .buttonStyle(TrackingSecondaryButtonStyle())
                }
            }
        } else {
            VStack(spacing: Theme.spaceXS) {
                ForEach(purchases.offerings, id: \.identifier) { package in
                    packageRow(package)
                }
            }
        }
    }

    private var linksRow: some View {
        VStack(spacing: Theme.spaceXS) {
            HStack(spacing: 0) {
                Button("Restore Purchases") { Task { await purchases.restore() } }
                    .foregroundStyle(Theme.teal)
                    .opacity(purchases.isRestoring || purchases.isPurchasing ? 0.5 : 1)
                    .disabled(purchases.isRestoring || purchases.isPurchasing)
                if purchases.isRestoring { ProgressView().padding(.leading, Theme.spaceXS) }
                if let url = purchases.managementURL {
                    Text("  ·  ").foregroundStyle(Theme.muted)
                    Link("Manage subscription", destination: url).foregroundStyle(Theme.teal)
                }
            }
            HStack(spacing: 0) {
                Button("Privacy Policy") { document = LegalContent.privacy }
                Text("  ·  ").foregroundStyle(Theme.muted)
                Button("Terms of Use") { document = LegalContent.terms }
            }
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Components

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.muted)
                .frame(width: 44, height: 44)
                .background(Theme.surface, in: Circle())
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    private func packageRow(_ package: Package) -> some View {
        HStack(spacing: Theme.spaceM) {
            VStack(alignment: .leading, spacing: Theme.spaceXXS) {
                HStack(spacing: Theme.spaceXS) {
                    Text(package.storeProduct.localizedTitle).font(.subheadline.weight(.semibold)).lineLimit(1)
                    if package.packageType == .annual { bestValue }
                }
                Text("\(package.storeProduct.localizedPriceString) \(periodSuffix(package))")
                    .font(.caption).foregroundStyle(Theme.muted).monospacedDigit()
            }
            Spacer(minLength: 8)
            Button { Task { await purchases.purchase(package) } } label: {
                Text(purchases.isPurchasing ? "…" : "Subscribe")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal, Theme.spaceL).frame(minHeight: 44)
                    .background(Theme.teal, in: .rect(cornerRadius: Theme.radiusButton))
                    .opacity(purchases.isPurchasing ? 0.7 : 1)
            }
            .buttonStyle(.plain)
            .disabled(purchases.isPurchasing)
        }
        .padding(Theme.spaceS)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.radiusRow))
        .inkBorder(cornerRadius: Theme.radiusRow)
    }

    private var bestValue: some View {
        Text("Best value")
            .font(.caption2.weight(.semibold)).foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.spaceXS).padding(.vertical, Theme.spaceXXS)
            .background(Theme.ink.opacity(0.06), in: .rect(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.border, lineWidth: 1))
    }

    private func periodSuffix(_ package: Package) -> String {
        switch package.packageType {
        case .monthly: return "per month"
        case .annual: return "per year"
        default: return ""
        }
    }
}

/// Staggered entrance for paywall sections; runs once per presentation.
private struct Stagger: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Bool = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .onAppear {
                guard !shown else { return }
                if reduceMotion { shown = true }
                else { withAnimation(.snappy(duration: 0.35).delay(Double(index) * 0.07)) { shown = true } }
            }
    }
}

private extension View {
    func staggered(_ index: Int) -> some View { modifier(Stagger(index: index)) }
}

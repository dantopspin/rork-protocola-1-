import Foundation

/// One of the Pro benefits shown as a TrustRow on the paywall.
struct PaywallBenefit: Identifiable {
    let icon: String
    let title: String
    let detail: String
    var id: String { title }

    static let unlimitedProtocols = PaywallBenefit(icon: "list.bullet.rectangle", title: "Unlimited active protocols", detail: "Keep separate timelines for each protocol.")
    static let comparePeriods = PaywallBenefit(icon: "arrow.left.arrow.right", title: "Compare recorded periods", detail: "Descriptive windows around a recorded change.")
    static let askTimeline = PaywallBenefit(icon: "text.bubble", title: "Ask your timeline", detail: "Questions grounded in your own recorded events.")
    static let visitSummary = PaywallBenefit(icon: "doc.text", title: "Visit Summary PDF", detail: "A structured record of your protocol's evolution.")
    static let catalog: [PaywallBenefit] = [.unlimitedProtocols, .comparePeriods, .askTimeline, .visitSummary]
}

/// Why the paywall was presented. Drives the eyebrow, headline, and which benefit leads,
/// so the paywall restates the feature the user just tried to use.
enum PaywallReason: String, Identifiable {
    case pro, compare, ask, summary, secondProtocol
    var id: String { rawValue }

    var eyebrow: String {
        switch self {
        case .pro: "Protocola Pro"
        case .compare: "Compare · Pro"
        case .ask: "Ask Protocola · Pro"
        case .summary: "Visit Summary · Pro"
        case .secondProtocol: "Unlimited protocols · Pro"
        }
    }

    var headline: String {
        switch self {
        case .pro: "Understand your\nprotocol's evolution."
        case .compare: "Compare periods\naround a change."
        case .ask: "Ask your own\nrecorded timeline."
        case .summary: "Bring the record\nto your next visit."
        case .secondProtocol: "Track more than\none protocol."
        }
    }

    /// The benefit matching the trigger; shown first on the paywall.
    private var leadingBenefit: PaywallBenefit {
        switch self {
        case .pro, .secondProtocol: .unlimitedProtocols
        case .compare: .comparePeriods
        case .ask: .askTimeline
        case .summary: .visitSummary
        }
    }

    var orderedBenefits: [PaywallBenefit] {
        [leadingBenefit] + PaywallBenefit.catalog.filter { $0.id != leadingBenefit.id }
    }
}

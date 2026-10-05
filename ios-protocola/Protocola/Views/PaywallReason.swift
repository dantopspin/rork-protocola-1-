import Foundation

/// One concise outcome shown on the Pro paywall.
///
/// The paywall intentionally uses only three outcome groups so the complete
/// conversion surface can fit on one screen at standard Dynamic Type sizes.
struct PaywallBenefit: Identifiable {
    let icon: String
    let title: String
    let detail: String

    var id: String { title }

    static let unlimitedProtocols = PaywallBenefit(
        icon: "list.bullet.rectangle",
        title: "Unlimited protocols",
        detail: "Keep every protocol on its own timeline."
    )

    static let patternsOverTime = PaywallBenefit(
        icon: "chart.xyaxis.line",
        title: "See patterns over time",
        detail: "Compare changes and visualize your recorded dose levels."
    )

    static let completeRecord = PaywallBenefit(
        icon: "doc.text",
        title: "Use your complete record",
        detail: "Ask your timeline and export Visit Summary PDFs."
    )

    static let catalog: [PaywallBenefit] = [
        .unlimitedProtocols,
        .patternsOverTime,
        .completeRecord
    ]
}


/// Verified customer feedback displayed as social proof.
///
/// Keep this collection empty until feedback is genuinely received. Never ship
/// invented names, ratings, quotes, or usage claims on the purchase surface.
struct PaywallTestimonial: Identifiable {
    let quote: String
    let attribution: String

    var id: String {
        quote + attribution
    }

    static let verified: [PaywallTestimonial] = []
}


/// Why the paywall was presented.
///
/// The opening promise changes with the locked feature the user just attempted,
/// while the compact three-benefit structure stays consistent.
enum PaywallReason: String, Identifiable {
    case pro
    case compare
    case levels
    case ask
    case summary
    case secondProtocol

    var id: String { rawValue }

    var eyebrow: String {
        switch self {
        case .pro:
            "Protocola Pro"

        case .compare:
            "Compare · Pro"

        case .levels:
            "Estimated levels · Pro"

        case .ask:
            "Ask Protocola · Pro"

        case .summary:
            "Visit Summary · Pro"

        case .secondProtocol:
            "Unlimited protocols · Pro"
        }
    }

    var headline: String {
        switch self {
        case .pro:
            "Know what changed. See the full picture."

        case .compare:
            "See what changed over time."

        case .levels:
            "See your recorded dose pattern."

        case .ask:
            "Ask questions about your own record."

        case .summary:
            "Take your complete record with you."

        case .secondProtocol:
            "Track every protocol separately."
        }
    }

    var supportingCopy: String {
        switch self {
        case .pro:
            "Turn doses, changes, and history into one clear protocol record."

        case .compare:
            "Compare recorded periods around a change without digging through your timeline."

        case .levels:
            "Visualize transparent half-life estimates built only from doses you recorded."

        case .ask:
            "Get answers grounded in your own recorded timeline, not a generic history."

        case .summary:
            "Create a structured PDF from the protocol history you have already recorded."

        case .secondProtocol:
            "Keep separate schedules, logs, changes, and history for every protocol."
        }
    }

    /// The benefit most closely matching the trigger is shown first.
    private var leadingBenefit: PaywallBenefit {
        switch self {
        case .pro, .secondProtocol:
            .unlimitedProtocols

        case .compare, .levels:
            .patternsOverTime

        case .ask, .summary:
            .completeRecord
        }
    }

    var orderedBenefits: [PaywallBenefit] {
        [leadingBenefit]
        + PaywallBenefit.catalog.filter {
            $0.id != leadingBenefit.id
        }
    }
}

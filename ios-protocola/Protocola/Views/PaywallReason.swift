import Foundation

/// A concise outcome shown on the Pro paywall.
///
/// The purchase surface deliberately groups Pro into three outcomes instead of
/// listing every feature separately. This keeps the hierarchy clear and allows
/// the complete paywall to remain visible on one screen.
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
        title: "Visit Summary for check-ins",
        detail: "Export a PDF of your record for your provider, and ask your own timeline."
    )

    static let catalog: [PaywallBenefit] = [
        .unlimitedProtocols,
        .completeRecord,
        .patternsOverTime
    ]
}


/// Genuine customer feedback shown on the purchase surface.
///
/// Do not add invented quotes, names, ratings, or usage claims.
/// If this collection is empty, PaywallView automatically replaces the
/// testimonial with a compact product-trust strip.
struct PaywallTestimonial: Identifiable {
    let quote: String
    let attribution: String

    var id: String {
        quote + attribution
    }

    static let verified: [PaywallTestimonial] = [
        // Add genuine feedback here when available.
        //
        // PaywallTestimonial(
        //     quote: "Finally a tracker that feels like an actual record.",
        //     attribution: "Alex R. · Pro user"
        // )
    ]
}


/// Why the paywall was presented.
///
/// The opening promise responds to the feature the user just attempted to use.
/// The underlying Pro proposition stays consistent.
enum PaywallReason: String, Identifiable {
    case pro
    case compare
    case levels
    case ask
    case summary
    case secondProtocol
    case health

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

        case .health:
            "Apple Health · Pro"
        }
    }

    var headline: String {
        switch self {
        case .pro:
            "Your record, ready for every check-in."

        case .compare:
            "See what changed over time."

        case .levels:
            "See your recorded dose pattern."

        case .ask:
            "Ask questions about your own record."

        case .summary:
            "Take your complete record with you."

        case .secondProtocol:
            "Track every compound in your stack."

        case .health:
            "See your weight next to your doses."
        }
    }

    var supportingCopy: String {
        switch self {
        case .pro:
            "Every protocol, every change, and a Visit Summary PDF when you need it."

        case .compare:
            "Compare recorded periods around a change without digging through your timeline."

        case .levels:
            "Visualize transparent half-life estimates built from doses you recorded."

        case .ask:
            "Get answers grounded in your own recorded timeline."

        case .summary:
            "Create a structured PDF from the protocol history you already recorded."

        case .secondProtocol:
            "Free covers one active protocol. Pro keeps a separate schedule, log and history for each one."

        case .health:
            "Read weight from Apple Health and view it beside your recorded entries. Read-only."
        }
    }

    private var leadingBenefit: PaywallBenefit {
        switch self {
        case .pro, .secondProtocol:
            .unlimitedProtocols

        case .compare, .levels, .health:
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
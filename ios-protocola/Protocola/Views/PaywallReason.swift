import Foundation

/// One concise outcome shown on the Pro paywall.
///
/// We intentionally keep this to three benefit groups so the complete paywall
/// can remain visible on one screen instead of becoming a feature list.
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


/// Verified customer feedback displayed on the paywall.
///
/// Add ONLY genuine feedback here.
/// If this array is empty, the testimonial block automatically disappears.
struct PaywallTestimonial: Identifiable {
    let quote: String
    let attribution: String

    var id: String {
        quote + attribution
    }

    static let verified: [PaywallTestimonial] = [
        // Example once you have genuine feedback:
        //
        // PaywallTestimonial(
        //     quote: "Finally a peptide tracker that feels like an actual record.",
        //     attribution: "Alex R. · Pro user"
        // )
    ]
}


/// Why the paywall was presented.
///
/// The opening message changes depending on the feature the user attempted
/// to use, while the core Pro proposition stays consistent.
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
            "Get answers grounded in your own recorded timeline."

        case .summary:
            "Create a structured PDF from the protocol history you already recorded."

        case .secondProtocol:
            "Keep separate schedules, logs, changes, and history for every protocol."
        }
    }

    /// Put the feature that triggered the paywall first.
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
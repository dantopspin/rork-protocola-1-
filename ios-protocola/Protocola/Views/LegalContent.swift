import Foundation

/// The in-app legal and disclosure documents. Copy states only what the app
/// actually does: local-first tracking, neutral record keeping, no medical or
/// dosing advice, and the limited records Ask Protocola may send.
enum LegalContent {
    static let updated = "October 3, 2026"

    static let privacy = LegalDocument(
        id: "privacy",
        title: "Privacy Policy",
        updated: updated,
        sections: [
            LegalSection(heading: "Summary", body: "Protocola keeps your protocols, entries, vials, and preferences on this iPhone. There is no account, and nothing is uploaded unless you explicitly share an export or send a question to Ask Protocola with sharing turned on."),
            LegalSection(heading: "What is stored on your device", body: "Your protocols, schedules, recorded entries, vial details, and app preferences are stored locally on this iPhone. This data never leaves your device except as described below. Clearing all data in Settings, or deleting the app, removes everything permanently."),
            LegalSection(heading: "Ask Protocola", body: "Record sharing for Ask Protocola is off by default. After your first-use opt-in, sending a question shares the visible protocol/date scope: compound information, amounts, units, times, statuses, schedules, recorded sites and symptoms, and relevant previous/new change values, together with the question you type. View shared data shows the payload and any coverage limits. Notes, protocol names, vial labels, and supplier information are never sent. Protocola does not save questions or answers to local record storage. Network processing is provided through the Rork AI gateway; this does not mean the service has no processing logs or retention. Avoid typing information you do not want sent."),
            LegalSection(heading: "Exports and sharing", body: "CSV exports and the Visit Summary PDF are created on your device. They leave your device only when you share them yourself through the iOS share sheet."),
            LegalSection(heading: "Notifications", body: "Reminders are scheduled locally with iOS. Protocola does not send notifications through a server."),
            LegalSection(heading: "No tracking", body: "Protocola contains no advertising, no analytics, and no third-party tracking. The app's privacy manifest declares no collected data types."),
            LegalSection(heading: "Sample records", body: "Demo mode shows illustrative records stored separately from your real records. Exiting the demo discards them."),
            LegalSection(heading: "Changes", body: "If this policy changes, the updated version will appear here with a new date.")
        ]
    )

    static let terms = LegalDocument(
        id: "terms",
        title: "Terms of Use",
        updated: updated,
        sections: [
            LegalSection(heading: "Acceptance", body: "By using Protocola you agree to these terms and to Apple's standard Licensed Application End User License Agreement."),
            LegalSection(heading: "What Protocola is", body: "Protocola is a personal record-keeping tool. It stores and converts information you enter. It does not provide medical services, advice, or interpretations of any kind."),
            LegalSection(heading: "Your records", body: "Your records remain yours. Protocola claims no ownership over them and processes them only on your device, except for the limited records sent when you use Ask Protocola with sharing enabled."),
            LegalSection(heading: "Premium", body: "Free includes one actively tracked protocol and core record keeping. Pro includes unlimited active protocols, Ask Protocola, advanced comparisons, and Visit Summary PDFs. US pricing is $7.99 monthly or $49.99 yearly, displayed in your local currency by Apple, with no free trial. Subscriptions renew automatically through your Apple ID unless canceled at least 24 hours before the period ends; manage or cancel in your Apple Account settings. Canceling or clearing local records does not itself cancel a subscription. On expiry, choose one protocol for Free tracking; others and their history are preserved read-only."),
            LegalSection(heading: "Acceptable use", body: "Do not use Protocola to provide medical care to others, to present generated summaries as professional medical records, or to attempt to obtain medical recommendations from features that do not provide them."),
            LegalSection(heading: "Disclaimer and liability", body: "Protocola is provided \"as is\" without warranties of any kind. To the extent permitted by law, the developers of Protocola are not liable for decisions made based on recorded or exported data. See the Medical Disclaimer."),
            LegalSection(heading: "Changes", body: "These terms may change from time to time. Continued use of the app after a change means you accept the updated terms.")
        ]
    )

    static let medicalDisclaimer = LegalDocument(
        id: "medical-disclaimer",
        title: "Medical Disclaimer",
        updated: updated,
        sections: [
            LegalSection(heading: "Not medical advice", body: "Protocola is a record-keeping tool. It does not prescribe, recommend, or verify doses, schedules, injection sites, dilutions, or any other medical decision."),
            LegalSection(heading: "Not a medical device", body: "Protocola is not a medical device and is not intended to diagnose, treat, cure, or prevent any condition."),
            LegalSection(heading: "Verify with a professional", body: "Every value shown in Protocola comes from what you enter. Always follow the instructions you were given by a qualified healthcare professional and the product label, and contact them with questions about your care."),
            LegalSection(heading: "Emergencies", body: "If you may be experiencing a medical emergency, contact your local emergency services immediately."),
            LegalSection(heading: "Calculator", body: "The conversion calculator performs arithmetic on the values you enter. Its results are not guidance of any kind.")
        ]
    )

    static let aiDataUse = LegalDocument(
        id: "ai-data-use",
        title: "Ask Protocola and your records",
        updated: updated,
        sections: [
            LegalSection(heading: "Off by default", body: "Record sharing for Ask Protocola is off by default. Core tracking never depends on it, and nothing is sent until you send a question yourself."),
            LegalSection(heading: "What is sent", body: "After your first-use opt-in, tapping Ask sends your typed question plus scoped compound information, amounts, units, times, statuses, schedules, sites, symptoms and relevant change values. Protocol/date scope remains visible. View shared data is optional; you do not need to confirm sharing again for each question. Nothing is sent in the background."),
            LegalSection(heading: "What is never sent", body: "Notes, protocol names, vial labels, supplier information, lab records, and hidden audit metadata are never sent."),
            LegalSection(heading: "How answers are produced", body: "The request is processed by an AI service over the network, and the summary it returns is shown to you. Protocola does not save questions or answers to local record storage. Network processing is provided through the Rork AI gateway; this does not mean the service has no processing logs or retention. Avoid typing information you do not want sent."),
            LegalSection(heading: "Turning it off", body: "Turn off \"Ask Protocola record sharing\" in Data & Privacy at any time. Ask Protocola stops sending records immediately.")
        ]
    )
}

import Foundation

/// The in-app legal and disclosure documents. Copy states only what the app
/// actually does: local-first tracking, neutral record keeping, no medical or
/// dosing advice, and the limited records Ask Protocola may send.
enum LegalContent {
    static let updated = "October 5, 2026"

    static let privacy = LegalDocument(
        id: "privacy",
        title: "Privacy Policy",
        updated: updated,
        sections: [
            LegalSection(heading: "Summary", body: "Protocola keeps your protocols, schedules, entries, vials, labs, and preferences on this device. There is no Protocola account. Tracking records are not uploaded unless you explicitly share an export or send a question to Ask Protocola with record sharing turned on. Subscription status is handled separately through Apple and RevenueCat."),
            LegalSection(heading: "What is stored on your device", body: "Your protocols, schedules, recorded entries, vial details, labs, audit history, and app preferences are stored locally on this device. This tracking data leaves the device only through the actions described below. Clear All Data removes Protocola's local tracking records and preferences, but it does not cancel a subscription or erase purchase records managed by Apple or RevenueCat."),
            LegalSection(heading: "Ask Protocola", body: "Record sharing for Ask Protocola is off by default. After you opt in, sending a question shares the visible protocol/date scope: compound information, amounts, units, times, statuses, schedules, recorded sites and symptoms, and relevant non-private change values, together with the question you type. View shared data shows the payload and coverage limits. Notes, protocol names, vial labels, supplier information, lab records, and hidden audit metadata are excluded from automatic sharing. Protocola does not save questions or answers to local record storage. Questions are processed by " + AIService.processorDescription + "; this does not mean the service has no processing logs or retention. Avoid typing information you do not want sent."),
            LegalSection(heading: "Apple Health", body: "If you connect Apple Health, Protocola reads your body weight to show it beside your recorded entries. It only reads; it never writes to Health. Health data is not stored by Protocola, is not included in exports or the Visit Summary, is never sent to Ask Protocola or any server, and is never used for advertising. You can turn access off at any time in the Health app."),
            LegalSection(heading: "Exports and sharing", body: "CSV exports and the Visit Summary PDF are created on your device. They leave your device only when you share them yourself through the iOS share sheet."),
            LegalSection(heading: "Notifications", body: "Reminders are scheduled locally with iOS. Protocola does not send notifications through a server."),
            LegalSection(heading: "Subscriptions and tracking", body: "Protocola contains no advertising, no analytics SDK, and no third-party advertising tracking. Apple and RevenueCat process subscription and entitlement information for purchase functionality. The app privacy manifest declares purchase history, and the health records and questions you choose to send to Ask Protocola, for app functionality only, and declares tracking as off."),
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
            LegalSection(heading: "Premium", body: "Free includes one actively tracked protocol and core record keeping. Pro includes unlimited active protocols, Ask Protocola, advanced comparisons, and Visit Summary PDFs. Available plans and current prices are shown in the paywall and confirmed by Apple before purchase. There is no free trial unless the paywall explicitly shows one. Subscriptions renew automatically through your Apple ID unless canceled in your Apple Account settings. Canceling or clearing local records does not itself cancel a subscription. On expiry, choose one protocol for Free tracking; others and their history are preserved read-only."),
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
            LegalSection(heading: "Verify with a professional", body: "Every value shown in Protocola comes from what you enter, except body weight you choose to read from Apple Health. Always follow the instructions you were given by a qualified healthcare professional and the product label, and contact them with questions about your care."),
            LegalSection(heading: "Emergencies", body: "If you may be experiencing a medical emergency, contact your local emergency services immediately."),
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
            LegalSection(heading: "How answers are produced", body: "The request is processed by an AI service over the network, and the summary it returns is shown to you. Protocola does not save questions or answers to local record storage. Questions are processed by " + AIService.processorDescription + "; this does not mean the service has no processing logs or retention. Avoid typing information you do not want sent."),
            LegalSection(heading: "Turning it off", body: "Turn off \"Ask Protocola record sharing\" in Data & Privacy at any time. Ask Protocola stops sending records immediately.")
        ]
    )
}

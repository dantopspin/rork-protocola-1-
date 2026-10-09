import SwiftUI
import Foundation

struct DoseEditorView: View {
    let revision: ScheduleRevision?
    let occurrence: ScheduledEntry?
    let correcting: DoseLog?

    @Environment(TrackingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DoseDraft
    @State private var initialSnapshot: String?
    @State private var confirmDiscard = false

    private var hasUnsavedChanges: Bool {
        initialSnapshot.map { $0 != String(describing: draft) } ?? false
    }
    @State private var addVial = false
    @State private var showSiteMap = false
    @State private var showDetails = false
    @State private var keyboardShown = false
    @State private var editingTime = false

    init(
        revision: ScheduleRevision,
        occurrence: ScheduledEntry? = nil,
        prefill: DoseDraft? = nil
    ) {
        self.revision = revision
        self.occurrence = occurrence
        correcting = nil

        _draft = State(
            initialValue:
                prefill
                ?? DoseDraft(revision: revision)
        )
    }

    init(correcting: DoseLog) {
        revision = nil
        occurrence = nil
        self.correcting = correcting

        _draft = State(
            initialValue:
                DoseDraft(log: correcting)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                compoundSection

                amountSection

                timeSection

                symptomsSection

                if currentRoute.usesInjectionSite {
                    vialSection

                    injectionSiteSection
                }

                detailsSection

                if correcting != nil {
                    correctionNotice
                }
            }
            .listStyle(.plain)
            .paperList()
            .scrollContentBackground(.hidden)
            .doneKeyboard()
            .navigationTitle(
                correcting == nil
                    ? "Log Dose"
                    : "Correct entry"
            )
            .navigationBarTitleDisplayMode(.large)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillShowNotification
                )
            ) { _ in
                keyboardShown = true
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIResponder.keyboardWillHideNotification
                )
            ) { _ in
                keyboardShown = false
            }
            .safeAreaInset(edge: .bottom) {
                // Hidden while typing so the keyboard and the button never
                // stack over the form; Done dismisses the keyboard.
                if !keyboardShown {
                Button(
                    correcting == nil
                        ? "Log Dose"
                        : "Save correction"
                ) {
                    save()
                }
                .buttonStyle(TrackingPrimaryButtonStyle())
                .padding(.horizontal, Theme.pageInset)
                .padding(.vertical, Theme.spaceS)
                .background(Theme.paper)
                }
            }
            .discardGuard(
                hasChanges: hasUnsavedChanges,
                confirming: $confirmDiscard
            ) {
                dismiss()
            }
            .onAppear {
                if initialSnapshot == nil {
                    initialSnapshot = String(describing: draft)
                }
            }
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button {
                        if hasUnsavedChanges {
                            confirmDiscard = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
            .sheet(isPresented: $addVial) {
                VialEditorView()
            }
            .sheet(isPresented: $showSiteMap) {
                InjectionSitePickerView(
                    selection: $draft.site,
                    logs: store.logs
                )
            }
            .trackingErrors()
        }
    }
}


// MARK: - Sections

private extension DoseEditorView {

    var compoundSection: some View {
        Section {
            FieldRow(
                icon: "pills",
                label: "Compound"
            ) {
                Text(
                    correcting?.compoundName
                    ?? revision?.compoundName
                    ?? "Entry"
                )
                .font(Theme.serifTitle)
                .foregroundStyle(Theme.ink)
            }

            Picker(
                "Status",
                selection: $draft.status
            ) {
                ForEach(
                    [
                        "Logged",
                        "Skipped",
                        "Partial",
                        "Delayed"
                    ],
                    id: \.self
                ) {
                    Text($0)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
    }


    /// Step for the − / + buttons, taken from the precision of the user's
    /// own recorded value (0.25 → 0.01, 250 → 10). Never a suggestion.
    var amountStep: Decimal {
        let text =
            revision?.amountText
            ?? correcting?.scheduledAmountText
            ?? draft.amount
        if let dot = text.firstIndex(of: ".") {
            let places = text.distance(from: dot, to: text.endIndex) - 1
            var step = Decimal(1)
            for _ in 0..<max(places, 0) { step /= 10 }
            return step
        }
        let digits = text.filter(\.isNumber)
        let zeros = digits.reversed().prefix { $0 == "0" }.count
        var step = Decimal(1)
        for _ in 0..<min(zeros, max(digits.count - 1, 0)) { step *= 10 }
        return step
    }

    func stepAmount(_ direction: Int) {
        let current = Decimal(string: draft.amount) ?? 0
        let next = max(0, current + amountStep * Decimal(direction))
        draft.amount = DoseCalculator.text(next)
    }

    func stepButton(
        _ systemImage: String,
        label: String,
        direction: Int
    ) -> some View {
        Button {
            stepAmount(direction)
        } label: {
            Image(systemName: systemImage)
                .font(Theme.label)
                .foregroundStyle(Theme.ink)
                .frame(
                    width: Theme.minimumTapTarget,
                    height: Theme.minimumTapTarget
                )
                .background(Theme.subtleFill, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }


    @ViewBuilder
    var amountSection: some View {
        if draft.status != "Skipped" {
            Section {
                HStack(spacing: Theme.spaceM) {
                    stepButton(
                        "minus",
                        label: "Decrease amount",
                        direction: -1
                    )

                    VStack(spacing: Theme.spaceXXS) {
                        TextField(
                            "0",
                            text: $draft.amount
                        )
                        .font(Theme.metricLarge)
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Actual amount")

                        Picker(
                            "Unit",
                            selection: $draft.unit
                        ) {
                            ForEach(AmountUnit.allCases) {
                                Text($0.rawValue)
                                    .tag($0)
                            }
                        }
                        .labelsHidden()
                        .tint(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    stepButton(
                        "plus",
                        label: "Increase amount",
                        direction: 1
                    )
                }
                .padding(.vertical, Theme.spaceXS)

            } header: {
                Eyebrow(text: "Amount")
            } footer: { FormFooter {
                Text(
                    "Values reflect your own records, not an administration recommendation."
                )
            }
            }
        }
    }


    /// Scheduled time, route and syringe scale: reference values kept out
    /// of the way until needed.
    var detailsSection: some View {
        Section {
            DisclosureGroup(
                isExpanded: $showDetails
            ) {
                if let occurrence {
                    RecordRow(
                        label: "Scheduled",
                        value:
                            occurrence.at.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                    )
                }

                RecordRow(
                    label: "Route",
                    value: currentRoute.rawValue
                )

                if draft.status != "Skipped" {
                    VStack(
                        alignment: .leading,
                        spacing: Theme.spaceXS
                    ) {
                        Text("Syringe scale")
                            .font(Theme.label)
                            .foregroundStyle(Theme.ink)

                        HStack(spacing: Theme.spaceXS) {
                            ForEach(
                                SyringeScalePreset.allCases
                            ) { preset in
                                Button(preset.label) {
                                    draft.unitsPerMl =
                                        preset.valueText
                                }
                                .buttonStyle(
                                    TrackingCompactButtonStyle()
                                )
                                .tint(
                                    SyringeScalePreset
                                        .match(draft.unitsPerMl)
                                        == preset
                                    ? Theme.teal
                                    : Theme.ink
                                )
                            }
                        }

                        TextField(
                            "Units per mL",
                            text: $draft.unitsPerMl
                        )
                        .keyboardType(.decimalPad)
                    }
                }
            } label: {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXXS
                ) {
                    Text("Details")
                        .font(Theme.label)
                        .foregroundStyle(Theme.ink)

                    Text(detailsSummary)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            .tint(Theme.textSecondary)
        }
    }

    /// "Today, Oct 8, 2026" / "Yesterday, …" / "Mon, Oct 5, 2026".
    var recordedDayText: String {
        let date =
            draft.loggedAt.formatted(
                .dateTime.month(.abbreviated).day().year()
            )
        let calendar = Calendar.current
        if calendar.isDateInToday(draft.loggedAt) {
            return "Today, " + date
        }
        if calendar.isDateInYesterday(draft.loggedAt) {
            return "Yesterday, " + date
        }
        return draft.loggedAt.formatted(
            .dateTime.weekday(.abbreviated)
        ) + ", " + date
    }

    var detailsSummary: String {
        var parts: [String] = []
        if let occurrence {
            parts.append(
                "Scheduled "
                + occurrence.at.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
        }
        parts.append(currentRoute.rawValue)
        if let preset = SyringeScalePreset.match(draft.unitsPerMl) {
            parts.append(preset.label)
        }
        return parts.joined(separator: " · ")
    }


    var timeSection: some View {
        Section {
            Button {
                withAnimation(.snappy(duration: Theme.motionStateDuration)) {
                    editingTime.toggle()
                }
            } label: {
                HStack(spacing: Theme.spaceS) {
                    FieldRow(
                        icon: "calendar",
                        label: "Date and time"
                    ) {
                        Text(recordedDayText)
                            .font(Theme.serifTitle)
                            .foregroundStyle(Theme.ink)

                        Text(
                            draft.loggedAt.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()
                    }

                    Image(
                        systemName:
                            editingTime
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(Theme.micro)
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                editingTime
                ? "Hides the date and time picker."
                : "Shows the date and time picker."
            )

            if editingTime {
                DatePicker(
                    "Recorded time",
                    selection: $draft.loggedAt,
                    in: ...Date.now
                )
                .datePickerStyle(.graphical)
                .tint(Theme.teal)
            }
        }
    }


    @ViewBuilder
    var vialSection: some View {
        Section {
            if let correcting {
                RecordRow(
                    label: "Recorded vial",
                    value: correcting.vialName
                )

                Text(
                    "The original vial and concentration snapshot are retained when correcting this entry."
                )
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)

            } else {
                Picker(
                    "Vial",
                    selection: $draft.vialID
                ) {
                    Text("No vial")
                        .tag(nil as UUID?)

                    ForEach(matchingVials) {
                        Text($0.name)
                            .tag(Optional($0.id))
                    }
                }

                if matchingVials.isEmpty {
                    Button {
                        addVial = true
                    } label: {
                        Label(
                            "Add a vial for \(revision?.compoundName ?? "this compound")",
                            systemImage: "plus"
                        )
                    }
                }
            }

        } header: {
            Eyebrow(text: "Vial")
        } footer: { FormFooter {
            if correcting == nil {
                Text(
                    draft.vialID == nil
                        ? "A vial is optional. Without one, Protocola records the entry but cannot reconcile vial balance or calculate volume."
                        : "The selected vial's recorded strength is used to update its inventory balance."
                )
            }
        }
}
    }


    var injectionSiteSection: some View {
        Section("Injection site") {
            if let selected =
                InjectionSite.match(
                    draft.site
                ) {
                RecordRow(
                    label: "Selected",
                    value: selected.rawValue
                )

            } else if !draft.site
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {
                RecordRow(
                    label: "Selected",
                    value: draft.site
                )
            }

            Button {
                showSiteMap = true
            } label: {
                Label(
                    draft.site.isEmpty
                        ? "Choose on body map"
                        : "Change on body map",
                    systemImage: "figure.stand"
                )
            }

            if !recentSiteUses.isEmpty {
                VStack(
                    alignment: .leading,
                    spacing: Theme.spaceXS
                ) {
                    Text(
                        "Recent across all protocols"
                    )
                    .font(Theme.label)
                    .foregroundStyle(Theme.ink)

                    ForEach(
                        recentSiteUses.prefix(4)
                    ) { use in
                        Button {
                            draft.site =
                                use.site.rawValue
                        } label: {
                            HStack(
                                spacing: Theme.spaceS
                            ) {
                                VStack(
                                    alignment: .leading,
                                    spacing:
                                        Theme.spaceXXS
                                ) {
                                    Text(
                                        use.site.rawValue
                                    )
                                    .font(Theme.body)
                                    .foregroundStyle(
                                        Theme.ink
                                    )

                                    Text(
                                        use.compoundName
                                        + " · "
                                        + relativeLabel(
                                            use.lastUsedAt
                                        )
                                    )
                                    .font(Theme.caption)
                                    .foregroundStyle(
                                        Theme.textSecondary
                                    )
                                }

                                Spacer()

                                if InjectionSite.match(
                                    draft.site
                                ) == use.site {
                                    Image(
                                        systemName:
                                            "checkmark"
                                    )
                                    .font(Theme.micro)
                                    .foregroundStyle(
                                        Theme.teal
                                    )
                                }
                            }
                            .contentShape(
                                Rectangle()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField(
                "Custom site label (optional)",
                text: $draft.site
            )

            Text(
                "The map and recent history record locations you already used. They do not recommend where to inject."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }


    var symptomsSection: some View {
        Section {
            FieldRow(
                icon: "waveform.path.ecg",
                label: "Symptoms (optional)"
            ) {
                TextField(
                    "What did you notice?",
                    text: $draft.symptoms
                )
            }

            if !draft.symptoms.isEmpty {
                Stepper(
                    "Severity: \(draft.severity) / 10",
                    value: $draft.severity,
                    in: 1...10
                )
            }

            FieldRow(
                icon: "doc.text",
                label: "Notes (optional)"
            ) {
                TextField(
                    "How are you feeling today?",
                    text: $draft.notes,
                    axis: .vertical
                )
            }
        } header: {
            Eyebrow(text: "Symptoms and notes")
        }
    }


    var correctionNotice: some View {
        Section {
            Text(
                "Saving reconciles the vial balance with the corrected amount. Scheduled values remain the original historical snapshot."
            )
            .font(Theme.caption)
            .foregroundStyle(Theme.textSecondary)
        }
    }
}


// MARK: - Derived values

private extension DoseEditorView {

    var currentRoute: AdministrationRoute {
        correcting?.route
        ?? revision?.route
        ?? .injection
    }


    var matchingVials: [VialRecord] {
        guard let compound =
            revision?.compoundName
        else {
            return []
        }

        return store.vials.filter {
            !$0.isArchived
            && $0.compoundName
                .caseInsensitiveCompare(
                    compound
                )
                == .orderedSame
        }
    }


    var recentSiteUses: [InjectionSiteUse] {
        InjectionSite.recentUses(
            from: store.logs
        )
    }


    func relativeLabel(
        _ date: Date
    ) -> String {
        let formatter =
            RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        return formatter.localizedString(
            for: date,
            relativeTo: .now
        )
    }
}


// MARK: - Actions

private extension DoseEditorView {

    func save() {
        let corrects = correcting != nil
        if store.saveDose(
            draft,
            revision: revision,
            occurrence: occurrence,
            correcting: correcting
        ) {
            if corrects {
                Haptics.success()
            }
            dismiss()
        }
    }
}


// MARK: - Injection site map

struct InjectionSitePickerView: View {
    @Binding var selection: String
    let logs: [DoseLog]

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var face:
        InjectionBodyFace = .front

    private var uses: [InjectionSiteUse] {
        InjectionSite.recentUses(
            from: logs
        )
    }

    private var selectedSite:
        InjectionSite? {
        InjectionSite.match(selection)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.sectionGap
                ) {
                    Picker(
                        "Body view",
                        selection: $face
                    ) {
                        ForEach(
                            InjectionBodyFace
                                .allCases
                        ) { face in
                            Text(face.rawValue)
                                .tag(face)
                        }
                    }
                    .pickerStyle(.segmented)

                    TrackingCard {
                        InjectionSiteMapCanvas(
                            face: face,
                            selection:
                                selectedSite,
                            uses: uses
                        ) { site in
                            selection =
                                site.rawValue
                        }
                    }

                    siteRecencyCard
                }
                .screenPadding()
            }
            .background(Theme.paper)
            .navigationTitle(
                "Injection site"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let selectedSite {
                    face =
                        selectedSite.bodyFace
                }
            }
        }
    }

    private var siteRecencyCard:
        some View {
        TrackingCard {
            Eyebrow(text: "Recorded recency")

            ForEach(
                sites(for: face)
            ) { site in
                Button {
                    selection = site.rawValue
                } label: {
                    HStack(
                        spacing: Theme.spaceS
                    ) {
                        Text(site.rawValue)
                            .font(Theme.body)
                            .foregroundStyle(
                                Theme.ink
                            )

                        Spacer()

                        Text(
                            recencyLabel(
                                for: site
                            )
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text(
                "Recency is calculated from your recorded entries across all protocols. It is descriptive only."
            )
            .font(Theme.caption)
            .foregroundStyle(
                Theme.textSecondary
            )
        }
    }

    private func sites(
        for face: InjectionBodyFace
    ) -> [InjectionSite] {
        InjectionSite.allCases.filter {
            $0.bodyFace == face
        }
    }

    private func recencyLabel(
        for site: InjectionSite
    ) -> String {
        guard let use =
            uses.first(
                where: {
                    $0.site == site
                }
            )
        else {
            return "Not recorded"
        }

        let formatter =
            RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        return formatter.localizedString(
            for: use.lastUsedAt,
            relativeTo: .now
        )
    }
}


struct InjectionSiteHistoryView: View {
    let logs: [DoseLog]

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var face:
        InjectionBodyFace = .front

    private var uses: [InjectionSiteUse] {
        InjectionSite.recentUses(
            from: logs
        )
    }

    private var recordedLogs:
        [DoseLog] {
        logs
            .filter {
                $0.route.usesInjectionSite
                && $0.status != "Skipped"
                && !$0.site
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            }
            .sorted {
                $0.loggedAt
                    > $1.loggedAt
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.sectionGap
                ) {
                    Picker(
                        "Body view",
                        selection: $face
                    ) {
                        ForEach(
                            InjectionBodyFace
                                .allCases
                        ) { face in
                            Text(face.rawValue)
                                .tag(face)
                        }
                    }
                    .pickerStyle(.segmented)

                    TrackingCard {
                        InjectionSiteMapCanvas(
                            face: face,
                            selection: nil,
                            uses: uses,
                            onSelect: nil
                        )
                    }

                    TrackingCard {
                        Eyebrow(text: "Most recent by site")

                        ForEach(
                            sites(for: face)
                        ) { site in
                            HStack(
                                spacing: Theme.spaceS
                            ) {
                                Text(
                                    site.rawValue
                                )
                                .font(Theme.body)
                                .foregroundStyle(
                                    Theme.ink
                                )

                                Spacer()

                                Text(
                                    recencyLabel(
                                        for: site
                                    )
                                )
                                .font(Theme.caption)
                                .foregroundStyle(
                                    Theme.textSecondary
                                )
                            }
                        }

                        Text(
                            "This view summarizes your own recorded history and does not recommend an injection location."
                        )
                        .font(Theme.caption)
                        .foregroundStyle(
                            Theme.textSecondary
                        )
                    }

                    if !recordedLogs.isEmpty {
                        TrackingCard {
                            Eyebrow(text: "Recent entries")

                            ForEach(
                                recordedLogs
                            ) { log in
                                VStack(
                                    alignment: .leading,
                                    spacing:
                                        Theme.spaceXXS
                                ) {
                                    HStack(
                                        spacing:
                                            Theme.spaceS
                                    ) {
                                        Text(
                                            log.site
                                        )
                                        .font(
                                            Theme.body
                                        )
                                        .foregroundStyle(
                                            Theme.ink
                                        )

                                        Spacer()

                                        Text(
                                            log.loggedAt
                                                .formatted(
                                                    date:
                                                        .abbreviated,
                                                    time:
                                                        .omitted
                                                )
                                        )
                                        .font(
                                            Theme.caption
                                        )
                                        .foregroundStyle(
                                            Theme.textSecondary
                                        )
                                    }

                                    Text(
                                        log.compoundName
                                        + " · "
                                        + log.protocolName
                                    )
                                    .font(
                                        Theme.caption
                                    )
                                    .foregroundStyle(
                                        Theme.textSecondary
                                    )
                                }
                            }
                        }
                    }
                }
                .screenPadding()
            }
            .background(Theme.paper)
            .navigationTitle("Site history")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sites(
        for face: InjectionBodyFace
    ) -> [InjectionSite] {
        InjectionSite.allCases.filter {
            $0.bodyFace == face
        }
    }

    private func recencyLabel(
        for site: InjectionSite
    ) -> String {
        guard let use =
            uses.first(
                where: {
                    $0.site == site
                }
            )
        else {
            return "Not recorded"
        }

        let formatter =
            RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        return formatter.localizedString(
            for: use.lastUsedAt,
            relativeTo: .now
        )
    }
}


private struct InjectionSiteMapCanvas:
    View {
    let face: InjectionBodyFace
    let selection: InjectionSite?
    let uses: [InjectionSiteUse]
    let onSelect:
        ((InjectionSite) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(
                    systemName:
                        "figure.stand"
                )
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    Theme.subtleFill
                )
                .overlay {
                    Image(
                        systemName:
                            "figure.stand"
                    )
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(
                        Theme.hairline
                    )
                }
                .padding(Theme.spaceML)

                ForEach(
                    InjectionSite
                        .allCases
                        .filter {
                            $0.bodyFace
                                == face
                        }
                ) { site in
                    marker(for: site)
                        .position(
                            x:
                                geometry.size.width
                                * CGFloat(
                                    site.normalizedX
                                ),
                            y:
                                geometry.size.height
                                * CGFloat(
                                    site.normalizedY
                                )
                        )
                }
            }
        }
        .frame(
            height:
                Theme.bodyMapHeight
        )
        .accessibilityElement(
            children: .contain
        )
    }

    @ViewBuilder
    private func marker(
        for site: InjectionSite
    ) -> some View {
        let recorded =
            uses.contains {
                $0.site == site
            }
        let selected =
            selection == site

        if let onSelect {
            Button {
                onSelect(site)
            } label: {
                markerVisual(
                    recorded: recorded,
                    selected: selected
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                site.rawValue
            )
            .accessibilityValue(
                markerAccessibilityValue(
                    site: site
                )
            )
        } else {
            markerVisual(
                recorded: recorded,
                selected: selected
            )
            .accessibilityLabel(
                site.rawValue
            )
            .accessibilityValue(
                markerAccessibilityValue(
                    site: site
                )
            )
        }
    }

    private func markerVisual(
        recorded: Bool,
        selected: Bool
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    selected
                        ? Theme.tealTint
                        : Theme.surface
                )
                .overlay {
                    Circle()
                        .stroke(
                            Theme.hairline,
                            lineWidth: Theme.ruleThickness
                        )
                }

            Circle()
                .fill(
                    selected
                        ? Theme.accentFill
                        : (
                            recorded
                            ? Theme.ink
                            : Theme.textTertiary
                        )
                )
                .frame(
                    width:
                        Theme.iconSmall,
                    height:
                        Theme.iconSmall
                )
        }
        .frame(
            width:
                Theme.compactButtonHeight,
            height:
                Theme.compactButtonHeight
        )
    }

    private func markerAccessibilityValue(
        site: InjectionSite
    ) -> String {
        if selection == site {
            return "Selected"
        }

        if let use =
            uses.first(
                where: {
                    $0.site == site
                }
            ) {
            return "Recorded "
                + use.lastUsedAt
                    .formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
        }

        return "No recorded entries"
    }
}

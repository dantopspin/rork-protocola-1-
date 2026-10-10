# Protocola Design System v5

`Theme.swift` is the executable source of truth for visual tokens. This document mirrors it. If the two ever disagree, update the document and code in the same change.

## Direction

**Calm Pine Record**

Protocola is a calm, legible record: warm paper canvas, white rounded cards with a soft elevation, serif (New York) titles and figures over SF Pro body text, one pine accent, capsule status chips and pill buttons, inside native iOS chrome. It records what the user did; it never suggests a dose.

The product supports **Light and Dark Mode**. Every foundation colour in `Theme` is adaptive (light value, dark value). `accentFill` (deep teal) stays the same in both appearances so white text on buttons and the hero card keeps 7.9:1; `teal` lightens in Dark Mode for text and marks. Share images always render the light card.

## Color

| Token | Value | Role |
| --- | --- | --- |
| paper | #FAF8F4 / dark #121514 | app canvas |
| surface | #FFFFFF / dark #1F2321 | every card and row |
| surfaceRaised | #FFFFFF | rare foreground surface |
| ink | #111B29 / dark #EFF2F0 | primary text/icons |
| textSecondary | #626A73 | supporting copy |
| textTertiary | #6C737C | quiet metadata; >=4.5:1 on paper |
| teal (pine) | #1E5B52 / dark #7EC4B6 | primary action, selection, Taken/Active chips, progress |
| accentFill | #1E5B52 (both) | filled buttons, selected day in the week strip |
| info | #286BBC / dark #86BCF4 | Due chips and the due-entry stripe |
| amber | #876832 | attention; >=4.5:1 in status text |
| danger | #A6534D | destructive semantics |
| onDarkPrimary | #FDFCF9 | primary content on teal |
| onDarkSecondary | onDarkPrimary @ 72% | supporting content on teal |
| hairline | ink @ 16% | every rule and card border |
| controlBorder | ink @ 46% | interactive outlined-control boundary |
| inactiveFill | ink @ 12% | fill for empty/inactive marks (status dots, empty heatmap days); never a rule |
| subtleFill | ink @ 2.5% | quiet fill |
| tealTint | teal @ 8% | selected/positive background |
| shadow | black @ 6%, radius 14, y 4 | card elevation (`quietElevation`) |

No local product colors. No decorative gradients or extra accent families.

## Typography

SF Pro carries body, labels, buttons and chips. New York (the system serif) carries page titles, navigation titles, card titles that name a record (`serifTitle`), modal titles and hero figures.

Sizes below are the default text size. Every token scales with the user's text-size setting through `UIFontMetrics` along a matching iOS text style (pageTitle/metrics capped so heroes fit). Share images use the fixed `share*` tokens.

**Headings:** a section is labelled with `Eyebrow` (via `EditorialSection` or a form `header:`): sentence case, Footnote Semibold (`sectionLabel`), secondary colour, like native iOS section headers. No uppercase, no letter-spacing. Never use `sectionTitle` as a section label.

**Doses:** outside a hero metric a dose is spelled with `DoseText` (`Compound · 250 mcg`) and rendered with tabular figures (`.monospacedDigit()`), never a monospaced typeface.

| Token | Size | Weight |
| --- | ---: | --- |
| pageTitle | 34 | serif medium |
| metricLarge | 34 | serif medium, tabular figures |
| metricCompact | 28 | serif medium, tabular figures |
| modalTitle | 20 | serif semibold |
| serifTitle | 17 | serif medium — the single subject of a page or sheet (vial card name, Log Dose compound). Compound names in list rows use cardTitle (sans). |
| chipLabel | 13 | medium — status chips |
| sectionTitle | 17 | semibold — the name of a thing (compound, a chart series), never a section label |
| cardTitle | 17 | semibold — title of every record or tool row |
| body | 17 | regular |
| buttonLabel | 17 | medium |
| label | 15 | medium |
| subheadline | 15 | regular — record row labels |
| caption | 13 | regular (Footnote) — meta, footers, legends |
| sectionLabel | 13 | semibold (Footnote) — section labels (`Eyebrow`) |
| micro | 11 | semibold |
| tabLabel | 10 | medium |
| segmentLabel | 13 | medium |
| shareMetric | 64 | semibold, tabular figures |

Doses, times and amounts use tabular figures. Two families only: SF Pro and New York. Product views must reference `Theme`; local font sizes are forbidden.

## Bottom spacing owner

Every scrolling screen ends with `screenPadding()` plus `spaceXL` bottom padding, nothing more. The tab bar and home indicator are already in the safe area; never add a second reservation for them. Scrolling screens use `trackingScrollChrome()` (opaque paper navigation bar).

## Spacing and alignment

4pt grid only: **4, 8, 12, 16, 20, 24, 32, 40, 48**.

- page inset: 24
- section gap (`sectionGap`): 32 on every scrolling screen, tabs included
- section label to content (`sectionHeaderGap`): 16
- tappable row vertical padding (`rowPadding`): 12, minimum height 44
- standard surface inset: 16
- hero inset: 20
- row gap: 12
- label/value micro gap: 4
- minimum tap target: 44

Root screens use the same 24pt content grid. Native Lists are acceptable in forms/sheets, but root product timelines should not introduce a different implicit inset.

## Geometry

- card: 18 (continuous)
- row card: 14
- button: 26 (pill)
- field: 12
- badge: capsule
- rule thickness: 1
- primary button height: 52
- compact/secondary button height: 44
- badge minimum height: 28
- entry status stripe: 4
- icon column: 24
- large empty-state icon: 28

Cards are white rounded rectangles on paper, separated by space (8–12pt), not by rules. Rules only divide rows inside one card.

## Motion

Apple's two spring parameters, response and damping. Anything people touch moves on a spring, so it can be interrupted and carries velocity.

- `pressSpring` — response 0.3, damping 1.0. Press feedback on every button and card, starting on touch-down.
- `stateSpring` — response 0.35, damping 1.0. State changes: logged, expanded, shown, undo banner, staggered entrance.
- `momentumSpring` — response 0.4, damping 0.8. Only after a drag or flick release (reordering), the one place overshoot is earned.
- No fixed-duration ease curves for interactive state. Tappable cards use `TrackingCardButtonStyle` (scale 0.98 plus dim).
- Reduce Motion: no scale or movement; dims and cross-fades only.

## Canonical components

### EditorialSection
Sentence-case `Eyebrow` above one white card holding the content (radius 18, 16pt inset, soft elevation).

### FieldRow / IconBadge
40pt tinted circle icon, caption label, then the value or control. Used in the Log Dose sheet and info cards.

### TrackingCard
Surface background, radius 18, 16pt inset, soft elevation, no border.

### TrackingHeroCard
accentFill surface, radius 18, 20pt inset. Everything inside uses the on-dark tokens and the inverted primary button.

### EditorialRule
The only horizontal rule (1pt, hairline; `onDark` variant on teal). `Divider()` is reserved for menu separators.

### RecordRow
Label left in Subheadline secondary, value right in Body, tabular figures for values.

### StatusBadge
Capsule chip, `chipLabel`, optional leading SF Symbol, minimum height 28, 12% tint fill. Taken/Active pine, Due blue, attention amber, expired red.

### PrimaryButton
accentFill pill, onDarkPrimary label, 52pt minimum height.

### SecondaryButton
Surface fill pill, controlBorder outline, ink label, 44pt minimum height.

### CompactButton
44pt minimum tap target, 12pt horizontal inset, same radius/border semantics as secondary.

### TrackingEmptyState
28pt tertiary icon, 20pt title, 15pt supporting copy, left aligned to the page grid.

### NotificationPermissionSheet
Pre-permission sheet before the one-time iOS notification prompt (protocol reminders, inventory alerts). 56pt teal icon tile (amber after denial), pageTitle headline, benefit rows in an EditorialSection, PrimaryButton + SecondaryButton.

### RecordedEntriesHeatmap
Insights calendar of non-skipped entries per day, 20 week columns. Cells use radiusCard, `heatmapGap`, `line` for empty and teal at `heatmapLevelOpacities` / solid for levels 1-4. No streak summary.

## Screen first-read hierarchy

- Today -> next entry / resolved-day state
- Protocols -> active protocol
- History -> timeline
- Insights -> primary metric
- Inventory -> remaining supply
- Vial -> remaining amount
- Paywall -> value of Pro
- Onboarding -> one concept per page

Secondary actions should use the pattern **object -> menu -> focused sheet -> return to object**.

## Native chrome

Titles: the four tab roots draw `PrimaryPageHeader` (34pt) in content with an empty bar title; every pushed screen and sheet uses the standard inline bar title. Sheet confirmation ("Done", "Save") sits top-right.

Forms (editors, Settings) keep native row insets; their section headers are `Eyebrow`.

Native tab bars, navigation bars, menus, system sheets/popovers, confirmation dialogs, and the transient Today undo material may remain native. Product content itself should use tokens/components.

## Enforcement

No local font sizes, product colors, non-grid spacing, line widths, opacities, animation timing, corner radii, shadows, or arbitrary frame dimensions in product views. Add a token first when a new visual value is genuinely required.

The source gate also rejects hand-drawn horizontal rules, `.insetGrouped` lists and sentence-case form headers.

`DesignSystemTests.swift` is the source-level regression gate.

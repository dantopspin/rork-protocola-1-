# Protocola Design System v4

`Theme.swift` is the executable source of truth for visual tokens. This document mirrors it. If the two ever disagree, update the document and code in the same change.

## Direction

**Clinical Editorial Instrument**

Protocola is a restrained technical record: warm paper, black sans-serif type, one blue-grey accent, sharp geometry, thin rules, and native iOS chrome. Product content should not look like a generic rounded-card wellness app.

The product is intentionally **light-only** in v4. `ContentView` pins `.preferredColorScheme(.light)`; therefore dark-mode color variants are not part of the current product contract. “Dark” below refers only to deliberate dark/accent modules inside the light interface.

## Color

| Token | Value | Role |
| --- | --- | --- |
| paper | #F8F7F3 | app canvas |
| surface | #FBFAF7 | quiet product surface |
| surfaceRaised | #FFFFFF | rare foreground surface |
| ink | #121211 | primary text/icons |
| textSecondary | #67655F | supporting copy |
| textTertiary | #747169 | quiet metadata; >=4.5:1 on paper |
| teal / darkSurface | #30536B | primary action, selection, charts, dark module |
| amber | #876832 | attention; >=4.5:1 in status text |
| danger | #A6534D | destructive semantics |
| onDarkPrimary | #FDFCF9 | primary content on teal |
| onDarkSecondary | onDarkPrimary @ 72% | supporting content on teal |
| hairline | ink @ 16% | every rule and card border |
| controlBorder | ink @ 46% | interactive outlined-control boundary |
| inactiveFill | ink @ 12% | fill for empty/inactive marks (status dots, empty heatmap days); never a rule |
| subtleFill | ink @ 2.5% | quiet fill |
| tealTint | teal @ 8% | selected/positive background |
| shadow | ink @ 3.5% | transient elevation only |

No local product colors. No decorative gradients or extra accent families.

## Typography

Apple system sans-serif throughout product content.

Sizes below are the default text size. Every token scales with the user's text-size setting through `UIFontMetrics` along a matching iOS text style (pageTitle/metrics capped so heroes fit). Share images use the fixed `share*` tokens.

**Headings:** a section is labelled with `Eyebrow` (via `EditorialSection` or a form `header:`), never with sentence-case `sectionTitle` text.

**Doses:** outside a hero metric a dose is spelled with `DoseText` (`Compound · 250 mcg`) and rendered with `.monospacedDigit()`.

| Token | Size | Weight |
| --- | ---: | --- |
| pageTitle | 34 | bold |
| metricLarge | 34 | semibold monospaced |
| metricCompact | 26 | semibold monospaced |
| modalTitle | 20 | semibold |
| sectionTitle | 18 | semibold — the name of a thing (compound in a hero, a chart series), never a section label |
| cardTitle | 16 | semibold — title of every record or tool row |
| body | 15 | regular |
| buttonLabel | 15 | medium |
| label | 14 | medium |
| caption | 12.5 | regular |
| micro | 11 | semibold |
| tabLabel | 10 | medium |
| segmentLabel | 13 | medium |
| shareMetric | 64 | semibold monospaced |

Technical values, doses, times, and calculations use monospaced digits/design. Product views must reference `Theme`; local font sizes are forbidden.

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

- card: 2
- row: 2
- button: 2
- field: 0
- badge: 2
- rule thickness: 1
- primary button height: 48
- compact/secondary button height: 44
- badge minimum height: 22
- icon column: 24
- large empty-state icon: 28

Capsules/circles are reserved for native segmented states and true circular/status geometry, not general cards.

## Motion

All explicit product motion uses `Theme` timing tokens.

- press: 0.12s
- feedback: 0.15s
- state: 0.25s
- transition: 0.30s
- quick spring: response 0.24 / damping 0.82
- standard spring: response 0.26 / damping 0.80
- emphasis spring: response 0.32 / damping 0.86

Respect Reduce Motion.

## Canonical components

### EditorialSection
Tracked uppercase `Eyebrow`, 1pt hairline, content, 1pt hairline; spacing 16. Use the shared component rather than recreating this structure.

### TrackingCard
Surface background, radius 2, 16pt inset, hairline border, no shadow.

### TrackingHeroCard
Teal dark surface, radius 2, 20pt inset. Used once: Today's next entry. Everything inside uses the on-dark tokens and the inverted primary button.

### EditorialRule
The only horizontal rule (1pt, hairline; `onDark` variant on teal). `Divider()` is reserved for menu separators.

### RecordRow
Label left, value right, body typography, monospaced digits for values.

### StatusBadge
Micro type, radius 2, minimum height 22, 8pt horizontal inset, semantic tint.

### PrimaryButton
Teal fill, onDarkPrimary label, radius 2, 48pt minimum height.

### SecondaryButton
Surface fill, controlBorder outline, ink label, radius 2, 44pt minimum height.

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
- Calculator -> calculated result
- Paywall -> value of Pro
- Onboarding -> one concept per page

Secondary actions should use the pattern **object -> menu -> focused sheet -> return to object**.

## Native chrome

Titles: the four tab roots draw `PrimaryPageHeader` (34pt) in content with an empty bar title; every pushed screen and sheet uses the standard inline bar title. Sheet confirmation ("Done", "Save") sits top-right.

Forms (editors, Settings, Calculator) keep native row insets; their section headers are `Eyebrow`.

Native tab bars, navigation bars, menus, system sheets/popovers, confirmation dialogs, and the transient Today undo material may remain native. Product content itself should use tokens/components.

## Enforcement

No local font sizes, product colors, non-grid spacing, line widths, opacities, animation timing, corner radii, shadows, or arbitrary frame dimensions in product views. Add a token first when a new visual value is genuinely required.

The source gate also rejects hand-drawn horizontal rules, `.insetGrouped` lists and sentence-case form headers.

`DesignSystemTests.swift` is the source-level regression gate.

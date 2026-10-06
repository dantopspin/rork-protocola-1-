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
| textSecondary / muted | #67655F | supporting copy |
| textTertiary | #747169 | quiet metadata; >=4.5:1 on paper |
| teal / darkSurface | #30536B | primary action, selection, charts, dark module |
| amber | #876832 | attention; >=4.5:1 in status text |
| danger | #A6534D | destructive semantics |
| onDarkPrimary | #FDFCF9 | primary content on teal |
| onDarkSecondary | onDarkPrimary @ 72% | supporting content on teal |
| hairline / border | ink @ 16% | decorative rules/card borders |
| controlBorder | ink @ 46% | interactive outlined-control boundary |
| line | ink @ 12% | quiet internal rule |
| subtleFill / neutralTint | ink @ 2.5% | quiet fill |
| tealTint / amberTint / dangerTint | semantic color @ 8% | semantic background |
| shadow | ink @ 3.5% | transient elevation only |

No local product colors. No decorative gradients or extra accent families.

## Typography

Apple system sans-serif throughout product content.

| Token | Size | Weight |
| --- | ---: | --- |
| display | 38 | bold |
| pageTitle | 34 | bold |
| metricLarge / metric | 34 | semibold monospaced |
| metricCompact | 26 | semibold monospaced |
| modalTitle | 20 | semibold |
| sectionTitle | 18 | semibold |
| cardTitle | 16 | semibold |
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
- major section gap: 32
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
Teal dark surface, radius 2, 20pt inset. Rare: only for the highest-value context.

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

### Vendored components (SwiftPieces)
`Protocola/ThirdParty/SwiftPieces` holds unmodified third-party sources (license: `THIRD_PARTY_NOTICES.md`). They sit outside `Views/` and the source gate; product wrappers in `Views/` must pass only `Theme` tokens into their style structs.

- `NotificationPermissionSheet` wraps `PermissionSheet`: shown before the one-time iOS notification prompt (protocol reminders, inventory alerts).
- `RecordedEntriesHeatmap` wraps `ActivityHeatmap`: per-day recorded entries in Insights, streak summary hidden.

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

Native tab bars, navigation bars, menus, system sheets/popovers, confirmation dialogs, and the transient Today undo material may remain native. Product content itself should use tokens/components.

## Enforcement

No local font sizes, product colors, non-grid spacing, line widths, opacities, animation timing, corner radii, shadows, or arbitrary frame dimensions in product views. Add a token first when a new visual value is genuinely required.

`DesignSystemTests.swift` is the source-level regression gate.

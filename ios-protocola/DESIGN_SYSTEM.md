# Protocola Design System v2

This file is the fixed visual reference for every Protocola screen. Product UI must use shared tokens/components before introducing local styling.

## Direction

**Classical Clinical Minimalism**

Protocola should feel like a premium protocol record and editorial utility, not a wellness app or generic Settings screen.

- warm paper canvas
- warm-white product surfaces
- near-black typography and primary actions
- muted mineral teal only for semantic active/recorded/chart states
- classical system-serif typography
- relatively sharp geometry
- thin hairlines
- almost no decorative shadow
- generous whitespace
- native iOS interaction and navigation underneath

### Chrome vs product content

**Native iOS chrome may use system glass/material. Product content may not.**

Allowed glass/material:
- tab bar
- navigation toolbar
- menus
- system sheets/popovers
- transient undo/toast surfaces

Do not use glass/material for:
- cards
- protocol surfaces
- paywall benefits
- insight modules
- forms
- primary buttons

---

## Color tokens

| Token | Value | Use |
| --- | --- | --- |
| canvas / paper | #F5F3EE | main app background |
| surface | #FCFBF8 | cards and grouped content |
| surfaceRaised | #FFFFFF | rare modal/foreground surface |
| ink | #151513 | primary text/icons/actions |
| textSecondary | #706D66 | supporting copy |
| textTertiary | #96928A | dates/metadata/inactive |
| hairline | ink @ 11% | borders/dividers |
| subtleFill | ink @ 4.5% | quiet selection/fill |
| teal | #466C64 | recorded/active/chart/link semantics |
| tealFill | teal @ 10% | semantic background |
| amber | #94763F | overdue/low inventory/attention |
| amberFill | amber @ 10% | warning background |
| danger | #A6534D | destructive only |
| darkSurface | #171715 | one high-value dark module per screen |
| onDarkPrimary | #FAF9F5 | main text on dark |
| onDarkSecondary | onDarkPrimary @ 62% | supporting text on dark |

**90% of the product UI should remain canvas + surface + black + gray.**

No decorative blue, purple, gradients, or random accent colors.

---

## Typography

Use Apple's system serif design throughout product content. Native chrome can remain system-controlled.

| Token | Size | Weight | Use |
| --- | ---: | --- | --- |
| display | 38 | Semibold | rare onboarding/paywall hero |
| pageTitle | 34 | Semibold | root screens |
| metricLarge | 34 | Medium | key number/amount |
| modalTitle | 20 | Medium | modal emphasis |
| sectionTitle | 18 | Medium | major sections |
| cardTitle | 16 | Medium | card/object titles |
| body | 15 | Regular | main content |
| buttonLabel | 15 | Medium | primary/secondary actions |
| label | 14 | Medium | row labels/compact controls |
| caption | 12.5 | Regular | support/meta |
| micro | 11 | Medium | badges/tiny metadata |

Rules:
- sentence case
- no all-caps product headings
- important numbers may use monospaced digits
- do not use native pre-styled sans typography inside product content
- root tabs use 34 pt serif titles; detail/modal titles use inline navigation serif

---

## Spacing

4 pt base grid only:

- 4
- 8
- 12
- 16
- 20
- 24
- 32
- 40
- 48

Core layout:
- page horizontal inset: 24
- major section gap: 32
- standard card padding: 16
- hero padding: 20
- row gap: 12
- label-to-value: 4
- minimum tap target: 44

Empty space is part of the interface.

---

## Radius

Only these radii are allowed in product content:

- primary card: 12
- compact card/row: 10
- button: 10
- text field: 8
- badge: 6
- segmented state: capsule
- avatar/status dot: circle

Do not introduce local 16/18/22/26 pt card radii.

---

## Borders and shadows

Standard border:
- 1 pt
- hairline color

Normal cards:
- no shadow

Shadow is reserved for transient/floating surfaces:
- opacity ~5–6%
- blur 8
- y 3

---

## Core components

### HeroCard
- darkSurface
- radius 12
- padding 20
- max one per screen
- used only for the highest-value context

### SurfaceCard
- surface
- radius 12
- hairline border
- no shadow
- padding 16

### DataTile
- surface
- radius 10
- hairline border
- padding 14–16

### RecordRow
- 48 pt dense / 54 pt standard rhythm
- label → flexible space → value
- serif body typography

### NavigationRow
- optional 16–18 pt SF Symbol
- title/detail
- chevron 11–12 pt
- no decorative icon color unless semantic

### StatusBadge
- height 20
- radius 6
- 8 pt horizontal padding
- semantic color only

### PrimaryButton
- height 46
- radius 10
- ink fill / white label
- one dominant primary action per screen/context

### PrimaryButton on dark
- onDarkPrimary fill
- ink label

### SecondaryButton
- min height 44
- radius 10
- surface fill
- hairline border
- ink label

### CompactButton
- min 44 pt tap target
- compact horizontal padding
- radius 10
- use for inline Log/Add actions

### SegmentedSelector
- selected = ink + white
- unselected = transparent/subtle surface + secondary text
- capsules only for actual segmented/filter states

### EditorialEmptyState
- icon 28, textTertiary
- title 20 medium serif
- description 15 serif / secondary
- optional secondary/tertiary action
- never use ContentUnavailableView for branded product screens

### InlineNotice
- surface/subtle fill
- compact serif copy
- semantic color only when attention/destructive

### MetricBlock
- metricLarge
- supporting caption beneath
- one dominant metric per screen

### InjectionSiteMap
- body map height: 360
- canonical sites use 44 pt tappable markers
- selected site uses teal semantic emphasis
- previously recorded sites may use ink emphasis
- never visually imply a recommended site
- recency copy is descriptive history only
- free-text historical/custom site labels remain supported

### VialReferencePhoto
- maximum displayed height: 220
- radius 10
- no decorative shadow
- always secondary to recorded vial values
- photo is reference material, never interpreted as dosing guidance

### SyringeVisualization
- live arithmetic visualization only
- U-40 and U-100 are convenience scale presets, never recommendations
- barrel height uses the shared 44 pt compact-control token
- fill uses teal semantic emphasis
- over-scale state uses amber attention semantics
- custom units-per-mL values remain supported

### StackCalendar
- one week at a time
- combines scheduled entries across all trackable protocols
- 64 pt minimum day cell width
- selected day uses ink fill; unselected days remain surface + hairline
- entry cards stay read-only in the calendar
- status reflects the recorded log when present
- calendar copy must remain descriptive, never prescriptive

### CycleRestartReminder
- generated only from a user-recorded ON/OFF cycle with reminders enabled
- copy says the recorded cycle is scheduled to resume
- never instructs the user to administer, restart treatment, or change a dose
- uses the same owned notification namespace and capacity policy as entry reminders

### PlannedRevision
- temporal states are historical, current, and planned
- a planned revision never replaces the current revision before its effective date
- current revision ends exactly when the next planned revision begins
- multiple future revisions may be chained for the same compound
- future revisions may be edited or cancelled only before becoming effective
- historical and already-effective revisions remain immutable
- planning UI records user-supplied instructions and never recommends a titration

---

## Screen hierarchy

Every screen must have one first-read object:

- Today → next entry / resolved-day state
- Protocols → active protocol
- History → timeline
- Insights → primary metric
- Inventory → remaining supply
- Vial → remaining amount
- Calculator → calculated result
- Paywall → value of Pro
- Onboarding → one concept per page

Everything else visually recedes.

---

## Forms

Keep native SwiftUI Form/List behavior, but enforce:
- paper canvas
- serif typography
- sentence-case headers
- black primary controls
- secondary/tertiary token colors
- shared spacing
- no decorative cards inside forms

---

## Enforcement rule

**No local font sizes.  
No local product colors.  
No local corner radii.  
No local shadows.  
No arbitrary spacing outside the token grid.  
No new card geometry without first adding it here and to Theme.swift.**

All new product UI should be composed from the shared visual primitives or added to the system first.

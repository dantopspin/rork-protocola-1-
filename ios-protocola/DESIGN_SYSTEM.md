# Protocola Design System

This file is the fixed visual reference for Protocola. New screens and refactors should use these rules before inventing local styling.

## Direction

**Classical Clinical Minimalism**

- Native iOS interaction model.
- Classical editorial typography using the system serif design (New York-style).
- Warm neutral canvas.
- Near-black as the dominant visual anchor.
- Muted mineral teal only for status, selection, links, charts, and recorded/success semantics.
- Sharp-but-not-square geometry.
- Thin hairlines, almost no decorative shadow.
- Generous whitespace.
- One primary action or figure per screen.
- No gradients, glassmorphism for decoration, loud color, neo-brutalism, or soft wellness styling.

## Hierarchy

- Page title: serif, 30–32 pt, semibold.
- Section title: serif, 17 pt, medium.
- Body: serif, 15 pt, regular.
- Label / row title: serif, 13–14 pt, medium.
- Caption / metadata: serif, 12 pt, regular.
- Key metric: serif, 30–34 pt, medium, monospaced digits where appropriate.
- Primary text: near-black.
- Supporting text: muted warm gray.
- Selected segmented state: near-black fill, white text.
- Primary action: near-black fill on light surfaces; white fill on the dark hero.
- No all-caps headlines. Short uppercase technical labels are avoided unless the content itself is an acronym.

## Spacing

- Page horizontal inset: 24 pt.
- Major section separation: 32 pt.
- Card internal spacing: 16 pt.
- Row vertical rhythm: 12–14 pt.
- Label-to-value spacing: 4 pt.
- Minimum interactive target: 44 pt.
- Empty space is intentional; do not fill a screen merely to reduce whitespace.

## Geometry

- Primary cards: 12 pt radius.
- Rows / compact surfaces: 10 pt radius.
- Buttons: 10 pt radius.
- Badges: 6 pt radius.
- Pills are reserved for segmented selection and compact statuses.
- Avoid oversized 20–30 pt radii.

## Surfaces

- Canvas: warm paper.
- Standard surface: warm white.
- Dark surface: near-black; use selectively for one high-value module.
- Borders: 1 px equivalent, low-contrast warm neutral.
- Shadows: subtle and rare; borders and spacing should do most of the separation work.

## Screen composition

- Today: one dark next-entry hero, then quiet utility/data surfaces.
- Protocols: one stronger active protocol surface, secondary protocols as quieter rows.
- History: editorial timeline with dates and thin separators, not card soup.
- Insights: one dominant metric/chart, then small supporting modules and one dark change-context surface.
- Forms/editors: native Form/List behavior, serif hierarchy, compact sections, no decorative cards.
- Onboarding: native navigation, grouped selection rows, one preview surface per step, minimal copy.

## Motion

- Native navigation/sheet transitions first.
- Spring motion only for state changes that materially help orientation.
- Slight overshoot is acceptable for selection/morph transitions.
- No continuous decorative motion.
- Respect Reduce Motion.

## Product rule

If a new element does not improve hierarchy, comprehension, or interaction, do not add it.

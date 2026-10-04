# Protocola Peptide Product Roadmap

This roadmap deliberately excludes generic nutrition, calorie, hydration, community, and broad wellness features. The benchmark is peptide/GLP-1 protocol tracking only.

## Product position

**Protocola is a protocol operating system, not a diary.**

The product should automate protocol bookkeeping, preserve history, surface derived state, and make changes understandable over time.

Core loop:

**Protocol → Today → Log → Inventory → History → Insights**

Differentiator:

**Your protocol has a memory.**

Every future feature should either:
1. reduce manual logging,
2. derive useful state from recorded data,
3. preserve protocol history,
4. improve multi-compound protocol management, or
5. make the user's own records easier to review and share.

---

## Competitive baseline

### P0 — peptide tracking fundamentals

These are table stakes or near-table-stakes for a serious peptide tracker.

- [x] Multiple protocols
- [x] Multiple compounds
- [x] Scheduled entries
- [x] Multiple times per day
- [x] Daily / weekday / weekly / every-N-days schedules
- [x] One-tap scheduled logging
- [x] Skip status
- [x] Local reminders
- [x] Immutable protocol revision history
- [x] Protocol change timeline
- [x] Vial inventory
- [x] Concentration calculation
- [x] Volume / syringe-unit conversion
- [x] Automatic vial depletion from recorded entries
- [x] Estimated entries remaining
- [x] Injection-site recording
- [x] Symptoms / severity / notes
- [x] PDF visit summary
- [x] AI over personal timeline
- [x] Administration route per compound
- [x] Explicit “as needed” protocol mode
- [x] ON/OFF cycle scheduling
- [x] Cycle phase / restart countdown
- [x] One-tap Skip / Undo Skip from Today
- [x] Cycle restart reminder
- [x] Combined stack/calendar view
- [ ] Planned future titration revisions

### P1 — features that make Protocola materially better than a notes app

- [x] Injection-site rotation history across the entire stack
- [x] Visual body map for site logging/history
- [x] Vial reconstitution/opened date
- [x] Active / reserve / sealed vial state
- [x] Vial photo/reference attachment
- [x] Estimated depletion date
- [x] Reserve inventory / supply vault
- [x] Doses-per-vial calculation surfaced in inventory
- [x] U-40 and U-100 syringe presets
- [x] Interactive syringe visualization
- [ ] Estimated compound-level / half-life curve
- [ ] Multi-compound estimated-level overview
- [ ] Change-aware level curve after dose revisions
- [x] Weekly stack calendar
- [ ] Lock Screen / Live Activity for a due entry
- [ ] Home Screen widgets

### P2 — Protocola-specific advantages

These should be stronger than competitors rather than direct copies.

- [ ] Photo import of vial label / existing instructions into a reviewable draft
- [ ] Planned titration rendered as future immutable revisions
- [ ] Before/after protocol-change comparisons
- [ ] “Since last change” analysis
- [ ] Ask Protocola with tappable source records
- [ ] Ask: “What changed last month?”
- [ ] Ask: “Which vial was I using?”
- [ ] Ask: “Summarize the period after my last change.”
- [ ] Provider-facing longitudinal summary with revision timeline
- [x] Combined stack history with cross-compound site rotation
- [ ] Descriptive cycle adherence and restart history
- [ ] Import existing history from CSV / supported trackers

### Later ecosystem

- [ ] Apple Watch logging
- [ ] Watch complications
- [ ] Quick log from widgets / Live Activity
- [ ] HealthKit adapter for relevant measurements
- [ ] Android only after the iOS product is mature

---

## Explicitly out of scope for now

Do not expand into these simply because competitors do:

- calorie counting
- meal logging
- macro tracking
- barcode food scanning
- restaurant menu scanning
- water goals
- generic sleep tracking
- generic mood tracking
- social/community feed
- broad lifestyle coaching
- supplement marketplace

They dilute the core product.

---

## Implementation sequence

### Slice 1 — Protocol mechanics foundation
1. Administration route on every compound revision and dose snapshot.
2. Rename manual schedule mode to user-facing **As needed**.
3. Add ON/OFF cycles to schedule configuration.
4. Cycle phase and restart context.
5. One-tap Skip + Undo on Today.
6. Tests for scheduling, snapshots, skip inventory invariants, and revision preservation.

### Slice 2 — Injection intelligence
1. Structured injection sites.
2. Cross-stack recent-site history.
3. Body-map picker.
4. Rotation recency view.
5. Never phrase site rotation as medical instruction.

### Slice 3 — Vial intelligence
1. Reconstituted/opened date.
2. Vial state: active / reserve / sealed / archived.
3. Estimated depletion date from recorded schedule.
4. Supply runway.
5. Photo/reference attachment.
6. Syringe visualization.

### Slice 4 — PK / estimated levels
1. Reference half-life metadata.
2. Estimated level model based on actual logs.
3. Multiple-dose accumulation.
4. Multi-compound Today overview.
5. Revision-aware changes.
6. Explicit “estimated, not measured” framing.

### Slice 5 — Planned protocol evolution
1. Future revisions.
2. Titration schedule.
3. Cycle-aware changes.
4. Timeline representation.
5. Edit/cancel future change without rewriting past state.

### Slice 6 — iOS surface area
1. Live Activity.
2. Home Screen widgets.
3. Apple Watch.

---

## Product rules

- Historical logs are immutable snapshots.
- Protocol edits affect future state only.
- A skipped entry consumes zero inventory.
- Correcting/deleting an entry deterministically reconciles inventory.
- No feature recommends a dose, compound, treatment, or administration route.
- Derived calculations come only from explicit user-entered values or clearly labeled reference assumptions.
- One primary action per screen.
- Preserve the fixed visual system in DESIGN_SYSTEM.md.

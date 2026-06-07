# touch-designer-skill — roadmap

Forward-looking items deferred from preemptive import. Each entry has a **trigger condition** for when to investigate / capture — the goal is to anchor new entries in empirical work (HIGH-confidence per skill-growth-protocol v0.3) rather than batch-importing wiki docs at MEDIUM confidence.

When an item's trigger fires: capture in flow via the growth-protocol's pre-ask gates, then remove the item from this roadmap (commit references the now-completed entry).

---

## P2 — capture on next production opportunity

### Perform Mode / kiosk deployment gotchas

**Trigger:** ship a TD project to installation / kiosk / live-perform context (current first candidate: RADON_TREE).

**Why deferred from preemptive import:** Wiki content on Perform Mode is descriptive (parameter lists, Window COMP config), but the production-relevant value is **gotchas** that only surface when you ship — error handling without UI, window recreation on resize, fullscreen edge cases, multi-monitor coordination, audio routing under Perform. Importing distilled gotchas from wiki alone would give MEDIUM-confidence guidance without empirical anchoring. Waiting until we ship lets us produce HIGH-confidence dual-sourced entries.

**On trigger:** during the first installation prep, capture each gotcha as the empirical loop runs (`restart_td` after a perform-mode hang, errors that didn't surface in dev, fullscreen window quirks on Mac vs Windows) and stream them into a new `references/perform-mode-deployment.md` via the growth-protocol's in-flow ask.

**Sources to consult at trigger time:**

- [Perform_Mode](https://derivative.ca/UserGuide/Perform_Mode)
- [Window_COMP](https://derivative.ca/UserGuide/Window_COMP)
- [Monitors_DAT](https://derivative.ca/UserGuide/Monitors_DAT) (for multi-monitor)

---

## Future priority buckets

Empty for now. When other items emerge from production work or user requests, file them by priority (P0 critical / P1 high / P2 medium / P3 low) with explicit trigger conditions.

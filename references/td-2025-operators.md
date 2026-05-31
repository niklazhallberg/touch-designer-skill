# TD 2025 new operators — ORIENTATION LIST

> **This is an ORIENTATION list, not a tactics reference.** It confirms that 2025-series operators EXIST and roughly what they do, so the agent doesn't suggest 2022-era patterns when a 2025 operator solves the same problem better. **Tactics** — exact blend-mode lists, ACES pipeline recipes, realistic performance numbers on M1, laser operator surfaces — are NOT publicly verifiable as of 2026-05-31 and are listed as **Known gaps** at the bottom for growth-protocol capture during real production work.

**Source note:** A Perplexity research pass on 2026-05-31 (and an identical ChatGPT response — treated as the SAME source, not independent confirmation) returned the existence-layer of this file from TD release notes (HIGH confidence) but stopped at the tactics layer. That's the honest line between this file and the growth-protocol-only domain.

---

## Trigger (load this file when)

When choosing a TOP for compositing, color/HDR work, blob tracking, or any visual-pipeline decision in TD 2025+, **check this file first**. Training-data priors will suggest pre-2025 operators that have been superseded; this file exists to break that habit.

---

## Layer Mix TOP — replaces long Composite/Over chains

**Build:** introduced in 2025.31310 / 2025.31550 (TD 2025 experimental series)
**Source:** TD 2025 per-build release notes | **Confidence:** HIGH (release notes)

What it is: a single TOP that stacks an unbounded number of input layers, each with its own per-layer settings. Replaces long `compositeTOP` / `overTOP` / `addTOP` chains.

**Rule:** in TD 2025+, prefer `layerMixTOP` over multi-`overTOP` / multi-`compositeTOP` chains for any compositing of **3+ layers**. *Why:* one operator vs N reduces cook cost, debug surface, and reasoning cost (see `td-architecture.md` § "Minimalism — prefer fewer operators over more"). *Symptom it prevents:* deep, hard-to-trace composite chains where adding a fourth layer means inserting another `overTOP` and rewiring downstream — the kind of network that looks 2022 in a 2025 project.

**Known gap:** exact set of blend modes supported, their semantics (linear vs sRGB blending, alpha pre-multiplication behavior), and per-layer parameter surface — not publicly verifiable. Capture from production when you open one.

---

## Color Space system — projects now control primaries / transfer / HDR

**Build:** introduced across the TD 2025 series. **Window Pixel Formats** parameter on the Window COMP added in 2025.32050.
**Source:** TD 2025 release notes | **Confidence:** HIGH (release notes)

What it is: a project-level color-management system. A new tab in **Preferences → Color** controls color primaries, transfer function, and HDR behavior. Window Pixel Formats exposes the output pixel format for the Window COMP. Settings are saved **per-project** — new projects inherit defaults that may not match HDR or color-accurate requirements.

**Rule:** when starting a TD 2025+ project that targets HDR display or needs color-accurate output, **check Preferences → Color first** before building the render path. *Why:* the per-project defaults inherit from a likely-wrong global default; without explicit setup, color appears subtly "off" with no error message — the bug surfaces visually downstream, far from its cause. *Symptom it prevents:* hours of debugging a "muddy" or "washed-out" render that's actually a color-space mismatch upstream.

**Known gaps:** what specific primaries / transfer functions are exposed in the UI; full ACES viability in TD 2025 (is ACES a one-click preset, or manual OCIO config?); the canonical HDR display setup on Apple Silicon (supported in principle via Metal but TD-specific path unclear); scene-linear vs display-referred conventions. All captured from production.

---

## Blob Track TOP — 2-blob NC limit removed

**Build:** 2025.32820
**Source:** [2025.32820 release notes](https://derivative.ca/release/202532820/74545) | **Confidence:** HIGH (release notes)

What changed: the 2-blob limit for Non-Commercial licenses has been removed. All license tiers (NC, Educational, Commercial) can now track an unbounded number of blobs.

**Rule:** if a project was previously avoiding `blobTrackTOP` due to NC licensing concerns (only 2 blobs allowed), it's now usable for multi-touch, multi-marker, or multi-performer tracking on NC. *Why:* this rhymes with the NC-clamp gotcha in `td-gotchas.md` § "Non-commercial TD silently clamps resolution" — same licensing-trap territory, now partially loosened. *Symptom it prevents:* the agent recommending MediaPipe (heavier, ML-based) for a use case that `blobTrackTOP` (lighter, image-based) now handles fine on NC.

**Known gap:** realistic blob count on M1 Pro before frame budget collapses — not benchmarked publicly. Capture when you actually push it.

---

## Other 2025-series additions — "confirmed exists, depth needed from production"

Released across the 2025 experimental → official series. Listed so the agent knows they exist when older training data would suggest workarounds:

- **Render Simple TOP** — simplified render setup for common cases.
- **Layout TOP grid improvements** — bug fix for column counts exceeding the hardware sampler limit (more common on Mac due to the 16-sampler cap; cross-link `mac-gotchas.md` § "16-sampler GLSL cap").
- **New POP features** beyond what's in `pops.md` — check release notes for per-build POP additions across 2025.30600 → 2025.32820 that the agent might not know about.
- **VS Code integration improvements** for TD Python development across the 2025 series.
- **tdPyEnvManager v1.3.1 with autoSetup** — automated Python dependency setup at TD startup. Relevant for plugins with pip dependencies (e.g., MediaPipe-adjacent tooling). Changes the friction model for plugin distribution.

**Rule:** when starting any 2025-build project, **scan [derivative.ca/release](https://derivative.ca/release) for the build's release notes** — additions accumulate across the experimental series and old training data won't have them. *Symptom it prevents:* the agent fabricating a workaround for a problem 2025 solved natively three builds ago.

**Known gaps:** depth on each — operator surfaces, parameter pages, real production use cases, performance characteristics. All captured from production.

---

## Laser overhaul — exists, no public operator-level detail

**Build:** mentioned in the TD 2025 release-notes series
**Source:** release-notes drive-by mentions | **Confidence:** LOW (existence noted, no detail)

A significant redesign of laser control was referenced in 2025 release notes, but operator-level details are not publicly documented as of 2026-05-31. Just know it **exists** — when a laser project comes up, expect that the 2024-and-earlier laser workflow has changed.

**Rule:** if a project needs laser output in TD 2025+, **don't apply pre-2025 laser conventions blindly** — ask the user about their current laser DAC, and surface that the 2025 overhaul may have changed the workflow. Then capture from production.

**Known gap:** which build introduced the overhaul, what operators changed or were added, hardware DAC support changes, Mac-vs-Windows path parity. Pure growth-protocol territory.

---

## Known gaps (deliberately empty here)

These are publicly unresolvable as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md` § "Pre-ask filters"):

| Gap | Where it surfaces |
|---|---|
| Layer Mix TOP — exact blend mode list, blend semantics, alpha treatment | First time you open a `layerMixTOP` parameter page in production |
| Color Space system — ACES first-class state, HDR Mac path, scene-linear conventions | First HDR-target or color-accurate project |
| Blob Track TOP — realistic N on M1 Pro | First multi-blob production load |
| Laser overhaul — operator breakdown, DAC support, Mac parity | First laser project in TD 2025+ |
| Render Simple TOP, Layout TOP, etc. — production use cases vs older operators | When you actually try one and it diverges from the older op |

When any of these resolves in real work and survives the growth-protocol gates (observed-failure-and-fix YES, one-sentence-rule YES, user-novelty-signal YES), it moves into the appropriate section above or its own dedicated reference.

# Approach patterns — Fallback, Start weak

> **Trigger:** when you've failed on the same sub-step twice in a row, OR before
> starting any first render on a constrained platform (M1, mobile, browser,
> embedded). These are the two "reduce ambition first, raise later" patterns
> the skill leans on.

> **File type — meta-pattern, not domain knowledge.** Most files in `references/`
> capture TouchDesigner *facts* (POPs, audio CHOPs, GLSL gotchas). This file
> captures *how the agent works* under uncertainty. Same load-on-trigger model;
> different shelf. The other current meta-pattern file is
> `skill-growth-protocol.md` (how the agent learns). Domain-knowledge files
> answer "what is true about TD?"; meta-pattern files answer "what do I do
> when reality and plan diverge?".

Both patterns are also captured in user auto-memory
(`feedback_fallback_dont_get_stuck.md`, `feedback_start_weak_prove_technique.md`).
This file is the **skill-level** version — survives auto-memory loss, lives
in git, generalizes beyond the current user/project.

---

## Fallback — two strikes, then switch

**Trigger:** you've attempted the same sub-step twice and both attempts failed
(error, wrong output, perf below threshold, visual artefact). Not "I'm slightly
unsure"; *failed twice on the concrete same thing*.

**Rule:** stop. Switch to a simpler alternative that keeps the pipeline moving.
Report the path taken explicitly — don't silently pivot.

### Why

- Exploratory TD builds branch fast. A stuck sub-step blocks the whole flow;
  the user can't evaluate the next decision until this one resolves.
- Attempt #3 on the same path rarely fails for a new reason. The first two
  attempts have already covered the obvious variations.
- "Keep trying the same thing" silently burns time the user could spend
  redirecting the build entirely.

### How

1. Name the failed approach in one sentence ("Tim's splat .tox renders red/blue
   on M1 — two attempts to bypass the 16-sampler cap both failed").
2. Propose ONE simpler alternative ("force splat color to white in-shader as
   creative workaround").
3. Ask the user to choose before proceeding.
4. If chosen alternative is taken, record which path was abandoned + why, so
   the next session doesn't re-try the same dead-end.

### Don't

- Auto-pivot without telling the user. The first failed attempt may have been
  the actually-correct path; the user owns the call.
- Treat "I haven't fully tried X" as failure #2 — failure means you executed
  and observed the failure, not just considered.

---

## Start weak — prove the technique before tuning quality

**Trigger:** first render on a constrained platform (M1 / mobile / browser /
embedded). Or first integration of a new technique whose viability on this
hardware is unknown.

**Rule:** start with the cheapest config that can answer "does the technique
work at all on this platform". Get a yes/no on capability. Only raise quality
once capability is confirmed.

### Why

- Constrained platforms hide failure modes that don't surface until you push
  them — sampler caps, memory ceilings, FPS cliffs. Starting at production
  quality means you discover the wall AFTER investing in polish.
- The cheap config is the cheapest experiment. If it fails, you've spent
  minutes, not hours. If it works, polish is incremental and verifiable.

### How

1. Pick the minimum config that exercises the technique end-to-end. For splats:
   1k points, no relighting, basic shader. For diffusion: 256×256, 4 steps,
   SD-Turbo. For audio-reactive: one band, raw spectrum, no smoothing.
2. Render. Confirm "the thing happens" with the user.
3. Raise ONE axis (point count, resolution, step count, band count). Render
   again. Confirm.
4. Continue raising until budget collapses; that's the platform ceiling.

### Don't

- Open with production-quality config and "see if it holds." It will collapse
  with FPS=12 and you won't know which dimension caused it.
- Skip the "confirm with user" steps — the user is the one judging whether
  "the thing happens" matches the brief.
- Use this pattern outside its trigger. On stable platforms with known headroom,
  start at target quality directly.

---

## How these patterns interact

Both fire on uncertainty. Fallback fires on **observed failure**; Start weak
fires **before** the first observation, to make any failure cheap to see.
A typical session uses Start weak first (cheap exploratory render), and
Fallback if the cheap render itself stalls twice.

---

## Known gaps

| Gap | Where it surfaces |
|---|---|
| What counts as "fully tried" for failure #1 / #2 (depth of debug effort) | First time two failures feel uneven — one was 30 seconds, one was an hour |
| Per-platform ceilings for cheap-config defaults (M1 Pro splat count, M1 diffusion res) | First production push where the ceiling matters |
| Whether Start weak should apply on Windows / desktop GPU where headroom is large | First non-Mac TD project |

When these resolve in real work and survive growth-protocol gates, they
move into this file or its successor.

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

## Check OP Snippets and Palette before building from scratch

**Source:** [TouchDesigner UserGuide — OP Snippets](https://derivative.ca/UserGuide/OP_Snippets) + [Palette](https://derivative.ca/UserGuide/Palette) | Date: pages fetched 2026-06-07 | **Confidence:** MEDIUM (external, vendor-documented; the access paths and existence of each surface are vendor-stated, but specific snippet/component contents have not been personally verified for any current task)

TouchDesigner ships two built-in discovery surfaces that often contain a working starting point for standard patterns. Check them before generating a from-scratch implementation.

- **OP Snippets** — operator-level examples, copy-paste into the network. Access: `Help menu → Operator Snippets`, OR right-click an operator in the network and select "Operator Snippets…", OR right-click an operator name in the OP Create dialog. Each snippet ships with a `readMe` Text DAT explaining when and how to apply it.
- **Palette Browser** — reusable COMP-level components, drag-drop into the network. Access: `Dialogs → Palette Browser`, OR the palette icon at the top-left of the UI, OR `ui.openPaletteBrowser()` from Python. Preview thumbnails are also droppable.

**Rule for the agent (discovery-first):**

Before generating a from-scratch implementation of a recognizable TD pattern (audio reactivity, basic scatter, simple instancing, dialog UI, projection calibration, common utility wiring, etc.), say to the user: "I'll check OP Snippets / Palette for an existing starting point first." Then either:

- Propose using the existing one (cite which snippet or palette component), OR
- Justify why building from scratch is needed (existing is wrong shape, missing a specific feature, target platform conflict, etc.).

The implementation cost of "check first" is one read; the cost of redoing work when the user later points at a shipped example is hours. This is a META-pattern about agent behavior, not technical TD content.

**Status: verify before relying — pages dated to 2026-06-07 fetch; re-check the Help / Dialogs menu paths in the user's TD build if a snippet or palette item isn't where this entry says it is.** Wiki content and menu organization occasionally rearrange between TD releases.

---

## Scope MCP queries to prevent context-window bloat

**Source:** RADON_TREE shared particles/grid pipeline, 2026-06-07 (own observation — MCP timeouts after multiple verbose probes during a grid-debugging session; restart_td required to recover) + [Reddit r/AI_Agents discussion on tool-response bloat](https://www.reddit.com/r/AI_Agents/comments/1rlucg7/) + general MCP-agent research, late 2025 (corroborating reference) | **Confidence:** HIGH (dual-sourced)

MCP tool responses can consume **40–80% of an agent's context window** when used without query scoping. For TD specifically, the failure mode is calling `query_network` or `find_children` on a root path like `/project1` flat — the JSON response from a large network can run thousands of lines per call, and stacking a few of those quickly fills context.

**Default scoping rules:**

- **Path-first:** Query the specific subnet you're working in (`/project1/MyScene/RenderChain`) rather than the project root. If you don't know where the work lives, do ONE narrow query to discover, then scope subsequent calls.
- **Family-filtered:** When listing operators, pass `type=` (e.g., `type='renderTOP'`) so the response includes only the family that matters.
- **Depth-bounded:** For broad audits, pass `depth=1` or `depth=2` first to see structure before recursing.
- **Prefer `read_tdn` for ≥3 operators:** A single TDN read returns the whole subgraph with default-omission and type_defaults — typically 20–90× fewer tokens than walking via `get_op` + `query_network`. See `mcp-tools-reference/SKILL.md` § `read_tdn` for when this beats per-tool MCP walks.

**What NOT to do:**

```python
# WRONG — flat root query, returns thousands of operators
query_network('/project1')

# RIGHT — scoped to the area of work
query_network('/project1/GaussianSplatting/TreePoints', recursive=False)
find_children('/project1/GaussianSplatting', type='renderTOP')
```

**Acceptance signal:** if a single MCP response is so long that it pushes earlier context out, the query was too broad. Re-issue with path/family/depth scoping. After scoping, the response should fit in a few hundred lines.

**Failure-mode also observed in own production work:** Sequential verbose probes during the 2026-06-07 RADON grid-debugging session led to MCP timeouts on subsequent trivial calls (`absTime.frame`) — TD-side state didn't recover until `restart_td`. The external-research bloat metric matched the lived experience: when probes are verbose AND stacked, the agent loses both context budget AND the ability to query at all.

**Cross-link:** `mcp-tools-reference/SKILL.md` § `read_tdn` for the preferred path when reading ≥3 operators; this rule is about scoping when `read_tdn` isn't the right shape.

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

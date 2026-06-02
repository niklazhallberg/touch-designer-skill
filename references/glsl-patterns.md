# GLSL structural patterns in TouchDesigner — DELIBERATELY RESERVED

**File type:** stub | **Confidence:** N/A (this file reserves a namespace; no knowledge is asserted yet — the empirical-capture mandate IS the content)

**Status:** placeholder. This file is intentionally near-empty as of 2026-05-31.

## Why this file is a stub

GLSL structural patterns in production TD work — how experienced authors structure `glslTOP` / `glslMAT` / `glslmultiTOP` / `computeTOP`, the conventions for uniform authoring, multi-pass chains, compute shader idioms on Apple GPUs, debugging recipes — exist primarily in:

- Practitioners' paid courses and YouTube channels
- TD's own example `.toe` files
- Embedded knowledge inside shipping production projects

…**not** in verifiable, dated web text. A Perplexity research pass on 2026-05-31 returned an honest "no TD-verified info" for the deep questions (workgroup sizing on Apple GPUs, SSBO support state on MoltenVK, glslTOP/MAT/multi structural decision criteria, multi-input shader ordering conventions). Perplexity stopping rather than speculating was the correct call — and that null result is the signal: **this domain belongs to the growth protocol, not web research.**

## How this gap closes

When the agent and user build a real shader during a TD project, and a non-obvious pattern survives the growth-protocol's pre-ask filters (Gate 1 observed-failure-and-fix YES, Gate 2 one-sentence-rule YES, Gate 3 user-novelty-signal YES) — the pattern is written here, generalized per the Step 1/2/3 rewrite rule in `skill-growth-protocol.md`.

Categories we'll capture as production work surfaces them:

- Choosing between `glslTOP` / `glslMAT` / `glslmultiTOP` / `computeTOP` for a given visual task
- Uniform authoring conventions (Vectors page vec4, `chops` parameter on MAT, manual `#define` in shader textDAT, hot-reload workflow)
- Multi-pass and ping-pong wiring patterns (`feedbackTOP` ↔ `glslTOP` loops, ordering, sync gotchas)
- Compute shader idioms on Apple Silicon (workgroup sizing that actually performs, SSBO fallbacks when MoltenVK limits hit)
- Mac-specific shader gotchas beyond the 16-sampler cap (subgroup ops, FP16 textures, memoryless render targets, anything that "works on Windows-Vulkan but silently fails on Mac-MoltenVK")
- Debugging conventions (`*_info` DAT signatures, TD-specific GLSL helpers like `TDOutputSwizzle` / `TDDeform` / `TDWorldToProj` / `TDCheckDiscard` / `uTDMats[cameraIndex]`)

Each pattern lands here only after observed in real TD work, not from web research.

## Don't

- Don't ask Perplexity / web research for "GLSL patterns in TD 2025" again. Already established 2026-05-31 that the verifiable layer doesn't exist online. This is empirical-capture territory.
- Don't create speculative entries here from training-data priors. Wait for real shader work and use the growth-protocol gates.
- Don't conflate the *workaround* knowledge we already have (16-sampler cap → sampler2DArray, etc.) with the *structural* patterns this file reserves space for. Workarounds are diagnostic-driven and live in `mac-gotchas.md`. Structural patterns are design-driven and land here.

## Existing GLSL knowledge in the skill (cross-references)

- `references/mac-gotchas.md` § "16-sampler GLSL cap (MoltenVK)" — the workaround menu (`sampler2DArray`, `samplerBuffer`, atlas packing, deleting unused fetches)
- `rules/td-python.md` § "Render Coordinate System" — Y-up vs Y-down for texture work that GLSL shaders consume
- Auto-memory + session record (2026-05-30): the uTime-via-Vectors-page pattern for exposing `absTime.seconds` as `vec4 uTime` on a `glslMAT` (used during the Gaussian splat flow-effect experiment; pattern itself worked, the effect was later removed)

## When this stub graduates

When 3+ production patterns have been captured here through the growth protocol, this file stops being a stub and becomes a real reference. The growth protocol's Consolidation trigger (§ Trigger A) will likely fire around that point — review the captured patterns, see if they consolidate into a smaller set of principles, then promote.

---

## Captured patterns

### `glslPOP.destroy()` does NOT fully release GPU state — restart_td if other shaders misbehave after

**Source:** RADON_TREE Roots pulse-shader experiment, 2026-06-02 | **Confidence:** HIGH (verified by bypass-test + restart_td)

After creating a `glslPOP` with compute shader code, destroying it via `op.destroy()` + destroying its docked DATs leaves the TD-side state clean (no leftover ops, no stale references in audits). **But** GPU-side state — compiled shader programs, SSBO bindings, uniform allocations — is not guaranteed to release. The symptom that surfaces this:

> An UNRELATED GLSL shader elsewhere in the project (typically a `glslMAT` rendering some other geometry — e.g. the splat shader on a separate `geometryCOMP`) starts producing visual artifacts (clipping, channel swaps, missing geometry) that look like camera/frustum issues but actually originate from corrupt GPU buffer reads.

**Diagnosis pattern:**
1. Audit Python-side: list children of the affected COMP, check wires, flags, transforms — everything looks normal
2. Bypass the suspected new ops — artifact persists → eliminates COMP-level cause
3. Conclude: stale GPU state. Run `restart_td`.

**Fix:** `mcp__envoy__restart_td`. The relaunch clears TD's GPU context completely. All persisted .toe state (operators, params, wires) survives intact; only the volatile shader-program cache is rebuilt.

**Avoid the trap:** when iterating on `glslPOP` configs and seeing weird side-effects in unrelated parts of the project, don't spend time hunting for camera or transform changes you didn't make. Restart first, debug second.

### `glslPOP.numthreadsmode='auto'` is unreliable — set thread count explicitly

**Source:** same experiment, 2026-06-02 | **Confidence:** HIGH

The default `numthreadsmode='auto'` does NOT consistently derive the dispatch count from the wire input — observed dispatching only **1 thread** for a 22 000-point input POP, regardless of the wired upstream POP's point count. The shader compiles successfully and the op shows green, but only point id=0 runs the kernel. Symptom: shader appears to do nothing despite correct code and uniforms.

**Fix — pick one explicitly:**

```python
# Option A: explicit numelems (manual count)
g.par.numthreadsmode = 'numelems'
g.par.numelems = 22000  # must match upstream point count

# Option B: derive from another POP's element count (preferred when chain length can vary)
g.par.numthreadsmode = 'otherinputelements'
g.par.numelemspop = 'upstream_pop_name'  # sibling-relative path
g.par.numelemsclass = 'point'  # or 'primitive', 'vertex'
```

**Don't rely on 'auto'** for compute shaders that should iterate over a wired input. Confirm dispatch count by checking the `*_info` DAT after first cook — if it doesn't show the expected thread count, the mode is wrong.

### POPs in `Geometry COMP` need either `PointScale` attribute OR a custom shader — `constantMAT` alone renders 1px

See `pops.md § "POPs render invisibly without PointScale attribute"`. Cross-listed here because the workaround sometimes involves a custom `glslMAT` (or `glslmultiTOP`) for billboard-sized particles instead of relying on per-point `PointScale`. Both paths are valid; the attribute path is simpler and documented; the glslMAT path is needed when you want per-point shape control (soft discs, splat-style billboards, custom blending).

---

## Known gaps

For the gap-list specific to this file, see § "Don't" and § "How this gap closes" above — they enumerate the categories deliberately reserved for empirical capture (workgroup sizing on Apple GPUs, SSBO state on MoltenVK, glslTOP/MAT/multi structural criteria, multi-input ordering, Mac-specific shader gotchas beyond 16-sampler, debugging conventions). Listing them again as a Known-gaps table would duplicate without adding signal — the stub IS the gap-list.

When a gap closes via production work and survives the growth-protocol gates, it lands as a new section above § "Existing GLSL knowledge in the skill" and the reserved category is struck from § "How this gap closes".

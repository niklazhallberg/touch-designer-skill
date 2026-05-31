# GLSL structural patterns in TouchDesigner — DELIBERATELY RESERVED

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

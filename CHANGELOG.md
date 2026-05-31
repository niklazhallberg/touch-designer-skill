# Changelog

All notable changes to **touch-designer-skill** are documented here.

Discoveries from real projects flow into the
"Improvements and newly acquired knowledge" section automatically
via the skill-growth protocol — see `references/skill-growth-protocol.md`
for the in-flow-ask mechanic and format spec.

At release time: those entries are consolidated under a `[vX.Y.Z]`
heading with the release date.

Format loosely inspired by [Keep a Changelog](https://keepachangelog.com/)
but adapted for skill evolution rather than a software API.

---

## Improvements and newly acquired knowledge

_New learnings registered from past or ongoing TouchDesigner projects._

### 💡 2026-05-31 — [project: skill-meta]
- **POPs reference deepened with production-grade architecture detail** in `references/pops.md` (260 → ~520 lines), filtered from a second strict-triage research pass. Major additions: (1) **Build delta table** — per-build POP additions across 2025.30770 → 2025.32820 for "my training data doesn't know about this" diagnosis; (2) **Operator vocabulary expanded** — full Generators list (Box/Circle/Plane/Primitive/Rectangle/Sphere/Torus/Tube/Revolve/Pattern/Sprinkle/Polygonize/Point File In/Import Select/OAK Select/ZED added), full Shaping list (Attribute Combine/Convert, Projection, Normalize, Quantize, ReRange, Limit, Trig, Twist, Facet, Connectivity, Subdivide, Cache Blend/Select, Field, Skin/Skin Deform, Texture Map, Lookup Attribute/Channel/Texture added), Copy/scatter subsection (Copy POP + GLSL Copy POP), explicit Experimental list (Alembic Out, Extrude, Line Thick, Phaser, Text, Trace, Triangulate per [Category:POPs 2025-10-28]), workhorse subset distilled from practitioner sources; (3) **`GLSL Create POP` flagged DEPRECATED** → use `GLSL Advanced POP` + optional `Topology POP`; (4) **Conversion bridges** with documented semantic translations — `SOP to POP` translates uv→Tex/Cd→Color/width→LineWidth/pscale→PointScale, `Dimension POP` for mesh-dimension preservation, `CHOP to POP` with "Precise names" for exact roundtrip, `DAT to POP` empty-headers crash workaround (2026-04 forum bug); (5) **Three-class attribute model** — points/vertices/primitives each with their own attribute lists, points-without-primitives don't render but are template/copy/instancing data, auto-generated attributes documented (`Nebr` from Neighbor POP, `PartVel/PartMass/PartLifeSpan/PartForce` from Particle/Force-Radial); (6) **NEW SECTION "Index pattern matching — POP grammar"** — TD 2025 introduced a new pattern language POPs use exclusively; documented syntax `[3-15]`, `^[100-200]`, `[0-15:2]`, `[0-15:2:5]`, `[*:3]` and which POP parameters accept it (Delete/Group/Primitive/Switch/GLSL/GLSL Advanced/Merge/Attribute Combine). This corrects/clarifies an earlier "no POP-inline-index-pattern-language" claim — TD HAS index patterns; what doesn't exist is Houdini-style inline attribute expressions (`@P.y > 0`), which remains in known-gaps; (7) **NEW SECTION "Map-pages — per-point parametric without shaders"** — before reaching for GLSL POP to vary a parameter per-point, check the operator's Map page (Particle POP / Force Radial POP / etc.); (8) **NEW SECTION "Line and curve workflows"** — `Line POP` family + `Trail POP` for ribbon trails, stay in POPs from generation to render; (9) **NEW SECTION "Particle systems — open feedback chain"** — explicit architecture: `Particle POP` → modifiers (`Force Radial POP` writes `PartForce`) → `Null POP` as feedback target, not a closed solver; (10) **NEW SECTION "GLSL POP in practice"** — SSBO model (each attribute = SSBO), one thread per element, **Initialize Output Attributes is the #1 crash prevention rule**, basic vs Advanced distinction (basic = mutate + multi-pass, Advanced = author/reshape + cross-class), cross-class function naming `TDIn_Attrib()` / `TDInVert_Attrib()` / `TDInPrim_Attrib()`; (11) **Debugging section expanded** — POP viewer overlays via Display Options for spatial intuition, common documented mistakes table (uninitialized GLSL POP outputs, DAT to POP empty headers, older Feedback POP disconnect, GLSL Create POP deprecation, "POP to render" anti-search). Sourcing: Derivative docs (HIGH for operators/bridges/semantics), 2025-series release notes (HIGH for build delta), Gianmaria Vernetti + Darien Brito (MEDIUM for practitioner workhorse subset).
- Value for user: the agent now has production-architecture-level POP knowledge — knows which POPs are Experimental (lower trust), knows the `GLSL Create POP` deprecation, has the SSBO + Initialize-Output-Attributes crash-prevention rule for GLSL POPs, knows the open-feedback-chain particle architecture, knows index patterns and Map pages exist before reaching for custom GLSL. Concrete improvements over the prior pops.md: when wiring particles, builds the open feedback chain explicitly; when scattering meshes, picks Copy POP / GLSL Copy POP over searching for non-existent operators; when filtering points, uses the index-pattern syntax instead of looping in Python; when authoring custom GLSL POPs, enables Initialize Output Attributes by default.
- File: `references/pops.md` (rewritten, expanded 260 → ~520 lines)
- Type: [discovery + correction]

### 💡 2026-05-31 — [project: skill-meta]
- **Audio-reactive systems reference** in `references/audio-reactive.md` (new). Filtered HIGH+MEDIUM findings from a strict-triage research pass. Covers: (1) **Input** — `Audio Device In CHOP` in frames-mode for low-latency, `Audio File In CHOP`, `Audio Device Out CHOP`, plus the canonical show-rig (one file source split to analysis + speakers); (2) **Frequency analysis** — `Audio Spectrum CHOP` (FFT bins) vs `Audio Analyze CHOP` (RMS/peak/centroid scalar metrics); (3) **Rate-gap mental model** — audio CHOPs at 48 kHz vs visual cook at 60 Hz, hard rule "audio-rate NEVER reaches shaders/POPs directly", `Resample CHOP` as the explicit rate-bridge, CHOP→GLSL uniform via the same vec4-Vectors-page pattern used for absTime (cross-link `glsl-patterns.md`); (4) **Mac routing** — BlackHole + Audio MIDI Setup Multi-Output Device as the critical Mac-specific pattern for "Spotify/Ableton → TD", with installation steps; (5) **Band patterns** — direct bins (jitter, graphic-EQ aesthetic) vs band averages (3-16 stable controls), with 20-150 Hz / 150 Hz-2 kHz / 2-12 kHz workhorse split; (6) **Asymmetric smoothing** — `Lag CHOP` with Filter Width Up < Down (attack 5-30 ms, release 150-500 ms) as the "liquid" feel default; (7) **Anti-jitter** — round-then-smooth for instance counts, hysteresis via two thresholds + `Logic CHOP` for state changes; (8) **Beat detection** — heuristic CHOP-built recipe (Spectrum → low band → Lag → Threshold → Logic Off-Delay refractory) OR `Ableton Link CHOP` when Ableton is in the loop (preferred); (9) **CPU/GPU** — audio is CPU-only, no GPU audio in TD, rarely the bottleneck on M1. **Critical empty-gap table** at the end: `Audio Beat CHOP`, `Audio Band Filter CHOP`, `Audio Band EQ CHOP`, `Audio Envelope CHOP`, `Audio Stream In CHOP`, and **native NDI audio receiver** — all confirmed NOT IN TD as of 2026-05; agent must build from primitives, not search palette. Bold CHOP names throughout for grep anchors.
- Value for user: closes one of the three top-tied gaps from the original ranking. Production-grade audio-reactivity is now answerable from references instead of guessing. The BlackHole-on-Mac pattern alone is worth the file — it's the single most common Mac trap for audio-reactive work. Cross-reference for the particle-system project the user mentioned wanting to build: asymmetric smoothing IS the "liquid feel" technique.
- File: `references/audio-reactive.md` (new) + `SKILL.md` § References table (new row)
- Type: [discovery]

### 💡 2026-05-31 — [project: skill-meta]
- **POPs reference expanded from thin defaults-page to full operator-family guide** in `references/pops.md` (75 → ~250 lines). New sections: (1) **What POPs replace vs don't replace** — keeps Derivative's "re-think your patterns, not full replacement" framing, marks SOPs-for-modeling and `particlesGPU` as coexisting; (2) **Operator vocabulary** organized by family with bold operator names as grep anchors — Generators (Point Generator / Grid / Sphere / Box / Line / Curve / File In / Alembic In POP, Official workhorses), Shaping (Attribute / Math / Noise / Lookup / Group / Sort / Random / ReRange / Transform / Limit / Quantize / Normalize POP, Official workhorses), Dynamics (Particle POP flagged Experimental in early 2025 builds, Feedback POP, Trail POP), GLSL POPs (GLSL POP + GLSL Advanced POP with Mac ray-query limitation), Topology, Attribute Authoring; (3) **Conversion bridges** — SOP/CHOP/DAT/TOP→POP exist, POP→CHOP exists, **explicit "NO 'POP to SOP' operator exists"** rule to stop the agent from searching for it; (4) **Attribute system mental model** — built-in P/Cd/N/Tex with component-suffix indexing, custom attributes via Attribute Create POP, type suffixes f/F/i/I/u/U, array indexing `MyArray_0_`, plus the confirmed-empty gap "no Houdini-style inline @P.y syntax"; (5) **Rendering pipeline** — `POP chain → Geometry COMP (instance source) → Render TOP`, explicit "no new POP-instancing-mode on Geometry COMP, integrates into the existing instancing UI"; (6) **Mac specifics** — no double-precision attributes on macOS, no hardware ray tracing → GLSL Advanced POP ray-query doesn't work on M1+; (7) **Debugging** — Info CHOP for total_cooks/cook_time/errors/warnings, Delete Input Attributes for isolation, OP Snippets for binding-syntax ground truth; (8) **Known gaps** explicitly listed (M1 benchmarks, full MoltenVK-POP bug list, exact GLSL POP binding syntax — defer to OP Snippets, Particle POP collision support). Official-since-2025.31550 (Oct 30, 2025) made authoritative. Discoverability: new row added to SKILL.md § "References (load-on-demand by topic)" with the "check before building SOP chains" trigger.
- Value for user: the agent now has a real operator-level vocabulary for POPs instead of "POPs are the default" hand-waving. Concrete: it won't search the palette for a non-existent "POP to SOP" operator, won't propose Houdini-style attribute syntax that doesn't exist in TD, knows ray-query won't work on M1, knows to drop an Info CHOP first when a POP chain misbehaves.
- Files: `references/pops.md` (expanded from 75 → ~250 lines) + `SKILL.md` § References table (new row)
- Type: [discovery]

### 💡 2026-05-31 — [project: skill-meta]
- **TD 2025 new operators — orientation list** in `references/td-2025-operators.md`. Confirms existence + rough purpose of: **Layer Mix TOP** (2025.31310/31550, replaces composite/over chains for 3+ layer compositing); **Color Space system** (2025-series, Preferences → Color tab; Window Pixel Formats added 2025.32050); **Blob Track TOP** (2025.32820 — 2-blob NC limit lifted for all license tiers); **Render Simple TOP**, **Layout TOP** grid fix, **VS Code integration**, **tdPyEnvManager** v1.3.1 autoSetup as "confirmed exists, needs production depth"; **laser overhaul** as "exists, no public operator-level detail." File is **explicitly labeled as ORIENTATION, not tactics** — known gaps (Layer Mix blend mode list, ACES on Mac, blob-N on M1 Pro, laser operator surfaces) listed at the bottom for growth-protocol capture. Each entry has a one-sentence rule + the symptom it prevents. Note on sourcing: ChatGPT and Perplexity returned identical TD 2025 content — treated as a SINGLE source, not independent confirmation.
- Value for user: stops the agent from proposing 2022-era composite chains, manual color setup, or 2-blob limit workarounds when 2025 operators now solve those better. Plus discoverability: new **References (load-on-demand by topic)** section in `SKILL.md` with the TD 2025 row and trigger condition — first entry in what will become a growing table as references mature.
- Files: `references/td-2025-operators.md` (new) + `SKILL.md` § "References (load-on-demand by topic)" (new section)
- Type: [discovery + convention]

### 🔧 2026-05-31 — [project: skill-meta]
- **GLSL deep structural patterns deliberately carved out of web research**: a Perplexity pass on the GLSL-deep-pattern questions (workgroup sizing on Apple GPUs, SSBO state on MoltenVK, `glslTOP`/`glslMAT`/`glslmultiTOP` structural decision criteria, multi-input shader ordering conventions) returned "no TD-verified info" as of 2026-05-31. That null result IS the signal — the domain lives in practitioners' courses, TD example `.toe` files, and embedded production knowledge, not in dated web text. New `references/glsl-patterns.md` stub explicitly reserves the namespace for growth-protocol capture and lists "don't ask Perplexity again" as a hard rule, preventing the next research attempt from wasting cycles.
- Value for user: stops the next "let's research GLSL in TD" attempt from spinning. Empirical capture via the growth-protocol's pre-ask gates is the right path for this domain — when a real shader pattern survives all three gates in actual project work, it lands in this file.
- File: `references/glsl-patterns.md` (new stub)
- Type: [convention]

### 💡 2026-05-31 — [project: skill-meta]
- **Gaussian Splatting pipeline split documented** in `components/gaussian-splatting-mac.md` — creation (vid2scene cloud, used in production for `RADON_Tree.ply`; OpenSplat local-Mac via Metal `-DGPU_RUNTIME=MPS`, AGPLv3, to-verify) is a separate step from rendering (TDGS, Tim Gerritsen, atarilover123, etc.). Explicit "don't mix these up" rule: OpenSplat replaces vid2scene (creator-to-creator), NOT TDGS (which is a renderer). OpenSplat caveats noted: requires libtorch+OpenCV+Xcode compile from source AND COLMAP/OpenSfM pre-processed input — not plug-and-play.
- Value for user: when a user asks "how do I get a Gaussian splat into TD", the agent now knows there are two pipeline steps and recommends the right tool for each layer instead of conflating creators with renderers.
- File: `references/components/gaussian-splatting-mac.md` § "Pipeline split — splat CREATION vs splat RENDERING" (new section, top of file)
- Type: [discovery]

### 💡 2026-05-31 — [project: skill-meta]
- **Minimalism principle + visual-verification reinforcement** from Dylan Roscover's "The Great Inversion" (March 2026). Two concrete agent rules: (1) prefer few operators over many — Derivative's `buttonMomentary` widget = 33 operators internally vs a Text COMP = 1 operator (10:1) — heavy palette abstractions are often unnecessary for project-specific work; (2) "if it looks correct, it is correct" — `capture_top` is ground truth, `errors=0` plus correct parameter values is necessary but not sufficient evidence that a visual change works. Manifesto/philosophy parts of the source article (taste-vs-execution, hardware moat, open-source bait) deliberately left out — not agent-actionable. Derivative-native-MCP claim from the same article also left out — already flagged as unconfirmed in earlier filtering.
- Value for user: agent picks lighter network structures by default; agent never claims "visual change done" without a capture to back it up.
- File: `references/td-architecture.md` (new)
- Type: [discovery]

### 💡 2026-05-31 — [project: skill-meta]
- **Four cross-platform TD gotchas** from research dossier filtering: (1) LLMs frequently hallucinate TD parameter names from training-data priors (`dat`→`pixeldat`, `colora`→`alpha`, `sizex`→`size`) — verify with `get_op` before setting; (2) Non-commercial TD silently clamps resolution to 1280×1280, and H.264/H.265/AV1 codecs require Commercial license — use ProRes/Hap on Non-Commercial; (3) "Invalid OP object" errors come from destroying + recreating same-name ops in one `execute_python` call — split, rename, or defer with `run(..., delayFrames=1)`; (4) MCP security model: localhost-only, no auth, `execute_python` runs unsandboxed as the TD process — rhymes with the DESTRUCTIVE cluster's per-call-yes rule. Plus a small note on Envoy tool count drift (~48 as of v5.0.413, third-party catalogs cite 45–50).
- Value for user: each item closes a real production-debug session before it starts. The parameter-names gotcha alone prevents a class of trial-and-error loops.
- File: `references/td-gotchas.md` (new)
- Type: [discovery]

### 💡 2026-05-31 — [project: skill-meta]
- **mac-gotchas.md upgraded**: (1) the 16-sampler GLSL cap now ships with WORKAROUNDS, not just the problem statement — texture arrays (`sampler2DArray`, one sampler N slices), texture buffers (`samplerBuffer`, one sampler for large flat arrays), atlas packing, and "delete unused fetches" as a no-effort first check; (2) intro paragraph corrected — TD's render backend is Vulkan on all platforms (MoltenVK is just the Mac translator), OpenGL was removed from TD in 2022 (so any "TD's OpenGL path" reference is outdated), and custom Metal compute backends for custom operators are unsupported / crash-prone on Mac as of mid-2025.
- Value for user: the 16-sampler entry is now constructive instead of just diagnostic — the agent can propose a structural fix instead of only the "force-white" hack. The Vulkan correction prevents the agent from suggesting Metal-direct paths that don't work.
- File: `references/mac-gotchas.md` § (intro + "16-sampler GLSL cap" workaround section)
- Type: [discovery + correction]

### 💡 2026-05-31 — [project: skill-meta]
- **MediaPipe component reference seeded**: (1) plugin output is ≥3 frames behind realtime due to internal web-browser inference path — when compositing tracking output with live camera, ALWAYS insert a Cache TOP on the camera branch to resync; (2) every enabled detection task (face / face landmarks / hands / pose / objects / image classification / image segmentation / image embeddings) carries CPU+GPU cost — turn off unused tasks on the MediaPipe COMP's tabs to recover FPS.
- Value for user: when a "hand overlay on live video" project shows visible lag, the agent now knows the cause and the fix (Cache TOP) instead of guessing at GLSL or render-graph issues. The disable-unused-tasks rule frequently recovers FPS on Mac M1 projects.
- File: `references/components/mediapipe.md` (new)
- Type: [discovery]

### 🌱 2026-05-30 — [project: skill-meta]
- **Phase 2 scaffolding landed**: 7 skills + 4 rules copied from `spin-the-spoon/.claude/` as canonical snapshots; growth-protocol v0.1 adapted from Lens Studio v0.6 (TD-flavored examples, single-user tone, kept all 3 generalization steps + CHANGELOG-prepend mandate); `scripts/session-sync.sh` written and made executable (NOT yet wired into `~/.claude/settings.json`); `references/project-bootstrap.md` written with verified working Embody config (v5.0.413, TD 2025.32820, AI Client=Claude Code, AI Project Root=Git root, Envoy port 9870); SKILL.md gained a tool-clusters section (OBSERVE / CREATE / MODIFY / DESTRUCTIVE / PROFILE / BRIDGE) with explicit cross-listing annotation.
- Value for user: from a new machine, three steps (clone repo, wire SessionStart hook, run `td-new <name>`) deliver a project ready for Embody-managed Claude integration. Tool-cluster grouping lets the agent reason about safety/approval once per cluster instead of restating per tool.
- Files: `skills/*` (7), `rules/*` (4), `references/skill-growth-protocol.md`, `references/project-bootstrap.md`, `scripts/session-sync.sh`, `SKILL.md` § Tool clusters
- Type: [structural]

### 💡 2026-05-30 — [project: skill-meta]
- **POPs as default for point/geometry/particle work** in TD 2025+ — POPs released October 2025, GPU-resident, replace most SOP→CHOP→instancing workflows. Mac-safe on Apple Silicon, hard-crash on Intel/AMD. Build 2025.32820 added `.point()/.prim()/.vert()` Python functions; use `delayed=True` to avoid GPU sync stalls.
- Value for user: skill now defaults to POPs for new particle/geometry work, doesn't suggest 2022-era SOP→CHOP→instancing patterns.
- File: `references/pops.md` (new)
- Type: [discovery]

### 💡 2026-05-30 — [project: skill-meta]
- **Gaussian Splatting on Mac — three viable paths beyond Tim Gerritsen's broken-on-Mac original**: (1) atarilover123/GaussianSplat_TD fork with 16-sampler-reduced shader for universal Mac+PC, (2) Lake Heckaman TDGS 1.3.1+ native Apple Silicon (TD 2025.31760+), (3) Derivative's own POP-based Gaussian Splatting example shipped in 2025.30600+. Tim Gerritsen's component fails silently with red/blue color corruption on Mac due to 17-sampler shader hitting the 16-sampler cap.
- Value for user: when starting a new splat project on Mac, the skill can immediately recommend the right component based on production needs instead of repeating the Tim-Gerritsen-red-blue investigation. Three alternatives are marked "to verify in production" so the agent flags uncertainty rather than asserting.
- File: `references/components/gaussian-splatting-mac.md` (new)
- Type: [discovery]

### 💡 2026-05-30 — [project: skill-meta]
- **Five Mac-specific gotchas seeded into mac-gotchas.md**: (1) MediaPipe requires Full Disk Access in System Settings → Privacy & Security or fails silently — Mac-critical, verified in production today; (2) macOS/MoltenVK 16-sampler GLSL cap — shaders with 17+ samplers compile but render channel-swapped/corrupt color silently; upstream MoltenVK allows 80 but TD's compilation path hits 16; (3) POPs crash Intel Macs with AMD GPUs, safe on Apple Silicon; (4) TD runs on one CPU core — Activity Monitor aggregate % lies, use TD's Performance Monitor; (5) MoltenVK regressions can halve FPS on specific experimental builds — check build version before blaming operators or modifying assets.
- Value for user: closes a class of "why isn't this working on Mac" debugging sessions before they start. The MediaPipe Full Disk Access item alone saved hours today.
- File: `references/mac-gotchas.md` (new)
- Type: [discovery]

### 🌱 2026-05-30 — [project: skill-meta]
- **Repo seeded** from `spin-the-spoon/.claude/` after a 7-skill / 4-rule / 6-memory-file maturity threshold was crossed. Skill promoted from project-local to central single-user repo with self-growing structure: `references/`, `CHANGELOG.md`, growth-protocol, SessionStart sync hook, `td-new` scaffold script. Auto-memory left untouched as a complement until references are confirmed working.
- Value for user: TD knowledge is no longer project-locked; new projects inherit the same skill via a one-command scaffold (`td-new`); learnings sync across machines via git pull on session start.
- File: this repo (initial commit)
- Type: [structural]

---

## Versions

No tagged versions yet. The skill is in continuous-improvement mode under
`## Improvements and newly acquired knowledge`. First version tag will land
when the references/ banks are populated and the team-scaling path is taken
(or earlier if the scope is locked).

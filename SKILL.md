---
name: touch-designer-skill
description: Builds and modifies TouchDesigner projects using Embody (externalization to git-trackable files) + Envoy MCP (live operator manipulation from Claude). Covers POP/SOP/TOP/CHOP/DAT operator creation, network layout, TDN-strategy COMPs, GLSL shaders in TD, hand-tracking, MediaPipe components, Gaussian splat workflows. TRIGGER when user mentions TouchDesigner, TD, .toe, .tox, .tdn, Envoy MCP, Embody, "operator", "network" in a TD context, or when CWD contains a .toe file or .embody/ directory. SKIP for Lens Studio, Unity, Unreal, Blender, Houdini, generic Python, or visual programming without TD context.
compatibility: Requires TouchDesigner 2025.32820+, Embody.tox v5.0.413+, Envoy MCP server on localhost:9870
metadata:
  version: "0.2.0"
---

# TouchDesigner skill

Build TD projects from Claude Code using Embody-externalized files + Envoy MCP for live network manipulation.

## Read these first (mandatory, session-start)

1. **Project CLAUDE.md** — Embody regenerates this in every TD project. Has the 12 critical rules (TDN-first, never assume paths, log analysis, etc.) and a per-tool skill-load table.
2. **`references/skill-growth-protocol.md`** — pause-on-discovery, generalize, write to references, CHANGELOG-prepend, commit + push after user ok. Same pattern as the LS skill but trimmed for single-user.
3. **`CHANGELOG.md`** — scan the last 10–20 entries. Each one points at a file/section; open the ones plausibly relevant before they fire as triggers.

Then scan `references/` filenames so you know what banks exist before they're needed.

## HARD TRIGGERS — run growth-protocol BEFORE next reply, not at end of task

Reflexive, not memory-dependent. Capture in flow. If ANY of these is true after a fix, IMMEDIATELY run the gates in `references/skill-growth-protocol.md` and propose a save — do NOT wait for the user to ask. Batched capture is a known failure mode (the user has had to remind in the past).

- **3+ probe→fix cycles** on the same sub-task (signals empirical territory, not docs-knowledge)
- **Reality contradicted your model** (you predicted X, observed Y, root-caused why)
- **Non-obvious workaround** used (a fresh agent with docs wouldn't guess it)
- **`restart_td`** or any reset-tool needed because state didn't clean up
- **User expressed surprise** ("åh!", "oj", "varför?") or asked "how do we avoid this next time?"
- **You changed your mental model mid-flow** ("actually, X doesn't work like Z, it works like Y")

Multiple triggers from the same flow batch into one ask. Across turns, never — surface immediately.

## How this skill is split

| Lives here (central repo, user-level) | Lives per project (Embody auto-generates) |
|---|---|
| This `SKILL.md` (front door) | `<project>.toe` (your work) |
| `skills/*/SKILL.md` × 7 (canonical workflows) | `.mcp.json`, `.embody/envoy-bridge.py`, `.embody/envoy.json` |
| `rules/*.md` × 4 (canonical rules) | `CLAUDE.md`, `AGENTS.md` (per-project preface) |
| `references/*.md` (growth, gotchas, patterns) | `.claude/skills/*`, `.claude/rules/*` (Embody regen) |
| `CHANGELOG.md` (biography) | `.claude/settings.local.json` (per-machine perms) |
| `scripts/td-new`, `scripts/session-sync.sh` | `Backup/`, `TDImportCache/`, `logs/`, `.venv/` |

**Path A (sidecar):** Embody keeps generating project-local `.claude/skills/` and `.claude/rules/`. The central repo's versions are *canonical snapshots* the agent reads from when project-local files are stale or missing. References, growth-protocol, and CHANGELOG are central-only.

If a project-local skill conflicts with a central one (rare; Embody regen is usually deterministic): central wins for *additive* knowledge (new references), project-local wins for *workflow* (Embody knows the project's tool versions). Surface the conflict explicitly when it happens — don't silently average.

## Role split

You (Claude Code) are the **technical executor**. The user is the **creative director + approver**. Apply the same rules as the Lens Studio skill: never bundle multiple actions per message, never auto-advance on silence, always ask before destructive/risky operations.

## Tool clusters (Envoy MCP)

Before picking a tool, pick a *cluster*. Cluster-level rules apply uniformly to every tool in the cluster — this lets the agent reason about safety/approval once per cluster instead of restating per tool. Full per-tool reference: `skills/mcp-tools-reference/SKILL.md`.

### OBSERVE — read-only, free to call in parallel, no approval required
`query_network`, `find_children`, `read_tdn`, `get_op`, `get_parameter`, `get_dat_content`, `get_connections`, `get_annotations`, `get_enclosed_ops`, `get_op_position`, `get_op_flags`, `get_op_errors`, `get_op_performance`*, `get_network_layout`, `get_td_status`*, `get_td_info`, `get_td_classes`, `get_td_class_details`, `get_module_help`, `get_logs`, `get_externalizations`, `get_externalization_status`, `get_project_performance`*, `capture_top`

### CREATE — instantiate new operators; requires layout planning per `create-operator` skill
`create_op`, `create_extension`, `create_annotation`, `import_network`

### MODIFY — change existing operators; requires read-back verification of compound/expression edits
`set_parameter`, `set_dat_content`, `edit_dat_content`, `set_op_flags`, `set_op_position`, `rename_op`, `copy_op`, `set_annotation`, `connect_ops`, `disconnect_op`, `layout_children`, `cook_op`, `exec_op_method`, `externalize_op`, `save_externalization`, `remove_externalization_tag`, `export_network`

### DESTRUCTIVE — cannot be undone; requires explicit per-call user approval
`delete_op`, `execute_python` (the escape hatch — unbounded reach, no undo)

### PROFILE — performance diagnostics; use to diagnose *before* optimizing or modifying assets
`get_op_performance`*, `get_project_performance`*

### BRIDGE — meta-tools that work even when TD is down
`get_td_status`*, `launch_td`, `restart_td`, `switch_instance`, `batch_operations`

**Cross-listing:** tools marked with `*` appear in two clusters intentionally. `get_op_performance` and `get_project_performance` are in both **OBSERVE** (read-only, free to call) and **PROFILE** (analytical intent). `get_td_status` is in both **OBSERVE** and **BRIDGE** (meta-tool that works pre-TD-launch). This is by design — pick the cluster matching your current intent, not the "first" or "narrowest" listing.

**Default rule per cluster:**
- OBSERVE → batch freely, run in parallel where independent
- CREATE/MODIFY → read-back after each call (especially expression/compound writes); see `td-python.md` § Operator Storage gotchas
- DESTRUCTIVE → state intent + show what will be affected + wait for explicit user yes per call (don't reuse prior approval)
- PROFILE → use *before* asking the user to shrink an asset or accept lower quality
- BRIDGE → safe before launching TD; use `get_td_status` first when connection is uncertain

## Skills (load-on-demand)

Each skill has YAML frontmatter that triggers it. The central versions live here in `skills/`; Embody also regenerates them per project. Use the project-local copy when in a project; fall back to central when missing.

| Skill | Trigger |
|---|---|
| `create-operator` | Before any `create_op` MCP call |
| `create-extension` | Before `create_extension` |
| `manage-annotations` | Before `create_annotation` / `set_annotation` |
| `externalize-operator` | Before `externalize_op` / `save_externalization` |
| `debug-operator` | When operator errors appear or behavior is reported broken |
| `mcp-tools-reference` | Before the first MCP call in a session |
| `td-api-reference` | Before writing TD Python (`execute_python`, DAT scripts) |

## References (load-on-demand by topic)

Knowledge banks beyond the skills above. Load when the trigger fires; the file's first paragraph confirms whether you've matched the right one. Grows as production work surfaces new patterns via the growth protocol.

| Topic | Trigger | File |
|---|---|---|
| **TD 2025 new operators** | When choosing a TOP for compositing, color/HDR work, or any visual-pipeline decision in TD 2025+ — check whether a 2025 operator now solves it better than the pre-2025 pattern training data would suggest | `references/td-2025-operators.md` |
| **POPs / point-cloud / GPU particles / spline work** | When the task involves points, particles, point clouds, scatter/instancing, or spline geometry — check this for the right POP **before** building SOP chains; TD 2025 likely has a POP for it | `references/pops.md` |
| **Audio-reactive visuals / audio input** | When the task involves audio-driven visuals, audio input, or beat/tempo — load this. **And remember the BlackHole routing for system audio on Mac** | `references/audio-reactive.md` |
| **Third-party TD ecosystem tools** | When a user asks for a capability that feels heavy to build from scratch (advanced particles physics, raymarching, ML tracking beyond MediaPipe, 2D dynamic lighting, motion blur, etc.) — check this awareness catalog before proposing to build it | `references/td-community-tools.md` |
| **AI / LLM integration / real-time gen AI** | When the task involves LLM/AI-driven visuals, real-time generative AI, or agent-controlled TD parameters — load this. **The OSC bridge (Python → OSC → TD) is the recurring stable architecture; specific tools/models are snapshot-in-time.** | `references/ai-integration.md` |
| **Mac gotchas (M1 / MoltenVK)** | When something works in spec but breaks visually on Mac — corrupt colors, silent failures, FPS halving — OR before configuring anything Mac-specific. **Check this BEFORE blaming operators or assets** — Mac compiler caps (16-sampler), MoltenVK regressions, MediaPipe Full Disk Access trap, single-core CPU model | `references/mac-gotchas.md` |
| **TD cross-platform gotchas** | When a `set_parameter` call fails with "no such parameter", when output is mysteriously clamped to 1280×1280, when "Invalid OP object" errors appear, or before trusting LLM-suggested TD parameter names. **Verify with `get_op` BEFORE setting** — LLM training data has wrong TD parameter names (`dat`→`pixeldat`, `colora`→`alpha`) | `references/td-gotchas.md` |
| **TD architecture — minimalism + visual verification** | Before dropping a palette widget (button/slider/toggle), before declaring any visual change "done", or when reading a network with deep internal nesting. **`errors=0` is necessary but not sufficient** — `capture_top` is ground truth; 33-operator widget vs 1-operator primitive matters for cook cost | `references/td-architecture.md` |
| **GLSL structural patterns** | When picking between `glslTOP` / `glslMAT` / `glslmultiTOP` / `computeTOP`, authoring uniforms, or building multi-pass shader chains. **Stub today — don't web-research, it's empirical-capture territory.** Cross-link `mac-gotchas.md` § 16-sampler for the workaround menu | `references/glsl-patterns.md` |
| **Gaussian splat components on Mac** | When user wants to render a `.ply` / `.spz` splat in TD on macOS, or when a splat component renders with corrupt colors (red/blue). **Don't conflate creators (vid2scene / OpenSplat) with renderers (Tim / TDGS / POP-native)** — different pipeline layers, both required | `references/components/gaussian-splatting-mac.md` |
| **MediaPipe component** | When using `torinmb/mediapipe-touchdesigner` for hand / face / pose tracking, OR when tracking overlay drifts ≥3 frames behind live camera. **Insert Cache TOP on the camera branch** to resync; **disable unused detection tabs** to recover FPS. Mac prereq: Full Disk Access (see `mac-gotchas.md`) | `references/components/mediapipe.md` |
| **StreamDiffusion in TD on Mac (M1+)** | When user mentions StreamDiffusion / StreamDiffusionTD / dotsimulate / Daydream / "realtime AI diffusion in TD" / "ControlNet in TD" / "hand or body tracking → AI visuals" on a Mac. **No local NVIDIA GPU = no local realtime diffusion** (TensorRT-only); diffusion always runs in cloud. Covers Route A (Daydream backend, default) vs Route B (Scope + Syphon), model-gated ControlNet rules (SD-Turbo gets OpenPose; SDXL-Turbo gets IP-Adapter but no pose), server-side preprocessing (raw camera → IN1, server handles depth/canny/HED/OpenPose), latency-hiding tactics (feedback TOPs both sides + local preview overlay), MediaPipe → conditioning chain, audio → parameter modulation, Mac setup + landmines, 10-item TEST-before-relying checklist | `references/components/streamdiffusion-td-mac.md` |
| **Projection mapping in TD (KantanMapper / CamSchnappr / Stoner / multi-projector / edge blending)** | When user mentions projection mapping / projector calibration / installation mapping / KantanMapper / CamSchnappr / Stoner / projectorBlend / quadReproject / edge blending / multi-projector / structured light / `cv2.calibrateCamera` for projection / Resolume-MadMapper-Millumin handoff / multi-machine sync (Sync CHOP / Hardware Frame-Lock / Quadro Sync) / multi-output hardware (Datapath FX4 / Matrox TH2Go / NVIDIA Mosaic). **Decision rule built-in**: flat keystone → Stoner; 2D polygon/bezier → KantanMapper; 3D model surface → CamSchnappr (≥6 points → `cv2.calibrateCamera`). Covers calibration theory (intrinsics/extrinsics, PnP), TD coordinate conventions (right-handed Y-up, camera -Z, Vulkan NDC Z 0..1, UV bottom-left vs OpenCV top-left), Spout/Syphon/NDI handoff with limits, hardware splitters, named community .tox repos | `references/projection-mapping.md` |
| **Project bootstrap (central ↔ project setup)** | When scaffolding a new TD project, when an Embody-generated file conflicts with the central canonical version, or when a colleague needs to install the skill on a new machine. **Use `scripts/td-new`** — don't hand-stitch the per-project layout | `references/project-bootstrap.md` |
| **Skill growth protocol** | When you've just solved something non-obvious in production — before you move on, check this for the pre-ask gates (observed-failure-and-fix, one-sentence-rule, user-novelty). **All three YES → in-flow ask; any NO → silent drop.** This is where the skill's biography grows | `references/skill-growth-protocol.md` |
| **Text TOP rendering / fonts** | Before configuring fonts / sizes / weights / styling on a Text TOP — OR when text renders pixelated, wrong-size, or oddly-spaced on Mac. **`keepfontratio=True` silently ignores `fontsizey`** (fontsizex is master); **Automatic Display Method has documented Mac GPU bugs at >10pt — use `dispmethod='scalable'`**; **`strokewidth` only affects `dispmethod='stroke'`** (no-op in Polygon/Bitmap/Scalable). Plus Spec DAT pattern for per-row styling | `references/text-top.md` |
| **Hand-driven camera controls (pattern)** | Before building a MediaPipe / hand-tracking → camera-parameter binding (Y, pitch, zoom, dolly, FOV). **Five-stage CHOP chain (pick → math → presence-gate → lag → null-export)**, **two-camera split** (CameraExt-extended for mouse-navigation fallback + bare cameraCOMP as the actually-rendered one), **mirror-binding rule** before any `renderTOP.par.camera` swap. Also covers calibration drift from MediaPipe detection-order vs handedness | `references/patterns/hand-driven-camera-controls.md` |

## Named Decision Rules — flat index

Quick index of the named decision rules across the skill — for when you need to pick X vs Y but don't remember which file holds the rule. The Reference Lookup table above answers "I'm working on X, what file do I read?"; this index answers "I need to pick X vs Y, where's the rule?" Entries point at existing rules; no new content is asserted here.

### Build-time & MCP workflow

- **`read_tdn` vs `get_op` walks** — Use `read_tdn` for reading ≥3 operators (authored state); `get_op` / `get_parameter` for evaluated runtime values, cook errors, output data. See `skills/mcp-tools-reference/SKILL.md` § "TDN Network Format".
- **`execute_python` vs many MCP calls vs `batch_operations`** — One `execute_python` when the build needs loops/conditionals/computed positions; many MCP calls for per-step error visibility; `batch_operations` for 3+ same-tool runs. See `skills/mcp-tools-reference/SKILL.md` § "Choosing `execute_python` vs many MCP calls (or `batch_operations`)".
- **Scope MCP queries (path / family / depth) vs flat root query** — Scope to a subnet, family-filter, or depth-bound before issuing; flat `query_network('/project1')` burns 40–80% of context. See `references/approach-patterns.md` § "Scope MCP queries to prevent context-window bloat".
- **OP Snippets / Palette vs build from scratch** — Check the in-app discovery surfaces for a working starting point before generating from-scratch implementations of recognizable TD patterns. See `references/approach-patterns.md` § "Check OP Snippets and Palette before building from scratch".
- **Fallback — two strikes, then switch** — After two observed failures on the same sub-step, stop, propose ONE simpler alternative, report the abandoned path. See `references/approach-patterns.md` § "Fallback — two strikes, then switch".
- **Start weak vs target quality** — On constrained platforms (M1 / mobile / browser), start at the cheapest config that proves the technique end-to-end; raise quality one axis at a time. See `references/approach-patterns.md` § "Start weak — prove the technique before tuning quality".

### Operator referencing

- **Relative paths vs `parent.CompName` vs `op.CompName`** — Relative for siblings/nearby; `parent.CompName` for code inside a component reaching its owner; `op.CompName` for project-wide singleton access. Never absolute. See `rules/td-python.md` § "Choosing the right reference".
- **`op()` vs `opex()`** — `opex()` raises clearly when the operator must exist; `op()` returns `None` silently and is only correct when `None` is an acceptable result. See `skills/td-api-reference/SKILL.md` § "`op()` vs `opex()`".
- **`debug()` vs `print()`** — `debug()` carries source DAT name and line number; use it over `print()` in TD Python. See `skills/td-api-reference/SKILL.md` § "`debug()` vs `print()`".

### Python architecture (event / signal / expression)

- **`parameterexecuteDAT` vs CHOP chain vs expression** — Callback DAT for one-shot side-effects on change; CHOP chain when downstream needs the value as a live signal; expression for pure value derivations with no side-effect. See `references/python-architecture.md` § "When a callback DAT replaces a node chain".
- **Evaluate DAT vs Select/Convert/Reorder chain vs scriptDAT** — Evaluate DAT for same-shape per-cell math referencing neighbors; stock chain for structural reshape; scriptDAT for whole-table compute. See `references/python-architecture.md` § "Evaluate DAT for table transforms".
- **`replicatorCOMP` vs Python `create_op` loop vs Geometry COMP instancing** — Replicator when the set is data-driven and changes at runtime; one-shot Python loop when the set is static; instancing when "replicas" are visual copies of geometry. See `references/python-architecture.md` § "Replicator COMP for runtime-templated networks".
- **scriptOP vs stock-op chain vs glslPOP/glslTOP** — scriptOP for CPU-shaped irregular logic on moderate data; stock chain for clean compositions; GLSL for uniform per-element work across many elements. See `references/python-architecture.md` § "When a scriptOP replaces a chain".
- **`tdu.Dependency` vs polling executeDAT vs `op.storage`** — Dependency for reactive state read by expressions; CHOP when it IS a signal; `op.storage` when the value must survive save/load. See `references/python-architecture.md` § "Reactive state without per-frame polling".

### Cook control & performance

- **`passive()` vs cooking expression** — Wrap reads of Info attributes in `passive(op)` to avoid making the caller depend on the source op's cook. See `skills/td-api-reference/SKILL.md` § "Reading without cooking".
- **`op.cook(force=True)` vs fixing dirty propagation** — Force-cook is the override for stale dirty propagation; the default first move is fixing the missing dirty propagation upstream. See `skills/td-api-reference/SKILL.md` § "Forcing a cook".
- **`comp.allowCooking = False` vs `bypass`** — `allowCooking = False` for whole subnetworks that should idle (cheaper — nothing inside cooks); `bypass` for single ops in a chain that still need to pass input through. See `references/td-gotchas.md` § "`comp.allowCooking = False` — gate an entire subnetwork that's irrelevant this frame".
- **`subprocess` vs blocking Python** — Spawn a subprocess (read results via OSC / DAT / file) for HTTP / disk-heavy / inference work; blocking the main thread freezes the cook. See `references/td-architecture.md` § "Offload blocking Python with subprocess".
- **Diagnostic-driven perf vs fixed-order optimization** — Performance Monitor + 64×64 GPU-bottleneck test before optimizing; don't apply a generic resolution → transparency → particles order without measurement. See `references/td-architecture.md` § "Performance optimization — diagnostic-driven, not a fixed order".
- **Palette widget vs primitive** — Build from primitives (Text COMP, Constant CHOP, Switch CHOP) when the widget's extra features aren't needed — 33 internal operators vs 1 for the same button. See `references/td-architecture.md` § "Minimalism — prefer fewer operators over more".
- **`capture_top` vs `errors=0`** — `errors=0` is necessary but not sufficient; capture the affected TOP after any render-path change. See `references/td-architecture.md` § "Visual verification — `capture_top` is ground truth".
- **`run(callable, ...)` vs `run("string", ...)`** — Prefer the callable form: avoids string parsing, surfaces NameError/AttributeError at call time, keeps stack traces readable. See `skills/td-api-reference/SKILL.md` § "`run()` — Delayed Code Execution".

### State & storage

- **`TDStoreTools.StorageManager` vs raw `store`/`fetch`** — StorageManager for typed-defaults + dependency-aware extension state with several values; raw store/fetch for opaque or one-shot values where reactivity isn't needed. See `skills/td-api-reference/SKILL.md` § "Typed extension state — `TDStoreTools.StorageManager`".
- **`'key' in op.storage` vs `fetch` with default** — Membership test when you need to distinguish "absent" from "stored falsy"; `fetch('k', default)` collapses both into the default. See `skills/td-api-reference/SKILL.md` § "Operator Storage".
- **`tdu.Dependency.val =` vs direct assignment** — Assign through `.val` to trigger recooks; `dep = 5` destroys the Dependency object. See `skills/td-api-reference/SKILL.md` § "`tdu.Dependency` for Reactive Values".
- **`.eval()` vs `.val`** — Always `.eval()` for runtime values; `.val` only reads the constant-mode value, and setting `.val` silently switches mode to CONSTANT. See `skills/td-api-reference/SKILL.md` § "Parameter Access Patterns".
- **`tdu` math classes vs NumPy vs hand-rolled** — `tdu.Vector/Matrix/Quaternion/...` for per-object work matching TD's conventions; NumPy when batch-shaped across many; raw floats only for trivial one-shot. See `skills/td-api-reference/SKILL.md` § "`tdu` math classes — prefer over hand-rolled".

### Render & camera

- **Two-camera split (CameraExt fallback + bare hand-driven camera)** — Hand-tracking drives a bare cameraCOMP (no CameraExt) that the render points at; the CameraExt-extended camera stays as mouse-navigation fallback. See `references/patterns/hand-driven-camera-controls.md` § "The two camera-pose split (critical pattern)".
- **Mirror bindings before swapping `renderTOP.par.camera`** — Inventory expressions/exports targeting the old camera and mirror them on the new one before the swap, or accept silent feature regression. See `references/td-gotchas.md` § "Swapping a renderTOP's camera silently breaks bindings on the old camera".
- **Depth Peel ON vs OFF** — Enable for ≥2 overlapping transparent surfaces; leave off when there's only one transparent layer (depth peel adds render passes). See `references/td-gotchas.md` § "Depth Peel needed for nested/overlapping transparent surfaces".
- **`layerMixTOP` vs Composite/Over chains** — In TD 2025+, prefer one `layerMixTOP` over multi-`overTOP` / `compositeTOP` chains for 3+ layers. See `references/td-2025-operators.md` § "Layer Mix TOP — replaces long Composite/Over chains".

### POPs & scatter

- **POPs vs SOPs (TD 2025+)** — Default to POPs for new point/particle/point-cloud/scatter work in TD 2025+; SOPs remain correct for modeling, boolean, volume operations. See `references/pops.md` § "What POPs replace vs don't replace".
- **Sprinkle-on-surface vs grid+jitter** — `sprinklePOP` on a filled mesh surface for organic scatter; `gridPOP` + jitter produces visible artefacts (lines or cell-boundary clumps). See `references/pops.md` § "`sprinklePOP method='perprim'` distributes points PER TRIANGLE, not per area".
- **Copy POP vs legacy Geometry COMP instancing for POP-native scatter** — Copy POP / GLSL Copy POP is the documented POP-native scatter path; legacy Instance-page pipelines need a POP→CHOP/TOP/SOP bridge. See `references/pops.md` § "What POPs replace vs don't replace".

### Audio

- **Lag CHOP asymmetric attack/release** — Attack 5–30 ms (sub-bass up to 50); release 150–500 ms — fast attack so beats land sharp, slow release so visuals decay musically. See `references/audio-reactive.md` § "Smoothing — asymmetric attack/release (the \"liquid\" feel)".
- **Band averages vs direct bins** — Band averages (3–16 stable bands) for music-following response; direct bins only when bin-level jitter IS the visual. See `references/audio-reactive.md` § "Band patterns — bins vs band-averages".
- **Ableton Link CHOP vs heuristic beat detection** — Link when a Link-aware DAW is the source; heuristic (Spectrum → low band → Lag → Threshold → Logic Off Delay) only when no Link source exists. See `references/audio-reactive.md` § "Beat detection — Audio Beat CHOP does NOT exist; build it".
- **BlackHole + Multi-Output Device vs other Mac audio routes** — Default for system-audio (Spotify / Ableton / Logic) into TD on Mac; Loopback and Soundflower are paid / older alternatives. See `references/audio-reactive.md` § "Mac routing — BlackHole (CRITICAL)".

### Mac-specific

- **Mac sudden-FPS-drop diagnosis order** — `get_td_info` build → check release notes for known MoltenVK regressions → only then profile operators or decimate assets. See `references/mac-gotchas.md` § "MoltenVK regressions can halve FPS — check build version first".
- **`dispmethod='scalable'` vs Automatic / Polygon on Mac** — Set Scalable explicitly on every Text TOP on macOS, especially >10pt; Automatic silently selects Polygon which has documented Mac GPU rendering bugs. See `references/text-top.md` § "Display Method = Scalable on macOS (avoid Automatic → Polygon)".
- **`keepfontratio=False` when `fontsizey` must matter** — With `keepfontratio=True`, `fontsizex` drives both dimensions and `fontsizey` is silently ignored. See `references/text-top.md` § "`keepfontratio` silently ignores `fontsizey`".
- **16-sampler reduction techniques (texture array / buffer / atlas / prune)** — Pick by data shape: `sampler2DArray` for similar 2D textures; `samplerBuffer` for large flat value arrays; atlas for many small textures; or just delete unused fetches. See `references/mac-gotchas.md` § "16-sampler GLSL cap (MoltenVK)".

### Components & 3rd-party

- **Route A (Daydream backend) vs Route B (Scope + Syphon) for StreamDiffusion on Mac** — Default to Route A for anything involving OpenPose/ControlNet body tracking; Route B only for Wan2.1 video continuity or LoRA-driven looks with the bridge accepted. See `references/components/streamdiffusion-td-mac.md` § "1. The decision: Route A vs Route B (head-to-head)".
- **SD-Turbo vs SDXL-Turbo vs SD1.5 for ControlNet** — SD-Turbo or SD1.5 for literal skeletal OpenPose; SDXL-Turbo when IP-Adapter FaceID matters (drive body via Depth or Canny, not pose). See `references/components/streamdiffusion-td-mac.md` § "3. ControlNet availability is MODEL-GATED (the rule that bites)".
- **KantanMapper vs CamSchnappr vs Stoner — projector decision tree** — Flat keystone → Stoner; 2D polygon/bezier on flat → KantanMapper; 3D model surface with ≥6 correspondences → CamSchnappr. See `references/projection-mapping.md` § "3.2 2D-content-on-flat (KantanMapper) vs 3D-object (CamSchnappr) — decision rule".
- **TD-stays vs hand off to Resolume / MadMapper / Millumin** — Stay in TD for generative / interactive / 3D-model-based / sensor-integrated work; hand off to the external mapper for artist-friendly surface mapping, VJ clip playback, or timeline-driven installation playback. See `references/projection-mapping.md` § "5.2 When to hand off to Resolume / MadMapper / Millumin".
- **Gaussian splat component choice on Mac** — Picks differ by context (legacy investment, fresh start, paid production, alignment with Derivative roadmap). See `references/components/gaussian-splatting-mac.md` § "Decision rule".
- **MediaPipe `mediapipe-touchdesigner` vs `LucieMrc/MediaPipe_TD` on M1** — Use Torin's GPU-accelerated plugin (no install, Mac+PC); avoid the Python-based fork on M1 (needs Rosetta2 + x86 Python 3.7, fragile). See `references/components/streamdiffusion-td-mac.md` § "8. The tracking plugin: MediaPipe for TouchDesigner [OK]".

## Operational rules (locked)

Full text in `rules/`. One-line summaries:

1. **TDN-first** — `.tdn` JSON on disk is faster than MCP round-trips for reading ≥3 operators. Edit `.tdn` then `import_network` with `clear_first=True`.
2. **Never assume network paths** — `query_network` on `/` to discover the actual root.
3. **Forward slashes always** for cross-platform compatibility.
4. **Verify before claiming** — TD wiki (`docs.derivative.ca`) is authoritative.
5. **Binary files** (`.toe`/`.tox`) — inspect via MCP, never via filesystem.
6. **Check errors after creating** — `get_op_errors` with `recurse=true` immediately.
7. **Favor annotations over OP comments**.
8. **Read logs after MCP operations** — ring buffer holds 200; Embody Logfolder has the full picture.
9. **Never edit `externalizations.tsv` manually** — Embody owns it.
10. **Never auto-modify heavy assets** for perf — report, recommend, wait.
11. **Don't touch dialed-in knobs** when adding a new feature — modify only what the new feature requires.

## Approach guidelines

- Hypothesis → evidence → fix. State the hypothesis before acting.
- Define success criteria up front; loop until verified.
- Fail loud: "done" is wrong if anything was silently skipped.
- Surface conflicts; don't silently average between two patterns.
- Two failed attempts on a sub-step → switch to simpler fallback, report which path. Full pattern: `references/approach-patterns.md` § Fallback.
- Start weak on constrained platforms (M1, browser, mobile). Prove the technique, raise quality after. Full pattern: `references/approach-patterns.md` § Start weak.
- **Mid-task: if you just solved something non-obvious in production** — before moving on, check `references/skill-growth-protocol.md` § Pre-ask filters to decide whether it's worth capturing. The protocol grows the skill through your real work, not through batch reviews.

## Starting a new TD project

```bash
cd ~/Projects/
~/.claude/skills/touch-designer-skill/scripts/td-new my-project-name
```

Then in TouchDesigner: save the `.toe`, drag in `Embody.tox`, set `Aiclient = 'claude'`. Embody generates the rest (`.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`, `.claude/rules/`). Full flow: `references/project-bootstrap.md`.

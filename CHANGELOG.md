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

### 💡 2026-06-07 — [project: skill-meta — second projection-mapping dossier enrichment]

- **Projection-mapping reference enriched with complementary content from second dossier**: Surgical additions to `references/projection-mapping.md` of items NOT covered by the first dossier import. External-only source (second user-provided projection-mapping dossier 2026-06-07), MEDIUM confidence + re-check per protocol v0.3. Specifically:
  - **§ 1.2 CamSchnappr** — multi-projector blending of a *single* 3D model (Dec 2025 docs upgrade): combine blend-masks from multiple CamSchnappr instances against one model.
  - **§ 1.4 Native edge blending** — VIOSO operational notes (10–25% projector overlap target, Logitech HD Pro camera recommendation, 30-day trial w/ watermark, Display Split support for NVIDIA Surround/Mosaic + AMD Eyefinity + Matrox + Datapath). **Operational numbers attributed inline to dossier+date — operating specifics drift; never quoted timeless.** Plus precedence note: prefer `quadReproject` over `sweetSpot` for LED/XR.
  - **§ 3.1 Workflow patterns** — speculative cross-link to depth-camera / monocular-depth assist for unmodeled surfaces. **Explicitly flagged [SPECULATIVE — not yet observed end-to-end]**; cross-references the [TEST]-flagged CoreML-TDSyphon Bridge in `streamdiffusion-td-mac.md`. Research thread to watch, not a workflow to recommend.
  - **§ 4 Community repos** — Warpa direct GitHub URL (Richard-Burns/Warpa standalone), Dylan Roscover's pixel-map component for LED volumes (a category otherwise uncovered), TD-WebRTC-LAN (jshea2) for low-latency multi-machine LAN streaming, **+ Patreon-resold-patches caveat** (prefer original-author GitHub/Derivative-community over Patreon mirrors; check last-commit dates).
  - **§ 5.2 Resolume/MadMapper/Millumin** — Resolume DXV-codec-required + yearly-upgrade-cost gotcha (**operational specifics attributed to dossier+date**). Plus open-source mappers reference (MapMap / VPT / Splash) for low-budget / experimental contexts.
  - **NEW § 6 Field discipline (on-gig notes)** — test patterns as ground truth (grid + frame counter + directional sweeps + high-bit noise, branded with studio logo), Spout/Syphon canvas-parallelism for team-mapping (split master canvas via sub-zones to avoid project-file collisions), calibration-data-is-versioned-content reframing.
- Skipped: github.com/topics meta-pointer (#7 in triage — belongs as README link, not reference content).
- Value for user: Fills three real gaps (LED-volume mapping coverage via Dylan Roscover, multi-machine LAN-streaming via TD-WebRTC, on-gig field-discipline section), adds vendor-source-attributed operational specifics for VIOSO and Resolume, catches the Dec 2025 CamSchnappr multi-projector upgrade, and adds the community-vetting Patreon caveat that prevents recommending resold patches.
- File: `references/projection-mapping.md` (enriched in §§ 1.2, 1.4, 3.1, 4, 5.2 + new § 6)
- Type: [docs]

### 💡 2026-06-07 — [project: skill-meta — user-provided projection-mapping dossier import]

- **Projection mapping in TouchDesigner — deep technical reference imported**: New comprehensive reference covering built-in palette tools (KantanMapper / CamSchnappr / Stoner / projectorBlend / quadReproject / sweetSpot / kinectCalibration), calibration theory (intrinsics/extrinsics, PnP vs `calibrateCamera`, why ≥6 points, RMS reprojection error), TD-specific coordinate conventions (right-handed Y-up, camera faces −Z, NDC X/Y −1..1 + Z 0..1 per Vulkan, UV bottom-left vs OpenCV top-left — the porting gotcha), workflow patterns (single-surface vs multi-surface vs full-3D decision tree), multi-machine sync layers (Sync CHOP + Hardware Frame-Lock + Quadro Sync), Spout/Syphon/NDI handoff with limits (Syphon 8-bit only, Spout 10-sender default cap), multi-output hardware (Datapath FX4 8K×8K, Matrox TH2Go, NVIDIA Mosaic), and a curated list of named community .tox repos. External-source-only (user-provided dossier referencing docs.derivative.ca + OpenCV calib3d + nVoid + IIHQ + Paul Bourke + named TD creators), MEDIUM confidence + re-check per protocol v0.3. Document's own inline `(Confidence: …)` tags mapped to v0.3 tiers in file header.
- Value for user: Gives the agent a complete projection-mapping decision tree (flat keystone → Stoner; 2D polygon → KantanMapper; 3D model → CamSchnappr) without needing to re-research per project. Includes the calibration math (why ≥6 points, what `cv2.calibrateCamera` actually solves), the coordinate-system gotchas (UV bottom-left flip when porting OpenCV imagePoints), and the multi-machine + multi-output hardware patterns needed for any installation deployment.
- File: `references/projection-mapping.md` (new) + SKILL.md Reference Lookup row
- Type: [docs]

### 💡 2026-06-07 — [project: skill-meta — user-provided StreamDiffusion dossier import]

- **StreamDiffusion + TouchDesigner on Mac M1 — master reference imported**: New comprehensive reference covering Route A (StreamDiffusionTD operator + Daydream cloud backend) vs Route B (Daydream Scope + Remote Inference + Syphon) decision matrix, the model-gated ControlNet table (SD-Turbo gets OpenPose but no IP-Adapter; SDXL-Turbo gets IP-Adapter+FaceID but no pose; SD1.5 gets both; Wan2.1 uses VACE not SD-CN), Mac-specific local-NVIDIA blockers (TensorRT/CUDA), server-side preprocessing rules (Daydream mode = raw camera to IN1 only, server runs depth/canny/HED/OpenPose), low-latency architecture and feedback patterns, MediaPipe → parameter modulation chain, audio-reactive parameter binding, parameter surface, Mac setup + known errors, and a 10-item TEST-before-relying checklist. External-source-only (user-provided dossier referencing dotsimulate.com/docs/streamdiffusiontd + docs.daydream.live as primary sources), MEDIUM confidence + re-check per protocol v0.3. Document's own `[OK]/[LIKELY]/[INFER]/[TEST]` tags mapped to v0.3 tiers in file header.
- Value for user: Eliminates the need to re-research StreamDiffusion architecture every time it comes up — gives the agent a complete map of the route decision (Daydream operator is default; Scope is secondary for Wan2.1), the model→ControlNet matrix (the most common planning mistake the document calls out), and the Mac-specific gotchas (TensorRT not available; CoreML bridge to TEST; numpy crash fix) in one place. Plus an explicit re-check checklist for the most volatile items.
- File: `references/components/streamdiffusion-td-mac.md` (new) + `SKILL.md` Reference Lookup row
- Type: [docs]

### 💡 2026-06-07 — [project: skill-meta — wiki audit]

- **Check OP Snippets and Palette before building TD patterns from scratch**: TD ships two discovery surfaces — OP Snippets (operator-level examples, `Help menu → Operator Snippets`) and Palette Browser (reusable COMPs, `Dialogs → Palette Browser`). Both should be checked before generating from-scratch implementations of recognizable patterns. The agent should explicitly say "I'll check OP Snippets / Palette first" before proceeding to build. External-only source (Derivative wiki), MEDIUM confidence + re-check per protocol v0.3.
- Value for user: Prevents the agent from confidently building from scratch when a working starting point already ships with TD — saves time, produces more idiomatic results, and aligns with what an experienced TD user would do reflexively.
- File: `references/approach-patterns.md` § Check OP Snippets and Palette before building from scratch
- Type: [discovery]

### 🌱 2026-06-07 — [project: skill-meta — repo structure]

- **Add ROADMAP.md for forward-looking deferred work**: New top-level file tracking items deferred from preemptive import per the v0.3 protocol's "external source = MEDIUM" philosophy. Each entry has an explicit trigger condition (what real-world event should bring it back into scope). First item: Perform Mode / kiosk deployment gotchas, deferred until RADON_TREE (or another project) ships — so we can capture HIGH-confidence empirical gotchas instead of MEDIUM wiki distillation.
- Value for user: Makes deferred-but-not-forgotten work visible. Future maintainers (or future-self) can see WHY something wasn't imported AND what trigger should bring it back into scope, without losing the consideration to memory.
- File: `ROADMAP.md` (new)
- Type: [convention]

### 💡 2026-06-07 — [project: RADON_TREE + research-dossier dual-source]

- **Scope MCP queries by path prefix / family / depth to prevent 40–80% context-window bloat**: Flat queries on `/project1` root return verbose JSON that consumes huge fractions of context. Default scoping: narrow path first, then `type=` filter, then `depth=` bound. For ≥3 operator reads, `read_tdn` (with default-omission) is 20–90× cheaper than per-tool walks. Dual-sourced: own observation (MCP timeouts after stacked verbose probes in RADON grid-debugging, restart_td required to recover) + external MCP-agent research (40–80% bloat metric).
- Value for user: Keeps agent context budget available for actual work; prevents the "I lost track of what we were doing because tool responses ate the window" failure mode AND the secondary failure mode of MCP-side state breaking when probes are stacked verbosely.
- File: `references/approach-patterns.md` § Scope MCP queries to prevent context-window bloat
- Type: [discovery]

### 💡 2026-06-07 — [project: skill-meta — research-dossier audit]

- **4D / animated Gaussian splats are not supported in TouchDesigner — workaround is image-sequence point clouds**: Bake per-frame point positions to a 2D texture sequence, sample as Movie File In TOP, reconstruct on GPU. Don't propose "use a 4D splat renderer in TD" — there is none. External-only source (Derivative forum), MEDIUM confidence + re-check obligation per protocol v0.3.
- Value for user: Prevents agent from confidently suggesting a non-existent feature when user asks for animated splats — and gives a concrete workaround if the use case is pre-computed.
- File: `references/components/gaussian-splatting-mac.md` § 4D / animated Gaussian splats — not supported in TD
- Type: [docs]

### 🔧 2026-06-07 — [project: skill-meta — protocol v0.3]

- **Skill-growth-protocol gains Source confidence tiers (own empiry vs external research vs dual-sourced)**: Gate 1 now distinguishes three evidence types. Own empiry → HIGH no re-check. External (forum/research/vendor) → MEDIUM max + obligatory `verify before relying — source dated YYYY-MM-DD` line. Dual-sourced (own + external corroboration) → HIGH with both citations. Reason: previous protocol left implicit how external research should be represented; entries from external sources started appearing without re-check obligations, making it impossible for readers to tell "we know" from "someone reported".
- Value for user: Reader can immediately see whether a rule is safe to act on (HIGH/own) or needs verification first (MEDIUM/external) — distinguishes "we tested this and it worked" from "the internet says this works". Prevents stale external claims from being treated as gospel.
- File: `references/skill-growth-protocol.md` § Source confidence — own empiry vs external research (new section between Pre-ask filters and In-flow ask) + protocol-internal changelog bump to v0.3
- Type: [convention]

### 💡 2026-06-07 — [project: RADON_TREE]

- **Inspect external geometry-source attributes before merging into an existing chain**: When merging a freshly loaded POP source (PLY, SOP-bridge, external bake) into an existing chain, attribute names + component counts + value scales must match the downstream consumer's expectations. Mismatches merge silently — no error, wrong output downstream. Recipe: probe `pointAttributes` + sample 1–5 values BEFORE wiring.
- Value for user: Avoids "I merged the new source and now the colors are wrong / points are invisible / one branch dominates" debug sessions — gives a pre-merge inspection checklist and concrete mismatch examples (Color vs Cd, 0–1 float vs 0–255 byte, vec3 vs vec4, missing PointScale).
- File: `references/pops.md` § POP rendering — gotchas captured from real builds
- Type: [discovery]

### 💡 2026-06-07 — [project: RADON_TREE]

- **Single MAT downstream of a merge applies to all inputs — branch styling per-point upstream**: For per-branch alpha/color/blending in a merged POP chain, set per-point Color BEFORE the merge — the MAT honors per-point values when configured for it (`constantMAT.applypointcolor=True`). Adjusting MAT-level alpha dims ALL merged inputs uniformly.
- Value for user: Resolves "I changed alpha on one branch and BOTH dimmed" confusion with a clean architecture pattern that doesn't require duplicating MATs.
- File: `references/pops.md` § POP rendering — gotchas captured from real builds
- Type: [discovery]

### 💡 2026-06-07 — [project: RADON_TREE]

- **noisePOP combineop='none' creates the output attribute; default 'add' silently fails if attr doesn't exist upstream**: Common trap when generating per-point random vectors — the default `combineop='add'` produces empty/zero output instead of a visible error. The fix is `combineop='none'` to create a fresh attribute.
- Value for user: Saves debug-hours on "my noise op isn't outputting anything" — names the silent-failure mode and gives the correct config.
- File: `references/pops.md` § POP rendering — gotchas captured from real builds
- Type: [docs]

### 💡 2026-06-07 — [project: RADON_TREE]

- **mathcombinePOP binary ops are component-wise on multi-component attributes**: `min/max/add/mult` between two float3 attributes operates per-component — no separate combs needed. Empirically confirmed via stress test in source incident (max-amplitude inputs → ceiling held on Y, X and Z untouched via 1e6 sentinels).
- Value for user: Removes guesswork when designing per-component clamps or ops on vector attributes — and shows the stress-test pattern to verify component-wise behavior on other ops before depending on it.
- File: `references/pops.md` § POP rendering — gotchas captured from real builds
- Type: [discovery]

### 💡 2026-06-07 — [project: RADON_TREE]

- **Topology change + large cook hangs TD — use bypass-during-refactor**: Creating, deleting, or rewiring ops downstream of high-density POP chains hangs TD silently (UI frozen, MCP timeouts on trivial probes, no crash, unsaved work lost). Defensive pattern: bypass new op first → configure → wire → unbypass last. Density-reduction is the fallback when bypass isn't applicable.
- Value for user: Eliminates a class of "TD froze and I lost work" incidents — gives a concrete recipe for safe refactoring of large pipelines.
- File: `references/td-gotchas.md` § TD stability gotchas captured from real work
- Type: [discovery]

### 💡 2026-06-07 — [project: RADON_TREE]

- **Shared POP-chain with mode-switch — branch ALL noise sources, not just the obvious one**: When a chain serves multiple visual modes (particles/grid) via switchPOP, all per-point noise/jitter ops downstream must be mode-branched, not just the obviously-named one. Symptom of partial branching: motion stops but output is still statically broken — diagnostic fingerprint of a second source (typically per-point random with `t4d=0`) still active. Long-wavelength noise (period >> cell size) is safe both modes; empirically verified in source incident at period=0.05m (broke 0.04m cells) vs period=8m (preserved 50×50 grid).
- Value for user: Saves hours when "I branched the noise but my grid is still torn apart" — gives a direct diagnostic ("motion stopped but still broken = static source still active") and a complete fix recipe with empirically-verified safe vs unsafe noise periods.
- File: `references/pops.md` § POP rendering — gotchas captured from real builds
- Type: [discovery]

### 💡 2026-06-02 — [project: skill-meta — Perplexity-report audit + primary-source anchoring]

User shared a Perplexity-generated TouchDesigner architecture report and asked which findings the skill should adopt. Audit produced two adds (depth peel, performance optimization) and one defer (two-layer sim/visual architecture — no Derivative primary source found). The exercise surfaced a **methodological learning worth keeping**: AI-synthesis reports can be confidently wrong on specifics, even when the surrounding framing is correct.

- **Depth Peel for nested transparency** — Render TOP exposes `Transparency` (with "Order Independent Transparency" mode), `Depth Peel`, and `Transparency/Peel Layers` (`transpeellayers`) for rendering multiple overlapping transparent surfaces. Without it, nested-transparent scenes (glass-cube-with-water, layered glass, transparent particles over transparent geometry) sort wrong and show artifacts. Source: `docs.derivative.ca/Render_TOP`, with exact wiki quotes preserved. → `references/td-gotchas.md` § "Rendering gotchas / Depth Peel needed for nested/overlapping transparent surfaces"
- **Performance optimization is diagnostic-driven, NOT a fixed order** — the Perplexity report claimed an order ("resolution → transparency → particles → cook → CPU/Python"). Verification against three primary Derivative sources (`docs.derivative.ca/Optimize`, `learn.derivative.ca` optimization curriculum, `derivative.ca` community post "TouchDesigner Optimization Strategies") showed Derivative documents **no such fixed order** — they document a measurement-first workflow: Performance Monitor reveals bottleneck → 64×64 render test isolates GPU-vs-CPU → targeted fix. Adopted the actual Derivative workflow, explicitly flagged the framing correction in the file so future agents see the trap. → `references/td-architecture.md` § "Performance optimization — diagnostic-driven, not a fixed order"
- **Deferred: two-layer sim/visual architecture** — Perplexity described separation of simulation layer (POPs/TOPs) from visual layer (Geometry COMP / GLSL) as a designprinciple. The pattern is real and emergent in community practice, but no Derivative-published page names it as a documented architecture pattern. Per the user's "primary source or wait" rule, deferred until either (a) a Derivative palette example / curriculum page surfaces that explicitly documents the pattern, or (b) we build a project where the separation becomes empirically concrete.

**Process learning — primary-source verification beats AI-synthesis trust.** The Perplexity report was ~85% aligned with TD documentation and felt confidently authoritative, but the optimization-order claim was a confabulated structure not present in any Derivative source. Capturing it as-is would have polluted the skill with a plausible-sounding but wrong rule, and future agents would have followed it without verification. **Rule going forward:** when a research synthesis (AI search, third-party article, blog) proposes "principles" that look like they should be in primary docs, verify against the primary source before adopting. If the principle survives verification → adopt with primary source. If the synthesis can't be traced to primary → either wait for empirical confirmation OR mark explicitly as community-practice with a community source (e.g. II HQ tutorial, Derivative forum thread). Never adopt synthesis-as-principle.

### 💡 2026-06-02 — [project: RADON_TREE — Squirrel + Roots procedural particle additions]

Ten generalizable discoveries from a session that added a procedural squirrel and L-system root system to a Gaussian-splat tree scene. All saved in-flow per skill-growth-protocol after the user pointed out batched capture had been happening (post-session ask, not in-flow). Added HARD TRIGGER section to `SKILL.md` and `skill-growth-protocol.md` + auto-memory feedback entry to prevent recurrence.

- **POPs render invisibly without `PointScale` attribute** — TD's default render path renders points at ~1 px when no per-point pointscale is set, regardless of constantMAT settings. Adding an `attributePOP` with `attr0name='pointscale', attr0value0=0.06` makes them visible. → `references/pops.md`
- **`sprinklePOP method='perprim'` distributes points PER TRIANGLE, not per area** — verified via direct Y-histogram probe (expected top-heavy distribution from area-based assumption was wrong; actual was tip-heavy from triangle-count). Fix density gradient via depth-aware `TUBE_SIDES` in mesh generation. → `references/pops.md`
- **`soptoPOP` has 0 input connectors — uses `par.sop` reference, not wire** — `connect_ops()` to this op fails. Set the source SOP via the `sop` parameter (sibling name string or direct OP assignment). Family-bridge convention. → `references/pops.md`
- **`attributePOP.par.attr` is a Sequence — set via `.sequence.numBlocks`, NOT `set_parameter`** — MCP `set_parameter value="1"` silently fails on Sequence-style params. Use `execute_python` with `.sequence.numBlocks = N` API. Same applies to other sequence params on POPs (matattr, ren, etc.). → `references/pops.md`
- **`fileinSOP` does NOT read `.glb` (glTF binary)** — supports `.obj`, `.bgeo`, `.geo` only. Convert offline with a stdlib Python script (12-byte header + JSON chunk + BIN chunk → `v x y z` + `f i j k`). → `references/td-gotchas.md`
- **`fbxCOMP` imports `.glb` but `importselectPOP` data is unreliable** — observed 4 438 points vs 148 185 in source `.glb`, and bbox shape completely wrong (flat instead of cubic). Use external `.obj` conversion instead. → `references/td-gotchas.md`
- **`glslPOP.destroy()` does NOT fully release GPU state — `restart_td` if other shaders misbehave** — major gotcha. Python-side audit shows clean state (no leftover ops) but GPU shader/SSBO caches may persist and corrupt unrelated GLSL shaders elsewhere in project (rendered as camera/clipping artifacts on entirely separate `glslMAT`). Symptom-pattern: audit clean → bypass eliminates COMP-level cause → conclude stale GPU state → `restart_td`. → `references/glsl-patterns.md`
- **`glslPOP.numthreadsmode='auto'` is unreliable — set explicitly** — observed dispatching only 1 thread for a 22000-point input. Use `'numelems'` with manual count or `'otherinputelements'` with explicit `numelemspop` reference. → `references/glsl-patterns.md`
- **Visibility-fade by camera distance — use material alpha + blending, NOT `PointScale=0`** — TD clamps rendered point size to a minimum even when the attribute is 0. Expression on `mat.par.alpha` with `tdu.clamp((FAR - cam.par.tz) / FADE_WIDTH, 0, 1)` produces clean fade-in as user zooms in. → `references/patterns/scene-coupling.md`
- **Attached-position pattern for objects on a rotating sibling** — orbital tx/tz expressions (`r*cos(rad(ry))` / `-r*sin(rad(ry))`) keep a sibling COMP glued to a position on a rotating sibling without reparenting. Combine with ry-mirror expression for face-correctly-during-spin. → `references/patterns/scene-coupling.md`

Process learning: HARD TRIGGER section added to `SKILL.md` (always-loaded) so the in-flow rule survives across sessions without depending on the agent remembering to load `skill-growth-protocol.md`. Also added auto-memory feedback entry tied to "user has had to remind in past" — multi-layer redundancy on the same rule.

### 💡 2026-06-01 — [project: Heatmap_Body_Tracker bootstrap]
- **Embody.tox can be auto-fetched from GitHub releases; the rest of bootstrap can't be automated from a pre-existing claude session.** Two related findings landed today during a real new-project setup attempt.
  - **Closed TODO — direct asset URL pattern works** (no auth needed): `https://github.com/dylanroscover/Embody/releases/download/<tag>/Embody-<tag>.tox`. Asset filename includes the version (e.g. `Embody-v5.0.429.tox`); the intuitive `Embody.tox` 404s at every tag. Discovery method = brute-force probe of plausible filename variants at the known tag's download path. WebFetch on the releases page itself returns a "Loading…" placeholder because assets render via JS. `gh release view` needs auth.
  - **Automation boundary documented:** `td-new` + curl can scaffold folder, init git, and pre-fetch Embody.tox. Beyond that, the user must do 4 clicks in TD (Save As, drag-drop the .tox, set Aiclient=claude, ⌘S) because there's no MCP bridge until Embody is loaded — bootstrapping. Once those 4 clicks land, Embody starts Envoy and the agent can verify the rest via MCP.
- **Value for user:** future new-project setups no longer guess at the .tox URL; `td-new` can optionally pre-fetch (~330 KB, instant); the manual click-list is documented so neither user nor agent wastes time pretending the boundary can be moved further with current TD + Embody architecture.
- **File:** `references/project-bootstrap.md` § "Direct asset URL pattern (verified 2026-06-01)" + § "What `td-new` and Embody can/can't automate"
- **Type:** [discovery] (URL pattern) + [convention] (automation boundary)

### 💡 2026-05-31 — [project: skill-meta]
- **Consolidated learnings (2026-05-31 burst)** — 13 same-date discoveries from a research-and-write burst, summarized below as principles pointing at the references files where full content lives. Originals preserved verbatim in § "Archived detail (pre-consolidation 2026-05-31)" below. Listed in original burst order (newest first).
  - **AI / LLM integration architecture** — Python → OSC → TD bridge is the stable pattern; externalize the API caller to a separate Python process. Anthropic tool-use, vision, and Gemini text-gen all follow it. Tool names are snapshot-April-2026; the architecture is durable. → `references/ai-integration.md`
  - **Third-party TD ecosystem awareness** — check the community-tools catalog (POPX, RayTK, LOPs, YOLO plugin, others) before proposing "build from scratch". Awareness only; production-tested tools graduate to `components/<tool>.md`. → `references/td-community-tools.md`
  - **POPs comprehensive reference** — full operator vocabulary, conversion bridges (no "POP to SOP-render" op — render via Geometry COMP), three-class attribute model, index-pattern grammar, Map-page-per-point-parametric before reaching for GLSL POP, open-feedback-chain particle architecture, GLSL POP SSBO model with **Initialize Output Attributes** as the #1 crash-prevention rule, `GLSL Create POP` deprecated → use `GLSL Advanced POP`. Plus practitioner patterns (relational point networks, audio-reactive POP chain, data-viz canonical paths). Side effect: Blob Track canonical wiring added to `td-2025-operators.md`. → `references/pops.md`
  - **Audio-reactive systems** — `Resample CHOP` is the explicit rate-bridge between audio (48 kHz) and visual cook (60 Hz); audio-rate signal NEVER reaches shaders / POPs directly. BlackHole + Audio MIDI Setup Multi-Output Device is the critical Mac routing pattern. Asymmetric `Lag CHOP` (attack < release) is the "liquid feel" default. `Audio Beat CHOP` does NOT exist — build from Spectrum primitives, or use `Ableton Link CHOP` when a DAW is in the loop. → `references/audio-reactive.md`
  - **TD 2025 new operators — orientation** — Layer Mix TOP (3+ layer compositing), Color Space system (Preferences → Color), Blob Track TOP (NC 2-blob limit removed in 2025.32820), Render Simple TOP, Layout TOP grid fix, tdPyEnvManager autoSetup. ORIENTATION only — tactics (blend modes, ACES path, per-op surfaces) are growth-protocol territory. → `references/td-2025-operators.md`
  - 🔧 **GLSL deep patterns deliberately carved out** — Perplexity returned "no TD-verified info" on workgroup sizing, SSBO state on MoltenVK, `glslTOP`/`glslMAT`/`glslmultiTOP` decision criteria. Null result IS the signal: the domain lives in practitioners' courses, TD example `.toe` files, and embedded production knowledge. Empirical capture via growth-protocol; don't web-research again. → `references/glsl-patterns.md` (stub)
  - **Gaussian splat creation vs rendering** — splat creation (vid2scene cloud, OpenSplat local-Mac) and splat rendering (TDGS, Tim Gerritsen, atarilover123, POP-native) are SEPARATE pipeline layers — don't conflate them. OpenSplat replaces vid2scene (creator-to-creator), NOT TDGS (renderer). A Mac splat pipeline always needs ONE creator + ONE renderer. → `references/components/gaussian-splatting-mac.md § Pipeline split`
  - **Minimalism + visual verification** — prefer fewer operators (Derivative's `buttonMomentary` widget = 33 operators vs `Text COMP` = 1 operator; 10:1 ratio) and build project-specific UI from primitives. AND: `capture_top` is ground truth — `errors=0` is necessary but not sufficient to claim a visual change is done. → `references/td-architecture.md`
  - **TD cross-platform gotchas** — verify TD parameter names with `get_op` before setting (LLMs hallucinate: `dat`→`pixeldat`, `colora`→`alpha`). Non-commercial TD silently clamps to 1280×1280 (use ProRes/Hap, not H.264). "Invalid OP object" comes from destroy+recreate-same-name in one `execute_python` — split, rename, or defer with `delayFrames=1`. MCP is localhost-only, no auth, `execute_python` is unsandboxed. → `references/td-gotchas.md`
  - **Mac gotchas — workarounds + Vulkan correction** — 16-sampler GLSL cap now ships with workarounds (texture arrays `sampler2DArray`, texture buffers `samplerBuffer`, atlas packing, deleting unused fetches). AND: TD's render backend is Vulkan on all platforms (MoltenVK is just the Mac translator); OpenGL was removed from TD in 2022; custom Metal compute backends are unsupported / crash-prone on Mac. → `references/mac-gotchas.md`
  - **MediaPipe component reference** — plugin output lags ≥3 frames behind live camera (internal web-browser inference path); ALWAYS insert a `Cache TOP` on the camera branch for any overlay-on-live-video composite. Every enabled detection task (face / hands / pose / objects / segmentation / etc.) carries CPU+GPU cost — disable unused tabs to recover FPS. → `references/components/mediapipe.md`
- Value for user: session-start "scan last 10-20 entries" reads as indexed principles, not essays. Each principle has a clear pointer to the references file where the full content lives.
- File: CHANGELOG.md (this entry); referenced files unchanged
- Type: [consolidation summary]

### 🔧 2026-05-31 — [project: skill-meta]
- **Consolidation review** — 13 same-date burst discoveries from 2026-05-31 consolidated into the single principles-index entry above. Originals retained verbatim in § "Archived detail (pre-consolidation 2026-05-31)" below per growth-protocol's "annotate, never delete" rule. Triggered by § Consolidation Trigger B (count-and-flag at 15-entry boundary, fired on session start).
- Structural note: relocating originals to an archive section is one tolerant reading of "annotate" — they remain in the file with their full content and a back-pointer to the consolidated principle, just out of the session-start hot-path. The literal "in-place annotation" reading is preserved for future use; this relocation is justified by the burst's violation of the protocol's own `Format for entry` rule (1-2 sentence description).
- Value for user: CHANGELOG biography readable again — session-start scan goes from ~80 lines of essays to ~30 lines of indexed principles + structural entries
- File: CHANGELOG.md
- Type: [structural, consolidation]

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

## Archived detail (pre-consolidation 2026-05-31)

The 13 entries below are the original 2026-05-31 burst discoveries in full, moved out of the hot-path Improvements section per the consolidation entry above. Each entry has a `→ consolidated in ...` suffix pointing at the consolidated principle. Order preserved (newest first).

### 💡 2026-05-31 — [project: skill-meta]
- **AI / LLM integration architecture** captured in new `references/ai-integration.md`. The STABLE pattern is **Python → OSC → TouchDesigner**: externalize the LLM/vision/diffusion API caller to a separate Python process (using `python-osc SimpleUDPClient`), let TD listen via `OSC In CHOP`/`OSC In DAT`. Reason: TD's Python is bound to the 60 Hz cook cycle; long-running API calls block the cook. Three concrete patterns documented with snapshot-April-2026 model names: (1) **Anthropic tool-use** with `osc_tool` having `input_schema` of bounded numeric params (brightness/contrast/color_shift etc) — Claude becomes an "AI artist" picking concrete values across many channels from high-level intent ("make it more brooding"); (2) **Anthropic vision** pattern — sample camera frames every N seconds (not every cook), base64-encode, send to Claude vision, parse the description into OSC modulation. Latency reality: vision APIs are seconds, so this is a slow-loop "interpretation-driven" pattern, not real-time; (3) **Gemini text-gen** via CHOP Execute DAT triggering external Python → genai.Client → Text TOP. Plus a real-time diffusion awareness section (StreamDiffusionTD, ComfyUI .tox, TouchDiffusion) flagged as April-2026 snapshot. Explicit rule that the file deliberately does NOT capture prompt engineering, per-model parameter tuning, .tox usage walkthroughs, or latency benchmarks — those age in months. Discoverability: new SKILL.md References row with "OSC bridge is the recurring stable architecture" trigger.
- Value for user: the agent now recognizes that LLM/vision/diffusion integration is an externalized-Python-process problem, not a "put it in a CHOP Execute callback" problem. When a brief calls for AI-driven visuals, it picks the bridge architecture immediately and treats specific tool names as evaluation targets, not authoritative answers.
- File: `references/ai-integration.md` (new) + `SKILL.md` § References (new row)
- Type: [discovery]
- → consolidated in references/ai-integration.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **Third-party TD ecosystem awareness catalog** in new `references/td-community-tools.md`. Lists what the 2026 TD ecosystem offers so the agent can recommend community tools before suggesting "build from scratch": **POPX** (physics-dynamics extension to POPs — fluid/rigid/soft-body where built-in Particle POP isn't enough), **RayTK** (raymarching/SDF framework — directly relevant to the GLSL-patterns stub gap), **LOPs** (DotSimulate's 60+ AI/LLM/RAG operators — complements `ai-integration.md`), **YOLO plugin** (Torin Blankensmith — non-human-object ML tracking, complements MediaPipe), **L2D / T3D / MFI Motion Blur** as brief mentions, **Embody** noted as the foundation the skill already runs on. **Explicit framing throughout: awareness catalog, NOT how-to. All third-party, mostly paid Patreon, untested by the user.** Confidence per item is "exists & does X roughly". File ends with "how this catalog ages" — tools will graduate/get abandoned, the agent's only job is to flag "a community tool may exist for this; investigate before building from scratch." When a tool gets actually used in production via the growth protocol, it can graduate to a dedicated `components/<tool>.md` reference (similar to how MediaPipe and Gaussian splat got their own files). Discoverability: new SKILL.md References row.
- Value for user: stops the agent from proposing "let's build particle physics from scratch" when POPX exists, "let's write a raymarcher in GLSL" when RayTK exists, etc. Each tool's entry includes a cross-link to the relevant existing reference so the agent threads them together.
- File: `references/td-community-tools.md` (new) + `SKILL.md` § References (new row)
- Type: [discovery]
- → consolidated in references/td-community-tools.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **POPs reference gains "Production patterns from practitioners" section** (cross-platform, MEDIUM confidence) with three named workflows from Gianmaria Vernetti's II HQ articles (May 2026): (1) **Relational point networks** — Connectivity / Neighbor / Ray / Proximity POPs combined for evolving point textures; Ray POP with a `SOP to POP`-converted target as input 2 projects points onto surfaces along their ray direction; canonical wiring includes `Cache POP` as the cost-freeze point between expensive upstream and downstream variation; (2) **Audio-reactive POP chain** — full wiring from Audio Device In through band-averaged Spectrum, asymmetric Lag CHOP, Resample CHOP, into the POP via Map page binding (no GLSL POP needed), out through Geometry COMP → Render TOP → Blur+Bloom composite. Three load-bearing decisions called out: Map page binding vs custom GLSL, asymmetric smoothing prevents jitter, post-processing (TOPs) delivers atmosphere where POPs deliver structure. Cross-link to `audio-reactive.md`; (3) **Data visualization** — table of data-source → canonical path: `.ply` → Point File In POP direct, mesh → SOP to POP + Dimension POP, CSV → Table DAT → CHOP normalize → CHOP to POP, OAK/ZED depth → POP direct. Plus the **canonical Blob Track wiring** added to `td-2025-operators.md` (Video In → Monochrome → Threshold → Blob Track TOP → Info DAT for per-blob u/v + size + ID → instancing / shader uniforms) since the 2025.32820 unlimited-blob change makes Blob Track usable for multi-touch / multi-marker / performer-tracking setups it was previously capped out of.
- Value for user: practitioner recipes give the agent concrete starting wiring instead of "you could use these operators" hand-waving. The audio-reactive POP chain in particular threads three existing references together (audio-reactive.md + pops.md + td-architecture.md visual-verification).
- File: `references/pops.md` § "Production patterns from practitioners" (new section) + `references/td-2025-operators.md` § Blob Track canonical wiring (new subsection)
- Type: [discovery]
- → consolidated in references/pops.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **POPs reference deepened with production-grade architecture detail** in `references/pops.md` (260 → ~520 lines), filtered from a second strict-triage research pass. Major additions: (1) **Build delta table** — per-build POP additions across 2025.30770 → 2025.32820 for "my training data doesn't know about this" diagnosis; (2) **Operator vocabulary expanded** — full Generators list (Box/Circle/Plane/Primitive/Rectangle/Sphere/Torus/Tube/Revolve/Pattern/Sprinkle/Polygonize/Point File In/Import Select/OAK Select/ZED added), full Shaping list (Attribute Combine/Convert, Projection, Normalize, Quantize, ReRange, Limit, Trig, Twist, Facet, Connectivity, Subdivide, Cache Blend/Select, Field, Skin/Skin Deform, Texture Map, Lookup Attribute/Channel/Texture added), Copy/scatter subsection (Copy POP + GLSL Copy POP), explicit Experimental list (Alembic Out, Extrude, Line Thick, Phaser, Text, Trace, Triangulate per [Category:POPs 2025-10-28]), workhorse subset distilled from practitioner sources; (3) **`GLSL Create POP` flagged DEPRECATED** → use `GLSL Advanced POP` + optional `Topology POP`; (4) **Conversion bridges** with documented semantic translations — `SOP to POP` translates uv→Tex/Cd→Color/width→LineWidth/pscale→PointScale, `Dimension POP` for mesh-dimension preservation, `CHOP to POP` with "Precise names" for exact roundtrip, `DAT to POP` empty-headers crash workaround (2026-04 forum bug); (5) **Three-class attribute model** — points/vertices/primitives each with their own attribute lists, points-without-primitives don't render but are template/copy/instancing data, auto-generated attributes documented (`Nebr` from Neighbor POP, `PartVel/PartMass/PartLifeSpan/PartForce` from Particle/Force-Radial); (6) **NEW SECTION "Index pattern matching — POP grammar"** — TD 2025 introduced a new pattern language POPs use exclusively; documented syntax `[3-15]`, `^[100-200]`, `[0-15:2]`, `[0-15:2:5]`, `[*:3]` and which POP parameters accept it (Delete/Group/Primitive/Switch/GLSL/GLSL Advanced/Merge/Attribute Combine). This corrects/clarifies an earlier "no POP-inline-index-pattern-language" claim — TD HAS index patterns; what doesn't exist is Houdini-style inline attribute expressions (`@P.y > 0`), which remains in known-gaps; (7) **NEW SECTION "Map-pages — per-point parametric without shaders"** — before reaching for GLSL POP to vary a parameter per-point, check the operator's Map page (Particle POP / Force Radial POP / etc.); (8) **NEW SECTION "Line and curve workflows"** — `Line POP` family + `Trail POP` for ribbon trails, stay in POPs from generation to render; (9) **NEW SECTION "Particle systems — open feedback chain"** — explicit architecture: `Particle POP` → modifiers (`Force Radial POP` writes `PartForce`) → `Null POP` as feedback target, not a closed solver; (10) **NEW SECTION "GLSL POP in practice"** — SSBO model (each attribute = SSBO), one thread per element, **Initialize Output Attributes is the #1 crash prevention rule**, basic vs Advanced distinction (basic = mutate + multi-pass, Advanced = author/reshape + cross-class), cross-class function naming `TDIn_Attrib()` / `TDInVert_Attrib()` / `TDInPrim_Attrib()`; (11) **Debugging section expanded** — POP viewer overlays via Display Options for spatial intuition, common documented mistakes table (uninitialized GLSL POP outputs, DAT to POP empty headers, older Feedback POP disconnect, GLSL Create POP deprecation, "POP to render" anti-search). Sourcing: Derivative docs (HIGH for operators/bridges/semantics), 2025-series release notes (HIGH for build delta), Gianmaria Vernetti + Darien Brito (MEDIUM for practitioner workhorse subset).
- Value for user: the agent now has production-architecture-level POP knowledge — knows which POPs are Experimental (lower trust), knows the `GLSL Create POP` deprecation, has the SSBO + Initialize-Output-Attributes crash-prevention rule for GLSL POPs, knows the open-feedback-chain particle architecture, knows index patterns and Map pages exist before reaching for custom GLSL. Concrete improvements over the prior pops.md: when wiring particles, builds the open feedback chain explicitly; when scattering meshes, picks Copy POP / GLSL Copy POP over searching for non-existent operators; when filtering points, uses the index-pattern syntax instead of looping in Python; when authoring custom GLSL POPs, enables Initialize Output Attributes by default.
- File: `references/pops.md` (rewritten, expanded 260 → ~520 lines)
- Type: [discovery + correction]
- → consolidated in references/pops.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **Audio-reactive systems reference** in `references/audio-reactive.md` (new). Filtered HIGH+MEDIUM findings from a strict-triage research pass. Covers: (1) **Input** — `Audio Device In CHOP` in frames-mode for low-latency, `Audio File In CHOP`, `Audio Device Out CHOP`, plus the canonical show-rig (one file source split to analysis + speakers); (2) **Frequency analysis** — `Audio Spectrum CHOP` (FFT bins) vs `Audio Analyze CHOP` (RMS/peak/centroid scalar metrics); (3) **Rate-gap mental model** — audio CHOPs at 48 kHz vs visual cook at 60 Hz, hard rule "audio-rate NEVER reaches shaders/POPs directly", `Resample CHOP` as the explicit rate-bridge, CHOP→GLSL uniform via the same vec4-Vectors-page pattern used for absTime (cross-link `glsl-patterns.md`); (4) **Mac routing** — BlackHole + Audio MIDI Setup Multi-Output Device as the critical Mac-specific pattern for "Spotify/Ableton → TD", with installation steps; (5) **Band patterns** — direct bins (jitter, graphic-EQ aesthetic) vs band averages (3-16 stable controls), with 20-150 Hz / 150 Hz-2 kHz / 2-12 kHz workhorse split; (6) **Asymmetric smoothing** — `Lag CHOP` with Filter Width Up < Down (attack 5-30 ms, release 150-500 ms) as the "liquid" feel default; (7) **Anti-jitter** — round-then-smooth for instance counts, hysteresis via two thresholds + `Logic CHOP` for state changes; (8) **Beat detection** — heuristic CHOP-built recipe (Spectrum → low band → Lag → Threshold → Logic Off-Delay refractory) OR `Ableton Link CHOP` when Ableton is in the loop (preferred); (9) **CPU/GPU** — audio is CPU-only, no GPU audio in TD, rarely the bottleneck on M1. **Critical empty-gap table** at the end: `Audio Beat CHOP`, `Audio Band Filter CHOP`, `Audio Band EQ CHOP`, `Audio Envelope CHOP`, `Audio Stream In CHOP`, and **native NDI audio receiver** — all confirmed NOT IN TD as of 2026-05; agent must build from primitives, not search palette. Bold CHOP names throughout for grep anchors.
- Value for user: closes one of the three top-tied gaps from the original ranking. Production-grade audio-reactivity is now answerable from references instead of guessing. The BlackHole-on-Mac pattern alone is worth the file — it's the single most common Mac trap for audio-reactive work. Cross-reference for the particle-system project the user mentioned wanting to build: asymmetric smoothing IS the "liquid feel" technique.
- File: `references/audio-reactive.md` (new) + `SKILL.md` § References table (new row)
- Type: [discovery]
- → consolidated in references/audio-reactive.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **POPs reference expanded from thin defaults-page to full operator-family guide** in `references/pops.md` (75 → ~250 lines). New sections: (1) **What POPs replace vs don't replace** — keeps Derivative's "re-think your patterns, not full replacement" framing, marks SOPs-for-modeling and `particlesGPU` as coexisting; (2) **Operator vocabulary** organized by family with bold operator names as grep anchors — Generators (Point Generator / Grid / Sphere / Box / Line / Curve / File In / Alembic In POP, Official workhorses), Shaping (Attribute / Math / Noise / Lookup / Group / Sort / Random / ReRange / Transform / Limit / Quantize / Normalize POP, Official workhorses), Dynamics (Particle POP flagged Experimental in early 2025 builds, Feedback POP, Trail POP), GLSL POPs (GLSL POP + GLSL Advanced POP with Mac ray-query limitation), Topology, Attribute Authoring; (3) **Conversion bridges** — SOP/CHOP/DAT/TOP→POP exist, POP→CHOP exists, **explicit "NO 'POP to SOP' operator exists"** rule to stop the agent from searching for it; (4) **Attribute system mental model** — built-in P/Cd/N/Tex with component-suffix indexing, custom attributes via Attribute Create POP, type suffixes f/F/i/I/u/U, array indexing `MyArray_0_`, plus the confirmed-empty gap "no Houdini-style inline @P.y syntax"; (5) **Rendering pipeline** — `POP chain → Geometry COMP (instance source) → Render TOP`, explicit "no new POP-instancing-mode on Geometry COMP, integrates into the existing instancing UI"; (6) **Mac specifics** — no double-precision attributes on macOS, no hardware ray tracing → GLSL Advanced POP ray-query doesn't work on M1+; (7) **Debugging** — Info CHOP for total_cooks/cook_time/errors/warnings, Delete Input Attributes for isolation, OP Snippets for binding-syntax ground truth; (8) **Known gaps** explicitly listed (M1 benchmarks, full MoltenVK-POP bug list, exact GLSL POP binding syntax — defer to OP Snippets, Particle POP collision support). Official-since-2025.31550 (Oct 30, 2025) made authoritative. Discoverability: new row added to SKILL.md § "References (load-on-demand by topic)" with the "check before building SOP chains" trigger.
- Value for user: the agent now has a real operator-level vocabulary for POPs instead of "POPs are the default" hand-waving. Concrete: it won't search the palette for a non-existent "POP to SOP" operator, won't propose Houdini-style attribute syntax that doesn't exist in TD, knows ray-query won't work on M1, knows to drop an Info CHOP first when a POP chain misbehaves.
- Files: `references/pops.md` (expanded from 75 → ~250 lines) + `SKILL.md` § References table (new row)
- Type: [discovery]
- → consolidated in references/pops.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **TD 2025 new operators — orientation list** in `references/td-2025-operators.md`. Confirms existence + rough purpose of: **Layer Mix TOP** (2025.31310/31550, replaces composite/over chains for 3+ layer compositing); **Color Space system** (2025-series, Preferences → Color tab; Window Pixel Formats added 2025.32050); **Blob Track TOP** (2025.32820 — 2-blob NC limit lifted for all license tiers); **Render Simple TOP**, **Layout TOP** grid fix, **VS Code integration**, **tdPyEnvManager** v1.3.1 autoSetup as "confirmed exists, needs production depth"; **laser overhaul** as "exists, no public operator-level detail." File is **explicitly labeled as ORIENTATION, not tactics** — known gaps (Layer Mix blend mode list, ACES on Mac, blob-N on M1 Pro, laser operator surfaces) listed at the bottom for growth-protocol capture. Each entry has a one-sentence rule + the symptom it prevents. Note on sourcing: ChatGPT and Perplexity returned identical TD 2025 content — treated as a SINGLE source, not independent confirmation.
- Value for user: stops the agent from proposing 2022-era composite chains, manual color setup, or 2-blob limit workarounds when 2025 operators now solve those better. Plus discoverability: new **References (load-on-demand by topic)** section in `SKILL.md` with the TD 2025 row and trigger condition — first entry in what will become a growing table as references mature.
- Files: `references/td-2025-operators.md` (new) + `SKILL.md` § "References (load-on-demand by topic)" (new section)
- Type: [discovery + convention]
- → consolidated in references/td-2025-operators.md (2026-05-31)

### 🔧 2026-05-31 — [project: skill-meta]
- **GLSL deep structural patterns deliberately carved out of web research**: a Perplexity pass on the GLSL-deep-pattern questions (workgroup sizing on Apple GPUs, SSBO state on MoltenVK, `glslTOP`/`glslMAT`/`glslmultiTOP` structural decision criteria, multi-input shader ordering conventions) returned "no TD-verified info" as of 2026-05-31. That null result IS the signal — the domain lives in practitioners' courses, TD example `.toe` files, and embedded production knowledge, not in dated web text. New `references/glsl-patterns.md` stub explicitly reserves the namespace for growth-protocol capture and lists "don't ask Perplexity again" as a hard rule, preventing the next research attempt from wasting cycles.
- Value for user: stops the next "let's research GLSL in TD" attempt from spinning. Empirical capture via the growth-protocol's pre-ask gates is the right path for this domain — when a real shader pattern survives all three gates in actual project work, it lands in this file.
- File: `references/glsl-patterns.md` (new stub)
- Type: [convention]
- → consolidated in references/glsl-patterns.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **Gaussian Splatting pipeline split documented** in `components/gaussian-splatting-mac.md` — creation (vid2scene cloud, used in production for `RADON_Tree.ply`; OpenSplat local-Mac via Metal `-DGPU_RUNTIME=MPS`, AGPLv3, to-verify) is a separate step from rendering (TDGS, Tim Gerritsen, atarilover123, etc.). Explicit "don't mix these up" rule: OpenSplat replaces vid2scene (creator-to-creator), NOT TDGS (which is a renderer). OpenSplat caveats noted: requires libtorch+OpenCV+Xcode compile from source AND COLMAP/OpenSfM pre-processed input — not plug-and-play.
- Value for user: when a user asks "how do I get a Gaussian splat into TD", the agent now knows there are two pipeline steps and recommends the right tool for each layer instead of conflating creators with renderers.
- File: `references/components/gaussian-splatting-mac.md` § "Pipeline split — splat CREATION vs splat RENDERING" (new section, top of file)
- Type: [discovery]
- → consolidated in references/components/gaussian-splatting-mac.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **Minimalism principle + visual-verification reinforcement** from Dylan Roscover's "The Great Inversion" (March 2026). Two concrete agent rules: (1) prefer few operators over many — Derivative's `buttonMomentary` widget = 33 operators internally vs a Text COMP = 1 operator (10:1) — heavy palette abstractions are often unnecessary for project-specific work; (2) "if it looks correct, it is correct" — `capture_top` is ground truth, `errors=0` plus correct parameter values is necessary but not sufficient evidence that a visual change works. Manifesto/philosophy parts of the source article (taste-vs-execution, hardware moat, open-source bait) deliberately left out — not agent-actionable. Derivative-native-MCP claim from the same article also left out — already flagged as unconfirmed in earlier filtering.
- Value for user: agent picks lighter network structures by default; agent never claims "visual change done" without a capture to back it up.
- File: `references/td-architecture.md` (new)
- Type: [discovery]
- → consolidated in references/td-architecture.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **Four cross-platform TD gotchas** from research dossier filtering: (1) LLMs frequently hallucinate TD parameter names from training-data priors (`dat`→`pixeldat`, `colora`→`alpha`, `sizex`→`size`) — verify with `get_op` before setting; (2) Non-commercial TD silently clamps resolution to 1280×1280, and H.264/H.265/AV1 codecs require Commercial license — use ProRes/Hap on Non-Commercial; (3) "Invalid OP object" errors come from destroying + recreating same-name ops in one `execute_python` call — split, rename, or defer with `run(..., delayFrames=1)`; (4) MCP security model: localhost-only, no auth, `execute_python` runs unsandboxed as the TD process — rhymes with the DESTRUCTIVE cluster's per-call-yes rule. Plus a small note on Envoy tool count drift (~48 as of v5.0.413, third-party catalogs cite 45–50).
- Value for user: each item closes a real production-debug session before it starts. The parameter-names gotcha alone prevents a class of trial-and-error loops.
- File: `references/td-gotchas.md` (new)
- Type: [discovery]
- → consolidated in references/td-gotchas.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **mac-gotchas.md upgraded**: (1) the 16-sampler GLSL cap now ships with WORKAROUNDS, not just the problem statement — texture arrays (`sampler2DArray`, one sampler N slices), texture buffers (`samplerBuffer`, one sampler for large flat arrays), atlas packing, and "delete unused fetches" as a no-effort first check; (2) intro paragraph corrected — TD's render backend is Vulkan on all platforms (MoltenVK is just the Mac translator), OpenGL was removed from TD in 2022 (so any "TD's OpenGL path" reference is outdated), and custom Metal compute backends for custom operators are unsupported / crash-prone on Mac as of mid-2025.
- Value for user: the 16-sampler entry is now constructive instead of just diagnostic — the agent can propose a structural fix instead of only the "force-white" hack. The Vulkan correction prevents the agent from suggesting Metal-direct paths that don't work.
- File: `references/mac-gotchas.md` § (intro + "16-sampler GLSL cap" workaround section)
- Type: [discovery + correction]
- → consolidated in references/mac-gotchas.md (2026-05-31)

### 💡 2026-05-31 — [project: skill-meta]
- **MediaPipe component reference seeded**: (1) plugin output is ≥3 frames behind realtime due to internal web-browser inference path — when compositing tracking output with live camera, ALWAYS insert a Cache TOP on the camera branch to resync; (2) every enabled detection task (face / face landmarks / hands / pose / objects / image classification / image segmentation / image embeddings) carries CPU+GPU cost — turn off unused tasks on the MediaPipe COMP's tabs to recover FPS.
- Value for user: when a "hand overlay on live video" project shows visible lag, the agent now knows the cause and the fix (Cache TOP) instead of guessing at GLSL or render-graph issues. The disable-unused-tasks rule frequently recovers FPS on Mac M1 projects.
- File: `references/components/mediapipe.md` (new)
- Type: [discovery]
- → consolidated in references/components/mediapipe.md (2026-05-31)

---

## Versions

No tagged versions yet. The skill is in continuous-improvement mode under
`## Improvements and newly acquired knowledge`. First version tag will land
when the references/ banks are populated and the team-scaling path is taken
(or earlier if the scope is locked).

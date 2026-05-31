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

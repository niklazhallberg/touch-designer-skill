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

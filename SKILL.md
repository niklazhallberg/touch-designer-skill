---
name: touchdesigner
description: Builds and modifies TouchDesigner projects using Embody (externalization to git-trackable files) + Envoy MCP (live operator manipulation from Claude). Covers POP/SOP/TOP/CHOP/DAT operator creation, network layout, TDN-strategy COMPs, GLSL shaders in TD, hand-tracking, MediaPipe components, Gaussian splat workflows. TRIGGER when user mentions TouchDesigner, TD, .toe, .tox, .tdn, Envoy MCP, Embody, "operator", "network" in a TD context, or when CWD contains a .toe file or .embody/ directory. SKIP for Lens Studio, Unity, Unreal, Blender, Houdini, generic Python, or visual programming without TD context.
---

# TouchDesigner skill

Build TD projects from Claude Code using Embody-externalized files + Envoy MCP for live network manipulation.

## Read these first (mandatory, session-start)

1. **Project CLAUDE.md** — Embody regenerates this in every TD project. Has the 12 critical rules (TDN-first, never assume paths, log analysis, etc.) and a per-tool skill-load table.
2. **`references/skill-growth-protocol.md`** — pause-on-discovery, generalize, write to references, CHANGELOG-prepend, commit + push after user ok. Same pattern as the LS skill but trimmed for single-user.
3. **`CHANGELOG.md`** — scan the last 10–20 entries. Each one points at a file/section; open the ones plausibly relevant before they fire as triggers.

Then scan `references/` filenames so you know what banks exist before they're needed.

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

(Other references like `mac-gotchas.md`, `td-gotchas.md`, `td-architecture.md`, `components/gaussian-splatting-mac.md`, `components/mediapipe.md`, `glsl-patterns.md`, `project-bootstrap.md`, `skill-growth-protocol.md` exist and load on topic match — they will be added to this table as their trigger conditions are formalized.)

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

Full rationale: `references/operational-discipline.md`.

## Approach guidelines

- Hypothesis → evidence → fix. State the hypothesis before acting.
- Define success criteria up front; loop until verified.
- Fail loud: "done" is wrong if anything was silently skipped.
- Surface conflicts; don't silently average between two patterns.
- Two failed attempts on a sub-step → switch to simpler fallback, report which path. Full pattern: `references/operational-discipline.md` § Fallback.
- Start weak on constrained platforms (M1, browser, mobile). Prove the technique, raise quality after. Full pattern: `references/start-weak-protocol.md`.

## Starting a new TD project

```bash
cd ~/Projects/
~/.claude/skills/touch-designer-skill/scripts/td-new my-project-name
```

Then in TouchDesigner: save the `.toe`, drag in `Embody.tox`, set `Aiclient = 'claude'`. Embody generates the rest (`.mcp.json`, `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`, `.claude/rules/`). Full flow: `references/project-bootstrap.md`.

## Repo status

- Local: `~/Projects/touch-designer-skill/`
- Remote: TBD (user creates GitHub repo + pushes)
- Single-user today. Structure ready to scale to team — references are written in plain English, project-agnostic, no client names.

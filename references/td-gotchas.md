# TouchDesigner gotchas (cross-platform)

TD-specific traps that aren't Mac-only. Each item: source + date + verification status. See `mac-gotchas.md` for macOS-specific items.

---

## LLM training data has wrong TD parameter names

**Source:** TD/MCP research dossier (May 2026), cross-checked against live `get_op` calls | Date: May 2026 | **Confidence:** HIGH (the 3 listed confusions are empirically verified; the broader pattern of LLM training-data drift is well-established)

LLMs frequently produce TD parameter names from training-data priors that don't match the actual TD parameters. Known confusions:

| LLM-suggested (wrong) | Actual TD name | Operator family |
|---|---|---|
| `dat` | `pixeldat` | glslTOP (pixel shader source) |
| `colora` | `alpha` | constantTOP and similar (alpha channel) |
| `sizex` | `size` | many ops where "size" is scalar |

**Rule for the agent:** never trust your priors on TD parameter names. Before setting a parameter you haven't recently verified, run `get_op <path>` or `read_tdn` and confirm the exact name. The cost of one extra read is much lower than the cost of an "Invalid parameter" trial-and-error loop. This reinforces `rules/parameters.md` — that file describes the conventions (capitalization, naming rules); this entry adds the verify-first habit.

**Check first when:**

- About to set a parameter on an op you haven't inspected in this session
- A `set_parameter` call returns "no such parameter" or fails silently
- You're translating natural-language intent ("set the alpha to 0.5") into a parameter name

---

## Non-commercial TD silently clamps resolution

**Source:** TD/MCP research dossier (May 2026) | Date: May 2026 | **Confidence:** HIGH (TD-documented licensing behavior)

Non-Commercial TD licenses cap output resolution at **1280×1280**. Setting `resolutionw = 1920` silently produces 1280×1280 — no warning, no error, just clamped output.

**Adjacent licensing constraints:**

- **H.264, H.265, AV1** codecs require Commercial license
- On Non-Commercial: use **ProRes** or **Hap** codecs — they work without license walls
- The clamp applies at write time on movie-out and TOPs driving recording

**Check first when:**

- User reports output smaller than the configured resolution
- A recording looks "downscaled" from what was set
- Codec parameter rejects H.264 without an obvious error message
- Output dimensions match 1280×1280 when you asked for higher

**Rule:** when configuring a recording or render-out chain, ask the user what license tier they're on if it's not obvious. Default to **ProRes** or **Hap** on Non-Commercial.

---

## "Invalid OP object" — don't destroy + recreate same-name in one Python call

**Source:** TD/MCP research dossier (May 2026) | Date: May 2026 | **Confidence:** MEDIUM (dossier-derived; user has not personally hit this — workaround set is the documented pattern but each variant untested in this skill's production work)

Destroying an operator and immediately recreating one with the same name inside a single `execute_python` call (or scripted callback) often leaves dangling references that throw "Invalid OP object" errors downstream. TD's operator registry hasn't fully reconciled the destroy when the create runs.

**Workarounds (pick by context):**

1. **Split into two MCP calls:** destroy in one `execute_python`, create in the next.
2. **Use a different name** on recreation, then rename after the destroy settles.
3. **Defer the recreate** with `run('...', delayFrames=1)` to let the destroy clear.

**Check first when:**

- A script that creates+destroys ops mid-build throws "Invalid OP object"
- Operators look correct in the network but expressions referencing them fail
- An "update" function that re-creates configuration ops fails after the first call

---

## MCP security model — localhost only, no auth, `execute_python` is unbounded

**Source:** Envoy/Embody architecture (verified against bridge code) | Date: May 2026 | **Confidence:** HIGH (verified against Envoy bridge source; security properties are explicit design choices)

Security properties of the Envoy MCP setup as deployed:

- **Bind address:** `127.0.0.1` only. Not reachable from the network.
- **Authentication:** none. Any process on localhost that can hit the port can call any tool.
- **`execute_python` scope:** runs as the TouchDesigner process, with TD's full Python environment + filesystem access. No sandboxing.
- **`set_dat_content` / `edit_dat_content`:** can write arbitrary Python into a DAT that may then be called by TD's cook cycle.

**Implications for the agent (rhymes with SKILL.md DESTRUCTIVE cluster):**

- Treat `execute_python` per the DESTRUCTIVE-cluster rule: explicit per-call user yes, state intent before running.
- Don't `execute_python` arbitrary user-pasted code without reading it first — it executes with the same privileges as TD.
- Never expose the Envoy port (default 9870) to the network. The 127.0.0.1 binding is the security boundary.

**Check first when:**

- Adding any code that writes to or executes against a DAT
- The user asks to run "this Python script" — read it before running
- A workflow proposes opening any TCP port for the bridge

---

## Envoy tool count — citations drift

**Source:** Envoy/Embody live count vs. third-party catalogs | Date: May 2026 | **Confidence:** LOW (informational drift note, not load-bearing — exact count varies by Envoy build)

The Envoy server exposes **~48 tools** as of Embody v5.0.413. Other sources drift: Glama lists ~45, some marketing copy says "~50". The drift is from minor additions/renames across versions.

**Rule:** if asked "how many tools does Envoy have," answer "~48 as of v5.0.413, mind drift across versions." Don't assert a specific count without checking the current MCP `tools/list` response.

---

## `.N.toe` numbered files are TD's normal backup-on-save behavior, not separate state

**Source:** agent-friction observation 2026-06-01 during Heatmap_Body_Tracker Phase 0 bootstrap (agent in fresh project session gated execution on `project.name == 'X.1.toe'` vs `'X.toe'` thinking the canonical file was different — both files were identical 3418 bytes / same timestamp) | **Confidence:** HIGH (TD save behavior is well-documented and the friction case was concrete + cost real session time)

When you Save As to `Heatmap_Body_Tracker.toe`, TD writes the canonical file AND immediately starts actively editing the next numbered increment — `Heatmap_Body_Tracker.1.toe`, then `.2.toe`, etc., bumping on every subsequent ⌘S. The canonical un-numbered `.toe` and the latest numbered `.N.toe` reflect the **same** project state (within one save cycle). They are not competing files; there is no "real one" vs "backup one" distinction at the build-content level.

Symptom of agent confusion: `project.name` returns `Foo.1.toe` and the agent assumes "I should bail because the user wanted Foo.toe specifically." This is wrong. TD chose to edit `.1.toe`; the canonical `.toe` is updated alongside as a snapshot.

**Rule for the agent:** `project.name` returning `<basename>.N.toe` (numeric suffix > 0) is **normal and expected**. Do not gate execution on it. Verify the project identity by:

1. `project.folder` matches the intended project folder (this is the real identity check)
2. `project.name` starts with the expected basename (strip the numeric suffix before comparing)

Only bail if the project folder is wrong, or if the basename is wrong (e.g. `NewProject.1.toe` instead of `Foo.1.toe`).

**Check first when:**

- An agent in a fresh TD project session reports the file is "the wrong .toe" but the basename matches
- A plan or build prompt includes a "verify the file is X.toe" step that doesn't account for the `.N.toe` increment
- Multiple `.N.toe` files exist in the project folder with similar timestamps (they're the save-chain history; the highest N is the live edit target)

**Don't:**

- Treat `.N.toe` files as "backups to ignore" — the highest-numbered one IS the live edit target
- Save As to overwrite the canonical `.toe` "to fix the discrepancy" — there is no discrepancy; the canonical and latest-numbered files match each save cycle
- Plan a "verify file is X.toe (not X.1.toe)" step in any build prompt or onboarding plan; it generates exactly this false alarm

For build-prompt authors specifically: don't write a Step 1 that gates on `project.name == 'X.toe'` literally. Write it as "`project.name` basename matches expected project name" (allowing the `.N.toe` increment).

### Related: `project.save(path)` writes the file but does not update `project.name`

Observed in the same 2026-06-01 bootstrap session, immediately downstream of the rule above. When the agent calls `project.save('/abs/path/to/Foo.toe')`, the file is written to disk at that path — but `project.name` continues to return whatever was active before the save call. This is consistent with how TD models project identity internally (the save call writes a snapshot; it does not "rename" the live project).

**Implication for verification:** don't use `project.name` to check that a save landed where you intended. Use the filesystem:

```python
import os
target = '/abs/path/to/Foo.toe'
project.save(target)
# Verify with filesystem, not project.name
exists = os.path.exists(target)
size = os.path.getsize(target) if exists else 0
mtime = os.path.getmtime(target) if exists else 0
# Sanity-check size > 0 and mtime is recent
```

`project.name` is informational about TD's active editing context, not about which path was last written. Agents post-save-verifying via `project.name` will see what looks like a mismatch when there is none.

---

## Swapping a renderTOP's camera silently breaks bindings on the old camera

**Source:** production session 2026-05-31 (M1 Pro, Gaussian splat scene with CameraExt-extended cameraViewport + bare-camera swap) | Date: 2026-05-31 | **Confidence:** HIGH (user-observed failure and fix in the same session — the bound feature visibly stopped working in the rendered view, mirror-binding on the new camera restored it)

Re-pointing `renderTOP.par.camera` from one cameraCOMP to another transfers ONLY which transform/lens drives the render. Any **bindings** other ops had pointing at the old camera — parameter expressions, CHOP exports, drag-targets — are **not** moved. Those bindings continue to fire; they keep writing to the (no-longer-rendered) old camera's params. The visible effect is that a previously-working interactive control (zoom dolly, look-at, light tracking) appears "off" in the rendered view, while the binding remains alive in the network.

**Common signature:** a pinch-driven `Pivotdistance` (or similar) on a cameraViewport with CameraExt stops affecting the render when render switches to a new bare cameraCOMP. The pinch signal still fires, the matrix still updates, the renderTOP just isn't reading from that camera anymore. User notices immediately ("the zoom is off") and is right — the regression is silent in errors/warnings.

**Rule for the agent (before any swap):** before changing `renderTOP.par.camera`, scan the project for expressions or CHOP exports targeting the OLD camera's path. For each match: decide whether to **mirror** the binding to the new camera, or accept the breakage and tell the user explicitly. The check is one MCP query; the cost of missing it is a silent feature regression.

**Quick inventory (paste-ready):**

```python
# Find params whose expression references the old camera's path
old_path = '/project1/.../oldCamera'
hits = []
for child in op('/project1').findChildren(maxDepth=10):
    for p in child.pars():
        expr = p.expr or ''
        if old_path in expr:
            hits.append((child.path, p.name, expr))
        if p.mode == ParMode.EXPORT:
            hits.append((child.path, p.name, 'EXPORT'))
return hits
```

**Check first when:**

- About to change `renderTOP.par.camera`
- A previously-working interactive control (zoom, dolly, look-at) appears inactive after a camera or render-graph change
- Migrating from a CameraExt-driven camera to a bare cameraCOMP (or vice versa)
- Adding a parallel camera intended to coexist with the original

**Don't:**

- Assume bindings track the *rendered* camera — they track the cameraCOMP they reference by path
- Trust that "the render still renders" means "all controls still work" — the failure is silent
- Skip the inventory query because "I know what's connected" — the network may have bindings added across sessions

Cross-link: `skill-growth-protocol.md § Generalization rule` for the protocol that surfaced this lesson; `td-architecture.md` for the "errors=0 ≠ correct" principle that this gotcha is a textbook case of.

---

## Known gaps (deliberately empty)

These are publicly unresolvable or untested as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md § Pre-ask filters`):

| Gap | Where it surfaces |
|---|---|
| Complete list of LLM-hallucinated TD parameter names — only 3 confirmed (`dat`→`pixeldat`, `colora`→`alpha`, `sizex`→`size`) | Each time an unfamiliar parameter fails to set; collect new confusions here |
| NC resolution clamp boundary behavior — does it clamp 1500×1500 → 1280×1280, or pass through up to 1280? Not tested at intermediate values | First time a project sets a width between 1280 and 1920 on NC |
| "Invalid OP object" workaround variants — `delayFrames=1` vs split-into-two-calls vs rename-then-destroy: which is most reliable in which context? Untested in production by user | First time a script runs into the race condition |
| MCP timeout behavior in newer Envoy builds (>v5.0.413) — does the 30-second cap still hold? | First time a long MCP operation is needed against a newer Embody |
| Whether `addError` / `addScriptError` semantics changed in TD 2025+ | First time an extension method needs to raise a TD error from a non-cook context |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

---

## Mesh-import gotchas captured from real work

### `fileinSOP` does NOT read `.glb` (glTF binary) — convert to `.obj` externally

**Source:** Squirrel build (.glb mesh), 2026-06-02 | **Confidence:** HIGH (verified, then fbxCOMP attempted as alternative — also unreliable, see next entry)

`fileinSOP` supports `.obj`, `.bgeo`, `.geo` — **not** `.glb` or `.gltf`. Pointing the `file` param at a `.glb` produces `"Error: Unable to read file"` (even when the file exists and is readable on disk).

**Fix (clean, reliable):** convert offline with a stdlib Python script that reads glTF binary structure (12-byte header + JSON chunk + BIN chunk), extracts `POSITION` floats and triangle `indices`, writes `v x y z` + `f i j k` lines to `.obj`. ~30 lines of code, no external libs. Drops textures, normals, UVs (acceptable if downstream pipeline doesn't need them; the squirrel/roots pipeline scatters POPs by surface area so vertex colors aren't relevant).

Same script pattern works for any procedural-to-TD mesh path where you don't want a Blender/external-tool dependency. Keep generators in `Assets/generate_<thing>.py` so regen is `python3 Assets/generate_<thing>.py` + `op('.../filein').par.refresh.pulse()` in TD.

### `fbxCOMP` imports `.glb` but `importselectPOP` data is unreliable

**Source:** same Squirrel build, 2026-06-02 | **Confidence:** MEDIUM (one observation; pattern may vary per asset)

`fbxCOMP` accepts `.glb` files (modern TD's FBX importer handles Khronos glTF) and the import reports zero errors. However, the resulting POP at `.../<fbxCOMP>/group1/mesh` (`importselectPOP` type) returned data that did NOT match the source `.glb`:

- Source `.glb`: 148 185 vertices, mesh bbox X:0.37 × Y:1.82 × Z:1.90 (roughly cubic)
- `importselectPOP` output: 4 438 points, bbox X:4.43 × Y:0.59 × Z:0.058 (**flat**, drastically different shape)

The flat Z dimension and 33× point-count discrepancy suggest the POP was sampling some derived/UV representation rather than 3D positions, OR the import pipeline has an `pops=True` toggle bug. The `mergedGeos/primitive1` path showed only the default 6-vertex placeholder.

**Conclusion: don't trust fbxCOMP's POP output for mesh data extraction.** Use external `.obj` conversion or other documented paths instead. If the goal is rendering (not POP-data-access), the fbxCOMP's geometry+material may still render correctly — that path wasn't tested in this case.

---

## Rendering gotchas

### Depth Peel needed for nested/overlapping transparent surfaces

**Source:** [docs.derivative.ca/Render_TOP](https://docs.derivative.ca/Render_TOP) — Derivative wiki, primary | **Confidence:** HIGH

Default Render TOP sorts opaque geometry by depth correctly but can produce visual artifacts when multiple **transparent** surfaces overlap (e.g. a glass cube with water/objects inside, multiple glass layers, transparent particles in front of transparent geometry). The artifacts: surfaces draw in wrong order, the backmost-transparent shows in front, or transparency math compounds incorrectly.

**Fix:** the Render TOP exposes three related parameters:

- **`Transparency`** (menu) — three modes; the relevant one is **"Order Independent Transparency"** which uses depth peeling as part of its process.
- **`Depth Peel`** — enables depth peeling separately from blending. Per the Derivative docs: *"Depth peeling is a technique used as part of Order-Independent Transparency, but this parameter allows you to use it in a different way."*
- **`Transparency/Peel Layers`** (`transpeellayers`) — the number of rendering passes. Each layer captures one further-back transparent surface.

**How depth peel works (Derivative quote):** *"first rendering geometry normally and saving that image and depth. Then another render is done but the closest pixels that were occluded by the previous pass are written to the color buffer instead."*

**When to enable:** any scene with ≥2 transparent surfaces that can be in front of each other from the camera's view. Concrete cases: glass-cube-with-internal-water, layered glass panels, transparent particle volumes in front of transparent geometry, dual-sided glass (front + back face both transparent).

**When NOT to enable:** scenes with only one transparent layer (single glass pane, particles against opaque background). Depth peel adds render passes — leaving it off when not needed saves frame budget.

**Layer count rule of thumb:** start at 2–4 layers; increase only if you still see the artifact. Each layer costs roughly one extra render pass.

---

## TD stability gotchas captured from real work

### Topology change + large cook = TD hangs — bypass during refactor

**Source:** Repeated POP-chain refactors in a 500K+ point pipeline, 2026-05 to 2026-06 | **Confidence:** HIGH (TD hung 3+ times before pattern was understood; pattern eliminated subsequent hangs)

TD hangs (UI frozen, MCP timeouts on trivial probes) when **topology changes** (op creation, deletion, rewiring, or sequence-block expansion) happen simultaneously with **large-input cooks** (high point counts, deep render chains, big PLY loads). The combination forces TD to recompute the entire downstream graph in one transaction while also rebuilding the network — no checkpoint, no rollback.

The hang is silent: no error, no crash, TD process is alive but unresponsive. Recovery requires `restart_td` (or kill + launch). Any unsaved work is lost.

**Triggers in practice:**

- Creating a `deletePOP` (or any culling op) downstream of a high-density POP chain — the op starts cooking the full input the moment it appears, before you can finish configuring it.
- Rewiring a `mergePOP` while both inputs are producing thousands of points.
- Expanding `attributePOP.par.attr.sequence.numBlocks` while the op has live input.
- Calling `import_network(clear_first=True)` on a COMP whose downstream consumers are actively rendering.

**Defensive pattern — bypass-first for new ops:**

```python
new_op = parent.create(deletePOP, 'cull1')
new_op.par.bypass = True               # 1. bypass FIRST (no cook)
new_op.par.delcondition = '...'        # 2. configure (still no cook)
new_op.par.delgroup = '...'
connect_ops(upstream, new_op)          # 3. wire (still bypassed)
connect_ops(new_op, downstream)
new_op.par.bypass = False              # 4. unbypass LAST — single cook of configured op
```

**Density-reduction pattern (when bypass isn't applicable):**

Before a refactor that touches multiple ops simultaneously, temporarily reduce the upstream point count — `sprinklePOP.par.density`, `fileinPOP.par.thinstep`, etc — to a few thousand points. Refactor at low density, verify behavior, restore density last.

**MCP-side companion rule:** when MCP calls timeout, the TD-side operation may still execute on main thread (per Envoy 30s cap). Always verify final state via filesystem (e.g. `.toe` mtime for save) rather than trusting MCP response success or failure.

### `comp.allowCooking = False` — gate an entire subnetwork that's irrelevant this frame

**Source:** [docs.derivative.ca/OP_Class](https://docs.derivative.ca/OP_Class) | Page last edited: see wiki | **Confidence:** MEDIUM (Derivative wiki — verify in your TD version)

`comp.allowCooking = False` gates an entire subnetwork that's irrelevant this frame; re-enable when needed — cheaper than `bypass` on heavy COMPs because nothing inside the COMP cooks at all (vs. bypass which still resolves the cook graph and passes input through).

Cross-link: this is the Python-side lever for the pain documented above in § "Topology change + large cook = TD hangs — bypass during refactor". When the offending subnetwork is the whole COMP rather than a single op in a chain, `allowCooking = False` on the COMP is the wider hammer — useful for whole inactive scenes, off-screen UI panels, or staging subgraphs that should idle until needed.

```python
op('heavy_scene').allowCooking = False  # whole subnetwork stops cooking
# ... do work that no longer triggers heavy_scene cooks ...
op('heavy_scene').allowCooking = True   # re-enable when relevant again
```

**Check first when:**

- A whole COMP-worth of network is off-screen / inactive / staging and still eating cook budget
- Bypassing single ops inside the COMP isn't enough — the heavy work is internal cook-graph resolution
- Multi-scene apps where only one scene-COMP needs to cook at a time

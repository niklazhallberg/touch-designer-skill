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

# POPs (Point Operators) — default for point/geometry/particle work in TD 2025+

> **Trigger:** when the task involves points, particles, point clouds, scatter/instancing, or spline work, **check this file for the right POP BEFORE building SOP chains** — TD 2025 likely has a POP for it. Suggesting SOP→CHOP→instancing in TD 2025+ is generating 2022-era code.

---

## POPs are the correct default in TD 2025+

**Source:** [2025 Official Update](https://derivative.ca/community-post/2025-official-update/73153), [2025.31550 Official release notes](https://derivative.ca/release/202531550) | **Date:** October 30, 2025 (TD 2025 Official) | **Confidence:** HIGH

POPs (Point Operators) became **officially released in TD 2025 Official on October 30, 2025** (build 2025.31550) — the first new operator family added in over a decade. They run **entirely on GPU/VRAM**: data never leaves the GPU until render time. Fundamental architectural shift from SOPs (CPU-bound, data shuttled to/from CPU per frame).

**What POPs do that SOPs / TOPs-with-GLSL couldn't easily before:**
- Millions of points in real-time without writing custom GLSL
- Arbitrary user-defined point attributes (Houdini-style: position, normal, color, velocity, custom float/int/vector/arrays)
- Particle systems, point clouds, polygons, line strips, spline curves — all from one data model
- Per-point simulations (reaction diffusion, differential growth) patchable without shaders

**Default rule:** for any new point/particle/point-cloud/scatter work in TD 2025+, propose POPs first.

---

## What POPs replace vs don't replace

**MEDIUM confidence** — Derivative's own framing is "**re-think your patterns, not full replacement**"; keep that framing rather than asserting hard substitution.

### POPs replace

- **GPU-particle workflows** previously requiring `particlesGPU` + custom GLSL
- **SOP-heavy point clouds** where the CPU-side SOP→CHOP boundary was the bottleneck
- **Procedural scatter/distribution** patterns built as SOP→CHOP→instancing chains

### POPs do NOT replace

- **SOPs for modeling / boolean / volume operations** — POPs are point-data-on-GPU, not a modeling toolkit. Mesh boolean, lattice deformation, volume operations remain SOP territory.
- **Geometry COMP instancing** — POPs feed an existing Geometry COMP's instance source; there is **no new "POP-instancing-mode"** on Geometry COMP. Same instancing model, new data source.
- **Legacy `particlesGPU`** — coexists with POPs. New work uses POPs; existing networks using `particlesGPU` don't need migration.

---

## Operator vocabulary

> TD palette tags each POP as **Official** or **Experimental**. The "workhorses" — generators + core shaping — graduated to Official with the 2025.31550 release. Some advanced operators (e.g. ray-query in **GLSL Advanced POP**) remained Experimental and have Mac-specific limits (see § Mac platform support). **Verify the per-operator tag in your TD palette before relying on an Experimental POP in production.**

### Generators — produce a starting point set

Official (workhorses) as of 2025.31550. Reach for these first when you need points to exist.

- **Point Generator POP** — emit N points from scratch, parameter-controlled count
- **Grid POP** — structured 2D grid of points
- **Sphere POP** — points on a sphere surface
- **Box POP** — points on a box surface or interior
- **Line POP** — points along a line segment
- **Curve POP** — points along a curve/spline
- **File In POP** — load `.ply` and similar point-data files (this is how the Gaussian splat `RADON_Tree.ply` enters TD when a POP-based splat pipeline is used; cross-link `components/gaussian-splatting-mac.md`)
- **Alembic In POP** — load Alembic point caches

### Shaping / modification — transform an existing point set

Official (workhorses).

- **Attribute POP** — read/write point attributes (the central editor of the attribute system)
- **Math POP**, **Math Mix POP**, **Math Combine POP** — per-attribute arithmetic
- **Noise POP** — add noise to position or any attribute (one of the most-reached-for shaping POPs)
- **Lookup POP** — remap attribute values through a curve/table
- **Group POP** — select subsets of points by predicate, for downstream targeting
- **Sort POP** — reorder points (camera-space sort, attribute-based sort, etc.)
- **Random POP** — generate per-point random values
- **ReRange POP** — remap attribute ranges (analogous to `mathCHOP` fromrange/torange)
- **Transform POP** — translate/rotate/scale entire point sets
- **Limit POP** — clamp attribute values
- **Quantize POP**, **Normalize POP** — attribute conditioning

### Dynamics — time-evolving point behavior

- **Particle POP** — velocity-based simulation, life-cycle particles. *Status:* Experimental in early 2025 builds; verify in your palette.
- **Feedback POP** — POP-equivalent of `feedbackTOP`, for time-stepped simulation
- **Trail POP** — generate trail geometry from moving points

### GLSL POPs — custom compute when built-ins aren't enough

- **GLSL POP** — custom GLSL kernel operating on POP data; the escape hatch when shaping POPs can't express your operation
- **GLSL Advanced POP** — extended GLSL POP with additional features including ray-query. **Mac note:** ray-query does NOT work on Apple Silicon (no hardware ray tracing exposed to TD's path) — see § Mac platform support.

### Topology / flow control

- **Merge POP** — combine multiple POP streams
- **Select POP** — pick a specific POP from a chain
- **Cache POP** — cache POP data (useful for freezing expensive upstream)
- **Null POP** — passthrough naming anchor

### Attribute authoring

- **Attribute Create POP** (`attribcreatePOP`) — create new custom attributes
- **Attribute Blur POP** (`attribblurPOP`) — spatially propagate attribute values (used in Gaussian Splat color correction, etc.)

Full class reference: [docs.derivative.ca/POP_Class](https://docs.derivative.ca/POP_Class).

---

## Conversion bridges + canonical wiring

POPs are a new data family; bridges convert between POPs and the older TOP/CHOP/SOP/DAT families. **Use the conversion operators by their TD palette names** (query via `get_td_classes` or search the palette if uncertain — naming follows TD's conventional `<source>To<target>` pattern).

### Bridges that EXIST

- **SOP → POP** — convert a SOP's point data into a POP stream (use this when wrapping legacy modeling output into a POP pipeline)
- **CHOP → POP** — channels become per-point attribute values
- **DAT → POP** — table rows become point data
- **TOP → POP** — texture pixels become points (positions/colors/values from texture data)
- **POP → CHOP** — POP attributes become CHOP channels (this is how you READ POP data back to the CPU/parameter side without using `delayed=True` Python access)

### Bridge that does NOT exist

> **There is NO "POP to SOP" operator.** POPs are GPU-resident and never round-trip back to SOPs. To render POPs: feed a **Geometry COMP** (whose instance source is the POP), render via **Render TOP**. To read POP data into the older system: use **POP → CHOP**. **Don't waste time searching the palette for a `popToSop` operator — it doesn't exist.**

### Canonical rendering wiring

```
[POP chain] → [Geometry COMP] → [Render TOP]
                    ↑
            (instance source = your POP)
```

The Geometry COMP's existing instancing parameters point at the POP. No new "POP-mode" on Geometry COMP — same instancing UI you've used since TD 2019, new data source.

---

## The attribute system — mental model

POPs follow a **Houdini-style attribute model**. Each point carries arbitrary named attributes; operators read, write, and compose them.

### Built-in attributes (always present where meaningful)

| Attribute | Meaning | Components |
|---|---|---|
| **P** | Position | `Px`, `Py`, `Pz` |
| **Cd** | Color (diffuse) | `Cdr`, `Cdg`, `Cdb`, `Cda` |
| **N** | Normal | `Nx`, `Ny`, `Nz` |
| **Tex** | Texture coord | `Texu`, `Texv`, `Texw` |

Access individual components via the component-suffix index (`Px`, `Cdr`, etc.). Operators typically allow operating on the whole vector (e.g. on `P`) or specific components.

### Custom attributes

Authored via **Attribute Create POP** or the `attribcreatePOP` operator. Name freely (e.g. `Speed`, `Lifetime`, `Phase`).

### Type suffixes (when naming custom attributes)

POPs encode attribute type in the naming convention:

- **`f`** / **`F`** — float scalar / float array
- **`i`** / **`I`** — int scalar / int array
- **`u`** / **`U`** — uint scalar / uint array

Lowercase = single value per point; uppercase = array per point.

### Array attribute indexing

Arrays of values per point are accessed with index notation: **`MyArray_0_`** = element 0 of the `MyArray` array attribute on each point.

> **Known gap:** there is **no POP-inline-index-pattern-language** beyond name + scope. If you find yourself wanting Houdini-style `@P.y` expression syntax inside operators, that doesn't exist in TD POPs — work via per-component naming (`Py`) or full-vector operations.

---

## Rendering pipeline (deeper than the table above)

The full canonical POP→render path:

1. **POP chain** ends in a useful state (positions, colors, sizes, etc. authored as attributes)
2. **Geometry COMP** consumes the POP via its **Instance** parameter page — the POP is the instance source, attributes map to instance position/rotation/scale/color
3. **Render TOP** renders the Geometry COMP using whatever camera + lights + material setup you have
4. (If you need to read POP data back to CPU for parameter binding: insert **POP → CHOP** somewhere in the chain, then `selectCHOP` from there)

**Integration into the existing instancing model** is the key insight: POPs didn't introduce a new instancing UI on Geometry COMP. They became a new instance-source data shape. Everything else (camera setup, lights, MAT assignment, render TOP) works identically to non-POP rendering.

---

## Mac platform support

**Mac-relevant** | **Sources:** [Experimental 2025.30770 release notes](https://derivative.ca/release/experimental-202530770/72562), TD 2025 release-notes series | **Confidence:** HIGH

### Hardware

- **Apple Silicon (M1/M2/M3/M4):** safe, recommended. M1 Pro is safe.
- **Intel Macs with AMD GPUs:** **DO NOT USE POPs** — hard crash, potential driver corruption requiring system reboot.

### Apple Silicon limits (from TD docs, cross-reference `mac-gotchas.md`)

- **No double-precision attributes on macOS.** Attributes that would be `double` on other platforms fall back to single-precision float on Apple Silicon. If a calculation needs double precision, POPs won't deliver it on M1+.
- **No hardware ray tracing.** TD's Apple Silicon GPU path does not expose hardware ray tracing → **GLSL Advanced POP's ray-query feature does not work on M1+**. Fall back to single-precision float and CPU-side / shader-side intersection math.
- **Early-2025-build POP example issues** existed on macOS (DMX POP examples, some viewer display modes). Mostly resolved by 2025.32820 — check release notes if a specific POP behaves oddly.

See also `mac-gotchas.md` § "POPs crash Intel Macs" and § "MoltenVK regressions can halve FPS".

---

## TD 2025.32820 — Python access functions with `delayed=True`

**Source:** [2025.32820 release notes](https://derivative.ca/release/202532820/74545) | **Date:** May 6, 2026 | **Confidence:** HIGH

Build 2025.32820 added `.point()`, `.prim()`, `.vert()` Python access functions to POP operators. **Use `delayed=True` to avoid GPU/CPU sync stalls** when accessing POP data from Python.

```python
# Safe — non-blocking, returns when GPU has the data
n = pop_op.numPoints(delayed=True)
bounds = pop_op.bounds(delayed=True)

# Blocking — downloads from GPU, stalls the cook
pts = pop_op.points('P')  # synchronous; expensive in tight loops
```

**Rule:** when reading POP attributes from Python during normal cook flow, default to `delayed=True`. Reserve synchronous reads for one-off inspection or when you genuinely need the value before the next operation.

Other 2025.32820 POP additions (informational):
- Array attribute iteration via `name[:]` syntax across Math, Limit, ReRange, Lookup, Quantize, Normalize, Random, Noise POPs
- Math Mix and Math Combine POP inline block summaries (readability improvement only)

---

## Debugging POPs

When a POP chain doesn't produce what you expect, three diagnostic tools — in this order:

### 1. **Info CHOP** wired to the POP

Drop an **Info CHOP** with the POP as its source. Channels exposed:

- **`total_cooks`** — has this POP actually cooked? (zero means it's bypassed or upstream-broken)
- **`cook_time`** — per-cook ms, identifies hotspot POPs in the chain
- **`errors`** — error count
- **`warnings`** — warning count

**Rule:** before guessing why a POP chain looks wrong, drop an Info CHOP and check that the POP is actually cooking. Lots of "broken" POP chains are simply not getting evaluated because nothing downstream demands them.

### 2. **Delete Input Attributes** — isolate

To isolate which upstream POP is the source of a bad attribute value, insert temporary Delete Input Attributes (via Attribute POP delete-mode or similar) to strip attributes one at a time and see what the downstream POP renders with vs without each input. Reduces the chain to a minimum reproducible failure.

### 3. **OP Snippets** — Derivative's example library

Open `Help → OP Snippets` for example .toe files using each POP. When in doubt about exact parameter behavior or expected output, snippets are the authoritative living reference — more current than secondhand tutorials.

> **Known gap:** **exact GLSL POP binding syntax** (how input attributes are exposed as shader uniforms, the shader's main() signature for POP context) — **check OP Snippets, don't guess**. Don't write speculative GLSL POP code without confirming the binding pattern from an example.

---

## Known gaps (deliberately empty here)

These are publicly unresolvable as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md` § "Pre-ask filters"):

| Gap | Where it surfaces |
|---|---|
| **POP performance benchmarks on M1 Pro** specifically (point counts before frame budget collapses) | First time you push N to its limit in real work |
| **Full MoltenVK / Apple Silicon POP bug list** beyond no-double-precision and no-ray-tracing | First time a POP misbehaves on Mac in a way other docs don't predict |
| **Exact GLSL POP binding syntax** (uniform layout, attribute IO) | When you actually write a GLSL POP — use OP Snippets as ground truth |
| **POP-inline-index-pattern-language** (does NOT exist; this gap is "confirmed empty") | Don't go looking for Houdini-style `@P.y` syntax — it's not there. Use component naming. |
| **Particle POP collision** (does built-in collision exist, or is it GLSL POP territory?) | When you actually need collision in a particle sim |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

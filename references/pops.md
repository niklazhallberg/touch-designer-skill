# POPs (Point Operators) — default for point/geometry/particle work in TD 2025+

> **Trigger:** when the task involves points, particles, point clouds, scatter/instancing, or spline work, **check this file for the right POP BEFORE building SOP chains** — TD 2025 likely has a POP for it. Suggesting SOP→CHOP→instancing in TD 2025+ is generating 2022-era code.

---

## Contents

This file is ~660 lines. Jump to the section you need:

- [POPs are the correct default in TD 2025+](#pops-are-the-correct-default-in-td-2025) — the "why POPs"
- [What POPs replace vs don't replace](#what-pops-replace-vs-dont-replace) — what NOT to retire
- [Build delta — POP additions across the 2025 series](#build-delta--pop-additions-across-the-2025-series) — per-build POP additions
- [Operator vocabulary](#operator-vocabulary) — Generators, Shaping, Line/curve, Dynamics, Copy/scatter, GLSL, Bridges, Experimental, Workhorses
- [Conversion bridges + canonical wiring](#conversion-bridges--canonical-wiring) — SOP/CHOP/DAT/TOP ↔ POP
- [The attribute system — mental model](#the-attribute-system--mental-model) — points / vertices / primitives, built-ins, custom
- [Index pattern matching — POP grammar](#index-pattern-matching--pop-grammar) — `[3-15]`, `^[100-200]`, etc.
- [Map-pages — per-point parametric without shaders](#map-pages--per-point-parametric-control-without-shaders) — before reaching for GLSL POP
- [Rendering pipeline (deeper)](#rendering-pipeline-deeper-than-the-table-above) — Geometry COMP, render flags, scatter vs instancing
- [Line and curve workflows](#line-and-curve-workflows--first-class-pop-territory) — Line / Curve / Trail POPs
- [Particle systems — open feedback chain](#particle-systems--open-feedback-chain-not-a-closed-solver) — explicit architecture, not closed solver
- [Production patterns from practitioners](#production-patterns-from-practitioners) — relational nets, audio-reactive POP chain, data-viz canonical paths
- [GLSL POP in practice](#glsl-pop-in-practice--ssbos-initialization-thread-model) — SSBO model, Initialize Output Attributes
- [Mac platform support](#mac-platform-support) — Apple Silicon vs Intel; no double-precision, no ray tracing
- [TD 2025.32820 — Python access functions](#td-202532820--python-access-functions-with-delayedtrue) — `.point()`/`.prim()`/`.vert()` with `delayed=True`
- [Debugging POPs](#debugging-pops) — Info CHOP, viewer overlays, POP to DAT, GLSL POP errors
- [Known gaps (deliberately empty)](#known-gaps-deliberately-empty) — what's NOT in here yet

---

## POPs are the correct default in TD 2025+

**Source:** [2025 Official Update](https://derivative.ca/community-post/2025-official-update/73153), [2025.31550 Official release notes](https://derivative.ca/release/202531550) | **Date:** October 30, 2025 (TD 2025 Official) | **Confidence:** HIGH

POPs (Point Operators) became **officially released in TD 2025 Official on October 30, 2025** (build 2025.31550) — the first new operator family added in over a decade. They run **entirely on GPU/VRAM**: data never leaves the GPU until render time. Fundamental architectural shift from SOPs (CPU-bound, data shuttled to/from CPU per frame).

**What POPs do that SOPs / TOPs-with-GLSL couldn't easily before:**
- Millions of points in real-time without writing custom GLSL
- Arbitrary user-defined point attributes (Houdini-style: position, normal, color, velocity, custom float/int/vector/arrays/matrices)
- Particle systems, point clouds, polygons, line strips, spline curves — all from one data model
- Per-point simulations (reaction diffusion, differential growth) patchable without shaders
- Direct rendering from `Geometry COMP` — no SOP roundtrip needed

**Default rule:** for any new point/particle/point-cloud/scatter work in TD 2025+, propose POPs first.

---

## What POPs replace vs don't replace

**MEDIUM confidence** — Derivative's own framing is "**re-think your patterns, not full replacement**"; keep that framing rather than asserting hard substitution.

### POPs replace

- **GPU-particle workflows** previously requiring `particlesGPU` + custom GLSL
- **SOP-heavy point clouds** where the CPU-side SOP→CHOP boundary was the bottleneck
- **Procedural scatter/distribution** patterns built as SOP→CHOP→instancing chains
- **Line/curve work** as a workspace (`Line POP` + family) rather than just an export format

### POPs do NOT replace

- **SOPs for modeling / boolean / volume operations** — POPs are point-data-on-GPU, not a modeling toolkit. Mesh boolean, lattice deformation, volume operations remain SOP territory.
- **Legacy `particlesGPU`** — coexists with POPs. New work uses POPs; existing networks using `particlesGPU` don't need migration.

### Geometry COMP instancing — partial doc gap

The official `Geometry COMP` help describes POPs as the **rendered geometry** source — that path is well-documented. The older `COMP Instance Page` / `Instance` docs, however, still describe CHOP/DAT/TOP/SOP as instance data sources and don't formally cover POP-as-instance-source.

A 2026-01 forum bug report ([forum thread](https://forum.derivative.ca/t/crash-when-activating-geo-comp-viewer-with-a-broken-glsl-pop-in-instancing-chain/)) confirms **direct POP-as-instance-source works in practice** but docs are lagging.

**Practical rule:**
- For POP-rendered geometry: use `Geometry COMP` with the POP inside (well-documented path).
- For POP-native scatter "one mesh per point": use **`Copy POP`** or **`GLSL Copy POP`** (the documented POP-native scatter path).
- For legacy `Instance` page-based pipelines on `Geometry COMP`: bridge via `POP→CHOP`, `POP→TOP`, or `POP→SOP` if you need the documented path. Direct POP-as-instance-source exists but is forum-evidenced, not docs-evidenced.

---

## Build delta — POP additions across the 2025 series

**Confidence:** HIGH (release notes)

Quick reference for which POP feature shipped when. Useful when diagnosing "my training data doesn't know about this":

| Build | Date | Notable POP additions |
|---|---|---|
| **2025.30770** experimental | 2025-08-09 | `Line Resample POP`, `Plane POP`, `ZED POP`. Mac-AMD crash warnings still active. |
| **2025.31310** experimental | 2025-10-08 | `Alembic In POP`, `File Out POP`. Intel-Mac support restored; AMD crash/corrupt-output fix; macOS "too many attributes" fix. |
| **2025.31550** Official | 2025-10-30 | POPs become first-class in Official; new index-pattern syntax is mandatory for POPs. |
| **2025.32820** Official | 2026-05-06 | `name[:]` array iteration across Math/Limit/ReRange/Lookup/Quantize/Normalize/Random/Noise POPs. `.point()/.prim()/.vert()` Python access with `delayed=True`. |

---

## Operator vocabulary

> TD's palette tags each POP as **Official** or **Experimental**. The "workhorses" — generators + core shaping + bridges — are all Official as of 2025.31550. **Verify the per-operator tag in your TD palette before relying on an Experimental POP in production.**

### Generators — produce a starting point set

Official. Reach for these first when you need points to exist.

- **Point Generator POP** — emit N points from scratch, parameter-controlled count
- **Point POP** — single-point primitive
- **Box POP**, **Sphere POP**, **Torus POP**, **Tube POP**, **Circle POP**, **Rectangle POP**, **Plane POP**, **Primitive POP** — canonical geometry generators
- **Grid POP** — structured 2D grid of points
- **Line POP**, **Curve POP** — line strips with multiple interpolation modes (including splines); see § "Line and curve workflows"
- **Revolve POP** — rotational surfaces
- **Pattern POP** — parameter-driven patterned point distributions (used in Vernetti's senior point-cloud patches)
- **Sprinkle POP** — random scatter generator
- **Polygonize POP** — polygonal output
- **File In POP** — load `.ply` and similar point-data files (this is how `RADON_Tree.ply` enters TD when a POP-based splat pipeline is used; cross-link `components/gaussian-splatting-mac.md`)
- **Point File In POP** — point-specific file loading
- **Alembic In POP** — load Alembic caches (added 2025.31310)
- **Import Select POP** — select from imported data
- **OAK Select POP**, **ZED POP** — depth-camera/sensor sources

### Shaping / modification — transform existing point data

Official workhorses.

- **Attribute POP** — central editor of the attribute system: create / read / write / delete attributes
- **Attribute Combine POP** — combine attributes across points
- **Attribute Convert POP** — type conversion (float ↔ int ↔ vector etc.)
- **Math POP**, **Math Mix POP**, **Math Combine POP** — per-attribute arithmetic
- **Random POP** — generate per-point random values
- **Noise POP** — add noise to position or any attribute (one of the most-reached-for shaping POPs)
- **Transform POP** — translate/rotate/scale entire point sets
- **Projection POP** — coordinate-system projection (used in Vernetti's point-cloud workflow)
- **Normal POP**, **Normalize POP** — normal handling and vector normalization
- **Quantize POP**, **ReRange POP**, **Limit POP** — attribute conditioning (clamp, remap, snap)
- **Lookup POP**, **Lookup Attribute POP**, **Lookup Channel POP**, **Lookup Texture POP** — remap via curves / tables / channels / textures
- **Trig POP** — trigonometric attribute transforms
- **Twist POP**, **Facet POP** — geometric deformation
- **Connectivity POP**, **Neighbor POP** — relational queries between points (Neighbor produces the array attribute `Nebr`)
- **Proximity POP** — spatial proximity queries (used in Vernetti's relational-net workflow)
- **Ray POP** — ray-cast queries
- **Group POP** — define groups for downstream targeting
- **Select POP**, **Sort POP**, **Delete POP**, **Merge POP**, **Switch POP**, **Blend POP** — flow control + composition
- **Convert POP** — POP-internal type/family conversion
- **Subdivide POP** — increase point density
- **Trail POP** — generate trail geometry from moving points
- **Cache POP**, **Cache Blend POP**, **Cache Select POP** — caching (useful for freezing expensive upstream)
- **Field POP** — field-based sampling
- **Skin POP**, **Skin Deform POP** — surface skinning
- **Texture Map POP** — texture-coordinate authoring
- **Null POP** — passthrough naming anchor

### Line/curve specialized

- **Line Divide POP**, **Line Resample POP** (2025.30770), **Line Smooth POP**, **Line Break POP**, **Line Metrics POP** — work directly on line-strip geometry inside POPs without leaving for SOPs

### Dynamics — time-evolving point behavior

- **Particle POP** — velocity-based simulation; **architecture is an open feedback chain, not a closed solver**. See § "Particle systems — open feedback chain".
- **Force Radial POP** — radial force field; writes the `PartForce` attribute consumed by `Particle POP`
- **Feedback POP** — POP-equivalent of `feedbackTOP` for time-stepped simulation. **Critical:** older builds (pre-2025.31310) had disconnect/feedback crashes (TD-verified bug, [forum 2025-09-22](https://forum.derivative.ca/t/pops-touchdesigner-freezes-when-i-disconnect/)); fixed in subsequent builds.
- **Trail POP** — point trails over time (note: also listed under shaping; trail is dynamic in practice)

### Copy / scatter — POP-native instancing

This is the documented POP-native way to "one geometry per point", separate from the legacy `Geometry COMP` instance page.

- **Copy POP** — make copies of input geo, count-based or template-input-based. When a template input is connected, the **count equals the number of points in the template**.
- **GLSL Copy POP** — same, but run a per-copy GLSL compute kernel over points/verts/prims of each copy. Use when copies need per-instance attribute computation.

### GLSL / custom-compute

- **GLSL POP** — basic compute over a chosen attribute class (points / verts / prims). Cannot change element count. **Unique feature vs GLSL Advanced:** can run multiple passes in a single node.
- **GLSL Advanced POP** — read and write point + vertex + primitive attributes simultaneously in a single dispatch. **Use this when authoring or reshaping geometry on GPU**, not basic `GLSL POP`.
- **Topology POP** — describe geometry from buffers produced by `GLSL Advanced POP`; pairs with Advanced for "author/reshape structure on GPU" workflows.
- **GLSL Copy POP**, **GLSL Select POP** — purpose-built GLSL variants.
- **CPlusPlus POP** — C++ escape hatch.
- **⚠️ `GLSL Create POP` is deprecated.** Per its own docs, use `GLSL Advanced POP` with (or without) `Topology POP` instead.

### Bridges to/from other operator families

See § "Conversion bridges + canonical wiring" below.

### Currently Experimental (lower-trust, verify in your palette)

As of 2025-10-28 ([Category:POPs](https://docs.derivative.ca/Category:POPs)):

- `Experimental:Alembic Out POP`
- `Experimental:Extrude POP`
- `Experimental:Line Thick POP`
- `Experimental:Phaser POP`
- `Experimental:Text POP`
- `Experimental:Trace POP`
- `Experimental:Triangulate POP`

**Rule:** treat these as lower-trust until they graduate. Their parameter surface, performance characteristics, and stability are subject to change. Don't rely on them for shipping installations without explicit verification.

### What practitioners actually reach for (workhorse subset)

**MEDIUM confidence** — distilled from Darien Brito's POPGuide, Gianmaria Vernetti's tutorials, and the 2025 release-notes pattern. The recurring "everyday vocabulary" in real production patches:

`Attribute`, `Math Mix`, `Math Combine`, `Random`, `Noise`, `Transform`, `Group`, `Delete`, `Select`, `Merge`, `Switch`, `Proximity`, `Neighbor`, `Ray`, `Copy` / `GLSL Copy`, `Feedback`, `Particle`, `Convert`, `Topology`, plus the bridges to CHOP/TOP/DAT/SOP.

If you're sketching a new POP network and unsure which operator to reach for first, this set covers 80% of production patches.

Full class reference: [docs.derivative.ca/Category:POPs](https://docs.derivative.ca/Category:POPs).

---

## Conversion bridges + canonical wiring

POPs are a new data family; bridges convert between POPs and the older TOP/CHOP/SOP/DAT families. **Confidence:** HIGH (all bridges have dedicated docs pages).

### Bridges that EXIST (with documented semantic translations)

| Bridge | Direction | Key semantics |
|---|---|---|
| **`SOP to POP`** | SOP → POP | Translates: `uv` → `Tex`, `Cd` → `Color`, `width` → `LineWidth`, `pscale` → `PointScale`. Does NOT preserve mesh dimension automatically — use **`Dimension POP`** downstream if that info needs to survive. |
| **`CHOP to POP`** | CHOP → POP | One point per sample. With **"Precise names"** sample mode, channel names round-trip exactly through `POP to CHOP`. |
| **`DAT to POP`** | DAT → POP | Table rows become points. Supports array attribute patterns like `MyArray[0]` or `Abc_0_`. **Bug as of 2026-04:** doesn't tolerate empty headers during dynamic state changes — keep at least one header row alive until the [reported fix](https://forum.derivative.ca/t/run-out-of-gpu-memory-error-crash/) ships. |
| **`TOP to POP`** | TOP → POP | Texture pixels become points. Channel-scope per input TOP maps to attribute-scope on the resulting POP. |
| **`POP to CHOP`** | POP → CHOP | Read POP attributes back as CHOP channels (the CPU-side read path without using Python). |
| **`POP to TOP`** | POP → TOP | Write POP attributes into a texture (useful for instancing TOPs or visualizers). |
| **`POP to SOP`** | POP → SOP | "Next frame (Fast)" vs "Immediate (Slow)" — pick Fast for normal flows, Slow only when you genuinely need same-frame SOP data. |
| **`POP to DAT`** | POP → DAT | CPU inspection of POP attributes. Same "Next frame (Fast)" vs "Immediate (Slow)" trade-off. Primary debugging tool — see § "Debugging POPs". |

### Bridge that does NOT exist

> **There is NO direct "POP to SOP-render" rule that auto-creates a SOP — but `POP to SOP` (above) DOES exist as a data bridge.** What does NOT exist is a free implicit conversion: POPs render natively from `Geometry COMP`, never as SOPs in a Render path. **Don't search the palette for a "render POPs as SOPs" operator — the workflow is `POP inside Geometry COMP → Render TOP`, full stop.**

### Canonical rendering wiring

```
[POP chain inside Geometry COMP] → Render TOP
       ↑
   (with render flag on)
```

`Geometry COMP` says explicitly: "POPs with render flag on are rendered by Render TOP. Multiple POPs can be rendered simultaneously in the same Geo." Per-point attributes drive rendering at two levels — see § "Rendering pipeline".

---

## The attribute system — mental model

POPs follow a **Houdini-style attribute model**, but with one important refinement: there are **three separate attribute classes**, each with its own attribute list.

### Three classes (the central mental model)

- **Points** — per-point attributes (the most common)
- **Vertices** — per-vertex attributes (for geometry that has verts, e.g. polygons)
- **Primitives** — per-primitive attributes (for line strips, polygons, point primitives)

A single POP can carry attributes on all three classes simultaneously. Most operators work on a chosen class; `GLSL Advanced POP` is the one that reads/writes across all three in a single dispatch.

### Built-in attributes (always present where meaningful)

| Attribute | Class | Meaning | Components |
|---|---|---|---|
| **P** | Point | Position | `Px`, `Py`, `Pz` |
| **Color** | Point | Color (Cd in SOP terms) | `Colorr`, `Colorg`, `Colorb`, `Colora` |
| **N** | Point | Normal | `Nx`, `Ny`, `Nz` |
| **Tex** | Point | Texture coord | `Texu`, `Texv`, `Texw` |
| **LineWidth** | Primitive | Line thickness | scalar |
| **PointScale** | Point | Per-point scale | scalar |

### Automatically generated attributes (operator-specific)

Some operators emit reserved attributes that downstream POPs consume:

- **`Particle POP`** uses/produces `PartVel`, `PartMass`, `PartLifeSpan`, and consumes `PartForce` in feedback
- **`Force Radial POP`** writes `PartForce` (consumed by `Particle POP`)
- **`Neighbor POP`** produces the array attribute `Nebr` (indices of neighboring points)

These are the POP-equivalent of "operator state that used to be hidden inside the node" in older operator families. They're visible attributes you can read, manipulate, and route.

### Custom attributes

Authored via **`Attribute POP`** or **`Attribute Create POP`**. Name freely (e.g. `Speed`, `Lifetime`, `Phase`).

### Types

Per [Attribute POP docs](https://docs.derivative.ca/Attribute_POP):
- Float / int / uint / double, 1–4 components
- **Array attributes** with arbitrary length
- **Matrix attributes**

**2025.32820 shift:** array attributes now support iteration syntax `name[:]` across `Math`, `Limit`, `ReRange`, `Lookup`, `Quantize`, `Normalize`, `Random`, `Noise` POPs. Before 32820, array attributes were practically GLSL-POP-only.

### Array attribute indexing

Two access patterns depending on source:

- **`MyArray[0]`** — standard syntax for direct element access
- **`Abc_0_`** — alternative naming for sources that don't tolerate brackets

### Type suffixes (informal naming convention)

POPs encode attribute type in custom-attribute naming:

- **`f`** / **`F`** — float scalar / float array
- **`i`** / **`I`** — int scalar / int array
- **`u`** / **`U`** — uint scalar / uint array

Lowercase = single value per point; uppercase = array per point.

### Points without primitives

Per [Points, Vertices and Primitives in POPs](https://docs.derivative.ca/Points,_Vertices_and_Primitives_in_POPs): **a POP can have a point list with no primitive class — these points don't render, but are useful as template / copy / instancing data.**

This is a production-critical distinction. Don't think only "do I have `P`?", think "do I have a renderable primitive class, or just data?".

---

## Index pattern matching — POP grammar

**Source:** [Pattern Matching](https://docs.derivative.ca/Pattern_Matching), [Pattern Matching Support](https://docs.derivative.ca/Pattern_Matching_Support), [2025.31550 release notes](https://derivative.ca/release/202531550) | **Confidence:** HIGH

TD 2025 introduced a new pattern-matching system. **POPs exclusively use the new system** — old patterns from pre-2025 don't apply here.

### Core index-pattern syntax

| Pattern | Meaning |
|---|---|
| `[3-15]` | Indices 3 through 15 (inclusive) |
| `^[100-200]` | NOT in 100-200 (negation) |
| `[0-15:2]` | Indices 0 to 15, every 2nd (step) |
| `[0-15:2:5]` | Indices 0 to 15, every 2nd starting at 5 |
| `[*:3]` | All, every 3rd |

This is **core POP grammar**, not a niche feature. Build pipelines assuming this syntax is available.

### Which POP parameters accept index/operator patterns

Per [Pattern Matching Support](https://docs.derivative.ca/Pattern_Matching_Support), index or operator patterns are supported on:

- **`Delete POP`** — delete by index pattern
- **`Group POP`** — define groups by pattern
- **`Primitive POP`** — primitive-class operations by pattern
- **`Switch POP`** — switch input by pattern
- **`GLSL POP`** and **`GLSL Advanced POP`** — scoping the compute dispatch
- **`Merge POP`** — input selection
- **`Attribute Combine POP`** — attribute scoping

**Rule:** when an operation needs "the first 100 points" or "every other point" or "all except 5–10", use the index pattern. Don't loop in Python, don't manually compute a group attribute — the syntax does it natively.

> **What does NOT exist:** Houdini-style inline attribute expressions like `@P.y > 0` inside operators. TD POPs have a powerful *index* pattern language but no per-point *predicate* expression language. For attribute-value-based filtering, use `Math POP` or `Group POP` with attribute conditions, or use `GLSL POP` for genuinely expressive predicates.

---

## Map-pages — per-point parametric control without shaders

**Source:** [Mapping POP Attributes to Parameters](https://docs.derivative.ca/Mapping_POP_Attributes_to_Parameters) (last edited 2026-04-20) | **Confidence:** HIGH

A growing set of POP operators expose a **Map page** that allows binding per-point attributes to per-point parameter values. This means more operators become "per-point parametric" without needing a custom GLSL POP.

**Example pattern:**
- `Particle POP` exposes a Map page where `PartVel`, `PartMass`, `PartLifeSpan` can be driven by input attributes instead of fixed parameters.
- `Force Radial POP` similarly can be parameterized per-point.

**Rule:** before reaching for `GLSL POP` to "vary parameter X per point", check the operator's Map page. If the operator exposes a Map binding for that parameter, the no-shader path exists.

---

## Rendering pipeline (deeper than the table above)

The full canonical POP → render path:

```
[POP chain inside Geometry COMP] → Render TOP
       │
       ├──── POP-native rendering: P/Color/N/Tex drive the visible geometry directly
       └──── Material-side: glslMAT reads custom POP attributes via TDAttrib_*()
```

### Two levels of per-point-attribute rendering

**Level 1 — POP-native geometry.** Modify `P`, `Color`, `N`, `Tex`, etc. on the POP, and `Render TOP` renders that geometry directly. No material work needed for the basic attributes.

**Level 2 — Material-side via `glslMAT`.** Per [Write a GLSL MAT](https://docs.derivative.ca/Write_a_GLSL_MAT), custom POP attributes can be declared on the material's Attributes page and accessed via `TDAttrib_AttribName()` in the shader. The Buffers page provides direct SSBO-style access to arbitrary POP attributes. Use this when the vertex/pixel shader needs to read POP data beyond what the renderable POP geometry exposes.

### Render-flag semantics

`Geometry COMP` says: **POPs with the render flag on are rendered by `Render TOP`. Multiple POPs can be rendered simultaneously in the same Geo.** So a single Geo COMP can contain a chain of POPs where 2+ are flagged for render — they all render in one pass.

### POP-native scatter vs legacy instancing

- **POP-native scatter** ("one mesh per point"): use **`Copy POP`** or **`GLSL Copy POP`**. When the template input is connected, the number of copies equals the number of points in the template.
- **Legacy `Geometry COMP` Instance page** ("one mesh per instance from instance-data source"): still works with CHOP/DAT/TOP/SOP sources per the official docs. **POP-as-direct-instance-source works in practice** (forum 2026-01-05/06) but documentation has not caught up — for pipeline-critical work, bridge via `POP to CHOP` if you need the documented path.

---

## Line and curve workflows — first-class POP territory

**Source:** [Line POP](https://docs.derivative.ca/Line_POP), [Experimental 2025.30770 release notes](https://derivative.ca/release/experimental-202530770/72562) | **Confidence:** HIGH

Line and curve work in TD 2025+ is not a SOP-detour problem — it's first-class POP territory.

- **`Line POP`** generates line strips with multiple interpolation methods including spline forms; per-point attributes supported
- **`Curve POP`** for curve-specific generation
- **`Line Divide POP`**, **`Line Resample POP`** (added 2025.30770), **`Line Smooth POP`**, **`Line Break POP`**, **`Line Metrics POP`** — operate directly on line geometry
- **`Trail POP`** — trail geometry from moving points (closes the loop with `Particle POP` for ribbon trails)

**Rule:** for guide-line / relational-net / sketchy-line visuals, **stay in POPs from generation to render**. Don't detour through SOPs for curve manipulation — TD 2025 has the operators.

---

## Particle systems — open feedback chain (not a closed solver)

**Source:** [Particle POP docs](https://docs.derivative.ca/Particle_POP), [Force Radial POP docs](https://docs.derivative.ca/Force_Radial_POP) | **Confidence:** HIGH

The TD 2025 particle architecture is **fundamentally different from a closed "particle solver" black box**. It's an open feedback chain where every step is a visible POP.

### Canonical architecture

```
[Initial-position POP] → [Particle POP] → [Force Radial POP / other modifiers] → [Null POP]
                              ↑                                                       │
                              └─────────── Feedback target ───────────────────────────┘
```

- **`Particle POP`** outputs current state (positions + `PartVel` + `PartMass` + `PartLifeSpan` etc.)
- Modifier POPs (`Force Radial POP`, custom `GLSL POP`, etc.) update state — `Force Radial POP` writes `PartForce`
- **`Null POP`** at the end is the feedback target — `Particle POP` reads from it on the next frame
- Initial position comes from the input `P` attribute
- `PartVel` / `PartMass` / `PartLifeSpan` can come from parameters OR from input attributes via the Map page (see § "Map-pages")

### What changes for the designer

Instead of "configure a solver and trust the black box", you **compose solver logic as visible nodes around the feedback loop**. Want a custom force field? Drop a custom `GLSL POP` (or another `Force Radial POP` with a custom Map binding) into the chain. The system is open and editable end-to-end.

**Rule:** when a user wants "particles", build the open feedback chain explicitly. Don't search for a single all-in-one particle operator — that's not the TD 2025 pattern.

---

## Production patterns from practitioners

**MEDIUM confidence** — these are recurring patterns from named practitioners (primarily Gianmaria Vernetti's II HQ articles, May 2026), not Derivative docs. The operators are docs-verified individually; the *combinations* into a workflow are practitioner-derived recipes.

### Relational point networks — dynamic textures from spatial relationships

**Source:** [Gianmaria Vernetti — Creative Uses of POPs in TouchDesigner](https://interactiveimmersive.io/blog/touchdesigner-tutorials/creative-uses-of-pops-in-touchdesigner/) (II HQ, 2026-05-14)

For evolving point textures and relational visual structures, four operators carry most of the load:

- **Connectivity POP** — group points by topological connectivity
- **Neighbor POP** — for each point, find K nearest points; produces the array attribute `Nebr` (indices of neighbors)
- **Ray POP** — cast rays from points against triangles/quads (provided as input 2); useful for projection / surface-attachment / line-of-sight queries
- **Proximity POP** — connect points within a near/far distance threshold

**Canonical combination:**

```
[Point Generator] → [Attribute POP: custom attrs] → [Random / Noise: variation]
                            │
                            ↓
                  [Proximity / Neighbor: relationships]
                            │
                            ↓
                  [Math Combine: blend attribute streams]
                            │
                            ↓
                  [Cache POP: freeze expensive upstream]
                            │
                            ↓
                  [Geometry COMP → Render TOP]
```

For surface-projection patterns specifically: use **`Ray POP`** with a target SOP (converted via `SOP to POP`) as input 2 — points project onto the target surface along their ray direction.

### Audio-reactive POP chain — band magnitudes drive POP parameters

**Source:** Gianmaria Vernetti II HQ tutorials | **Cross-link:** `audio-reactive.md`

Canonical wiring for audio-reactive point/particle visuals:

```
[Audio Device In CHOP, frames mode] → [Audio Spectrum CHOP]
                                              │
                                              ↓
                                  [Math: low/mid/high band averages]
                                              │
                                              ↓
                                  [Lag CHOP: asymmetric, 5-30 ms attack / 150-500 ms release]
                                              │
                                              ↓
                                  [Resample CHOP: audio rate → cook rate]
                                              │
                                              ↓
                                  [CHOP to POP]  OR  [bind via Map page directly]
                                              │
                                              ↓
                                  [POP chain — band drives parameter per-point via Map page]
                                              │
                                              ↓
                                  [Geometry COMP → Render TOP]
                                              │
                                              ↓
                                  [Blur TOP → bloom-equivalent → composite]
```

Three load-bearing decisions in this chain:

1. **Map page binds band → POP parameter** (§ "Map-pages") so the agent doesn't need a custom GLSL POP for per-point audio response.
2. **Asymmetric smoothing in `Lag CHOP`** (attack < release) prevents jitter while preserving beat impact — the "liquid" feel cross-referenced in `audio-reactive.md`.
3. **Post-processing (`Blur TOP` → bloom → composite) is where atmosphere lives** — POPs deliver structure, TOPs deliver finish. Don't try to make POPs alone produce "ethereal/cinematic" — they're geometry; the look comes from compositing on top.

Full audio-reactive details: `audio-reactive.md`.

### Data visualization from external sources

**Source:** Gianmaria Vernetti II HQ tutorials

For loading external 3D / point data into POPs:

| Data source | Path |
|---|---|
| `.ply` point cloud (Gaussian splat, scanned cloud) | **`Point File In POP`** direct → POP chain |
| 3D mesh (`.fbx`, `.obj`) | `File In SOP` → `SOP to POP` → POP chain |
| Tabular CSV (numerical columns) | `Table DAT` → `DAT to CHOP` → `Math` / `ReRange CHOP` (normalize) → `CHOP to POP` |
| Real-time sensor (OAK / ZED depth camera) | `OAK Select POP` / `ZED POP` direct → POP chain |

**For visualization output:** the loaded points feed either a particle system (`Particle POP` with light initial velocity for "drift" feel) or a connectivity network (`Proximity POP` + `Line POP`-generated connections) depending on data shape.

**Rule of thumb:**
- Tabular numerical data → CHOP-then-POP (normalize in CHOP-land first)
- 3D point clouds with built-in attributes (`.ply` etc.) → `Point File In POP` direct
- Mesh geometry → `SOP to POP` with `Dimension POP` if mesh dimension matters downstream

---

## GLSL POP in practice — SSBOs, initialization, thread model

**Source:** [Write a GLSL POP](https://docs.derivative.ca/Write_a_GLSL_POP), [GLSL POP docs](https://docs.derivative.ca/GLSL_POP), [GLSL Advanced POP](https://docs.derivative.ca/GLSL_Advanced_POP), [Topology POP](https://docs.derivative.ca/Topology_POP) | **Confidence:** HIGH

### Execution model

- **One thread per element** (point / vert / prim, depending on chosen attribute class). Conceptually identical to a compute dispatch over a 1D index range.
- **Each attribute is an SSBO** (shader storage buffer object). Input attributes from all inputs are automatically readable; you choose which output attributes to allocate for writing.

### Basic `GLSL POP` vs `GLSL Advanced POP`

| Operator | Attribute classes | Element count | Unique feature |
|---|---|---|---|
| **`GLSL POP`** | One class per node (points OR verts OR prims) | Cannot change | Can run **multiple passes in a single node** |
| **`GLSL Advanced POP`** | All three classes simultaneously in one dispatch | Can author/reshape (pair with `Topology POP`) | Geometry creation / structural reshape |

**Rule:**
- Mutating existing data → basic **`GLSL POP`** (consider its multi-pass feature)
- Authoring / restructuring geometry on GPU → **`GLSL Advanced POP`** with (or without) **`Topology POP`**

### Cross-class attribute access in GLSL

When inside a basic `GLSL POP` working on (e.g.) the point class:

- **`TDIn_Attrib()`** — reads from the current class (point)
- **`TDInVert_Attrib()`** — reads from the vertex class
- **`TDInPrim_Attrib()`** — reads from the primitive class

This lets a point-class compute pass read vertex- or primitive-level attributes for context without leaving the operator.

### Initialization is the #1 crash source

**Critical:** output attributes are uninitialized unless either (a) you write every value yourself, or (b) you enable the operator's **"Initialize Output Attributes"** setting (which performs a copy/default-init first).

Reading uninitialized output values in downstream POPs produces **undefined behavior including crashes**.

**Rule:** when authoring a `GLSL POP`, default to enabling Initialize Output Attributes unless you're certain your kernel writes every element of every output. The performance cost is negligible relative to the debug cost of an undefined-behavior crash.

### Read-Write output access

For atomics / read-modify-write patterns inside the kernel, set the output access mode to **`Read-Write`**. Default output is write-only.

### Deprecated: `GLSL Create POP`

Per the [GLSL Create POP page](https://docs.derivative.ca/GLSL_Create_POP), this operator is **deprecated** — use `GLSL Advanced POP` (with or without `Topology POP`) instead. Don't reach for `GLSL Create POP` for new work.

---

## Mac platform support

**Mac-relevant** | **Sources:** [Experimental 2025.30770 release notes](https://derivative.ca/release/experimental-202530770/72562), [Experimental 2025.31310 release notes](https://derivative.ca/release/experimental-202531310), TD 2025 release-notes series | **Confidence:** HIGH

### Hardware

- **Apple Silicon (M1/M2/M3/M4):** safe, recommended. M1 Pro is safe.
- **Intel Macs with AMD GPUs:** earlier 2025 experimental builds had hard crashes; **2025.31310 fixed AMD crash + corrupt-output** and restored Intel-Mac support. Officially the 2025.31550+ Official line includes the fix. Older networks may still need re-validation on Intel Macs.

### Apple Silicon limits (cross-reference `mac-gotchas.md`)

- **No double-precision attributes on macOS.** Attributes that would be `double` on other platforms fall back to single-precision float on Apple Silicon. If a calculation needs double precision, POPs won't deliver it on M1+.
- **No hardware ray tracing.** TD's Apple Silicon GPU path does not expose hardware ray tracing → **`GLSL Advanced POP`'s ray-query feature does not work on M1+**. Fall back to single-precision float + CPU-side / shader-side intersection math.
- **macOS "too many attributes" issue** existed in pre-2025.31310 experimental builds; **fixed** in 2025.31310. Apple Silicon production POPs on 2025.31550+ are in the officially-supported lane.

### What Mac status looks like in 2025.32820 Official

The official 2025.31550, 2025.32280, and 2025.32820 release notes contain **no remaining POP-specific MoltenVK warnings** for Apple Silicon. The macOS risk profile documented in release notes is largely in the pre-Official experimental history.

**Practical line for M1 Pro on 2025.32820:**
- Stick to Official (non-Experimental) POPs as your primary set
- Geo-render, bridge operators, `Particle` / `Feedback` / `Force Radial`, standard attribute work — most stable subset
- Treat still-Experimental POPs (Text, Trace, Triangulate, Extrude, Line Thick, Alembic Out, Phaser) as lower-trust until they graduate

See also `mac-gotchas.md` § "POPs crash Intel Macs" and § "MoltenVK regressions can halve FPS".

---

## TD 2025.32820 — Python access functions with `delayed=True`

**Source:** [2025.32820 release notes](https://derivative.ca/release/202532820/74545) | **Date:** May 6, 2026 | **Confidence:** HIGH

Build 2025.32820 added `.point()`, `.prim()`, `.vert()` Python access functions to POP operators. **Use `delayed=True` to avoid GPU/CPU sync stalls** when accessing POP data from Python.

```python
# Safe — non-blocking, returns when GPU has the data (one-frame delay)
n = pop_op.numPoints(delayed=True)
bounds = pop_op.bounds(delayed=True)

# Blocking — downloads from GPU, stalls the cook
pts = pop_op.points('P')  # synchronous; expensive in tight loops
```

The same stall-vs-delay trade-off shows up in `POP to DAT` and `POP to SOP` as **"Next frame (Fast)" vs "Immediate (Slow)"** modes — same architecture, surfaced as a parameter choice rather than a Python kwarg.

**Production implication:** per-frame heavy work belongs in POP/GLSL; Python and CPU bridges belong in tooling, inspection, low-frequency logic, or deliberate one-frame-late couplings. Don't pull large attribute arrays synchronously inside a cook callback.

Other 2025.32820 POP additions (informational):
- **`name[:]` array iteration** across Math, Limit, ReRange, Lookup, Quantize, Normalize, Random, Noise POPs — array attributes are now usable outside pure GLSL
- Math Mix and Math Combine POP inline block summaries (readability)

---

## Debugging POPs

Four diagnostic tools, in roughly this order:

### 1. **Info CHOP** wired to the POP

Drop an **Info CHOP** with the POP as its source. Channels exposed:

- **`total_cooks`** — has this POP actually cooked? (zero means it's bypassed or upstream-broken)
- **`cook_time`** — per-cook ms, identifies hotspot POPs in the chain
- **`errors`** — error count
- **`warnings`** — warning count

**Rule:** before guessing why a POP chain looks wrong, drop an Info CHOP and check the POP is actually cooking. Many "broken" POP chains simply aren't getting evaluated because nothing downstream demands them.

### 2. **POP viewer overlays** via Display Options

**Source:** [Display Options](https://docs.derivative.ca/Display_Options) (last edited 2025-10-28) | **Confidence:** HIGH

POP viewers in 2025+ support **attribute overlays** directly on the network: text labels per point, vector arrows, dot sizing, color encoding — with thinning controls and screen-space scaling so dense point clouds remain readable.

**Rule:** when an attribute "looks wrong" visually, turn on overlay rendering for that attribute and see what the actual values are at the point level. This is faster than `POP to DAT` for spatial intuition.

### 3. **`POP to DAT`** for CPU inspection

The canonical "what's actually in my POP right now" tool.

- **"Next frame (Fast)"** for normal inspection — doesn't stall the cook
- **"Immediate (Slow)"** only when you need same-frame data
- Use `Extract Mode` + thinning + group selection to isolate the subset you care about

### 4. **Info DAT** for GLSL POP compile errors

**MEDIUM confidence** — `GLSL TOP` docs explicitly say "use the Info DAT to check for compile errors"; the same workflow applies to `GLSL POP` per a [Jan 2026 forum bug report](https://forum.derivative.ca/t/crash-when-activating-geo-comp-viewer-with-a-broken-glsl-pop-in-instancing-chain/) where compile errors appeared in the Info DAT before the viewer crashed.

There's no dedicated GLSL POP-Info-DAT docs page but the workflow is real.

### Common documented mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Reading uninitialized `GLSL POP` output attributes downstream | Undefined behavior, crashes | Enable **Initialize Output Attributes** or write every value in the kernel |
| `DAT to POP` with empty headers during dynamic state changes | Reproducible crash (forum, 2026-04) | Keep at least one header row alive until the fix lands |
| Older `Feedback POP` disconnect during a live network | Freeze / crash (pre-2025.31310) | Fixed in 2025.31310+; upgrade if affected |
| Reaching for `GLSL Create POP` | Deprecation warning | Use `GLSL Advanced POP` (with/without `Topology POP`) |
| Reaching for "POP to render" as a single operator | Not found | Use `POP inside Geometry COMP → Render TOP` instead |

---

## Known gaps (deliberately empty)

These are publicly unresolvable as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md` § "Pre-ask filters"):

| Gap | Where it surfaces |
|---|---|
| **POP performance benchmarks on M1 Pro** specifically (point counts before frame budget collapses) | First time you push N to its limit in real work |
| **POP-specific `Point Sprite MAT` workflow** | Docs are still SOP/Particle-SOP/Convert-SOP-formulated. No TD-verified POP-specific point-sprite path as of 2026-05-31. |
| **Direct POP-as-instance-source on `Geometry COMP`** | Works in practice (forum-evidenced 2026-01); docs lag. For pipeline-critical work, the documented path is bridging via `POP to CHOP` / `POP to TOP` / `POP to SOP`. |
| **Particle POP collision** (built-in vs custom-GLSL) | When you actually need particle-particle or particle-mesh collision in a sim |
| **Full MoltenVK / Apple Silicon POP bug list** beyond no-double / no-ray-tracing / fixed historical items | First time a POP misbehaves on Mac in a way release notes don't predict |
| **Houdini-style inline attribute expressions** (`@P.y > 0` inside operators) | Don't go looking — TD has powerful *index* patterns but no per-point *predicate* expression language. Use `Group POP` / `Math POP` / `GLSL POP` for attribute-value filtering. |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

---

## POP rendering — gotchas captured from real builds

### POPs render invisibly without `PointScale` attribute

**Source:** real Roots/Squirrel build, 2026-06-02 | **Confidence:** HIGH

When you render a POP chain via `Geometry COMP → Render TOP` with a default `constantMAT` (or similar non-GLSL material), points render at the GPU's minimum point size (~1 px) — effectively invisible at typical zoom levels, especially against a dense background like a Gaussian splat. The render IS happening; the points are just too small to see.

**Fix:** add a `PointScale` per-point attribute somewhere in the chain. Cleanest path: an `attributePOP` that creates the built-in attribute `pointscale` (lowercase, the menu name) with value ~0.05–0.10 in world units. The `Geometry COMP`'s native rendering honors this attribute for point size.

```
... scatter POP → attributePOP (attr0name='pointscale', attr0value0=0.06, attrclass='point') → null POP
```

Without this step, debugging "my POPs don't appear" wastes time on flags/materials/transforms that are all correct.

### `sprinklePOP method='perprim'` distributes points PER TRIANGLE, not per area

**Source:** real Roots scatter, 2026-06-02 (caught via direct Y-histogram probe of `OUT.points('PointScale')`) | **Confidence:** HIGH

The intuitive assumption — "perprim = N points per primitive scaled by primitive area" — is **wrong**. Empirical measurement shows `perprim` distributes roughly the same number of points to EVERY triangle in the input mesh, regardless of triangle size. With a procedural mesh where deeper recursion levels have many small triangles, all those small triangles each get ~equal points → tip-heavy density even when total surface area is concentrated near the base.

**Symptom:** "I want denser scatter near thick parts, sparse at thin tips" produces the OPPOSITE — tips look denser because there are more tip-triangles competing for the point budget.

**Fix:** control density by adjusting **triangle count per region**, not radius/area. Use depth-aware tessellation when generating the mesh — more `TUBE_SIDES` (more triangles per ring) on top-level segments, fewer on tips. Concretely, for an L-system mesh with K levels: `tube_sides_by_level = [32, 8, 4]` produces ~60%/25%/15% point distribution between levels.

**Verify gradient with this probe pattern:**
```python
positions = op('/path/OUT').points('P', delayed=False)
ys = [p[1] for p in positions]
# 5-bin histogram by Y reveals actual distribution
```

### `SOP to POP` has 0 input connectors — uses `par.sop` reference, not wire

**Source:** Roots+Squirrel builds, 2026-06-02 | **Confidence:** HIGH

The `soptoPOP` bridge does NOT take wire input. Its op type has **zero input connectors** (`o.inputConnectors` length 0). Attempting `connect_ops(fileinSOP, soptoPOP)` fails with `"Destination input index 0 out of range"`.

Instead, set the SOP-source via the **`sop` parameter** (style `SOP`, in the SOP-to-POP page). The parameter accepts an operator reference (sibling-relative is cleanest):

```python
op('.../sop_to_pop').par.sop = 'filein_sop_name'   # sibling reference
# OR
op('.../sop_to_pop').par.sop = op('.../filein_sop_name')  # direct OP assignment
```

Downstream POPs wire from `sop_to_pop`'s output normally. This is a family-bridge convention also seen in other "single-source" bridges (verify pattern when encountered).

### `attributePOP.par.attr` is a Sequence — set via `.sequence.numBlocks`, NOT `set_parameter`

**Source:** Squirrel+Roots builds, 2026-06-02 | **Confidence:** HIGH

`attributePOP.par.attr` controls **how many attribute-slots** are active in the op (0 = no attribute created, 1 = `attr0*` block active, etc.). It's a `Sequence`-style parameter — setting it via MCP `set_parameter value="1"` silently fails (the param shows back as `"0"` after the call).

**Correct API** (via `execute_python`):
```python
sa = op('.../size_attr')
sa.par.attr.sequence.numBlocks = 1
sa.par.attr0name = 'custom'           # or 'pointscale', 'color', etc.
sa.par.attr0customname = 'MyAttr'     # only if attr0name='custom'
sa.par.attr0type = 'float'
sa.par.attr0numcomps = '1'
```

Same pattern applies to other Sequence-style params on POPs (`matattr`, `ren`, `dup`, `del` blocks on `attributePOP`, plus `const`/`vec`/`color`/`sampler` sequences on `glslPOP`). When MCP `set_parameter` returns a stale value on a Sequence param, switch to `.sequence.numBlocks` via Python.

### Mode-switching a shared POP-chain — branch ALL noise/mutator sources, not just the obvious one

**Source:** Shared particles/grid pipeline, 2026-06-07 | **Confidence:** HIGH (user-isolated root cause via empirical "motion stopped but still broken" signal)

When a single POP-chain serves multiple visual modes via a `switchPOP` (e.g. organic particles vs structured grid sharing the same deformation/styling chain), and the chain contains noise or random mutator ops downstream of the switch, **every** such op affecting position or topology must be mode-branched — not just the obviously-named one that matches the current task.

**Symptom of incomplete branching:** Animated motion stops correctly when the obvious noise (e.g. an op called `ground_noise`) is branched to `amp=0` in the topology-mode, but the rendered output is STILL broken statically — grid lines torn apart, point positions scrambled, faces not closed. This is the diagnostic fingerprint of a SECOND noise source (typically per-point random with `t4d=0`, named generically like `rand_noise`) still active.

**Detection before building:** Before introducing a mode-switch, enumerate ALL downstream ops that write to `P` or other topology-relevant attributes:

- `noisePOP` with `noiseoutputattrscope='P'` (writes P directly)
- `noisePOP` writing a delta attribute consumed by a downstream `mathcombinePOP` that mutates P
- `attributePOP` writing P
- per-point `mathcombinePOP` with random/jitter terms

Per-point random with short period (< topology cell size) tears apart any line/face-based topology; long-wavelength noise (period >> cell size) does not. **Both directions are empirically verified** in the source incident — short-period per-point noise (`rand_noise`, period=0.05m on 0.04m grid cells) visibly tore grid lines in still frames; switching to long-wavelength coherent noise at period=8m on 50×50 cells preserved grid closure at comparable amplitude. The failure mode is exclusively short-period noise relative to cell size.

**Fix pattern:**

```python
# branch every risk source on the mode parameter
noise_op.par.amp0.expr = "0.0 if parent.X.par.Mode == 'topology_mode' else 1.0"
```

Or for a tunable wave-style replacement in topology-mode:

```python
noise_op.par.period.expr = "parent.X.par.WaveLongPeriod if parent.X.par.Mode == 'topology_mode' else parent.X.par.NormalPeriod"
noise_op.par.amp0.expr   = "parent.X.par.WaveAmp        if parent.X.par.Mode == 'topology_mode' else parent.X.par.NormalAmp"
```

**Acceptance test:** In topology-mode with all wave/animation rattar at zero, the rendered output must be (a) perfectly static across frames AND (b) geometrically clean (lines straight, faces closed). If either fails, a static noise source is still active.

**User-side diagnostic heuristic worth listening for:** if the operator observes "motion stopped but the output is still broken" after branching the obvious source, a static per-point noise is still active. Search for downstream noise ops with `t4d = 0` and short `period`.

### `mathcombinePOP` binary ops are component-wise on multi-component attributes

**Source:** Y-ceiling clamp in shared deformation chain, 2026-06-04 (stress-tested with extreme parameter values to confirm) | **Confidence:** HIGH

When `mathcombinePOP` applies a binary op (`min`, `max`, `add`, `mult`, etc.) between two float3 attributes (typically P vs another vector), the operation is performed **component-wise** — no per-component setup needed.

```python
# Clamp only P.y to a ceiling without touching X or Z — sentinels on X and Z:
y_ceiling.par.vec0value0 = 1e6        # X — effectively no clamp
y_ceiling.par.vec0value1 = -0.915     # Y — actual ceiling
y_ceiling.par.vec0value2 = 1e6        # Z — effectively no clamp
y_ceiling.par.comb0oper = 'min'
y_ceiling.par.comb0scopea = 'P'
y_ceiling.par.comb0scopeb = 'y_ceiling'
y_ceiling.par.comb0result = 'P'
# Result: P.x = min(P.x, 1e6) = P.x, P.y = min(P.y, -0.915), P.z = min(P.z, 1e6) = P.z
```

Component-wise behavior was uncertain before empirical confirmation — alternatives considered were "3 separate min-combs, one per component" or "use `clamp` instead". This is the simpler path. Verified via stress test: max-amplitude noise + max-amplitude masters all turned on — `max(P.y)` remained ≤ -0.915 in all cases.

**Verify pattern when designing a single-component clamp:** stress-test before relying on it — push upstream values past the ceiling and check `numpyArray('P').max(axis=0)` after the clamp. Don't assume.

### `noisePOP` `combineop` controls whether output replaces or adds to an attribute

**Source:** Per-point random vector generation for sprinkle decay, 2026-06-04 | **Confidence:** HIGH

`noisePOP` writes its output to the attribute named in `noiseoutputattrscope`. The `combineop` parameter controls how the noise interacts with any existing value:

| `combineop` | Behavior | Use when |
|---|---|---|
| `'none'` | **Creates** the named attribute and writes noise into it (overwrites if exists) | Fresh attribute carrying noise — e.g. per-point random vector for downstream culling/jitter |
| `'add'` (default) | **Adds** noise to existing attribute value (silent zero/garbage if attribute doesn't exist upstream) | Perturb an existing position/value — e.g. add jitter to P |

**Common trap:** leaving `combineop='add'` (the default) while writing to a brand-new attribute scope produces empty/garbage output because there's nothing upstream to add to. No visible error — downstream consumers just see zeros or NaN.

**Standard config for creating a per-point random attribute:**

```python
rand_noise.par.noise = True
rand_noise.par.combineop = 'none'                # create, don't add
rand_noise.par.noiseoutputattrscope = 'rndvec'   # name the attribute
rand_noise.par.period = 0.05                     # short period for per-point variation
rand_noise.par.amp0 = 1.0
rand_noise.par.seed = 42
rand_noise.par.t4d = 0                           # 0 = static seed; >0 = animate over time
```

**Verify:** after configuring, sample 10–20 points via `op('.../rand_noise').points('rndvec')` and check values are non-zero, varied per-point, and within expected amplitude range.

### A single MAT downstream of a merge applies to ALL merged inputs — branch styling per-point upstream of the merge

**Source:** Shared multi-branch POP pipeline, 2026-06-05 (alpha tuning produced unwanted cross-branch effects) | **Confidence:** HIGH

When two or more POP chains merge upstream of a single `Geometry COMP` consuming one MAT, that MAT's properties (alpha, blending, color tinting, point sprite, depth behavior) apply uniformly to ALL merged inputs. There is no per-branch styling at the MAT layer.

**Symptom:** You want to dim branch A while leaving branch B at full opacity. Adjusting `MAT.par.alpha` dims BOTH because the merge happened before the MAT reads.

**Fix pattern — branch styling via per-point attributes upstream:**

Set per-point `Color` (or any MAT-consumed attribute) on each branch BEFORE the merge. The MAT then reads the per-point attribute, so each branch carries its own styling through the merge.

```python
# branch A — set per-point color/alpha BEFORE merge
set_color_A.par.attr0name = 'color'
set_color_A.par.attr0numcomps = '4'
set_color_A.par.attr0value0 = 255   # R
set_color_A.par.attr0value1 = 255   # G
set_color_A.par.attr0value2 = 255   # B
set_color_A.par.attr0value3 = 30    # alpha for branch A

# branch B — different alpha
set_color_B.par.attr0value3 = 77    # alpha for branch B

# downstream merge + single MAT now displays each branch with its own alpha
```

**When the MAT is `constantMAT`:** ensure `applypointcolor=True` so per-point Color overrides the MAT's uniform color.

**Mode-switch variant:** if the two "branches" are actually the same chain in different modes (via `switchPOP`), branch the attribute-setting expressions on the mode parameter — see also "Mode-switching a shared POP-chain — branch ALL noise/mutator sources" earlier in this section.

### Inspect external geometry-source attributes before merging into an existing chain

**Source:** External baked-PLY merging into a constantMAT-driven pipeline, 2026-05 to 2026-06 | **Confidence:** HIGH

When merging a newly-loaded POP source (`fileinPOP` of a PLY/GLB, freshly generated POPs from a SOP-bridge, output of an external bake) into a chain that's already rendering correctly, the source's attributes must match the existing chain's expectations in three dimensions: **name**, **component count**, and **value scale**.

If any of these mismatch, the merge succeeds silently — no error, no warning — but the rendered output is wrong or invisible. The downstream MAT may receive `Color` when it expects `Cd`, may read a 0–1 float as if it were 0–255 byte (or vice versa), or may sample component 3 of a vec4 when only vec3 was provided.

**Inspection recipe — run BEFORE wiring the merge:**

```python
src_pop = op('.../newly_loaded_pop')

# 1. Attribute names + classes
print(src_pop.pointAttributes)        # → {'P', 'Color', 'PointScale', ...}
print(src_pop.vertexAttributes)
print(src_pop.primAttributes)

# 2. Sample 1–5 points to see actual values + ranges + component counts
for name in src_pop.pointAttributes:
    vals = src_pop.points(name, delayed=False)[:3]
    print(f"{name}: {vals}")
```

Compare against the existing chain's expectations — sample the same attribute on the downstream `null`/OUT to see what range and naming the MAT actually consumes.

**Common mismatches to check for:**

- **Color attribute name**: `Color` vs `Cd` vs `color` (case matters in some POP API surfaces).
- **Color value scale**: 0–1 float vs 0–255 byte — baked PLY conventions vary by baker tool. A PLY with `Color=(0.5, 0.5, 0.5)` and one with `Color=(127, 127, 127)` both look "right" in isolation but mix wrong.
- **Component count**: `Color` may be vec3 (RGB) or vec4 (RGBA). Synthetic source with vec3 merged with baked vec4 leaves alpha undefined.
- **PointScale presence**: some PLY bakers include per-point `PointScale`; others omit it. Synthetic points without `PointScale` render at GPU minimum (~1px) when mixed with baked points that scale correctly.
- **Per-point transforms**: Gaussian-splat PLYs carry rotation/scale-3 attributes; merging plain points into that chain leaves those attributes undefined for the new points.

**Fix pattern when mismatch is found:**

Insert an `attributePOP` (or `attributecreatePOP`) on the new branch BEFORE the merge that synthesizes the missing attributes at matching name/count/scale. For value-scale mismatch (0–1 float to 0–255 byte), use a `mathPOP` to rescale before the merge.

**Verify:** after merging, capture the render and compare against the pre-merge baseline. If the rendered output differs in color, size, or visibility from "what the new points should add", run the inspection recipe on both branches at the merge point and reconcile.

# Python-as-architecture patterns

Where the architectural choice — which TD building block carries the logic — matters more than the API trivia. This file collects patterns for using runtime Python (callbacks, evaluate DATs, replicators, scriptOPs, dependencies) in place of node chains, where doing so produces a smaller, clearer, or more dynamic network. Mirrors the framing of `td-architecture.md` (minimalism + visual verification): fewer operators, clearer intent, fewer failure points.

---

## When a callback DAT replaces a node chain

**Source:** [docs.derivative.ca/ParameterexecuteDAT_Class](https://docs.derivative.ca/ParameterexecuteDAT_Class) | Page last edited: see wiki | **Confidence:** MEDIUM (Derivative wiki — verify in your TD version)

Prefer a `parameterexecuteDAT` over a CHOP chain when the response is a one-shot side-effect; expressions still beat both for pure value derivations.

A `parameterexecuteDAT` fires a Python callback when a watched parameter changes. The cost is one Python call at the moment of the change — no per-frame cook. A CHOP chain ingesting the same parameter, by contrast, cooks every frame the chain is pulled, regardless of whether the value actually moved.

**Reach for `parameterexecuteDAT` when:**

- The response is a one-shot side-effect — set another parameter, fire a pulse, store a value, log a transition.
- The action is event-shaped (it happens at the moment of change), not signal-shaped (a continuously evaluated function of the value).
- The chain would otherwise be: parameter → CHOP → trigger/Logic CHOP → executeCHOP → side-effect.

**Reach for a CHOP chain when:**

- Downstream consumers need the value as a live signal (filtered, smoothed, lagged, mixed with other channels).
- The transformation is mathematical and benefits from CHOP's vectorized cook (smoothing, blending, channel math at audio rate).

**Reach for an expression when:**

- The result is a pure function of one or more parameters with no side-effect (`op('x').par.tx + op('y').par.tx`). An expression has zero scheduling cost — TD pulls it when the consumer needs it. No DAT, no CHOP chain, no callback overhead. This is the default for value derivations.

**Decision rule:** "Is this an *event* I react to (side-effect on change) or a *signal* I evaluate (value flows downstream)?" Event → callback DAT. Signal feeding more signals → CHOP chain. Pure value derivation → expression.

**Check first when:**

- You're about to wire a `triggerCHOP` + `executeCHOP` pair to react to a parameter change.
- A CHOP chain exists purely to observe a parameter and run side-effecting Python on change.
- The "value" being computed has no downstream consumer that wants it as a signal.

**Status:** verify before relying — source dated [see wiki page footer]; re-check Derivative wiki / forum if this trips a user.

---

## Evaluate DAT for table transforms

**Source:** [docs.derivative.ca/Python_Tips](https://docs.derivative.ca/Python_Tips) | Page last edited: 2022-03-13 | **Confidence:** MEDIUM (Derivative wiki — verify in your TD version)

Inside an Evaluate DAT, `me.inputCell` plus `.offset(r,c)` reads relative cells — use for per-cell table transforms instead of chained Select/Convert/Reorder DATs.

An Evaluate DAT runs its expression once per output cell. Inside the expression, `me.inputCell` is the corresponding input cell, and `me.inputCell.offset(rowDelta, colDelta)` reads cells relative to it. This lets a single DAT carry a per-cell transform that would otherwise require a chain — Select DAT to slice columns, Convert DAT to change types, Reorder DAT to reshape, plus glue ops to wire them together.

**Reach for an Evaluate DAT when:**

- The transform is *per cell* and references neighbors (previous row, adjacent column, header row).
- The output shape is the same as the input — same rows, same columns, transformed values.
- The logic is too specific to fit a stock DAT (e.g. format a value based on a cell two rows up, conditionally rewrite a column).

**Reach for a Select/Convert/Reorder chain when:**

- The transform is *structural* — pick columns, drop rows, change a numeric column to a string column. Stock DATs do this with no Python.
- A single stock DAT already covers the case — don't reach for Evaluate just because you can.

**Reach for a scriptDAT when:**

- The output shape differs from the input (compute new rows from aggregates, fan out one row to many).
- The transform needs the whole table at once (sort, group, join with another DAT).

**Decision rule:** "Same shape, per-cell math referencing neighbors" → Evaluate DAT. "Structural reshape" → stock DAT chain. "Whole-table compute" → scriptDAT.

**Check first when:**

- A Select+Convert+Reorder chain exists to do work that boils down to "transform each cell based on its row/column position".
- You're about to write a per-row loop in an executeDAT to populate a derived table.

**Status:** verify before relying — source dated 2022-03-13; re-check Derivative wiki / forum if this trips a user.

---

## Replicator COMP for runtime-templated networks

**Source:** [docs.derivative.ca/Replicator_COMP](https://docs.derivative.ca/Replicator_COMP) | Page last edited: see wiki | **Confidence:** MEDIUM (Derivative wiki — verify in your TD version)

A `replicatorCOMP` driven by a table or count regenerates a templated COMP per row — use instead of looping `create_op` when the set changes at runtime.

A `replicatorCOMP` points at a template COMP plus a driver (a table DAT or a count parameter). When the driver changes, the replicator destroys its previous replicas and recreates one COMP per row (or one per count value), cloning the template. Per-replica customization happens in the replicator's callback DAT (`onReplicate`), which receives the new replica and its source row.

**Reach for a replicatorCOMP when:**

- The set of COMPs is *data-driven* — number and configuration come from a table that may change at runtime (a list of audio inputs, a connected device list, a config table loaded from disk).
- Replicas share structure but vary in parameters or paths (a row per device, a row per output channel, a row per scene).
- The user adds/removes entries at runtime and the network should follow.

**Reach for a Python loop calling `create_op` when:**

- The set is *static* — known at build time, never changes during the run. A one-shot Python loop in an extension `Init` keeps the operators visible in source control without the runtime regeneration cost.
- You need explicit operator names that won't be shuffled by the replicator's naming scheme.

**Reach for instancing (Geometry COMP instancing) when:**

- The "replicas" are visual copies of geometry, not separate operators. Instancing renders thousands of copies as one draw call — much cheaper than thousands of replica COMPs each with their own render path.

**Decision rule:** "Does the set change at runtime?" Yes → replicator. No → one-shot Python loop. "Are they visual copies?" → instancing, not replication.

**Check first when:**

- You're about to write a Python loop that recreates a set of COMPs every time a config DAT changes.
- A panel needs N UI rows where N is read from a table.
- A device-manager pattern: one COMP per connected device, list discovered at runtime.

**Status:** verify before relying — source dated [see wiki page footer]; re-check Derivative wiki / forum if this trips a user.

---

## When a scriptOP replaces a chain

**Source:** [docs.derivative.ca/Script_CHOP](https://docs.derivative.ca/Script_CHOP) | Page last edited: see wiki | **Confidence:** MEDIUM (Derivative wiki — verify in your TD version)

A single `scriptCHOP`/`scriptDAT`/`scriptSOP` beats 5+ math/select ops in series when logic doesn't vectorize on GPU; use NumPy inside for batch work.

A scriptOP carries arbitrary Python in place of a chain. Its cook cost is one Python call (plus whatever the Python does); the chain it replaces costs one cook per intermediate op. For CPU-side logic that doesn't vectorize across a CHOP's parallel sample model — branching per-sample, table joins, custom interpolation — a scriptCHOP with NumPy inside is both faster and shorter than a long math/select chain that contorts itself to express the same logic in stock ops.

**Reach for a scriptOP when:**

- The chain would be 5+ ops in series doing CPU-shaped logic (per-sample branching, conditional resampling, custom math that doesn't map cleanly to Math/Logic/Lookup CHOPs).
- You'd otherwise reach for an `executeCHOP` that writes into a `constantCHOP` — that's the slow path.
- The output is regular (a CHOP with N channels, a SOP with K points, a DAT with rows) but the *computation* is irregular.

**Reach for a stock-op chain when:**

- The transformation is a small composition of well-named ops (filter + lag + math) — clearer to read, and TD's vectorized CHOP cook is fast.
- The work is GPU-shaped — per-pixel TOP math, per-point POP math. Stay on the GPU; scriptOP runs on CPU.

**Reach for a glslPOP/glslTOP when:**

- The per-element work is uniform across thousands+ elements and benefits from GPU parallelism. ScriptOPs run one Python call per cook; GPU shaders run thousands of element threads.

**Decision rule:** "Is this CPU-shaped (per-sample branching, irregular logic) on a moderate dataset?" → scriptOP with NumPy. "GPU-shaped, uniform across many elements" → GLSL. "Small clean composition of stock ops" → stay with the chain.

**Use NumPy inside.** The scriptOP wins on cook count, not raw Python speed. Inside the script body, prefer `numpyArray()`-style batch reads/writes over per-sample Python loops — a scriptCHOP iterating per sample in Python is slower than the chain it replaced.

**Check first when:**

- A CHOP chain has grown to 5+ ops chaining selects and maths to express conditional logic.
- An `executeCHOP` writes derived values into a `constantCHOP` every frame.
- The logic reads as "for each sample, if X then Y else Z" — hard to express in stock CHOPs, easy in a scriptCHOP.

**Status:** verify before relying — source dated [see wiki page footer]; re-check Derivative wiki / forum if this trips a user.

---

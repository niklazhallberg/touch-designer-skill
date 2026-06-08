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

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

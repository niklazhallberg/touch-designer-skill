# TouchDesigner architecture — minimalism + visual verification

Two principles for how the agent should reason about TD network structure: prefer minimal operator counts, and verify against visual output, not just successful execution.

---

## Minimalism — prefer fewer operators over more

**Source:** [The Great Inversion (Dylan Roscover, March 2026)](https://derivative.ca/community-post/great-inversion/74207) | Date: March 2026

Concrete reference point: Derivative's stock `buttonMomentary` widget COMP contains **33 operators internally** to provide a single push-button. A bare `Text COMP` set up to react on click does the same job with **1 operator**. The ratio is roughly **10:1** in this example, and it generalizes — heavy widget abstractions from the palette are often unnecessary for project-specific work.

**Why this matters:**

- **Cook cost:** every internal operator may cook every frame. 33 vs 1 changes the per-frame budget noticeably at scale.
- **Debug surface:** every operator is something that can go wrong. Fewer operators = fewer failure points.
- **Reasoning cost (for the agent):** when reading the network, the agent has to model what each operator does. A 33-operator widget burns context to understand a button.
- **Render-graph depth:** more operators = deeper dependency chains, slower to settle on parameter changes.

**Rule for the agent:**

- For project-specific UI/interaction, **build from primitives** (Text COMP, Constant CHOP, Switch CHOP, etc.). Don't drop a palette widget unless its features (skinnable styling, gesture variants, accessibility) are actually needed.
- When a palette COMP is already in place and works, **don't preemptively replace it** — but flag the trade-off if you see opportunities to simplify and the user is open to refactoring.
- "Minimal" doesn't mean "premature DIY" — if reaching for a primitive forces you to reimplement gesture handling, easing, debouncing, etc., the widget was probably the right call.

**Decision rule:** for each abstracted COMP, ask "does this give me something I'd otherwise have to reimplement?" If no, prefer the primitive.

**Check first when:**

- About to drop a palette widget for a simple control (button, slider, toggle, label)
- Reading an existing network with deep internal nesting and trying to understand what it does
- Profiling cook times and looking for sources of background load
- Planning a layout where many widgets will live side-by-side

---

## Visual verification — `capture_top` is ground truth

**Source:** [The Great Inversion (Dylan Roscover, March 2026)](https://derivative.ca/community-post/great-inversion/74207) | Date: March 2026

**"If it looks correct, it is correct."** TD is a visual program; the output of a TOP/render is the only ground truth. Code that runs without errors and parameters that read as expected do not, by themselves, prove the network produces the intended image/animation.

This reinforces and extends existing rules:

- Project `CLAUDE.md` § Critical Rule 9: "Always check for errors and warnings after creating operators" — *necessary, not sufficient.*
- `rules/td-python.md` § Operator Referencing: "Always verify references resolve correctly" — *necessary, not sufficient.*
- `rules/td-python.md` § Module-Level Code Hazard: defers state-access to method-call time — *preventive, doesn't confirm output.*

**Add: after any meaningful change to a render path or visual operator chain, call `capture_top` on the affected output before declaring the change done.**

### When to capture (mandatory)

- After modifying a GLSL shader (vertex or pixel) — colors, transforms, culls, alpha behavior
- After re-wiring a render graph (changing render TOP inputs, swapping select TOPs, inserting overTOP/addTOP)
- After parameter changes that affect what gets rendered (camera distance, scale, light intensity, alpha threshold)
- After composite changes (Over/Add/Multiply TOPs reordered or replaced)
- After ANY claim of "done" on a visual feature — even if `get_op_errors` returns 0 and parameters read as expected

### When you can skip the capture

- The change is purely data-side (CHOP processing that doesn't affect any TOP downstream)
- The render path is verifiably unchanged (the modified operator is upstream of a known-stable null/select boundary that you've separately confirmed)
- You're at a non-visual checkpoint (extension code, parameter wiring without a render consumer yet attached)

### Rule

`errors=0` + "parameter reads correct" is **necessary but not sufficient**. The image is the proof. If you didn't capture, you don't know.

A small extension: when comparing before/after on a non-trivial change, capture *both* and surface the diff. Don't ask the user to remember what the previous frame looked like.

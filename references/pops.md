# POPs (Point Operators) — default for point/geometry/particle work in TD 2025+

Trigger this reference when the user asks about creating points, particles, point clouds, instancing from arbitrary attributes, or geometry that lived in SOPs in earlier TD versions.

---

## POPs are the correct default in TD 2025+

**Source:** [2025 Official Update](https://derivative.ca/community-post/2025-official-update/73153), [Interactive Immersive blog](https://interactiveimmersive.io/blog/touchdesigner-resources/whats-new-in-the-2025-touchdesigner-release/) | Date: October 2025 (TD 2025 Official release)

POPs (Point Operators) became officially released in TD 2025 Official on **October 30, 2025** — the first new operator family added in over a decade. They run **entirely on GPU/VRAM**: data never leaves the GPU until render time. This is the fundamental architectural shift from SOPs (CPU-bound, data shuttled to/from CPU per frame).

**What POPs do that SOPs/TOPs-with-GLSL-shaders couldn't before:**
- Millions of points in real-time without writing custom GLSL
- Arbitrary user-defined point attributes (position, normal, color, velocity, custom float/int/vector — Houdini-style)
- Particle systems, point clouds, polygons, line strips, spline curves — all from one data model
- Direct instancing from POP data without SOP→CHOP conversion (eliminates the CPU spike at that boundary)
- Reaction diffusion, differential growth, and other per-point simulations patchable without shaders

**Community consensus** ([Reddit thread](https://www.reddit.com/r/TouchDesigner/comments/1rdik06/pops_instancing_in_touch_designer/)): "in most cases you can substitute SOPs with POPs for improved GPU efficiency, but POPs don't replace instancing — you still instance from a Geometry COMP." The old SOP→CHOP→instancing workflow is now often replaceable by a single POP chain feeding a Geometry COMP directly.

**Default rule:** for any new geometry/particle/point-cloud work in TD 2025+, propose POPs first. Suggesting SOP→CHOP→instancing is generating 2022-era code.

---

## Mac platform support

**Mac-relevant** | Source: [Experimental 2025.30770 release notes](https://derivative.ca/release/experimental-202530770/72562) | Date: August 2025

- **Apple Silicon (M1/M2/M3/M4):** safe, recommended. User's M1 Pro is safe.
- **Intel Macs with AMD GPUs:** **DO NOT USE POPs** — hard crash, potential driver corruption requiring system reboot.
- **Some POP example issues** existed in early 2025 builds on macOS (DMX POP examples, some viewer display modes). Less of an issue in 2025.32820 but check release notes if a specific POP behaves oddly.

See also `mac-gotchas.md` § "POPs crash Intel Macs" and "MoltenVK regressions can halve FPS".

---

## TD 2025.32820 — Python access functions with `delayed=True`

**Source:** [2025.32820 release notes](https://derivative.ca/release/202532820/74545) | Date: May 6, 2026

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

## Common POP types (quick reference)

| POP | Role |
|---|---|
| `gridPOP`, `spherePOP`, `linePOP` | Generator: produce structured point sets |
| `noisePOP` | Add noise to position or any attribute |
| `transformPOP` | Translate/rotate/scale points |
| `mathPOP`, `mathMixPOP`, `mathCombinePOP` | Per-attribute arithmetic |
| `particlePOP` | Velocity-based simulation |
| `mergePOP`, `selectPOP`, `cachePOP`, `nullPOP` | Topology + flow control |
| `fileinPOP` | Load `.ply` and similar point data |
| `glslPOP` | Custom GLSL when built-in POPs don't cover the operation |
| `attribcreatePOP`, `attribblurPOP` | Author and propagate per-point attributes |

Full class reference: [docs.derivative.ca/POP_Class](https://docs.derivative.ca/POP_Class).

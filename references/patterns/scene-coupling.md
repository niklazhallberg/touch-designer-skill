# Scene-coupling patterns — visibility-by-distance + attached-to-rotating-sibling

> **Trigger:** when a sibling COMP needs to (a) appear/disappear based on the
> render camera's distance, or (b) stay locked to a position on another
> rotating sibling (typical: ekorre/squirrel/details on a Gaussian splat tree
> that rotates via hand control).

Both patterns assume the project drives camera distance and/or sibling rotation
via CHOP expressions (often hand-tracking pinch/swipe). Both are siblings-of-
splat-COMP solutions — they do NOT require reparenting under the rotating COMP.

---

## Pattern A — Visibility fade by camera distance

**Source:** Roots component in RADON_TREE, 2026-06-02 | **Confidence:** HIGH

**Goal:** sibling geometry (e.g. roots, particles, detail layer) is invisible
when the camera is far ("default zoom") and fades in as the user zooms toward
the scene.

**Why not `PointScale = 0`:** for POP-rendered points with `constantMAT`, TD
appears to clamp rendered point size to a minimum (~1 px) even when the
per-point `PointScale` attribute is 0. Verified empirically: setting all
points' PointScale to 0 STILL produced visible particles in render.

**Solution — material alpha + blending, expression-driven by camera tz:**

```python
mat = op('.../mat_white')          # the constantMAT applied to the COMP
mat.par.blending = True
mat.par.alpha.expr = (
    "tdu.clamp((FAR_BOUNDARY - "
    "op('/path/to/camera').par.tz) / FADE_WIDTH, 0.0, 1.0)"
)
mat.par.alpha.mode = ParMode.EXPRESSION
```

Tuning constants:
- `FAR_BOUNDARY` — camera tz value above which the geometry is fully invisible
  (alpha=0). Typically = the camera's max-zoom-out distance (`zoom_clamp.max`).
- `FADE_WIDTH` — how many world-units of zoom traverse a full 0→1 alpha
  transition. Small = sharp pop-in; large = gentle fade.

Example with `tz` clamped to range [0.5, 6.0] (max-in to max-out):
- `FAR_BOUNDARY=5.0, FADE_WIDTH=3.0` → invisible at tz>=5, fully visible at tz<=2, linear between

**Caveats:**
- `blending=True` may introduce z-order issues if the COMP overlaps other
  transparent geometry. For solid scene elements (opaque splat, opaque
  background), the alpha-fade is purely additive — no z-fight.
- The expression evaluates every frame because `op(cam).par.tz` is
  expression-driven by the pinch CHOP. No manual cook needed.

---

## Pattern B — Attached position on a rotating sibling

**Source:** Squirrel + Roots components in RADON_TREE, 2026-06-02 | **Confidence:** HIGH

**Goal:** a sibling COMP appears "glued" to a specific position on another
sibling that rotates continuously around the world Y axis. When the rotating
sibling spins, the attached COMP must rotate **with** it (so its position
stays at the same angular location relative to the rotating object) AND its
own mesh must rotate by the same amount.

**The naive failure mode:** set the attached COMP's `ry` to mirror the
rotating sibling's `ry`. This rotates the attached COMP's mesh in place but
its **world position** stays fixed → as the rotating sibling spins, the
attached COMP drifts off the surface and orbits around the world origin.

**Solution — orbital expressions on tx + tz:**

```python
sq = op('.../attached_comp')

# Mesh rotation: mirror the rotating sibling's ry
sq.par.ry.expr = "op('rotating_sibling').par.ry"
sq.par.ry.mode = ParMode.EXPRESSION

# Position: orbit at radius r at world Y plane
r = 0.22  # radial distance from rotation axis
sq.par.tx.expr = f"{r} * math.cos(math.radians(op('rotating_sibling').par.ry))"
sq.par.tz.expr = f"-{r} * math.sin(math.radians(op('rotating_sibling').par.ry))"
sq.par.tx.mode = ParMode.EXPRESSION
sq.par.tz.mode = ParMode.EXPRESSION

# ty stays constant — vertical position on the rotation axis
sq.par.ty = -0.35
```

This makes the attached COMP "ride" the rotating sibling without reparenting.
Effectively equivalent to making it a child of the sibling's transform — but
without the network-restructuring cost.

**Why cosine/-sine specifically:** for a positive-Y right-handed rotation
(TD's default), a point at world `(r, 0, 0)` rotates to `(r*cos(θ), 0,
-r*sin(θ))` as `θ` increases. The `-sin` keeps the rotation direction
consistent with the rotating sibling.

**Choosing the radius `r`:** = world-units distance from the rotation axis
(world Y axis at X=Z=0 in this typical setup). Tune by observing render
output — set to small constant (e.g. 0.1) for "pressed against the trunk",
larger (0.3–0.5) for "out on a branch".

**Add an angular offset** (rotate the attached COMP's position around the
sibling by N degrees while staying glued) by adding `+ OFFSET_DEG` inside
`math.radians()`:

```python
sq.par.tx.expr = f"{r} * math.cos(math.radians(op('rotating_sibling').par.ry + 90))"
sq.par.tz.expr = f"-{r} * math.sin(math.radians(op('rotating_sibling').par.ry + 90))"
```

Same offset must be added to the ry mirror expression OR not — depends on
whether you want the attached COMP's mesh to also face the new angle. In
practice, faces-the-camera-correctly-during-spin is what users want, so
typically yes (same offset on ry and on tx/tz).

---

## When to NOT use these patterns

- If the COMP can be a CHILD of the rotating sibling without breaking its
  internal rendering pipeline (e.g. custom GLSL shader that depends on
  parent-shortcut paths) → reparent. Simpler, no math.
- If the rotation is one-time (not continuous) → just transform once,
  no expression needed.
- If the visibility fade should be sharp (binary on/off at a threshold) →
  use `render` flag with a Python callback on the CHOP, not material alpha.

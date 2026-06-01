# Hand-driven camera controls — pattern

> **Trigger:** when building MediaPipe (or other hand-tracking source) → camera-parameter bindings on TouchDesigner. Covers: Y/pitch/roll mapping, pinch→zoom, presence-gated smoothing, the multi-camera split that lets bare-camera drive while extension-driven camera stays as fallback, and the silent-regression hazard around `renderTOP.par.camera` swaps.
>
> **File type — pattern.** Architectural mould for a recurring TD effect, not a one-off gotcha. Companion artifact (when MCP is idle): `templates/components/hand-driven-camera-y.tdn`. Cross-links: `td-gotchas.md § Swapping a renderTOP's camera silently breaks bindings on the old camera`; `components/mediapipe.md` for the upstream MediaPipe wiring.

---

## When to use this pattern

You want a TD scene where a hand-tracking source drives one or more camera parameters in real time. Concrete examples:

- Vertical hand motion → camera Y (the radon-tree mapping from 2026-05-31)
- Pinch distance → camera dolly / `Pivotdistance`
- Hand tilt → camera pitch / look-at
- Two-hand spread → orthowidth / FOV
- N-finger flex → custom shader uniform that crossfades effects

The pattern is general beyond MediaPipe — any per-frame stream of normalized values (Leap Motion, ZED skeleton, OSC from external Python) can sub in for the hand-source upstream.

---

## Core architecture (5 stages)

```
hand source  ──┐
               │  (e.g. /project1/hand_control/pinch_lag — landmark x/y/z + presence channels)
               ▼
            ┌──────────────┐
            │  selectCHOP  │  pulls the relevant raw channels
            │  "pick"      │  e.g. b_wrist_y + hand_b_present
            └───────┬──────┘
                    ▼
            ┌──────────────┐
            │   mathCHOP   │  offset by center, multiply by gain, sign-flip if inverted
            │   "apply"    │  formula: (val − Center) * Gain * (−1 if Invert else 1) * Enable
            └───────┬──────┘
                    ▼
            ┌──────────────┐
            │   mathCHOP   │  multiplies "apply" output by presence channel
            │   "gate"     │  → output is 0 when hand is absent (camera centers, no drift)
            └───────┬──────┘
                    ▼
            ┌──────────────┐
            │   lagCHOP    │  smooths jitter — MediaPipe landmarks have ~0.14 noise floor
            │   "smooth"   │  even on stationary hands; lag of 0.15–0.4s is typical
            └───────┬──────┘
                    ▼
            ┌──────────────┐
            │   nullCHOP   │  renamed to the target param name (e.g. "ty")
            │   "out"      │  consumed by target camera via expression: handcam.par.ty.expr =
            └──────────────┘     op('/project1/camera_control/cam_y_out')['ty']
```

Each stage has a clear single responsibility. Replacing any stage (different smoothing, different math, different gating logic) doesn't ripple to the others.

---

## Custom-param surface

The wrapping baseCOMP exposes these custom params so dial-in happens in the parameter dialog, not by editing internal ops:

| Page | Param | Style | Purpose |
|---|---|---|---|
| Source | `Source` | StrMenu (`a` / `b`) | Which detected hand drives the signal. Match upstream's hand convention. |
| Y | `Yenable` | Toggle | Master on/off. When 0, gain multiplier becomes 0 and output is silent. |
| Y | `Ycenter` | Float (0–1) | Image-space value that maps to camera 0. Calibrate to user's natural rest position. |
| Y | `Ygain` | Float (−10 to 10) | Multiplier from normalized hand position to camera world units. |
| Y | `Yinvert` | Toggle | Sign-flip without changing Gain semantics. Useful when "up" and "up" don't agree. |
| Y | `Smoothlag` | Float (0–2 sec) | Lag time. 0.15 if jitter is low / response must be snappy. 0.3+ for stable camera. |

For multi-axis (Y + pitch + zoom), duplicate the page per axis. Pattern is symmetric across mapping types.

---

## The two camera-pose split (critical pattern)

**Do NOT drive the user-navigable camera (CameraExt-extended cameraViewport) directly with hand-tracking.** CameraExt writes a transform matrix and toggles `pxform=True` on any user mouse interaction, which silently overrides `tx/ty/tz/rx/ry/rz` param writes from CHOP exports.

Use a two-camera split:

```
┌───────────────────────────────┐
│  cameraViewport               │  Keeps CameraExt extension.
│  (extension-driven, fallback) │  User can mouse-navigate at any time.
│                               │  RECEIVES the pinch→Pivotdistance binding (historical zoom).
└───────────────────────────────┘
                   │
                   │ NOT in render path during interactive mode
                   │
┌───────────────────────────────┐
│  handcam                      │  Bare cameraCOMP, no extension.
│  (hand-driven, active)        │  No pxform toggle, no stored matrix.
│                               │  SRT params driven by CHOP exports + expressions.
│                               │  This is what renderTOP.par.camera points at.
└───────────────────────────────┘
```

`render1.par.camera = handcam` → the hand-driven camera renders.
`render1.par.camera = cameraViewport` → snap back to mouse-navigation mode for debugging / setup.

Match `handcam`'s `fov / aperture / focal / near / far` to `cameraViewport`'s at creation time so the swap is visually continuous.

---

## Mirror-binding rule (the silent-regression trap)

If the existing scene has expressions or CHOP exports bound to the OLD camera (e.g. `cameraViewport.par.Pivotdistance ← zoom_out['pinch_b']`), those bindings **do not follow** when `render1.par.camera` is repointed to `handcam`. They keep firing, keep updating the old camera's params — which are no longer in the render.

**Before swapping the render's camera:** inventory all params with expressions referencing the old camera. Mirror them on the new camera, OR accept the breakage and tell the user explicitly. Full procedure: `td-gotchas.md § Swapping a renderTOP's camera silently breaks bindings on the old camera`. The paste-ready inventory script is in that gotcha.

For zoom specifically: if cameraViewport had `Pivotdistance ← zoom_out['pinch_b']`, mirror on handcam as `tz ← zoom_out['pinch_b']`. Both expressions stay live; the user can swap the render camera back and forth without breaking zoom.

---

## Adaptation — how to vary the pattern

### Different hand-source

The pattern doesn't require MediaPipe specifically. Substitute any per-frame stream that provides:
- Normalized position values (one per axis you want to drive)
- A presence flag (so the gate stage can zero output when source is absent)

Sources tested or plausible: MediaPipe hands, Leap Motion (via tdleap), OAK-D depth + skeleton, OSC from external Python doing whatever.

### Different finger-pair / gesture

`pinch_b` (thumb-tip ↔ index-tip distance) is the default. Other useful pairings:

| Pair | Channel computation | Effect-fit |
|---|---|---|
| Thumb ↔ middle | `dist(lm[4], lm[12])` | Secondary continuous control independent of main pinch |
| Index ↔ middle | `dist(lm[8], lm[12])` | "Two finger spread" — natural for scale gestures |
| All-finger curl | average of MCP-to-tip Y-distances | Fist-clench → trigger / threshold |
| Hand tilt | `atan2(lm[9].y − lm[0].y, lm[9].z − lm[0].z)` | Camera pitch (Stage 2 in radon-tree plan) |

For each new channel, extend the upstream parser (e.g. `hand_parser` scriptCHOP) — additions-only, never edit existing channels. Then add a parallel `select → math → gate → smooth → null → camera_param` chain in the camera-control COMP.

### Different effect target

Same chain pattern, different consumer:
- Camera params (tx/ty/tz/rx/ry/rz/fov/orthowidth) — direct expression / export
- GLSL shader uniforms — bind via shader's parameter page
- Particle system spawn-rate / velocity — math output → POP / SOP param
- Audio mix — math output → audioCHOP gain

The chain is the same; only the final binding changes. Worth wrapping different consumers as separate COMPs (one per consumer) so you can mix and match.

---

## Calibration drift — design for it

MediaPipe's hand detection assigns indices by **detection order**, not handedness. "Hand B" may be your right hand in one frame and your left hand in the next if detection order flips. Symptoms: the camera suddenly responds to the wrong physical hand, or stops responding entirely.

Mitigations:

1. **Lock by handedness, not index.** The parser can emit `hand_a_is_right` / `hand_b_is_right` flags. Downstream chain switches its source based on the flag rather than the suffix.
2. **Expose a manual `Swap` toggle.** Single click recovery when MediaPipe gets confused. Cheap, predictable.
3. **Calibration session at startup.** First detection determines mapping for the session; manual override available.

Today's radon-tree build uses Source-suffix routing (hand_a vs hand_b). The handedness flags are emitted but not consumed by camera_control. Adding handedness-locked routing is a future polish.

---

## Empirical tuning notes (from the radon-tree build)

| Setting | Final value | Why |
|---|---|---|
| `Ycenter` | 0.5 | Image-space center; user's hand naturally rests near vertical middle of webcam frame |
| `Ygain` | 2.0 | Range −1 to +1 camera world units felt natural for a tree at z=−6 |
| `Smoothlag` | 0.15s | Compromise between snappy response and jitter rejection |
| `Yrest` | 0.0 | Default centering; we added Yrest param but found 0 worked once the gate was in place |
| `zoom_lag` (upstream) | 0.7s → 1.0s | Tuned UP because pinch-noise jitter on hold-still became visible when zoomed in close. Lag-based filtering is a partial solution; deadband / median would help further — backlog. |
| `pinch_lag` (shared) | 0.1s | Kept low: shared between zoom AND rotation chains, raising it makes rotation feel sluggish. |

---

## Known limits / open questions

| Question | Status |
|---|---|
| Lag-based smoothing has diminishing returns on hold-still oscillation around a stable pinch. Median filter or hysteresis-deadband would target the actual signal shape better. | Not yet built. Backlog. |
| Handedness-locked routing (use `hand_*_is_right` flags vs detection-order suffix) | Designed, not implemented in camera_control |
| Multi-axis composition (Y + pitch + roll) — do the chains compose linearly or does CameraExt's matrix-order matter when bypassed by SRT-driven bare camera? | Untested at scale; theoretical answer: SRT applies in `xord` order, so multi-axis works as expected. |
| Pitch via worldLandmarks 3D vs image-space-Y proxy | Worldlandmarks is the planned path; proxy is the fallback. Both untested in production. |

---

## Companion artifact

`templates/components/hand-driven-camera-y.tdn` — exported from radon-tree project 2026-06-XX (capture deferred until TD is idle from the splat-load cook). Re-import workflow:

1. `import_network` the .tdn into your project's `/project1/` (or wherever your `hand_control` lives).
2. Re-wire the `pick` selectCHOP's `chop` parameter to point at YOUR project's hand-source.
3. Update `Source` custom param to match your hand-index convention.
4. Bind your camera's `ty` param via expression to the `cam_y_out` null.
5. Tune `Ycenter / Ygain / Smoothlag` to your scene scale.

---

## Provenance

- **Originated:** 2026-05-31 production session (`hand_control_BANG_rfsu` → renamed `hand_control_radon_tree` 2026-06-01)
- **Verified:** rendered tree responds to vertical hand motion; camera centers on hand absence; zoom-via-mirror-binding preserved across camera swap
- **Confidence:** HIGH for the architecture (5-stage chain, two-camera split, mirror-binding rule). MEDIUM for the empirical tuning numbers — they're radon-tree-scene-specific; the calibration framework generalizes but the constants don't.

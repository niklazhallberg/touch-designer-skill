# MediaPipe component (`torinmb/mediapipe-touchdesigner`)

GPU-accelerated MediaPipe plugin by Torin Blankensmith and Dom Scott. Hand / face / pose / object tracking, gesture recognition, image segmentation. Cross-platform.

**Mac prerequisite:** Full Disk Access — see `mac-gotchas.md` § "MediaPipe requires Full Disk Access". Without it, the component fails silently with no console error.

**TD version requirement:** TouchDesigner **2022.33910 or later** — the plugin relies on TD's embedded Chromium browser which shipped in that build.

**Source:** [github.com/torinmb/mediapipe-touchdesigner](https://github.com/torinmb/mediapipe-touchdesigner) — repo README (primary).

---

## Architecture — embedded Chromium + WebAssembly + local WebSocket

**Source:** [github.com/torinmb/mediapipe-touchdesigner](https://github.com/torinmb/mediapipe-touchdesigner) — repo README (primary) | **Confidence:** HIGH

The plugin does **not** run MediaPipe natively in TD. Internally:

1. TD's embedded Chromium browser hosts the MediaPipe JavaScript bindings.
2. ML model inference executes via **WebAssembly** in the browser context.
3. Results are piped from browser → TD via a **local WebSocket server** embedded inside the component.
4. JSON detection results land on `*_results` DATs; segmentation masks land on internal TOPs.

**Why this matters for the agent:** every observable latency, async-style behavior, or "the data is one frame behind" symptom traces back to this architecture. The ML side is *not* on the cook clock — it runs at its own pace in the browser process and crosses into TD via async WebSocket messages. See § "Frame delay" below for the measured consequence; the architecture here is the **root cause** (not a tuning problem).

**Input resolution limit: 720p.** Per the repo README: *"Currently the model is limited to 720p input resolution."* If your camera or source TOP runs at higher resolution, the plugin will down-sample internally. Plan upstream resolution + any upscaling-of-mask logic accordingly.

---

## Frame delay — plugin output is ≥3 frames behind realtime

**Source:** TD/MCP research dossier (May 2026), torinmb/mediapipe-touchdesigner | Date: May 2026 | **Confidence:** HIGH (dossier-confirmed + user has hit the symptom in production; Cache TOP workaround is the documented architectural fix)

> **Root cause is documented in § "Architecture" above.** The ≥3 frame lag is not a tuning problem — it's the inherent cost of crossing the browser/WebAssembly/WebSocket boundary on every frame. No plugin configuration removes it. Treat Cache TOP compensation as an architectural requirement for any "overlay on live video" wiring.

The plugin uses an internal web-browser component for ML inference, which introduces a delay of **at least 3 frames** between camera input and tracking output. The `instance_data` channels (hand positions, pose keypoints, etc.) lag the visible webcam feed by that amount.

**When this matters:**

- Compositing the tracking overlay onto the live camera feed — overlay appears delayed relative to motion
- Reactive synthesis driven by hand/pose data — perceptible lag between physical motion and synthesized response
- Frame-tight audio-visual sync work
- Any "hand+camera" composite where the user expects the overlay to track exactly

**Workaround:** insert a **Cache TOP** on the camera branch to delay it 3+ frames, then resync with the tracking output downstream. The exact frame count is empirical — start at 3 and adjust by visual inspection until overlay and camera agree.

**Rule for the agent:** when wiring MediaPipe output into a render path that also uses the same camera feed, ALWAYS insert a Cache TOP on the camera branch to compensate. The compensation isn't optional for any "overlay on live video" use case.

**Check first when:**

- Hand/pose overlay drifts behind visible motion
- User reports the tracking "feels laggy" but FPS is fine
- A composite of MediaPipe output + camera looks off by a few frames

---

## Video input — Mac needs OBS Virtual Camera as a bridge for non-webcam sources

**Source:** [github.com/torinmb/mediapipe-touchdesigner](https://github.com/torinmb/mediapipe-touchdesigner) — repo README (primary) | **Confidence:** HIGH

The plugin reads input from a webcam selector dropdown. For sources that aren't a system-recognized webcam (video file, Syphon stream, NDI input, scriptTOP output, etc.) you need a bridge:

| Platform | Bridge | Notes |
|---|---|---|
| **macOS** | OBS Studio → "Start Virtual Camera" | No Syphon equivalent supported by the plugin. OBS becomes a virtual webcam that the plugin's webcam selector then sees. |
| **Windows** | SpoutCam | Spout-source ↔ SpoutCam → plugin sees as webcam. Multi-GPU laptops may show noise; configure GPU pipeline in SpoutSettings if so. |

This is a recurring "I want to feed a non-camera source into MediaPipe" pattern. The plugin does **not** accept TOP inputs directly — it always reads from a webcam source enumerated by the OS. The OBS / SpoutCam bridge is the architectural workaround.

---

## Disable unused detection tasks — CPU + GPU savings

**Source:** TD/MCP research dossier (May 2026) | Date: May 2026 | **Confidence:** HIGH (component behavior is documented via the plugin's parameter pages; the per-task cost claim is architectural — each detector runs independently)

The plugin runs detection tasks on a configurable set: face landmarks, face detector, hands, pose, objects, image classification, image segmentation, image embeddings. **Each enabled task carries CPU + GPU cost** — leaving all of them on for a project that only uses hand tracking burns frame budget on unused detectors.

**Rule:** on the MediaPipe COMP's tabs (Hands / Face / Pose / Objects / Image Classification / Image Segmentation / Image Embeddings), turn OFF every detection task the project doesn't consume. The component exposes per-task toggles directly on its parameter pages.

**Check first when:**

- FPS is below target on a MediaPipe-heavy project
- The project clearly only uses one detection modality
- `get_op_performance` shows the MediaPipe COMP as a hotspot
- Multiple detection tabs show "On" but only one is wired to anything downstream

---

## Officially unsupported tasks: Interactive Segmentation + Image Embedding

**Source:** [github.com/torinmb/mediapipe-touchdesigner](https://github.com/torinmb/mediapipe-touchdesigner) — repo README (primary) | **Confidence:** HIGH

Two MediaPipe ML tasks exist in the upstream MediaPipe library but are **not implemented** in this TD plugin:

- **Interactive Segmentation** — click-driven mask refinement (e.g. "click a person, get a clean mask"). Not wired in v0.5.2.
- **Image Embedding** — produces feature-vector embeddings of an image. Toggle `Detectimageembeddings` exists on the UI but the data path is incomplete.

**Don't waste time trying to enable these for a project.** If embeddings or interactive segmentation are needed, use a separate Python process (e.g. CLIP via `transformers`) and stream results over OSC/WebSocket into TD instead.

The supported tasks are: Face Detection + Face Landmarks, Hand Tracking + Gesture Recognition, Pose Estimation, Object Detection, Image Segmentation (background/foreground + multi-class), Image Classification.

---

## Parameter names + defaults (v0.5.2, verified live)

**Source:** live verification 2026-06-01 during Heatmap_Body_Tracker Phase 0 bootstrap (mediapipe-touchdesigner v0.5.2 on TD 2025.32820, M1 Pro) | Date: 2026-06-01 | **Confidence:** HIGH (all values read from live `get_op` output on the component, not from docs)

Built-in detector toggles, all on the top-level Custom parameter page:

| Parameter | Default | Notes |
|---|---|---|
| `Pnumposes` | 1 | Max simultaneous tracked poses. Multi-person use case: bump to your N (5 is common). |
| `Detectposes` | True | Pose Landmarker enable. |
| `Detectsegments` | **False** | Image Segmentation enable — **the only default-OFF detector**. Explicit opt-in required for the multi-person silhouette use case. |
| `Detectfacelandmarks` | True | Face Landmarker. |
| `Detectfaces` | True | Face Detector. |
| `Detectgestures` | True | Hand Gesture detection. |
| `Detectobjects` | True | Object Detector. |
| `Detectimages` | True | Image Classifier. |
| `Detectimageembeddings` | True | Image Embedder. |

**Watch for:** the asymmetric default (one detector OFF, six ON) is a perf trap. A fresh project that wants only pose tracking inherits 7-detector overhead until those toggles get flipped off explicitly. Don't trust "default" — explicitly set every detector toggle to the project's actual needs.

Segmentation model selection:

| Parameter | Default | Alternatives |
|---|---|---|
| `Smodeltype` | `selfieMulticlass` | 6-class output (background, hair, body_skin, face_skin, clothes, accessories) — exposes per-class colors via `Scolor0r..Scolor6b`. Other values: `selfie`, `landscape`, person/background. Test alternatives in Phase 1 for instance-mask use cases. |

---

## Performance reality on M1 Pro at default settings

**Source:** live measurement 2026-06-01 during Heatmap_Body_Tracker Phase 0, M1 Pro / TD 2025.32820 / FaceTime HD Camera 1280×720 | Date: 2026-06-01 | **Confidence:** HIGH (measured via the component's own `realtimeCalculatorCHOP` channels, hard numbers)

With Pose Landmarker (`Posemodeltype = full`) + Image Segmentation (`Smodeltype = selfieMulticlass`) + `Pnumposes = 5` all enabled:

| Channel | Value | Interpretation |
|---|---|---|
| `detectTime` | **75 ms** | Per-frame inference cost. |
| `realTimeRatio` | **2.25** | Running 2.25× slower than realtime → ~13 FPS effective at 30 FPS source. |
| `isRealtime` | **0** | Not keeping up. |
| `totalInToOutDelay` | -7.5 | Suspect value (sign/unit unclear — open question, see Known gaps). |

**Implications:**

- Pre-build research estimates (e.g. 17–28 ms based on docs / community reports) were ~3× optimistic on this hardware. Real budget at these defaults is closer to 75 ms.
- 30 FPS sustained is **not** achievable at defaults. Tuning is mandatory for live use.
- Visual prototype work can proceed at sub-30 FPS — but plan for tuning before any production demo.

**Tuning levers (in order of recover-most-time-first):**

1. **`Posemodeltype = lite`** (instead of `full`) — drops the heaviest single model. Quality cost is real but acceptable for prototyping.
2. **`Pnumposes = 1` or `2`** (instead of 5) — single-user or 2-person scenes don't need 5.
3. **`Smodeltype` to `selfie` or person/background** (instead of `selfieMulticlass`) — fewer output classes = lighter inference.
4. **Disable Segmentation entirely** if a Pose-skeleton-based silhouette suffices for the use case.
5. **Drop input resolution** (640×360 → upsample mask downstream).

Don't optimize blindly — measure after each lever via the same `realtimeCalculatorCHOP` channels.

---

## Subnet structure + canonical output paths (v0.5.2)

**Source:** live `find_children` on the MediaPipe COMP 2026-06-01 during Heatmap_Body_Tracker Phase 0 | Date: 2026-06-01 | **Confidence:** HIGH (verified by direct subnet enumeration)

The MediaPipe COMP exposes 71 children. Canonical Phase 1+ tap points:

| Path (relative to MediaPipe COMP) | Type | What it carries |
|---|---|---|
| `Viewer` | nullTOP, 1280×720 | Composited overlay (webcam + landmarks + bbox + confidence labels). Cosmetic surface — see Known gaps re: stale labels. |
| `pose_results` | textDAT | Raw landmark JSON, ~7 KB/frame at 1 person (x, y, z, visibility per landmark). |
| `pose_tracking/out1` | CHOP | Multi-pose CHOP output — sample-per-person. |
| `image_segmentation/segmentation_mask` | TOP | Multi-class segmentation output when `Smodeltype = selfieMulticlass`. |
| `image_segmentation/selfie_mask` | TOP | Alternate, simpler mask. |
| `realtimeCalculatorCHOP` | scriptCHOP | Perf-monitoring channels: `detectTime`, `drawTime`, `sourceFrameRate`, `realTimeRatio`, `totalInToOutDelay`, `isRealtime`. |

**Rule for the agent:** when building downstream of MediaPipe, always tap one of these named outputs — don't poke into arbitrary internal subnet ops. The 5 paths above are the documented integration surface for v0.5.2; everything else inside is implementation detail subject to change between releases.

---

## MCP drop-in pattern: `loadTox()` is cleaner than `create_op + externaltox`

**Source:** verified working 2026-06-01 during Heatmap_Body_Tracker Phase 0 drop-in | Date: 2026-06-01 | **Confidence:** HIGH (used in production successfully today)

To programmatically drop a vendored .tox component into `/project1` (or any parent), use:

```python
new_comp = op('/project1').loadTox('/abs/path/to/Component.tox', password='', unwired=True)
```

- `loadTox` returns the new COMP reference, ready for further `set_parameter` / position calls.
- `unwired=True` is the safe default for fresh drop-in — no auto-wiring to existing siblings.
- `password=''` is required even for unencrypted tox files (component accepts empty string).
- Use via `mcp__envoy__execute_python` since `loadTox` isn't exposed as a dedicated MCP tool.

Compare with the alternative `create_op(baseCOMP) + set_parameter(externaltox = path)` pattern: that requires a follow-up `cook_op` / explicit reload step and risks the external reference becoming a dangling parameter. `loadTox` instantiates the .tox contents inline.

**Check first when:**

- Setting up a vendored 3rd-party component (MediaPipe, YOLO, custom .tox) in a new project
- The .tox should be a self-contained internal COMP, not an externalized reference

If the same `loadTox` pattern proves canonical for non-MediaPipe components in future projects, promote this rule out of `mediapipe.md` and into a general "vendored .tox drop-in" section of `references/td-gotchas.md` or similar.

---

## Debugging — Chrome DevTools at `localhost:9222`

**Source:** [github.com/torinmb/mediapipe-touchdesigner](https://github.com/torinmb/mediapipe-touchdesigner) — repo README (primary) | **Confidence:** HIGH

While TD is running with the MediaPipe component active, the embedded Chromium instance exposes its DevTools at:

```
http://localhost:9222
```

Open in a regular Chrome / Chromium browser on the same machine. Gives you:

- The WebSocket message stream (browser → TD) for verifying inference output
- WebAssembly performance profiling (which detector is slow inside the browser process)
- JavaScript console errors from the MediaPipe runtime
- Network tab for tracing model-load timing

**When to reach for it:** the TD-side `realtimeCalculatorCHOP` channels (`detectTime`, etc.) show numbers that don't match what you expect, OR detection results look wrong/stale and the cause isn't visible from TD's side. DevTools lets you see the browser-side reality the plugin is hiding.

---

## Known gaps (deliberately empty)

These are publicly unresolvable or unmeasured. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md § Pre-ask filters`):

| Gap | Where it surfaces |
|---|---|
| Exact frame-delay variance by detection task — "≥3 frames" is verified, but face vs hands vs pose individual delays not measured | First time per-task latency matters for a tight A/V sync use case |
| CPU vs GPU cost split per detection task — disabling helps overall, but which task is the heaviest specifically? | First time profiling MediaPipe is needed for a perf-critical project |
| `totalInToOutDelay` sign/unit — measured -7.5 at Pose+Seg defaults on M1 Pro; unclear whether this is frames, milliseconds, signed offset, or component bug | First time the agent needs to reason about MediaPipe latency from this CHOP specifically |
| Viewer overlay vs detector-toggle state — disabled detectors (`Detectfaces=0`, etc.) still showed labels in the Viewer overlay during Phase 0. Unclear whether (a) the Viewer is purely cosmetic and unrelated to actual detector state, (b) toggles have latency to propagate, or (c) something else. The pose data DAT updated correctly, so the underlying pipeline followed the toggles; Viewer overlay is suspect | Phase 1 investigation, or any time the user inspects Viewer for verification |
| Combined hand+face+pose tracking simultaneously on M1 Pro — Phase 0 measured Pose+Seg only (75 ms); the 3-detector combination is still unmeasured | First time the user enables 3 ML detectors together |
| Whether the web-browser inference path can be replaced (Core ML / ONNX) to drop the ≥3 frame lag on Mac | First time the lag is unacceptable for a project |
| `instance_data` channel naming conventions across plugin versions (drift unverified) | First time the plugin updates and downstream wiring breaks |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

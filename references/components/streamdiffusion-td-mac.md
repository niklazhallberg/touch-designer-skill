# StreamDiffusion + TouchDesigner on Mac M1 — master reference

**Source:** User-provided research dossier, 2026-06-07 (synthesized from dotsimulate.com/docs/streamdiffusiontd, docs.daydream.live, Derivative community posts, Interactive & Immersive HQ, AllTouchDesigner) | **Confidence:** MEDIUM (external, vendor-documented; the author tags every claim with `[OK]/[LIKELY]/[INFER]/[TEST]` — those tiers MUST be respected, and they map to the skill-growth-protocol v0.3 source-confidence tiers as below)

**When to load this reference:** Any of the following triggers — user mentions StreamDiffusion / StreamDiffusionTD / dotsimulate / Daydream, asks for realtime AI image generation in TD, wants body/hand/audio → AI visuals on a Mac (M1+), or asks "can I run diffusion locally in TD on Mac" (the answer is in § 2).

## Author confidence tags vs protocol v0.3

| Doc tag | Meaning | Maps to v0.3 |
|---|---|---|
| **[OK]** | Verified against primary source (vendor docs) | MEDIUM (vendor-verified, no own empiry) |
| **[LIKELY]** | Primary source + corroboration, one inference step remains | MEDIUM (with caveat — fallback recommended) |
| **[INFER]** | Reasoned design conclusion, not directly documented | LOW (hypothesis, validate in-app) |
| **[TEST]** | Cannot be settled from docs; must be measured in TD/Scope | UNKNOWN — re-check obligation (see § 11) |

**Status: verify before relying — this dossier was authored 2026-06-07; re-check before any production install.** Per the author's own warning, this space moves monthly. Version numbers, server regions, beta status, and the CoreML bridge are the most volatile items. Section 11 is the explicit re-check checklist.

**Source-conflict resolution per author:** Daydream's own docs win for the Daydream backend; dotsimulate's docs win for the operator/local behavior. Patreon-scraper mirrors (Kemono) and undated social posts are weak — never implement on them alone.

---

**Target rig context:** MacBook Pro M1, 32 GB unified memory, macOS. No local NVIDIA GPU.
**Goal context:** TD-driven interactive install where hands/body/audio steer a real-time StreamDiffusion image via ControlNet, with interaction that *feels direct*.

---

## 0. The one-paragraph verdict

Build on **dotsimulate's StreamDiffusionTD operator with the Daydream cloud
backend** ("Route A"). It is the de-facto standard, the only mature StreamDiffusion
operator for TD, and the only path that gives you SD-based **OpenPose ControlNet**
for body tracking on a Mac. **[OK]** Local diffusion on M1 is not viable for realtime
(ControlNet needs TensorRT, which Apple Silicon lacks; raw img2img runs ~0.5–5 fps).
**[OK]** The alternative cloud product — **Daydream Scope + Remote Inference** ("Route
B") — is built around Wan2.1 video models with VACE conditioning, not SD-style
ControlNet, and is still beta with LoRAs/plugins disabled in remote sessions; keep
it as a secondary creative layer, not your body-tracking path. **[LIKELY]** The two
things that actually decide whether your install *feels direct* are not settled by
any document and must be tested by you: **Daydream's server region relative to
Stockholm**, and **whether the new CoreML-TDSyphon bridge works as described** for
local conditioning. **[TEST]**

---

## 1. The decision: Route A vs Route B (head-to-head)

| Dimension | **Route A — StreamDiffusionTD + Daydream backend** | **Route B — Daydream Scope + Remote Inference + Syphon** |
|---|---|---|
| What it is | dotsimulate TOX, `Backend=Daydream`, inference in cloud, output via WebRender TOP inside TD | Standalone Scope app, cloud H100s, video bridged to TD over Syphon |
| Lives where | Inside the TD network | Separate app, bridged in |
| SD-based ControlNet (incl. **OpenPose**) | **Yes** [OK] | **No** — uses VACE conditioning, different paradigm [LIKELY] |
| Models | SD-Turbo, SDXL-Turbo, SD1.5 [OK] | Wan2.1 (StreamDiffusion V2), LongLive, Krea, RewardForcing, MemFlow [OK] |
| IP-Adapter / FaceID | Yes (SDXL-Turbo, SD1.5) [OK] | Via VACE reference image; LoRAs in local only [LIKELY] |
| Cloud hardware | Reported RTX 4090 [LIKELY] | H100 [OK] |
| Temporal consistency | Manual: feedback TOPs both sides [OK] | Model-native autoregressive V2V [OK] |
| Transport | One API call + WebRender frame back | Two Syphon transfers + two WebRTC legs + Scope app boundary [INFER] |
| End-to-end latency | Fewer hops -> likely lower [INFER] | More hops; H100 speed offset by bridge overhead [INFER] |
| Stability | v0.3.x stable release [LIKELY] | Beta; 1-hour remote sessions; restart to switch pipelines [OK] |
| Mac setup | Low: TOX drag-in, API key, ffmpeg | Medium: .dmg, remote toggle, Syphon both sides |
| **Use for** | **Your primary build — body/hand/audio -> ControlNet** | Secondary layer for Wan2.1-style video continuity |

> **Decision rule for the agent:** default to Route A for anything involving
> OpenPose/ControlNet body tracking. Only reach for Route B if the user explicitly
> wants Wan2.1 video continuity or LoRA-driven looks and accepts the bridge.

---

## 2. Why local-on-M1 can't carry the realtime load

- ControlNet, IP-Adapter, and StreamV2V all **require TensorRT** (dotsimulate
  parameter docs). TensorRT is NVIDIA-only, **not supported on Apple Silicon**
  (dotsimulate v0.2.6 changelog). [OK]
- Daydream's own prerequisites confirm the split: local/desktop inference needs an
  NVIDIA GPU >=24 GB VRAM + CUDA 12.8; **Mac users run inference remotely.** [OK]
- Raw StreamDiffusion img2img on M1 (MPS): ~0.5–5 fps with mid-stream drops. Fine
  for offline look-dev, not for an interactive install. [OK]
- **Therefore:** TD is always the *local control brain* (tracking, audio analysis,
  routing, compositing, output). Diffusion always runs on a *remote GPU*.

> **The one local exception worth using — preprocessing, not diffusion:** the
> **CoreML-TDSyphon Bridge** (Derivative community, ~April 2026) reportedly runs
> vision models like DepthAnythingV2 on the Apple Neural Engine at **40+ fps** and
> Syphons the result into TD. That is exactly right for building local depth/pose
> conditioning images at zero cloud latency — then feed to Daydream for diffusion.
> **[TEST]** Verify the bridge exists and works as described before designing around it.

---

## 3. ControlNet availability is MODEL-GATED (the rule that bites)

The single most common planning mistake. On the Daydream operator backend, which
ControlNets exist depends on the base model: **[OK]**

| Model | ControlNets | **OpenPose?** | IP-Adapter? | Notes |
|---|---|---|---|---|
| **SD-Turbo** | OpenPose, HED, Canny, Depth, Color | **YES** | **No** (SD2.1-based) | Most CN variety; fastest |
| **SDXL-Turbo** | Depth, Canny, Tile (xinsir) | **No** | **Yes** (incl. FaceID) | Best quality; no pose |
| **SD1.5** (Dreamshaper 8, Openjourney v4) | OpenPose, HED, Canny, Depth, Color, TemporalNet | **YES** | Yes | Wide concept-art range; TemporalNet = flicker control |
| **Wan2.1** (Scope only) | VACE (depth/scribble/optical-flow control video) | No (not SD-sense) | N/A | Different paradigm entirely |

> **Implication for your hands/body vision:**
> - Want **literal skeletal pose** -> choose **SD-Turbo or SD1.5** (you lose IP-Adapter
>   on SD-Turbo; SD1.5 keeps it). [OK]
> - Want **SDXL quality + IP-Adapter FaceID** -> you only get **Depth/Canny/Tile**, so
>   drive the body with a **Depth map** (volume) or **Canny** (outline), not OpenPose.
>   Often looks better for full-body anyway (less jitter). [OK]
> - **TemporalNet** (SD1.5/SD-Turbo) is the anti-flicker ControlNet for moving bodies. [OK]
>
> **Practitioner lean:** SD-Turbo + OpenPose gives the tightest 1:1 body->structure
> feel; SDXL + Depth/Canny gives cinematic quality with IP-Adapter style-lock. [INFER]

---

## 4. The big simplification: Daydream does preprocessing server-side

This changes how you wire everything, and it's the most important practical fact: **[OK]**

- **Local mode:** YOU build the conditioning image (edge/depth/pose) in the TD
  network and feed the operator's **second input (IN2)**; IN2 resolution must match IN1.
- **Daydream mode (your case):** feed your **raw camera to IN1 only**. The server runs
  its own preprocessors (depth, canny, HED, OpenPose). **You do NOT build an OpenPose
  render in TD.** Conditioning is applied server-side.

Multi-ControlNet on Daydream is an **array in the request**, all CNs initialized at
stream start, toggled live by changing `conditioning_scale` (0 disables a CN without
a pipeline reload). The operator's `Cn` Sequence (`op('StreamDiffusionTD').par.Cn`)
maps to this — model ID + preprocessor + weight + enable per block. [OK]

```json
// Daydream API shape (confirmed on docs.daydream.live/api/quickstart)
{
  "pipeline": "streamdiffusion",
  "params": {
    "model_id": "stabilityai/sdxl-turbo",
    "prompt": "oil painting portrait",
    "controlnets": [
      { "enabled": true, "model_id": "xinsir/controlnet-depth-sdxl-1.0",
        "preprocessor": "depth_tensorrt", "conditioning_scale": 0.5 },
      { "model_id": "xinsir/controlnet-canny-sdxl-1.0",
        "preprocessor": "canny", "conditioning_scale": 0 }
    ]
  }
}
```

ControlNet operating rules: `Usecontrolnet` ON at stream start (toggle/weight live
after); scales 0.0–1.0, start at 0.5; each CN adds latency, enable only what you need;
dual-CN verified. [OK]
The exact `Cn` block weight parameter name in the operator UI is **[TEST]** (section 11).

---

## 5. Low-latency architecture (your primary objective)

No published Mac->cloud->back millisecond figures exist for either route. [OK]
Derived budget for Route A: ~22 fps cloud -> ~45 ms/frame; + camera capture ~33 ms;
+ network RTT (EU ~15–40 ms, US ~80–120 ms) -> **~65–125 ms perceived** if servers
are near. [INFER] The RTT term dominates and depends on **server region — unknown,
must verify (section 11).** [TEST]

**Latency-hiding techniques that actually work (apply several together):**
- **Local preview layer** — overlay the live MediaPipe skeleton / conditioning image
  semi-transparent on top of the diffused output. Something responds in <1 frame, so
  the whole thing *feels* direct while the AI layer catches up behind. [INFER] strongest lever
- **Feedback TOP both sides of the TOX** (opacity ~0.7–0.85): input-side calms jerky
  input before inference; output-side blends incoming frames. The canonical fix. [OK]
- **Filter CHOP (lag 0.05–0.1 s) on all tracking channels** — makes motion read as
  intentional and masks 1–2 frame drops. [INFER]
- **Kalman-style prediction on skeleton** to fill gaps between tracking frames. [INFER]
- **txt2img + ControlNet instead of img2img** — AI responds to body *structure*, not
  every camera pixel; more robust and faster. [INFER]
- **`Limitfps` 12–15 + output feedback 0.8** — fewer API calls, steadier generation,
  smoother than 20 fps with gaps. [LIKELY]
- **Local conditioning via CoreML bridge** (if verified) removes the preprocess hop
  entirely for depth. [TEST]

---

## 6. Interactive input pipelines (concrete TD operator chains)

Each pipeline's job: turn an interactive signal into either a **conditioning input**
(camera->IN1, server preprocesses) or a **parameter value** (prompt/seed/scale).

### 6A. Body -> OpenPose ControlNet (recommended for pose) [OK arch / INFER tuning]
```
Video Device In TOP (webcam)
  -> [optional Level/Blur for cleaner input]
  -> StreamDiffusionTD IN1            (raw feed; server runs OpenPose preprocessor)
Model: SD-Turbo (OpenPose available; no IP-Adapter)  OR  SD1.5 (OpenPose + IP-Adapter)
ControlNet: openpose, Usecontrolnet ON, scale ~0.5 then tune
```
No in-TD skeleton render needed in Daydream mode. The body steers image structure.

### 6B. Body/figure -> Depth or Canny (recommended for SDXL quality) [OK arch]
```
Video Device In TOP -> StreamDiffusionTD IN1   (server runs depth/canny preprocessor)
Model: SDXL-Turbo  -> keeps IP-Adapter FaceID
ControlNet: depth (volume) or canny (outline), scale ~0.5
```

### 6C. Hands as controllers — NOT a hand ControlNet [OK reasoning]
MediaPipe hand landmarks drop on fast motion/occlusion/distance, which makes bad
conditioning frames. So drive **scalar params** instead:
```
MediaPipe (torinmb plugin) -> hand landmark CHOPs
  -> Filter/Kalman CHOP (smooth)
  -> pinch_strength  -> Cnweight (CN in/out with gesture)
  -> wrist y / hand height -> Guidancescale (abstraction level)
  -> handedness     -> Promptdict blend (L/R hand = different prompt)
  -> pinch trigger  -> Seed change (style shift)
```
Body pose -> OpenPose CN; hands -> parameter modulation. Best of both. [INFER]

### 6D. Audio-reactive -> parameter modulation [OK pattern]
```
Audio Device In CHOP
  -> audioAnalysis COMP (TD Palette): low/mid/high/kick/snare/rhythm
  -> Select CHOP (isolate band) -> Math CHOP (remap) -> Filter CHOP (smooth) -> Null CHOP
  -> export to:
       Prompt Schedule weights (blend on beat; slerp)
       Seed Schedule (-1 / randomize; step on onset)
       ControlNet scale (pump structure with the kick)
       Steps / Delta / Guidance (responsiveness with energy)
```
Bind: drag CHOP channel onto the parameter, or `op('null_audio')['kick']` in an expr.
Audio modulates parameters; it doesn't make a conditioning image. [OK]

### 6E. Camera -> img2img [OK]
```
Video Device In TOP -> Level TOP -> [Blur] -> [Noise x Multiply for richer features]
  -> Resize TOP 512x512 -> StreamDiffusionTD IN1
```
Feature-rich input matters: the model encodes edges/textures/spatial structure, not
literal pixels. Featureless input (sparse particles, flat color) -> incoherent output. [OK]

### 6F. The showpiece — multi-CN + multi-driver [OK example]
Daydream's VJ example: **Depth @ 0.6 + Canny @ 0.3**, prompt schedule animated by
CHOPs, IP-Adapter cycling style images. Extend: body depth -> CN1, hands -> CN scale,
audio -> prompt blend.

### Routing & callbacks [OK]
Export CHOP channels to parameters, or script via callbacks: `onReceiveFrame`,
`onStreamStart`, `onStreamEnd`, `onFrameReady`, `onImageChange`. Operator also takes
MIDI/OSC like any TD component.

---

## 7. Parameter surface (Daydream backend) [OK]

| Parameter | Use |
|---|---|
| **Prompt Schedule** | Weighted prompts `[("anime",1.0),("oil painting",0.5)]` |
| **Prompt Interpolation** | `linear` / `slerp` (slerp = smooth morphs, best for VJ) |
| **Negative Prompt** | e.g. "blurry, low quality, flat" |
| **Seed Schedule** | Weighted seeds `[(42,1.0),(123,0.5)]`; **Randomize Seeds** button |
| **Seed Interpolation** | `linear` / `slerp` |
| **Guidance** | Prompt adherence 1.0–3.0 |
| **Delta** | Diffusion strength 0.0–1.0 (low = stable, high = responsive) |
| **Steps** | 1–4 (2–3 enough for realtime) |
| **ControlNet scales** | Per-CN 0.0–1.0 (start 0.5; 0 = disabled, no reload) |
| **IP Adapter** + Scale + Type | `regular` or `faceid` (SDXL only) |
| **Limitfps** | Cap API/render rate (12–15 for latency smoothing) |

Prompt scheduling animated from CHOPs with `slerp` is the killer live feature. [OK]

---

## 8. The tracking plugin: MediaPipe for TouchDesigner [OK]

- **Use Torin Blankensmith + Dom Scott's `mediapipe-touchdesigner`**
  (github.com/torinmb/mediapipe-touchdesigner). GPU-accelerated, **Mac + PC, no
  install**, WebGL-based (no Python dependency on Mac). Face/hand/pose/object +
  segmentation. [OK]
- **Avoid** `LucieMrc/MediaPipe_TD` on M1 — Python-based, needs Rosetta2 + x86
  Python 3.7, fragile. [LIKELY]
- The plugin has a built-in skeleton overlay AND landmark CHOP data. Its overlay uses
  MediaPipe colors, **not** OpenPose color convention — but in Daydream mode this is
  moot (server detects pose from raw camera). Only matters for local mode. [OK]
- Check the GitHub releases page for the current version on M1 today. [TEST]

**Cross-link:** `references/components/mediapipe.md` for the full MediaPipe component reference, including the Mac Full Disk Access prerequisite.

---

## 9. Realtime quality — making it not look bad [OK]

**#1 complaint: jumpy/"skippy" output** — frames are semi-independent.
**Fix: feedback + opacity reduction on BOTH sides of the TOX.**
```
[input] -> Feedback TOP (op ~0.7–0.85) -> StreamDiffusionTD -> Feedback TOP (op ~0.7–0.85) -> [output]
```
- Color washout from feedback accumulation: add a Level TOP before the feedback and
  lower opacity/brightness for longer trails without bleaching. [OK]
Other levers: **TemporalNet** CN (SD1.5/SD-Turbo) for motion; **Steps** higher = more
stable; **Delta** lower = more stable; fixed **Seed** = stable, `-1` = variation;
prompt **slerp**; start **512x512 / 2–3 steps**. [OK]
StreamV2V (cached attention) is **local-NVIDIA only** — not available on Mac/Daydream;
use feedback TOPs instead. [OK]

---

## 10. Setup & known errors (Mac, Route A) [OK]

**Prerequisites:**
```bash
brew install ffmpeg && ffmpeg -version          # required by Daydream backend
# TouchDesigner 2023.12600 (Mac build) — match the TOX's tested TD version
# StreamDiffusion 0.3.x TOX from patreon.com/dotsimulate
# Daydream API key: app.daydream.live/dashboard/api-keys
# Optional: Andrew's "Daydream SDXL Easy Quickstart File" (prebuilt project)
```
**First run:** drag TOX -> Install page -> Backend=Daydream -> paste API key ->
Start Stream (~30 s to first output; allow longer for cloud GPU provisioning). [OK]

**Mac landmines & fixes:**
| Issue | Fix |
|---|---|
| API key field read-only | Right-click field -> toggle "readonly" off |
| ffmpeg not found by TD | Ensure `/opt/homebrew/bin` is on TD's PATH (`os.environ['PATH']` in Textport) |
| numpy >=2.0 crash on stream connect (TD 2025 on Mac) | `pip install numpy==1.24.1` via Textport, restart — or just use TD 2023.12600 |
| torch version errors (local) | Python must be 3.10.x/3.11.x (use 3.11.9/3.11.10) |
| `no module named 'streamdiffusion.config'` | Don't name install folder `streamdiffusion` |
| Session limit | Daydream gives ~1 h GPU per session; reconnect for a new one |

Local-only (Windows/NVIDIA) errors, included so the agent recognizes them:
`No module named 'polygraphy'` (install TensorRT), `cannot import name 'cudart'`
(RTX 5070/CUDA, unresolved), `Acceleration has failed` (delete `engines/td/`),
flash-attn crash (`pip uninstall flash-attn`), `device_mesh` error
(`pip install accelerate==1.6.0 regex==2024.11.6`). Diagnostics:
`python -m sd_installer verify | repair | diagnose`. [OK]

**Route B setup (if used):** install DaydreamScope arm64 .dmg -> Settings -> Account
-> Sign in with Daydream -> enable Remote Inference -> pick pipeline -> Play
(~2–3 min provision + 1–2 min init). Bridge to TD: Scope Syphon sender (default name
reported as `ScopeOut`) -> TD `Syphon Spout In TOP` Server field. Exact field name
**[TEST]**. Wan2.1 handles temporal continuity natively (no feedback config). [LIKELY]

---

## 11. Remaining unknowns — TEST these before relying on them

These cannot be settled from docs. Resolve empirically; until then, do not hard-code
around them.

1. **[TEST] Daydream server region from Stockholm** — the single biggest latency
   factor. Ask in Daydream Discord (discord.gg/5sZu8xmn6U) or `ping` the API endpoint.
   If US-based: 80–120 ms baseline RTT; if EU: 15–40 ms. This can decide whether a
   "feels-direct" install is even achievable on cloud.
2. **[TEST] CoreML-TDSyphon Bridge** — does it exist as described (DepthAnythingV2 on
   ANE, 40+ fps, Syphon into TD)? Does its depth output work as a Daydream Depth CN
   conditioning input? If yes, it removes the depth-preprocess hop locally.
3. **[TEST] `Cn` block weight parameter name** in the current operator (e.g.
   `Cn1weight` vs a sequence/dict access) — right-click the weight slider -> Export.
4. **[TEST] Clap test for round-trip latency** — clap on camera, count frames at 30 fps
   playback until visible change; x33 ms = rough RTT on your actual broadband.
5. **[TEST] Does Scope Remote Inference expose any SD-Turbo+OpenPose pipeline**, or
   only Wan2.1? Check the pipeline dropdown. If SD-Turbo appears, Route B gains pose.
6. **[TEST] MediaPipe plugin current version** on M1 (native vs Rosetta) — check
   github.com/torinmb/mediapipe-touchdesigner/releases.
7. **[TEST] Syphon Spout In TOP field name** receiving `ScopeOut` ("Server" vs "Source").
8. **[TEST] CHOP export to a Promptdict sequence block** — exact Python child-parameter
   syntax; inspect `op('StreamDiffusionTD').par.Promptdict` children in Textport.
9. **[TEST] `Limitfps` semantics** — does it throttle cloud API calls or only local
   render rate? Watch Debug Mode.
10. **[TEST] Daydream API version pin status** — v0.3.x reportedly pinned to an older
    API with a stability fix pending; check the current changelog before a project.

When any of these gets resolved via own empiry: capture via the growth-protocol's in-flow ask, promote to HIGH-confidence dual-sourced entry per v0.3.

---

## 12. Source map (for re-verification)

- **dotsimulate** — dotsimulate.com/docs/streamdiffusiontd (install, parameters,
  examples, troubleshooting). Authoritative for operator behavior; CUDA/Windows-first.
- **Daydream** — docs.daydream.live (TD tutorial, sdks/touchdesigner/features,
  api/quickstart, scope/guides/remote-inference). Authoritative for the cloud backend
  + the model-gated CN table + server-side preprocessing.
- **Interactive & Immersive HQ** — smoothing / "make it not look bad."
- **AllTouchDesigner** — body-tracking + StreamDiffusion + Daydream workflow.
- **Derivative** — Scott Mann tutorials (First Project, Magic Mirror, audio-reactive),
  MediaPipe plugin tutorials, the CoreML-TDSyphon Bridge community post.
- **Weak (flag if sole source):** Kemono mirrors, undated Instagram/LinkedIn posts.

> Re-check before any production install: this space moves monthly. Version numbers,
> server regions, beta status, and the CoreML bridge are the most volatile items.

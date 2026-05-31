# macOS gotchas (Apple Silicon / MoltenVK)

TouchDesigner's render backend is **Vulkan on all platforms**; on macOS, MoltenVK translates Vulkan → Metal. **OpenGL was removed from TD in 2022** — any reference to "TD's OpenGL path" is outdated. Apple Silicon is the first-class macOS target as of 2025; Intel Macs require a discrete AMD GPU. **Custom Metal compute backends for custom operators are unsupported and crash-prone on Mac** (status as of mid-2025) — if a custom-op project needs GPU compute on macOS, use Vulkan-friendly paths, not Metal-direct ones. The items below caused real lost hours in production work and should be checked before debugging anywhere else.

**Audio routing on Mac** — for the "system audio (Spotify / Ableton / Logic) into TD" workaround, see `audio-reactive.md § Mac routing — BlackHole (CRITICAL)`. BlackHole + Audio MIDI Setup Multi-Output Device is the canonical pattern; it's filed in the audio-reactive reference because that's the trigger context, but it qualifies equally as a Mac gotcha — without it, `Audio Device In CHOP` can't see another app's output.

---

## MediaPipe requires Full Disk Access — fails silently without

**Mac-critical** | Source: [csdn.net article](https://blog.csdn.net/gitblog_07680/article/details/148507106), [torinmb/mediapipe-touchdesigner](https://github.com/torinmb/mediapipe-touchdesigner) | Date: June 2025 | **Confidence:** HIGH (user verified in production 2026-05-30)

On M-series Macs, `torinmb/mediapipe-touchdesigner` requires Full Disk Access granted to TouchDesigner.app in **System Settings → Privacy & Security → Full Disk Access**. Without it, the component fails intermittently with no console error and no obvious failure mode — the network just doesn't produce output.

**Check first when:**
- MediaPipe component loads but `hand_results`/`pose_results` text DAT is empty
- Plugin worked on another Mac but not on this one
- Webcam permission is granted but tracking still doesn't fire

**Verified by user in production** (2026-05-30): exact symptom encountered, fixed by toggling Full Disk Access on. This is the #1 thing to check before debugging anything else MediaPipe-related on Mac.

---

## 16-sampler GLSL cap (MoltenVK)

**Mac-critical** | Source: [Derivative forum (2022)](https://forum.derivative.ca/t/more-than-16-glsl-input-samplers-on-macos/306594), [Stack Overflow on MoltenVK 80-cap](https://stackoverflow.com/questions/78131065/how-to-get-more-than-80-textures-bound-to-a-pipeline-with-vulkan-for-macos) | Date: 2022 (still current) | **Confidence:** HIGH (user verified in production 2026-05-30)

macOS/MoltenVK caps GLSL at **16 input samplers per shader** in TD's compilation path. Shaders with 17+ samplers compile but render incorrect colors (typically red/blue swap or noise) and produce no visible error — the symptom is corrupt color, not a compile error.

**The MoltenVK upstream limit is 80 CombinedImageSamplers** at the Vulkan layer — TD's GLSL→SPIR-V path hits 16 earlier. This is a TD-specific compilation ceiling, not a hardware ceiling.

**Check first when:**
- GLSL TOP/MAT renders unexpected colors on Mac but is fine on Windows
- Splat/point-cloud component shows pinks/cyans where it should show photographic color
- Output looks "channel-swapped"

**Workaround:** rewrite the shader to use ≤16 samplers. The Tim Gerritsen Gaussian Splatting component's original Mac-incompatibility came from this exact cap.

**Reduction techniques (pick by data shape):**

- **Texture arrays** (`sampler2DArray`): consolidate N similar 2D textures into one 2D array — single sampler binding, N slices, read with `texelFetch(sArray, ivec3(x, y, slice), 0)`. Fits when textures share dimensions and format and are addressed by an integer index.
- **Texture buffers** (`samplerBuffer`): for large flat arrays of values (positions, scales, per-instance parameters), pack into a 1D buffer texture. Single sampler binding regardless of element count. Read with `texelFetch(sBuffer, index)`.
- **Atlas packing:** stitch many small textures into one larger texture, use UV math to select tiles. Fewer samplers, more shader math.
- **Remove redundant samplers:** the shader may declare inputs the project doesn't actually use. Read it carefully — sometimes 17 drops to 14 just by deleting unused fetches.

**Verified by user in production** (2026-05-30): observed during Gaussian splat tree work — Tim's `glslSplat_vertex` shader uses 17 samplers; M1 Pro rendered red/blue corruption. Worked around by forcing splats to white in-shader. A proper structural fix (texture array consolidation) was not attempted — left as a future option if color fidelity becomes required.

---

## POPs crash Intel Macs with AMD GPUs; safe on Apple Silicon

**Mac-relevant** | Source: [Experimental 2025.30770 release notes](https://derivative.ca/release/experimental-202530770/72562) | Date: August 2025 | **Confidence:** HIGH (Derivative release notes; user is on Apple Silicon so unaffected directly, behavior is documented)

POPs (Point Operators, GPU-bound) hard-crash on Intel Macs with AMD discrete GPUs, sometimes corrupting the driver state and requiring a system reboot. **M1/M2/M3 Apple Silicon is unaffected.** The user's machine (M1 Pro) is safe.

**Check first when:**
- A team member on an Intel Mac reports crashes you can't reproduce
- Migrating a POP-heavy project from Apple Silicon → Intel Mac for testing
- Diagnosing crashes after rapid POP creation

**Workaround:** Intel-Mac team members must use SOPs (or wait for the bug fix). Don't suggest POPs in cross-team work without confirming everyone is on Apple Silicon.

---

## TD runs on ONE CPU core — Activity Monitor lies

**Mac-relevant** | Source: [Derivative forum (Mac perf)](https://forum.derivative.ca/t/performance-issues-with-macos/244318) | Date: evergreen | **Confidence:** HIGH (TD architectural fact, broadly documented)

TouchDesigner's main loop is single-threaded. macOS Activity Monitor shows aggregate CPU% across all cores — a 10% Activity Monitor reading on an 8-core machine means TD is using **80% of one core** and is CPU-bound.

**Use TD's own Performance Monitor (Dialogs menu)** to see per-cook timings and identify which operator family is the actual bottleneck. CPU-bound work lives in SOPs and heavy DAT scripts; GPU-bound work lives in POPs, TOPs, and rendering.

**Don't:**
- Suggest multi-threading TD's main loop (impossible)
- Use Activity Monitor numbers to decide whether to optimize
- Assume aggregate-low CPU means there's headroom — there isn't if the one core is pegged

---

## MoltenVK regressions can halve FPS — check build version first

**Mac-critical** | Source: [Derivative forum 2025.31310 perf regression](https://forum.derivative.ca/t/resolved-mac-performance-issue-on-recent-experimental-build/825407) | Date: October 2025 | **Confidence:** HIGH (Derivative forum, marked resolved; specific build numbers verified against release notes)

MoltenVK rendering-line regressions have caused ~50% FPS drops on Apple Silicon in specific experimental builds (e.g., 2025.31310 — resolved in the next build). When FPS suddenly tanks on Mac without a network change, check the build version against the Derivative release notes before blaming operators.

**Diagnosis order on a sudden Mac FPS drop:**
1. `get_td_info` → check build number
2. Compare against [Derivative release notes](https://derivative.ca/community) for known regressions in that build
3. **Only then** profile operators, raise alpha thresholds, decimate assets, etc.

**Don't:**
- Modify the user's network/assets to chase performance before verifying the build isn't itself the regression
- Assume the latest experimental is the most performant — sometimes downgrading one build restores FPS

---

## Known gaps (deliberately empty)

These are publicly unresolvable or untested as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md § Pre-ask filters`):

| Gap | Where it surfaces |
|---|---|
| Intel-Mac POPs behavior on builds **after** the 2025.31310 fix | First time a colleague on an Intel/AMD Mac tries POPs on a current build |
| M1 Pro vs M3 / M4 GPU memory ceiling differences for large textures / POP point counts | First time the user's machine differs from the production target |
| MoltenVK FPS-cliff thresholds per build — only spot-checked, not exhaustively profiled | First time a build behaves differently than its release notes suggest |
| Whether custom-Metal-compute-backend crashes have improved since mid-2025 | First time a custom-op project actually needs GPU compute on macOS |
| Complete LLM-hallucinated TD parameter name list on Mac — only 3 confirmed (see `td-gotchas.md`) | First time a Mac-specific parameter (codec / pixel-format / window) gets hallucinated |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

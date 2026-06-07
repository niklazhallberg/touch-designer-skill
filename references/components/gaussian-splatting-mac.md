# Gaussian Splatting in TouchDesigner — Mac options

Three component families, distinct maturity and Mac support. Trigger this reference when the user wants to render a Gaussian splat (`.ply` / `.spz`) in TD on macOS, or when a Gaussian-splat component renders incorrectly (color corruption, empty output) on Mac.

---

## Pipeline split — splat CREATION vs splat RENDERING

**Confidence:** HIGH (the creation-vs-rendering distinction is architecturally clear; tool categorization below is verified per tool)

Gaussian splat work has **two distinct steps**; don't conflate them when picking tools.

1. **Create** — produce a `.ply` (or newer `.spz`) splat file from input photos/video. This step lives OUTSIDE TouchDesigner.
2. **Render** — load and display the splat inside TD. This is what the rest of this file covers.

The components listed below (Tim Gerritsen, atarilover123, TDGS, yeataro, POP-based) are all **renderers**. They consume an existing `.ply`/`.spz` — none of them create one.

### Creation tools

- **vid2scene.com** — cloud service, free tier, one-click upload-and-train. **Verified by user in production** (used to create `RADON_Tree.ply` for the splat-tree work, May 2026). Licensing/pro-tier terms on their site; check before commercial use.
- **OpenSplat** ([github.com/pierotofy/OpenSplat](https://github.com/pierotofy/OpenSplat)) — open source, AGPLv3, runs locally on Mac via Metal (`-DGPU_RUNTIME=MPS`). Commercial use permitted under AGPL terms. **Status: to verify** — not personally tested by the user. Practical caveats:
  - Requires compiling from source: libtorch + OpenCV + Xcode toolchain
  - Requires already-processed input (COLMAP or OpenSfM output) — not plug-and-play from raw video/photos
  - M1 build process has not been confirmed by the user

### Don't mix these up

- **OpenSplat replaces vid2scene** — both produce splats from input data.
- **OpenSplat does NOT replace TDGS** (or any other renderer in this file) — different layer of the pipeline. TDGS reads the output of either creator.
- A "Mac-native Gaussian splat pipeline" needs ONE creator + ONE renderer; mixing creators or mixing renderers is fine, but you always need both.

---

## Summary table

| Component | Mac support | License | Recommended? |
|---|---|---|---|
| **Tim Gerritsen's GaussianSplatting** (original `.tox`) | ❌ Original GLSL fails on Mac (16-sampler cap) | Free, Derivative community | No on Mac — alternatives are atarilover123-fork (to verify) or Lake Heckaman (to verify) |
| **atarilover123/GaussianSplat_TD** (fork) | 🟡 *Reported* Mac-compatible (16-sampler-reduced shader) — to verify | Free, GitHub | Candidate for universal Mac+PC use; **to verify in production** |
| **Lake Heckaman TDGS 1.3.1+** | ✅ Native Apple Silicon | Paid? — see source | Yes for production Mac work; **to verify in production** |
| **yeataro/TD-Gaussian-Splatting** | ✅ (Mac) | Open-source, GitHub | Reference only — documentation incomplete, performance unvalidated |
| **Native POP-based GS** (TD 2025.30600+) | ✅ Apple Silicon | Built into TD | Watch this space — Derivative ships an example `.toe`; bug fixed 2025.30770 |

---

## Tim Gerritsen's original `GaussianSplatting-1.0.tox`

**Source:** [Derivative community asset](https://derivative.ca/community-post/asset/gaussian-splatting/69107) | Released March 2024 | **Confidence:** HIGH (user verified Mac failure mode in production 2026-05-30; white-force workaround verified working)

**Mac status:** Fails silently — the GLSL vertex shader uses 17 samplers, which hits the macOS/MoltenVK 16-sampler cap and produces red/blue color corruption (not a compile error). See `mac-gotchas.md` § "16-sampler GLSL cap".

**Verified by user in production** (2026-05-30): rendered with corrupt red/blue colors on M1 Pro. Worked around by force-writing splat color to white in-shader (`color.rgb = vec3(1.0);` after `texelFetch(sColors, ...)`). The whitening is a usable creative outcome but not a solution to the underlying sampler-cap problem.

**What works on this component despite the color issue:**
- Geometry transform / positioning (custom `Rx`/`Ry`/`Rz`/`Ty`/`Scale` params drive an internal `pointtransform1` SOP)
- Alphathreshold culling
- Camera control via the internal `cameraViewport` cameraCOMP (note: `PivotDistance` is a Python `@property/@setter` — setting the COMP parameter alone does NOT trigger the setter; only Python assignment `cam.PivotDistance = val` actually moves the camera)
- Autosort toggle + manual `Sort` pulse — but the bitonic sort triggered by every camera move is the known performance hotspot

**When to keep using it anyway:** when you've already invested effort calibrating it for a specific project and the color workaround is acceptable.

---

## atarilover123/GaussianSplat_TD fork (*reportedly* Mac-compatible — to verify)

**Source:** [github.com/atarilover123/GaussianSplat_TD](https://github.com/atarilover123/GaussianSplat_TD), [YouTube walkthrough](https://www.youtube.com/watch?v=Mr8H0irijhM), [Derivative forum](https://forum.derivative.ca/t/gaussian-splatting-2024-03-04/) | Updated November 2025 (per third-party sources) | **Confidence:** LOW (existence not personally confirmed; user has not cloned the repo or rendered with it; reported via YouTube + forum reference only)

**Reported** community fork of Tim Gerritsen's `.tox` with a 16-sampler-reduced GLSL shader, claimed Mac+PC universal. Reported additions as of November 2025: portrait-mode fix, camera automation, noise effects.

**Existence and behavior have NOT been verified by the user.** The only sources are a YouTube walkthrough and a Derivative forum reference — neither the agent nor the user has cloned the repo, opened the `.tox` in TD, or rendered a `.ply` with it. Before recommending it as the default Mac path, verify (1) the GitHub repo actually exists and is reachable, (2) the `.tox` opens in the user's TD build (2025.32820+), and (3) it renders the user's `RADON_Tree.ply` with correct color on M1 Pro.

**Status: to verify in production (fork existence not confirmed).** Current production work uses the original Tim component with the in-shader white-force workaround. Don't substitute this fork without the verification steps above.

---

## Lake Heckaman TDGS 1.3.1 (native Mac)

**Source:** [Radiance Fields write-up](https://radiancefields.com/tdgs-for-gaussian-splatting-in-touchdesigner) | Date: December 2025 | **Confidence:** MEDIUM (Radiance Fields source verified; user has not personally evaluated TDGS 1.3.1 — capabilities list is from publisher's changelog)

Production-ready Mac-native Gaussian splat toolkit. Requires TD **2025.31760+**. Highlights from the published changelog:
- Full macOS compatibility including Apple Silicon (sample `.toe` confirmed running on M1 MacBook Air)
- Proper SPZ format support
- VRAM-conservative attribute handling
- Lazy execution: expensive passes only cook when their specific trigger parameter is active (e.g., attribute blur only runs when Zap Distance > 0)
- Splat-specific transform parameters allow spatial manipulation without geometry-level tricks

**Status: to verify in production.** The user has not personally tested TDGS 1.3.1 yet. If the user pivots to a serious Mac-native splat pipeline, this is the candidate to evaluate first. Check licensing/cost before recommending in a paid project context.

---

## yeataro/TD-Gaussian-Splatting (reference only)

**Source:** [github.com/yeataro/TD-Gaussian-Splatting](https://github.com/yeataro/TD-Gaussian-Splatting) | Date: late 2023 | **Confidence:** LOW (documentation incomplete per source; performance claims not independently validated; use for reference only)

Independent GitHub implementation. Documentation was incomplete as of late 2025; the repo claims faster performance than earlier approaches but this is not independently validated. **Use for reference only** — don't lead a Mac production with this until performance is benchmarked on the target hardware.

---

## Native POP-based Gaussian Splatting (TD 2025.30600+)

**Source:** [Experimental 2025.30770 release notes](https://derivative.ca/release/experimental-202530770/72562), [alltd.org POP GS overview](https://alltd.org/gaussian-splats-in-touchdesigner-now-in-pops-new-features/) | Date: June–August 2025 | **Confidence:** MEDIUM (Derivative ships the example .toe — existence is HIGH; user has not personally evaluated the pipeline yet)

Derivative now ships a Gaussian splat example `.toe` in their POP examples package (bug fixed in 2025.30770). Capabilities include:
- Relighting with native TD lights
- Baked color correction (gamma/brightness/contrast)
- Proximity POP plexus effects
- AttributeBlur POP for propagating effects across a splat
- Optimized bounding volumes

This is the path Derivative themselves are investing in. **Status: to verify in production.** If/when the user wants long-term sustainability, the POP-based pipeline is likely where Mac-native splat work converges.

---

## 4D / animated Gaussian splats — not supported in TD (workaround: image-sequence point clouds)

**Source:** [Derivative forum thread "4D Gaussian Splat - POPs"](https://forum.derivative.ca/t/4d-gaussian-splat/562056) | Date: November 2024 | **Confidence:** MEDIUM (Derivative's own response on the thread; status verified still current via May 2026 research dossier, not personally tested)

TD has no native support for 4D / animated Gaussian splats (splat-fields that change over time as a continuous animation). Derivative has not announced plans for it.

**Current workaround:** record the point cloud as an **image sequence** — bake each frame's positions/colors to a 2D texture (per-point P → RGB pixels), then sample the sequence as a normal Movie File In TOP and reconstruct points per-frame on the GPU.

**Limitations of the workaround:**

- Pre-computed only (no real-time deformation)
- Memory-heavy at high point counts (each frame = full point cloud as image)
- Loses Gaussian-specific attributes (rotation, scale-3, spherical harmonics) unless packed into additional textures

**Don't suggest:** "use a 4D splat renderer in TD" — there is none. If the user asks for an animated splat scene, surface this constraint and propose either the image-sequence workaround or a non-splat alternative (POP particle system, instanced geometry).

**Status: verify before relying — source dated 2024-11; re-check Derivative release notes if this trips a user.** Native 4D splat support could land in a future release; the constraint is current as of TD 2025.32820 but not guaranteed forward.

---

## Decision rule

When a user asks "what Gaussian splat component should I use on Mac?" — the answer depends on context:

| Situation | Recommendation |
|---|---|
| Already invested in Tim Gerritsen's `.tox`, color isn't critical | Keep + apply white-force shader hack |
| Starting fresh, want universal Mac+PC, free | Try atarilover123 fork first (verify in prod) |
| Production Mac work, paid project, latest features | Evaluate TDGS 1.3.1 (verify in prod) |
| Want to align with Derivative's roadmap | POP-based pipeline (TD 2025.30600+) |
| Looking at yeataro | Reference only, don't lead with it |

**Two failed renders on Mac with the original Tim component → stop, ask user which alternative to evaluate.** Don't substitute without consent.

---

## Known gaps (deliberately empty)

These are publicly unresolvable or untested as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md § Pre-ask filters`):

| Gap | Where it surfaces |
|---|---|
| TDGS 1.3.1 actual licensing cost + commercial-tier terms | First time the user evaluates TDGS for a paid project |
| atarilover123 fork existence + behavior on user's TD 2025.32820 + M1 Pro | First time the user clones the fork and renders `RADON_Tree.ply` with it |
| POP-based native pipeline performance on M1 Pro at production splat counts | First time the user evaluates Derivative's example `.toe` |
| OpenSplat M1 compile success rate (libtorch + OpenCV + Xcode build process untested by user) | First time the user wants a local-Mac creation pipeline |
| yeataro performance vs Tim / TDGS comparison on identical input `.ply` | If yeataro graduates from reference-only to candidate |
| Which Mac-renderer handles >1M splats best — none benchmarked at scale | First time a project pushes splat density past comfortable |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

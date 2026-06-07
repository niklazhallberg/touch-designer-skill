# Projection mapping in TouchDesigner — deep technical reference

**Source:** User-provided research synthesis, 2026-06-07 (compiled from docs.derivative.ca primary pages, OpenCV calib3d reference, Interactive & Immersive HQ blog, nVoid *Introduction to TouchDesigner*, Paul Bourke edge-blending paper, and named community contributors per § 4) | **Confidence:** MEDIUM (external, primary-source-anchored throughout; not personally verified for any specific projection install)

**When to load this reference:** Any of the following triggers — user mentions projection mapping / projector calibration / installation mapping / KantanMapper / CamSchnappr / Stoner / projectorBlend / quadReproject / edge blending / multi-projector / structured light, asks about 3D-model-based calibration with `cv2.calibrateCamera` in TD, asks about handing off to Resolume / MadMapper / Millumin, multi-machine sync (Sync CHOP / Hardware Frame-Lock / Quadro Sync), or multi-output hardware (Datapath FX4 / Matrox TH2Go / NVIDIA Mosaic).

## Author confidence tags vs protocol v0.3

The document uses inline `(Confidence: high/medium/low)` per-claim tags. These map to skill-growth-protocol v0.3 source-confidence tiers as below — preserve when re-citing facts from this reference.

| Doc tag | Meaning | Maps to v0.3 |
|---|---|---|
| **Confidence: high** | Primary source citation, verbatim quote, or stable docs page | MEDIUM (vendor-verified, no own empiry) |
| **Confidence: medium-high** | Multiple corroborating sources, minor inference | MEDIUM (mostly vendor + light synthesis) |
| **Confidence: medium** | Community consensus or forum-sourced, plausible but not from primary | MEDIUM (with caveat — verify in production) |
| **Confidence: low** | Single forum report or unsourced practice | LOW (hypothesis, validate in-app) |

**Status: verify before relying — research dated 2026-06-07.** Projection mapping toolchain (palette COMPs, OpenCV bindings, hardware vendors) is mostly stable, but always check current build behavior for the specific parameter names and any post-2026 wiki updates. The CamSchnappr internal Python, the Window COMP Frame-Lock semantics, and Spout's Windows registry behavior are the most likely items to drift.

**Source-conflict resolution:** Derivative wiki wins for tool behavior. OpenCV docs win for calibration math. Vendor datasheets win for hardware specs. Community guides (nVoid, IIHQ) win for workflow patterns where primary docs are silent.

---

## TL;DR
- TouchDesigner ships three core native mapping tools in the **Palette > Mapping** folder — **KantanMapper** (2D polygon/bezier mapping & masking), **CamSchnappr** (3D model-based projector calibration via OpenCV's `calibrateCamera`), and **Stoner** (corner-pin + mesh grid-warp keystoner) — plus **projectorBlend** for edge blending, **quadReproject** for LED/XR, and native integrations with VIOSO and Scalable Display for automated multi-projector alignment.
- CamSchnappr is a PnP-style solve: you supply ≥6 correspondences between a virtual 3D model and the projector's real-world output, and OpenCV's `cv2.calibrateCamera` recovers the camera intrinsics (fx, fy, cx, cy), distortion coefficients, and extrinsics (rotation/translation), storing them in a Camera COMP — making the virtual camera match the real projector.
- For production, hand off via Spout (Windows) / Syphon (macOS) / NDI (network) to media servers or external mappers (Resolume, MadMapper, Millumin); use Sync In/Out CHOPs + Hardware Frame Lock (Quadro Sync) for multi-machine sync, and Datapath FX4 / Matrox / NVIDIA Mosaic for multi-output distribution.

---

## Versioning context (read first — affects every claim below)
TouchDesigner abandoned the old 077/088/099 branch naming; current releases use a **year + build** scheme (e.g., 2022.20000, 2023.10000 series). The "099" still on the splash screen is, per Derivative's Malcolm Bechard, "just a leftover branding that we never got rid of" — to be removed in the 2025 series. (Confidence: high — direct correspondence quoted on mslinn.com and the Derivative forum.)

Key version facts as of 2026:
- The **2023.1xxxx Official series** continued receiving builds through 2024–2025 (e.g., 2023.12120 on 16 Dec 2024; 2023.12230 on 4 Mar 2025) while keeping the "2023" name, similar to "Office 2021." (Confidence: high.)
- A **2025.30000 series** exists with the major new **POPs (Point Operators)** family and continued Vulkan work. (Confidence: high — Release Notes reference 2025.30000 and POPs.)
- ⚠️ **Backward compatibility:** .toe files saved in 2023 Official "can not be loaded back into previous versions" — unlike earlier years where it sometimes worked. The same hard rule applies between Experimental and Official branches (Derivative's Experimental 2023.10130 notes state verbatim: "Project .toe files saved in Experimental can not be loaded back in Official"). Always note your build before sharing files. (Confidence: high.)
- Python moved from **3.9.5 → 3.11** in the 2023 series. Per Derivative's 2023 Official Update: "The Python version in TouchDesigner has been upgraded to 3.11. This can run up to 10-60% faster and also offers much better error reporting." Later 2025.30000-series experimental notes specify the exact point release **3.11.10**. (Confidence: high.)
- TouchDesigner switched its rendering backend to **Vulkan** (2022+), which changes NDC depth conventions (see §2). Pre-Vulkan GLSL ≤3.30 support was removed; main supported GLSL is **4.60**. (Confidence: high — Write a GLSL Material.)

The mapping Palette COMPs (KantanMapper, camSchnappr, stoner, projectorBlend, quadReproject) have been stable in form for years; their wiki pages were last edited around 2021 (the camSchnappr page was edited 23 Dec 2025), and they continue to ship in 2026 builds. Where a tool's behavior is build-sensitive, it is flagged inline.

---

## 1. Built-in tools & workflows

### 1.1 KantanMapper COMP
**What it is:** 簡単 (kantan = "easy/simple"). "Kantan Mapper 2 is a new projection mapping and masking toolkit" where "the user defines 2D polygons and bezier outlines in the field of view of a projector, then fills each shape with a selected image (TOP) with tools to warp how the image fits into the shape." Located in **Palette > Mapping**; drag it into your network and click the **Open Kantan Window** pulse parameter. (Confidence: high — docs.derivative.ca/Palette:kantanMapper.)

**Workflow / mesh creation:**
- **Create a Shape:** Use the **Create Quad** tool (click-drag start to opposite corner) or the **Create Freeform** tool (click to place bezier keys, drag out handles; close by clicking the first key). (Confidence: high.)
- **Transform:** With the **Select Shape Tool**, drag to reposition, or use outer handles to scale/rotate. Hold **Alt** while transforming to duplicate a shape. (Confidence: high.)
- **Modify keys/handles:** The **Select Key & Handle Tool** exposes per-key bezier handles.
- **Quad-specific tools:** Enter **gridwarp mode** to transform interior grid points/handles; **add rows/columns** by selecting an insert point; delete a row/column by selecting it and pressing Delete. Quad **Warping** modes are **Bezier** (keys + handles) or **Linear** (grid points only, linear connection). Quad **Mapping** modes are **Perspective** or **Bilinear**. **Reset Keystone** resets corner points; **Reset Warp** resets all grid points. ⚠️ Changing Rows/Cols by number **resets the gridwarp** — to remove a row/column without losing deformation, delete it in grid-warp mode. (Confidence: high.)
- **Freeform-specific:** **Detail** parameter changes edge resolution between keys.

**Layer management:** The **Shapes Tree** is a collapsible list of shapes and groups. Each row has an eyeball icon to hide/show. Shapes/groups can be reordered by dragging and **nested** by dragging onto groups. New groups via the **Add Group** button. (Confidence: high.)

**Texture / masking:**
- Assign a texture by dragging a TOP onto the **Texture** field in Shape Settings, then enabling it.
- **Edit Texture** opens the **Texture Editor** to choose the region of the source TOP to apply, or to "set as mask" so the shape's exact outline masks the content. (Confidence: high.)
- **Orientation** flips/rotates the assigned texture. **Color** fills the shape when no texture is enabled.
- **Project-level masking:** **Bg Mask** accepts a background-mask TOP with a **Bg Level** control.

**Soft-edge blending (per-shape):** The **Softedge** toggle applies a feathered edge. Per the docs: "While softedge on the quad is done via a basic shader, the softedge on the freeform is a bit more of an experiment using the Extrude SOP and Skin SOP." Internals live at `.../kantanMapper/project/allShapes/item*`. (Confidence: high.)

**Output routing:** **Resolution** should match the projector; **Window Options** opens the underlying Window COMP parameters; **Toggle Output** opens/closes the output window. Convention: monitor 0 = main display, 1 = first projector. (Confidence: high.)

**Performance helper — Kantan UV Helper:** A companion Palette tool that consumes Kantan's "second UV Map output" so that "Kantan itself is not anymore part of the rendering process," reducing processing time. Use this for installations where Kantan's live editing overhead is undesirable. (Confidence: high — Projection Mapping wiki.)

**Known limitations / gotchas:**
- Free (non-commercial) license caps output at 1280×720 — set the projector to match. (Confidence: high — multiple community sources.)
- The UI is "fairly straightforward… but its usage isn't particularly intuitive" (jmarsico). Texture must be explicitly enabled with the toggle behind the field or nothing shows. (Confidence: medium — community consensus.)
- Changing grid Rows/Cols destroys warp data (see above).
- KantanMapper is a 2D-on-flat-surface tool; for true 3D objects it cannot solve perspective from a model — use CamSchnappr.

### 1.2 CamSchnappr COMP
**What it is:** An "interactive mapping application entirely inspired by MAPAMOK, created by Kyle McDonald at the YCAM Interlab." Kyle's original mapamok (2012, openFrameworks + OpenCV) uses "OpenCV's cameraCalibrate to calibrate a projector via a model of the to-be-mapped structure instead of using a checkerboard." Derivative ported this to TouchDesigner via Python. Source/inspiration: github.com/YCAMInterlab/ProCamToolkit (mapamok). (Confidence: high — docs.derivative.ca/Palette:camSchnappr.)

**What you need:** TouchDesigner; a projector (reset all digital keystone/zoom on the projector first); a physical structure; and an accurate **3D model** of that structure.

**Workflow (3D-to-2D point correspondence):**
1. Build a render setup (Geometry COMP holding your model, a Camera COMP, a Render TOP).
2. Drop `camSchnappr` from Palette > Mapping. Assign the **Geo SOP** (the SOP holding the geometry — *not* a Material SOP or a branch containing one, "as this would break the blending"; reference textures via the Color Map parameter instead). Optionally assign your own Camera COMP to the **Project** parameter (default internal camera is named "project"). (Confidence: high.)
3. Set **Output Monitor** to the projector; **Open Main Window** (the arcball 3D view) and **Open Output** (the projector view).
4. In the **main viewport**, create control points by **Ctrl+left-click** on the geometry; activate by Ctrl+clicking blue spheres; delete by Ctrl+right-click; **Tab** cycles points.
5. In the **mapping/output viewport**, drag each selected point (or **Shift+left-click**) to its corresponding real-world position on the object as seen in the projection. Arrow keys nudge 1px; **Alt+arrow** moves by the Alt-multiplier (default 10px).
6. After aligning **≥6 points**, "the camera should be calibrated and you should see the projection mapped onto the object." (Confidence: high.)
7. Calibration values are saved **inside the Project Camera COMP as 2 Table DATs** — after which CamSchnappr itself can be deleted if you used an external camera. (Confidence: high — this is the reproducibility/persistence mechanism.)

**How it solves camera intrinsics/extrinsics:** Internally runs `cv2.calibrateCamera`, which "computes the position, rotation, scale and viewing angle" and stores intrinsics + extrinsics in the Camera COMP. See §2 for the full math. (Confidence: high.)

**OpenCV page parameters (these are the calibration solver controls):**
- **FOV** — initial field-of-view estimate seeding the camera matrix.
- **Intrinsic Guess** — sets `cv2.CALIB_USE_INTRINSIC_GUESS`; uses your initial focal length/principal point as a starting optimization point; otherwise principal point is set to image center and focal lengths are least-squares estimated.
- **Fix Aspect Ratio** — `cv2.CALIB_FIX_ASPECT_RATIO`; "considers only the vertical focal length as a free parameter. This should always be enabled unless you have an unusual projector with non-square pixels."
- **Zero Tangent Distance** — `cv2.CALIB_ZERO_TANGENT_DIST`; on by default because "most projectors have very little tangential distortion."
- **Fix Principal Point** — `cv2.CALIB_FIX_PRINCIPAL_POINT`; enable for "a high quality lens with zero lens shift."
- **Fix K1/K2/K3** — `cv2.CALIB_FIX_K1/K2/K3` radial distortion coefficients; for "extremely wide fisheye lenses."
- **Max Iterations / Precision** — termination criteria for the Levenberg-Marquardt optimization.
- **Calibration Error** — "Displays the calibration Error returned from OpenCV after cv2.calibrateCamera… the total sum of squared distances between the observed feature points imagePoints and the projected… object points objectPoints." (Confidence: high — direct quotes from docs.)

**Auto Blend page (multi-projector):** Uses Light COMPs to find overlapping projection regions and applies **Blend, Gamma (R/G/B), Luminance** per Paul Bourke's edge-blend paper (paulbourke.net/miscellaneous/edgeblend). Specify all other camSchnappr Camera COMPs in **camSchnappr Cameras**; Output 0 of the COMP becomes the blend mask between projectors. (Confidence: high.)

**OSC control:** Full TouchOSC layout (iPad/iPhone) with channels like `/1/selectPointNext`, `/1/pointFine`, `/1/altleft` etc., enabling on-site point nudging from a mobile device.

**When to use vs manual:** Use CamSchnappr when you have an accurate digital model of the surface — calibration becomes "a snap" with ~6–12 points. Use KantanMapper/Stoner when you have no model and the surface is flat or simple (manual corner-pin/mesh). (Confidence: high — Interactive & Immersive HQ.)

**Gotchas:** Reset projector keystone/zoom first (any hardware warp corrupts the solve). Don't point Geo SOP at a Material SOP branch. With large models, use **Use Point Group / Geo Group** to pick from predetermined calibration points. A known forum issue: points sometimes only appear when clicking the mesh in Main Output — ensure the correct Output Monitor. (Confidence: medium — forum-reported.)

### 1.3 Render pipeline operators
- **Geometry COMP:** Holds the 3D surfaces to render. Note 2026 behavior: geometry is now increasingly defined by **POPs** (Point Operators, the GPU-based successor that "are now done primarily on the GPU") whose **Render flag** is on; multiple can render at once. In older builds SOPs filled this role exclusively. (Confidence: high — Geometry COMP page; flag the SOP→POP shift as a 2025+ change.)
- **Camera COMP:** Defines the virtual projector/eye. Key params: **Projection** (Perspective / Orthographic / Perspective-to-Ortho Blend / **Custom Projection Matrix**), **Viewing Angle Method** (Horizontal FOV / Vertical FOV / Focal Length and Aperture), **focal**, **aperture**, **near/far**. The relation: `screenWidth = aperture`, `distanceToScreen = focal`. The **Custom Projection Matrix** option (4th choice) accepts a `tdu.Matrix`, CHOP, or DAT — this is what CamSchnappr and quadReproject manipulate. ⚠️ A 2022-build regression briefly affected custom projection matrices (forum "RESOLVED: Did something happen to Camera custom projection matrix… 2022 builds") — fixed; verify on your build if doing custom-matrix work. (Confidence: high.)
- **Render TOP:** Renders camera(s) + geometry + lights to a texture. Supports 8-bit fixed up to 32-bit float; **Order-Independent Transparency** via Multi-Pass Depth Peeling; **multiple cameras in one node** (pull results with **Render Select TOP**, faster on Multi-Camera-Rendering GPUs); **crop via projection matrix** (set the Render TOP aspect to the *real* overall output aspect, not the sub-section, "otherwise the projection will be stretched incorrectly" — important for multi-machine tiling). (Confidence: high.)
- **Phong MAT / PBR MAT:** Phong is "the most common material," supporting Color/Bump/Specular/Diffuse/Emit maps. PBR MAT uses a **Base Color Map**. Instance textures: up to 16384 textures on Windows / 128 on macOS at once. (Confidence: high.)
- **Cache TOP:** Stores frames; used in projection pipelines to **resync delayed inputs** (e.g., MediaPipe or Spout round-trips that add a fixed frame delay — feed the known delay into a Cache TOP to realign). (Confidence: medium-high — Torin Blankensmith's mediapipe docs describe exactly this use.)

### 1.4 Native edge blending & multi-projector
- **projectorBlend (Palette):** Blends NxM projector arrays. Based on Jeffrey Crouse's **ofxProjectorBlend** openFrameworks add-on, implementing Paul Bourke's "Edge blending using commodity projectors" (2004). Params: **Projector Array** (e.g., 1x2 = two stacked), **Projector Resolution** (all projectors must be same resolution), **Blankout Edges** (px), **Solid Edge** (solid-color blend region for setup), per-projector **Gamma/Hue/Sat/Value**, and **Per Side Control** for non-straight blend areas and independent edge color. Tip: set Array to 1×1 + Per Side Control to produce reusable blend masks you multiply against your own output. The 58140 build added a GLSL update; users report difficulty pushing it past 2 projectors without rebuilding. (Confidence: high for params; medium for the >2-projector limitation — forum-reported.)
- **Manual edge blend (nVoid method):** Split full-res content (e.g., 3840×1080) with **Crop TOPs**, offsetting each by half the blend zone (e.g., 128px each toward center = 256px overlap), then multiply blended edges by **alpha ramps** and composite onto a full-projector-resolution canvas. The key gotcha: pixels are discarded on non-blended edges, so "always be aware of this loss of pixels… to avoid placing critical information… around areas where pixels may be discarded." (Confidence: high — nVoid Introduction to TouchDesigner.)
- **Third-party automated:** **VIOSO** and **Scalable Display** are natively integrated — load calibration data from their external camera-based auto-alignment software via the **Scalable Display TOP** / Vioso integration, for domes, panoramas, and complex multi-projector blends. (Confidence: high.)
- **sweetSpot (Palette):** Trompe-l'œil — renders a scene from the observer's position and re-projects onto a surface for perspective illusions. For pixel-perfect LED/XR use **quadReproject** instead.

---

## 2. Calibration theory (the WHY)

### 2.1 Intrinsics vs extrinsics in the TouchDesigner context
- **Intrinsics** describe the projector's internal optics, encoded in a 3×3 matrix: focal lengths (fx, fy) and optical center / principal point (cx, cy), plus **distortion coefficients** (k1, k2, p1, p2, k3 — three radial, two tangential). Per OpenCV: "Intrinsic parameters are specific to a camera. They include information like focal length (fx, fy) and optical centers (cx, cy)." In TouchDesigner these map onto the Camera COMP's focal/aperture/FOV and a custom projection matrix. (Confidence: high — OpenCV camera calibration tutorial.)
- **Extrinsics** are the rotation and translation that place the projector in world space: "Extrinsic parameters corresponds to rotation and translation vectors which translates a coordinates of a 3D point to a coordinate system." In TD these become the Camera COMP's transform (position/rotation). (Confidence: high.)
- OpenCV fixes the camera-matrix **skew term to 0** (x and y image axes assumed orthogonal). (Confidence: high — Roboflow.)

### 2.2 The math behind CamSchnappr's solve (PnP / calibrateCamera)
- `cv2.calibrateCamera` "Finds the camera intrinsic and extrinsic parameters from several views of a calibration pattern" and returns `ret, mtx, dist, rvecs, tvecs`. (Confidence: high — OpenCV calib3d reference.)
- **Is it PnP?** Yes, conceptually. calibrateCamera's algorithm "Estimate[s] the initial camera pose as if the intrinsic parameters have been already known. This is done using **solvePnP**," then "Run[s] the global Levenberg-Marquardt optimization algorithm to minimize the reprojection error." So calibrateCamera is *broader* than PnP — it solves intrinsics + distortion + extrinsics jointly — but uses **solvePnP** to initialize each view's pose. **PnP (Perspective-n-Point)** proper is "estimating the pose of a calibrated camera in 3D space, given a set of correspondences between 3D points in the world and their 2D projections" — i.e., extrinsics only with known intrinsics. (Confidence: high — OpenCV calib3d + peer-reviewed PnP literature, PMC10305700.)
- **CamSchnappr's case:** A *single-view*, known-3D-model projector calibration. This is PnP-style, distinct from the multi-view chessboard intrinsic-calibration workflow in the OpenCV tutorial. The tutorial's "≥10 chessboard images" advice does **not** apply to CamSchnappr's single-view model-based use. (Confidence: high.)
- **Reprojection error:** The scalar `ret` is the **RMS reprojection error in pixels** — "the total sum of squared distances between the observed feature points imagePoints and the projected… object points objectPoints." "The closer the re-projection error is to zero, the more accurate the parameters." CamSchnappr surfaces this as **Calibration Error**; Harvey Moon's work added a "Ret Error" output for diagnostics. (Confidence: high.)
- **Why ≥6 points?** A full projection model has ~11 degrees of freedom (a 3×4 projection matrix defined up to scale). Each 3D↔2D correspondence gives 2 equations; 6 points → 12 equations, the minimum to over-determine ~11 unknowns (the standard DLT/PnP minimum). Derivative states the "6 points" floor explicitly; more (8–12+, as mapamok recommends) reduces error. (Confidence: high for the "6 points" requirement (Derivative docs); the DOF derivation is standard CV theory supplied as rationale.)

### 2.3 Coordinate system conventions
- **Handedness/axes:** TouchDesigner is **right-handed, Y-up**, with the camera facing the **−Z axis** by default ("Reset Camera… Returns the camera to a default position facing towards the negative Z axis"; Top view "look[s] down the negative y axis"). The Camera COMP's **Forward Direction** defaults to −Z. (Confidence: high — Palette:camera/cameraViewport; handedness is documented indirectly via the −Z/Y-up behavior rather than the literal word "right-handed.")
- **Units:** TouchDesigner units are **dimensionless / user-defined** — no enforced meters/inches; importing from unit-aware tools (Rhino, etc.) can mismatch because TD reads raw coordinate numbers. Convention treats 1 unit ≈ 1 m but this is not enforced. (Confidence: medium — forum-sourced; no official page sets a default unit.)
- **NDC:** Per Derivative's Projection POP page: "For points within the field of view, the first and second components are between −1 and 1 where 0,0 is at the center. The third component is between **0 and 1** (re-ranged to Near and Far)." ⚠️ This corrects the common assumption: classic OpenGL used Z ∈ [−1, 1], but TouchDesigner's stated depth NDC is **0..1**, consistent with the **Vulkan** backend (Vulkan defines 0 ≤ zc ≤ wc). So current TD: **X/Y NDC = −1..1, Z NDC = 0..1.** (Confidence: high.)
- **UV / texture origin:** **Bottom-left = (0,0)**, top-right = (1,1) ("U,V of 0,0 uses the bottom left of the texture image"). ⚠️ This is opposite OpenCV's **top-left** pixel origin — a real coordinate-flip gotcha when porting imagePoints between OpenCV and TD. (Confidence: high — Attribute / Texture Coordinates pages.)
- **GLSL transform functions:** Canonical vertex shader is `gl_Position = TDWorldToProj(TDDeform(TDPos()));`. **TDPos()** returns vertex position (P attribute); **TDDeform()** returns deformed position in **world space**; **TDWorldToProj()** transforms world → projection space. Use **TDDeformVec()/TDDeformNorm()** for vectors/normals, and wrap color output in **TDOutputSwizzle()**. As of the Vulkan switch, GLSL ≤3.30 was removed and main GLSL is **4.60**; lighting is computed in **world space** (099+) to support multi-camera rendering. (Confidence: high — Write a GLSL Material.)

### 2.4 Aligning a virtual camera to a real projector
The workflow is: model the surface → place a Camera COMP as a stand-in projector (matching focal/aperture/FOV to the real lens where known) → render → project → use CamSchnappr's point correspondences to let `calibrateCamera` solve the exact pose+intrinsics → the solved values overwrite the Camera COMP so the virtual camera *is* the real projector. nVoid frames it: "Camera COMPs come into play to simulate real-world projectors… the Camera COMP can accurately replicate the point of view of the projector." For a light acting as a projector, match the light's projection-map FOV to the camera's FOV via the projection matrix. (Confidence: high.)

---

## 3. Workflow patterns

### 3.1 Single-surface vs multi-surface vs full-3D
- **Single flat surface (2D):** KantanMapper or Stoner. Corner-pin + optional mesh warp. No model needed.
- **Multi-surface (still 2D-ish):** KantanMapper layers/groups — one shape per facet, each with its own texture and softedge. Or multiple Stoner instances (bake displacement maps, then remove Stoner for performance).
- **Full 3D geometry:** CamSchnappr — render a textured 3D model from a calibrated virtual projector. Required when the surface has genuine depth/curvature and you have a model.

### 3.2 2D-content-on-flat (KantanMapper) vs 3D-object (CamSchnappr) — decision rule
Interactive & Immersive HQ's rule: simple keystone/grid → **Stoner**; flat polygon/bezier masking like MadMapper → **KantanMapper**; complex surface *with* an accurate 3D model → **CamSchnappr** (great because alignment needs only a handful of points, but you must have/create the model). (Confidence: high.)

### 3.3 Calibration → render → output signal chain
Typical chain: `Geometry COMP (model) + Camera COMP (calibrated projector) + Light COMP → Render TOP → [mapping/warp/blend] → Null TOP → Window COMP → projector output`. For 2D: `content TOPs → KantanMapper/Stoner → Window COMP`. Run installations in **Perform Mode** (add a Window COMP) for performance. Bake Stoner to a displacement map + **Remap TOP** and delete the Stoner UI to cut overhead. Persist CamSchnappr calibration as the 2 Table DATs inside the Camera COMP. (Confidence: high.)

### 3.4 Multi-machine / multi-projector sync
Three layers (per Derivative Sync page + Interactive & Immersive HQ):
1. **Content/data sync** — share control signals over the network (OSC, Touch In/Out).
2. **Tight software sync** — **Sync In CHOP / Sync Out CHOP** (Pro license only) keep timelines "within a single frame of each other." One process runs Sync Out; clients run Sync In with their **Realtime flag off** (their frame rate is driven by Sync Out). All monitors must run the same refresh rate. (Confidence: high.)
3. **Hardware sync / genlock** — **Hardware Frame-Lock** toggle in the Window COMP + **NVIDIA Quadro Sync** cards ensure all displays refresh in phase, eliminating tearing. Genlock works regardless of project setup as long as V-Sync is on and doesn't need a Pro license; Frame-Lock ties TD's frame output to the Quadro Sync group. Software sync without hardware sync = content arrives in sync but refresh phase may differ; hardware sync without software sync is pointless. (Confidence: high.)

Use **GPU Affinity** (one TD process per GPU, supported since 2022.20000) for multi-GPU; keep each process's windows on its own GPU's desktop space to avoid cross-GPU copies. (Confidence: high.)

---

## 4. GitHub repos, .tox components & community resources

**Derivative official:**
- **Palette (built-in):** kantanMapper, camSchnappr, stoner, projectorBlend, quadReproject, cornerPinSOP/TOP, kinectCalibration, sweetSpot, domeViewer — all ship in-app. (Confidence: high.)
- **Operator Snippets** and the in-app Help. The Projection Mapping overview: docs.derivative.ca/Projection_Mapping.

**CamSchnappr lineage / calibration tools:**
- **YCAMInterlab/mapamok** — github.com/YCAMInterlab/ProCamToolkit — Kyle McDonald's original openFrameworks tool CamSchnappr is ported from. Foundational reference. (Older but seminal.)
- **harveymoon/TD_CameraProjectorCalibration** — github.com/harveymoon/TD_CameraProjectorCalibration — "A TouchDesigner add-on that calibrates a camera + projector pair using OpenCV," ported from cyrildiagne's ofxCvCameraProjectorCalibration. Uses a printed **ChArUco** board + projected circle-grid for full **camera↔projector stereo calibration** (structured-light-adjacent, semi-automatic). Why useful: goes beyond CamSchnappr's manual point-picking to a semi-automatic projector calibration. Harvey Moon also rebuilt CamSchnappr for single-point/VIVE-tracker input and added a Ret Error output (TD Summit 2019 talk). (Confidence: high.)
- **kamino410/procam-calibration** — github.com/kamino410/procam-calibration — "calibration software for projector-camera system using chessboard and structured light patterns" (Python/OpenCV; not TD-native but pairs with it). (Confidence: high.)
- **BingyaoHuang/single-shot-pro-cam-calib** — single-shot structured-light pro-cam calibration (academic, MATLAB). **bytedeco/procamcalib** — Java ProCamCalib. General **davidfofi/procamcalib** (MATLAB, stand-by). For ProCamCalib-style auto-calibration references. (Confidence: high.)
- **Palette:kinectCalibration** — built-in; calibrates a projector to a Kinect via projected checkerboard + pointcloud 3D corners, "same technique as camSchnappr" with the pointcloud as real-world reference. Depth-camera-assisted mapping. (Confidence: high.)

**Warping/blending/mapping .tox & toolkits:**
- **Stoner** (Palette) outputs a warped image **plus a displacement map** for the **Remap TOP** — the recommended reproducible/performant pattern (bake then delete the UI). (Confidence: high.)
- **ProjectorSplit** — forum.derivative.ca/t/projectorsplit-edge-blend-for-multiple-projectors/1874 — shared .tox splitting one image into corner-pinned, edge-blended projector feeds. (Older shared component.)
- **Richard-Burns/SimpleMixer** and **Richard-Burns/Mara_Lite** — github.com/Richard-Burns — TouchDesigner media-server/VJ systems; Mara_Lite adds projection-mapped sets, previz, and feed mapping; mapping mode embeds the **stoner** plus **"Warpa"** (a polygon drawing/warping tool). Tested in build 2023.12000. Useful as a full playback+mapping front-end. (Confidence: high — last activity recent, active Discord.)

**Notable creators' shared toolkits:**
- **Function Store (Daniel Molnar, functionstore.xyz)** — **github.com/function-store/FunctionStore_tools** — workflow/UX toolkit (operator defaults, custom-par promotion, MIDI/OSC mappers, ColorUI, BorderlessTD). Actively maintained — releases include **TD2025.31150 compatibility** fixes; minimum TD 2023.11600/11880. Not mapping-specific but the de-facto pro workflow layer; config save/load to JSON for reproducibility. Also **TopToMidi** (sonification, documentation-only repo). (Confidence: high — recent releases.)
- **Matthew Ragan (matthewragan.com / github.com/raganmd)** — **TD-Examples** (TouchDesigner Examples, Python), **BOS-in-TouchDesigner** (Book of Shaders port, GLSL), **touchdesigner-save-external** (modular external-tox saving — key for reproducible/versioned mapping projects), **touchdesigner_ldi_2017** & **touchdesigner-style-ragan** (his "plates, channels, projectors" architectural model for projection mapping). Long-time Obscura Digital / SudoMagic developer. His "Maintaining Perspective with Multiple Cameras" post covers slicing one scene across tiled cameras. (Confidence: high.)
- **nVoid — Introduction to TouchDesigner** — nvoid.gitbooks.io / github.com/nVoid/Introduction-to-touchdesigner (now under interactiveimmersivehq) — free book by Elburz Sorkhabi; the canonical Edge Blending and Rendering chapters cited above. (Confidence: high.)
- **The Interactive & Immersive HQ (Elburz Sorkhabi)** — interactiveimmersive.io blog — deep practical guides on projector tips, 3D projection mapping, KantanMapper basics, multi-system sync. (Confidence: high.)
- **Greg Hermanovic** (Derivative co-founder) — his **audioAnalysis** component and OP Create IO filter mod are widely reused (bundled into FunctionStore_tools and SimpleMixer). (Confidence: high.)
- **Bileam Tschepe / elekktronaut** (elekktronaut.com, YouTube) — Berlin-based educator; tutorials on **pixel mapping**, **virtual projection prototyping** (TD Tutorial 32: simulate projections on a virtual 3D space before going on-site), dome projection meetups. Best for workflow patterns and previsualization. (Confidence: high.)
- **Torin Blankensmith (torinblankensmith.com / github.com/torinmb)** — **mediapipe-touchdesigner** (github.com/torinmb/mediapipe-touchdesigner) — GPU-accelerated MediaPipe plugin (hand/body/face tracking, runs in embedded Chromium, no setup, Mac+PC). Not mapping per se but the go-to for interactive/tracked projection; co-created with Dom Scott. Note its fixed frame delay → use a **Cache TOP** to resync. Also co-creator of Shader Park. (Confidence: high — actively maintained.)
- **DBraun/TouchDesigner_Shared** (David Braun) — shared components referenced by elekktronaut. (Confidence: medium.)

**Point-cloud / depth-assisted mapping:** Palette **kinectCalibration**, **kinectPointcloud**, **depthProjection** components; OAK-D / Orbbec / ZED / RealSense sensor support expanded in 2023+ builds. (Confidence: high.)

---

## 5. Integration & advanced topics

### 5.1 Spout / Syphon / NDI output
- **Syphon Spout Out TOP** shares a TOP "with other applications that support the Spout framework on Windows or Syphon on macOS" via **shared GPU memory** — same machine only. Per the Derivative docs, verbatim: "Spout can send textures in various pixel formats up to and including **32-bit float RGBA**. **Syphon is limited to 8-bit RGBA**." Spout on Windows needs an NVIDIA/AMD GPU (Intel won't work) and defaults to a **10-sender limit**: "By default Spout on Windows is limited to 10 senders active on the computer. This limit can be changed by setting the Windows registry DWORD: `HKEY_CURRENT_USER\Software\Leading Edge\Spout\MaxSenders`." (Confidence: high.)
- **NDI In/Out TOP** and **Touch In/Out TOP** send across the **network** to another machine (Spout/Syphon cannot). NDI is the standard for cross-machine/media-server handoff. (Confidence: high.)
- Typical handoff: TouchDesigner generates content → Spout/Syphon/NDI → Resolume/MadMapper/Millumin does final mapping; or the reverse (mapper sends to TD for effects). Resolume auto-broadcasts its output once Syphon/Spout is enabled and always accepts inputs. (Confidence: high — Resolume docs.)

### 5.2 When to hand off to Resolume / MadMapper / Millumin
- **Stay in TouchDesigner** when you need generative/interactive/3D-model-based mapping, custom logic, sensor integration, or full pipeline control.
- **Hand off to MadMapper** for fast, artist-friendly surface mapping/masking and its mature warping UI; **Resolume Arena** for VJ/clip-based shows with built-in **Advanced Output** warp/blend (it can treat Syphon/Spout/NDI as a virtual screen and warp before sending); **Millumin** for timeline-driven theatrical/installation playback. Common pattern: TD as the generative/content engine, the external app as the mapper/playback surface. (Confidence: medium-high — synthesis of Resolume docs + community practice.)

### 5.3 Performance: resolution, GPU, multi-output cards
- **Pixel-shading bottleneck:** "There is a 1:1 ratio between a TOP's resolution and its GPU workload." Halving resolution halves GPU cost. Diagnose by lowering generator-TOP resolutions and watching cook times. (Confidence: high — nVoid.)
- **Disk bottleneck:** Many simultaneous HAP Q streams can saturate a slow disk regardless of CPU/GPU — use fast NVMe/SSD. (Confidence: high.)
- **Multi-output distribution:**
  - **Datapath FX4 / X4** — each appears as a single display to the OS. Per Datapath's official Fx4 datasheet the FX4 supports an **8K×8K maximum input surface** with four genlocked outputs (up to 1080p60 each) and a DisplayPort 1.2 main input handling 4096×2160p60; the X4 is capped lower (~4K). Both do arbitrary per-output scaling and 90°-increment rotation, and are hardware bandwidth-limited (X4 ~330 Mpx/s; FX4 roughly double). One 4-output GPU + four FX4 → up to 16×1080p. Datapath is the road-tested go-to. (Confidence: high.)
  - **Matrox TripleHead2Go / DualHead2Go** — turn one output into 2–3; cheaper, but with EDID quirks and some units running only at 50Hz / max 2 units per machine. (Confidence: medium-high.)
  - **NVIDIA Mosaic** — groups multiple GPU outputs into one virtual desktop/GPU; use the Mosaic Utility. Per Vizrt's Viz Multiplay docs, "If the video wall needs more than a 4K resolution, two or more of the outputs from the GPU can be combined with nVidia Mosaic to create for instance an 8K surface" (note the DisplayPort HBR2 ceiling of ~17.28 Gbit/s ≈ 4K/60 8-bit per link). A single-GPU + splitter generally outperforms a multi-GPU setup. (Confidence: high.)
- **Render TOP cropping** for tiling: crop via projection matrix and set the Render TOP aspect to the *overall* output aspect (not the sub-tile) to avoid stretching. (Confidence: high.)

### 5.4 Saving/loading calibration data, reproducibility
- **CamSchnappr** stores calibration as **2 Table DATs inside the Project Camera COMP** — these persist with the .toe and can be exported/version-controlled. (Confidence: high.)
- **Stoner** stores warp data + displacement map in a user-specified Base COMP ("Project" parameter); bake it, then remove the Stoner UI and drive a Remap TOP from the stored map. (Confidence: high.)
- **VIOSO / Scalable Display** read external calibration files (from their camera-based calibrators) via their TD integrations — calibration lives in those files, reloadable per show. (Confidence: high.)
- **External .tox + git:** Matthew Ragan's `touchdesigner-save-external` and Function Store's JSON config save/load enable modular, diffable, reproducible projects (binary .toe files don't diff well). Externalize mapping COMPs and calibration tables. (Confidence: high.)

---

## Quick-reference cheat sheet

**Tool selection (decision tree)**
| Situation | Tool | Notes |
|---|---|---|
| Simple keystone / grid warp, flat | **Stoner** | Corner-pin + bezier mesh; outputs displacement map for Remap TOP |
| 2D polygon/bezier mapping & masking | **KantanMapper** | Quads + freeform, layers/groups, per-shape softedge |
| 3D object, have a model | **CamSchnappr** | ≥6 points → `cv2.calibrateCamera`; stores 2 Table DATs in Camera COMP |
| Edge-blend projector array | **projectorBlend** | Paul Bourke method; all projectors same res |
| LED panels / XR / pixel-perfect | **quadReproject** | Uses Camera COMP custom projection matrix per panel |
| Auto multi-projector (dome/pano) | **VIOSO / Scalable Display** | Camera-based external calibration |
| Trompe-l'œil from a viewpoint | **sweetSpot** | Re-project from observer position |
| Projector↔camera auto-calib | **harveymoon/TD_CameraProjectorCalibration** | ChArUco + circle grid, OpenCV stereo |

**CamSchnappr workflow:** model → Render setup → assign Geo SOP (not a Material SOP) + Camera → Output Monitor = projector → Open Main + Output → Ctrl+click points on model → drag/Shift+click to real positions in output → ≥6 points → calibrated. Reset projector keystone/zoom first.

**CamSchnappr OpenCV flags:** Fix Aspect Ratio = ON (square pixels); Zero Tangent Dist = ON (projectors); Intrinsic Guess = CALIB_USE_INTRINSIC_GUESS; Fix K1/K2/K3 for fisheye; Calibration Error = RMS reprojection error (px), lower = better.

**Calibration math:** intrinsics = 3×3 matrix (fx,fy,cx,cy) + distortion (k1,k2,p1,p2,k3); extrinsics = rvecs/tvecs. calibrateCamera ⊃ solvePnP (PnP = pose only w/ known intrinsics). ≥6 pts because ~11 DOF, 2 eqns/pt.

**Coordinate conventions:** right-handed, **Y-up**, camera faces **−Z** by default. Units dimensionless. **NDC: X/Y = −1..1, Z = 0..1** (Vulkan; *not* OpenGL's −1..1). **UV origin = bottom-left** (OpenCV is top-left — flip!). GLSL: `gl_Position = TDWorldToProj(TDDeform(TDPos()))`; wrap color in `TDOutputSwizzle()`; GLSL 4.60.

**Texture sharing:** Spout (Win, ≤32-bit float, NVIDIA/AMD only, 10-sender default) / Syphon (Mac, 8-bit only) = **same machine**; NDI / Touch In-Out = **across network**.

**Multi-machine sync:** Sync Out CHOP (server) → Sync In CHOP (clients, Realtime OFF) [Pro only] = software sync; + Window COMP **Hardware Frame-Lock** + **Quadro Sync** = genlock. GPU Affinity (one process/GPU, 2022.20000+).

**Hardware:** Datapath FX4 (8K×8K max input surface, per-output scale/rotate, 1 display to OS) > Matrox TH2Go (cheaper, EDID quirks); NVIDIA Mosaic (virtual desktop, combine GPU outputs into 8K surface). Single GPU + splitter > multi-GPU.

**Versioning (2026):** year.build scheme (2022.20000 / 2023.10000 / 2025.30000); "099" = legacy splash branding only. 2023 .toe **can't** open in ≤2022. Python 3.11 (3.11.10 in 2025 experimental). Vulkan backend, GLSL 4.60. POPs are the new (2025) GPU geometry family replacing many SOP/particle workflows.

**Key URLs:** docs.derivative.ca/Projection_Mapping · /Palette:camSchnappr · /Palette:kantanMapper · /Palette:stoner · /Palette:projectorBlend · /Palette:quadReproject · /Quad_Reprojection · /Sync · /Hardware_Frame_Lock · /Write_a_GLSL_Material · github.com/harveymoon/TD_CameraProjectorCalibration · github.com/function-store/FunctionStore_tools · github.com/raganmd · github.com/torinmb/mediapipe-touchdesigner · nvoid.gitbooks.io/introduction-to-touchdesigner

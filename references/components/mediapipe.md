# MediaPipe component (`torinmb/mediapipe-touchdesigner`)

GPU-accelerated MediaPipe plugin by Torin Blankensmith and Dom Scott. Hand / face / pose / object tracking, gesture recognition, image segmentation. Cross-platform.

**Mac prerequisite:** Full Disk Access — see `mac-gotchas.md` § "MediaPipe requires Full Disk Access". Without it, the component fails silently with no console error.

---

## Frame delay — plugin output is ≥3 frames behind realtime

**Source:** TD/MCP research dossier (May 2026), torinmb/mediapipe-touchdesigner | Date: May 2026

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

## Disable unused detection tasks — CPU + GPU savings

**Source:** TD/MCP research dossier (May 2026) | Date: May 2026

The plugin runs detection tasks on a configurable set: face landmarks, face detector, hands, pose, objects, image classification, image segmentation, image embeddings. **Each enabled task carries CPU + GPU cost** — leaving all of them on for a project that only uses hand tracking burns frame budget on unused detectors.

**Rule:** on the MediaPipe COMP's tabs (Hands / Face / Pose / Objects / Image Classification / Image Segmentation / Image Embeddings), turn OFF every detection task the project doesn't consume. The component exposes per-task toggles directly on its parameter pages.

**Check first when:**

- FPS is below target on a MediaPipe-heavy project
- The project clearly only uses one detection modality
- `get_op_performance` shows the MediaPipe COMP as a hotspot
- Multiple detection tabs show "On" but only one is wired to anything downstream

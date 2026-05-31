# Third-party TouchDesigner ecosystem tools — awareness catalog

> **This is an AWARENESS catalog, not a how-to reference.** It lists what the TD ecosystem offers in 2026 so the agent knows when to recommend a community tool instead of building from scratch. **All tools are third-party, mostly Patreon/paid, and the user has not personally tested any of them.**

**Source for the catalog:** Crystal Jow / Interactive & Immersive HQ "Best TouchDesigner Tools 2026" list | **Confidence:** HIGH for existence, LOW for behavioral detail (untested by user).

---

## Trigger (load this file when)

When a user asks for a TD capability that feels heavy to build from scratch — advanced particle physics, raymarching/SDF, ML tracking beyond MediaPipe, AI-driven generation, 2D dynamic lighting, motion blur, etc. — **check this catalog first** to see if a community tool already covers it. Don't propose building from scratch when a Patreon tool exists. **The agent does NOT have hands-on experience with any of these; recommendations are "this exists, evaluate it" not "I know this works."**

---

## POPX (Mini Uv, popsextension.com)

**What it is:** an extension to the POPs system adding generators, falloffs, modifiers, tools, and **physics simulations** (rigid-body / soft-body / fluid dynamics) as POP-native operators.

**Why it matters:** smooth particle simulations beyond what built-in `Particle POP` + `Force Radial POP` deliver. If a brief calls for fluid-like behavior or constraint-based physics in points, POPX likely has it.

**Status:** third-party, paid (Patreon). Untested. Verify current pricing + Mac compatibility before recommending in a paid project.

**Cross-link:** complements `pops.md` § "Particle systems — open feedback chain" for cases where the native feedback chain isn't sufficient.

---

## RayTK (Tommy Ekins, github.com/t3kt/raytk)

**What it is:** a raymarching framework for TD — build SDF-based volumetric / procedural visuals without writing GLSL directly.

**Why it matters:** **directly relevant to the GLSL-patterns stub gap** (`glsl-patterns.md`). When a user wants raymarched volumes, signed-distance-function combinations, or volumetric effects, RayTK offers a node-based path without authoring custom GLSL POPs/TOPs from scratch.

**Status:** open-source on GitHub (free). Lower friction than the Patreon tools to evaluate. Untested by user.

---

## LOPs (DotSimulate)

**What it is:** 60+ operators for AI/LLM/RAG workflows inside TD.

**Why it matters:** when a project needs LLM-driven generation, retrieval-augmented patterns, or AI-orchestrated visuals, LOPs is the first place to look before building bespoke Python bridges. **See also `ai-integration.md`** for the underlying Python→OSC→TD architecture and how custom bridges fit alongside LOPs.

**Status:** third-party (DotSimulate Patreon). Untested. AI-tool ecosystems move fast — verify the current LOPs surface against the specific need before recommending.

---

## YOLO plugin (Torin Blankensmith)

**What it is:** real-time YOLO-based object detection + ML tracking in TD.

**Why it matters:** **complement to MediaPipe** (`components/mediapipe.md`). YOLO handles arbitrary object classes (cars, animals, custom-trained models) where MediaPipe specializes in faces/hands/pose. If a brief needs "detect [non-human object]", YOLO is the candidate.

**Status:** third-party. Untested. Verify Mac compatibility (YOLO models typically need ONNX/CoreML runtimes; check the plugin's setup requirements on Apple Silicon).

---

## L2D, T3D, MFI Motion Blur, others

Brief mentions — existence confirmed, no behavioral depth:

- **L2D** — 2D dynamic lighting system for TD (real-time 2D lighting, shadows, falloffs)
- **T3D** — 3D texture / procedural texture toolkit
- **MFI Motion Blur** — motion blur effect for TD render output

**Status:** all third-party, mostly Patreon. Awareness only — no hands-on knowledge.

---

## Embody (Dylan Roscover)

Mentioned here for completeness — **Embody is the foundation this skill is built on** (see `project-bootstrap.md` for the canonical setup). It's the externalization framework + Envoy MCP server that lets Claude operate against TD live.

Not a separate "tool to consider"; it's the bedrock the agent is already running on.

---

## AI / Generative AI in TD — see `ai-integration.md`

The AI ecosystem (real-time diffusion, LLM agents, vision-driven visuals) is changing fast enough that detailed tool lists go stale in months. The **stable** content — the Python → OSC → TD architecture for LLM/AI integration — lives in `ai-integration.md`. Treat specific `.tox` names and model names there as a snapshot in time.

---

## How this file ages

This catalog will go stale. Tools graduate / get abandoned / get superseded. **The agent should not treat this file as a buyer's guide** — its only job is to flag "a community tool may exist for this; investigate before building from scratch." When in doubt, check the tool's current status (its Patreon / GitHub) before committing project time.

**Update path:** when a community tool gets actually used in production and survives the growth-protocol gates (observed-failure-and-fix on a real task), it moves from this awareness catalog into a dedicated `components/<tool>.md` reference with behavioral depth (similar to how `components/mediapipe.md` and `components/gaussian-splatting-mac.md` work).

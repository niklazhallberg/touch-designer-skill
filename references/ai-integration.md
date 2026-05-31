# AI / LLM integration with TouchDesigner

> **The stable pattern is the Python → OSC → TD bridge architecture.** Specific tools, `.tox` versions, and model names age in months — treat the named tools below as a **snapshot of April 2026**. The architecture pattern is what's worth retaining; the tool names are placeholders for "whatever the equivalent is when you're reading this."

---

## Trigger (load this file when)

When the task involves LLM/AI-driven visuals, real-time generative AI, agent-controlled TD parameters, or any "AI thinks, TD shows" pattern — load this file. **The OSC bridge (Python → OSC → TD) is the recurring architecture.** When in doubt about specific tools, also check `td-community-tools.md` for the LOPs awareness entry.

---

## The stable architecture — Python → OSC → TouchDesigner

**Source:** [Gianmaria Vernetti — Best AI Tools to Pair with TD 2026](https://interactiveimmersive.io/blog/touchdesigner-tutorials/best-ai-tools-to-pair-with-touchdesigner-2026/) (II HQ, 2026-04-09) | **Confidence:** MEDIUM for the named tools, HIGH for the architecture pattern

```
[External Python process]  ←──→  [LLM API / vision model / diffusion model]
        │
        │ python-osc SimpleUDPClient
        ↓
[OSC packets over UDP]
        │
        ↓
[TD network: OSC In CHOP / OSC In DAT]
        │
        ↓
[TD parameters / Text TOP / textDAT / instancing source / shader uniforms]
```

### Why this pattern dominates

- TD's Python is bound to the cook cycle (60 Hz visual rate). Long-running API calls block the cook.
- Externalizing to a separate Python process keeps TD responsive while the API call (seconds, sometimes longer) completes.
- OSC is the canonical, stable inter-process protocol — both sides already understand it.
- The TD side just listens — no API client dependencies inside TD's Python environment.

### Rule

**When an integration needs LLM / vision / diffusion API calls, ALWAYS externalize the API caller to a separate Python process that talks to TD via OSC.** Don't put `requests.post(...)` or `anthropic.messages.create(...)` directly in a CHOP Execute callback or a DAT script — it blocks the cook and freezes the visual.

### Boilerplate

```python
# External Python process (run separately, not inside TD)
from pythonosc.udp_client import SimpleUDPClient

td = SimpleUDPClient("127.0.0.1", 7000)  # 7000 = TD's OSC In port

# whenever you have something to send TD:
td.send_message("/visual/brightness", 0.7)
td.send_message("/visual/text", "AI-generated content goes here")
```

```
TD side: OSC In CHOP listening on port 7000.
- For numeric params: OSC In CHOP → channel "/visual/brightness" routed to param expression
- For text: OSC In DAT → parameterDAT → Text TOP source
```

---

## Anthropic tool-use pattern — agent-driven visual control

**Source:** Vernetti II HQ article, 2026-04-09 | **Confidence:** MEDIUM (pattern stable, model names volatile)

Give Claude (or any tool-use-capable LLM) a custom `osc_tool` with an `input_schema` declaring which TD parameters it can modulate. The LLM picks parameter values that satisfy a high-level intent and emits them via OSC.

### Architecture

```python
# Snapshot pattern — exact model names age in months; the schema design is stable
osc_tool = {
    "name": "osc_modulate_visual",
    "description": "Modulate live TouchDesigner visual parameters in real time.",
    "input_schema": {
        "type": "object",
        "properties": {
            "brightness":  {"type": "number", "minimum": 0,    "maximum": 1},
            "contrast":    {"type": "number", "minimum": 0,    "maximum": 2},
            "color_shift": {"type": "number", "minimum": -180, "maximum": 180},
        },
        "required": ["brightness", "contrast", "color_shift"]
    }
}

# Claude is given the tool. On each turn (or each input from a sensor / user),
# it picks parameter values matching the intent and calls the tool. The wrapper
# code forwards the JSON to TD via OSC.
```

On the TD side: `OSC In DAT` parses the JSON; `parameterCHOP` or an Execute DAT routes the named values to live parameters.

### Why this matters for visuals

Claude becomes an "AI artist" that interprets high-level intent ("make it more brooding") into concrete parameter values across many channels simultaneously. Different from a fixed audio→bass→brightness mapping because the LLM understands what "brooding" *means* and picks the right combination across multiple parameters.

### Tool-design rules

- **The `input_schema` IS your interface.** Constrain tightly: `minimum`/`maximum`, enums, required fields. LLMs are more reliable on bounded outputs than open-ended ones.
- **Name parameters concretely** — `brightness` beats `param1`. The LLM reads the schema for semantic cues.
- **Include a `description` field on the tool** that tells the LLM what kinds of intent map to which values. ("Use higher contrast for dramatic moods.")

---

## Anthropic vision pattern — camera frames driving visuals

**Source:** Vernetti II HQ article, 2026-04-09 | **Confidence:** MEDIUM (architecture stable; latency/cost shift per model)

Send camera frames (base64-encoded) to Claude at some sampling rate — **every N seconds, not every cook**. Optionally compare two frames over time, describe the change, emit modulation parameters via OSC.

### Architecture

```
[Live camera in TD] → [moviefileout / capture frame at N-second interval] → [base64 encode]
        │
        ↓ external Python, async
[Claude Vision API: "describe the change between these two frames"]
        │
        ↓
[Parse response → derive parameter modulation]
        │
        ↓ OSC
[TD visual parameters update]
```

### Why this matters for visuals

Evolving AI-driven datascapes that respond to slow real-world change — sunlight over hours, room occupancy, scene composition, lighting mood. **Interpretation-driven, not frame-by-frame.**

### Latency reality

Vision API calls are seconds, not milliseconds. This is a **slow-loop pattern**, not a real-time pattern. Design the visual to be *driven over time* by the modulation, not gated by it — the visual should remain alive between API calls, with the AI input shaping the trajectory rather than each frame.

---

## Gemini text-gen pattern — generative text into Text TOP

**Source:** Vernetti II HQ article, 2026-04-09 | **Confidence:** MEDIUM

Variation of the bridge pattern when the output is text rather than numeric parameters:

```
[CHOP Execute DAT triggers on a pulse / sensor / cron]
        │
        ↓ external Python
[genai.Client / equivalent API call with prompt from a Text COMP or external state]
        │
        ↓
[Response written to a Text TOP / textDAT in TD]
```

Same externalize-the-API-call principle. **Don't block the cook with the API call** — trigger from external Python, write back to TD.

---

## Real-time diffusion — AWARENESS (snapshot April 2026)

**Confidence:** LOW (specific tools / `.tox` versions volatile)

> **The real-time diffusion ecosystem changes fast.** Specific tools, supported models, and performance characteristics age in months. Treat the names below as "tools that exist roughly in April 2026" — verify current state before integrating in a project.

### Tools that existed at this snapshot

- **StreamDiffusion / StreamDiffusionTD** (`.tox` by DotSimulate, Patreon) — real-time Stable Diffusion in/with TD. Local + cloud (Daydream) variants. Drives "still image becomes alive" effects when paired with motion input.
- **TouchDiffusion** — alternative real-time diffusion integration for TD.
- **ComfyUI `.tox`** (DotSimulate) — node-based generative AI pipeline accessible from TD, local or cloud-backed.

### Canonical "stillbild blir levande / animerad, driven av kroppsrörelse" pattern

This effect is **never a single operator** — it's a multi-stage chain:

```
[Tracking: MediaPipe / YOLO] → [ControlNet conditioning: pose / depth / edges]
                                          │
                                          ↓
                            [Real-time diffusion model: SD / SDXL / Turbo / etc]
                                          │
                                          ↓
                                  [Composite back into TD render]
```

**Rule:** when a user wants "AI generates visuals driven by body movement", the agent should recognize this is a multi-stage pipeline (4+ stages), not "drop in one `.tox`". Each stage has independent trade-offs:

- Tracking quality (MediaPipe Mac-FullDiskAccess constraint; YOLO classes)
- ControlNet conditioning type (pose / depth / canny — pose for body work, depth for environmental)
- Diffusion model (latency vs quality; turbo/lcm variants are needed for real-time)
- Composite blending (cross-fade, masking, color matching)

---

## What this file deliberately does NOT capture

This file flags **what** exists in the AI integration space and the **stable architecture pattern**. It deliberately does NOT capture:

- Detailed prompt engineering recipes (per-model, change per model release)
- Specific diffusion-model parameter tuning (depends on hardware, model, use case)
- Specific `.tox` usage walkthroughs (these go stale on `.tox` updates)
- Latency benchmarks (depend on hardware, network, model, time of day)

Those details will be wrong in 6 months. When the user actually builds an AI-integrated TD project:

- **The OSC bridge architecture** is the part of this file to trust and keep using
- **Specific tools / models / `.tox` versions** get verified in production at use-time, not captured here
- **New patterns** that survive the growth-protocol gates (`skill-growth-protocol.md` § "Pre-ask filters") land in this file as the architecture matures — fast-moving details stay out

---

## Known gaps (deliberately empty here)

| Gap | Where it surfaces |
|---|---|
| Specific real-time diffusion latency on M1 Pro for SD/SDXL/Turbo variants | When you actually run StreamDiffusionTD on the machine |
| Prompt engineering patterns for visual modulation via Claude tool-use | When you build the agent-driven patch in production |
| How to gracefully handle API failures / rate limits in the OSC bridge | When you ship an installation that needs to recover from API errors |
| ComfyUI workflow patterns for TD integration | When you build a node-graph generative pipeline through the `.tox` |

When these resolve in real work and survive growth-protocol gates, they move into a more detailed companion file (or replace sections here).

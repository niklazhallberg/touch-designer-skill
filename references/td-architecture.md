# TouchDesigner architecture — minimalism + visual verification

Two principles for how the agent should reason about TD network structure: prefer minimal operator counts, and verify against visual output, not just successful execution.

---

## Minimalism — prefer fewer operators over more

**Source:** [The Great Inversion (Dylan Roscover, March 2026)](https://derivative.ca/community-post/great-inversion/74207) | Date: March 2026 | **Confidence:** HIGH (the 33:1 widget-vs-primitive ratio is from Derivative's own palette; the architectural argument is broadly applicable)

Concrete reference point: Derivative's stock `buttonMomentary` widget COMP contains **33 operators internally** to provide a single push-button. A bare `Text COMP` set up to react on click does the same job with **1 operator**. The ratio is roughly **10:1** in this example, and it generalizes — heavy widget abstractions from the palette are often unnecessary for project-specific work.

**Why this matters:**

- **Cook cost:** every internal operator may cook every frame. 33 vs 1 changes the per-frame budget noticeably at scale.
- **Debug surface:** every operator is something that can go wrong. Fewer operators = fewer failure points.
- **Reasoning cost (for the agent):** when reading the network, the agent has to model what each operator does. A 33-operator widget burns context to understand a button.
- **Render-graph depth:** more operators = deeper dependency chains, slower to settle on parameter changes.

**Rule for the agent:**

- For project-specific UI/interaction, **build from primitives** (Text COMP, Constant CHOP, Switch CHOP, etc.). Don't drop a palette widget unless its features (skinnable styling, gesture variants, accessibility) are actually needed.
- When a palette COMP is already in place and works, **don't preemptively replace it** — but flag the trade-off if you see opportunities to simplify and the user is open to refactoring.
- "Minimal" doesn't mean "premature DIY" — if reaching for a primitive forces you to reimplement gesture handling, easing, debouncing, etc., the widget was probably the right call.

**Decision rule:** for each abstracted COMP, ask "does this give me something I'd otherwise have to reimplement?" If no, prefer the primitive.

**Check first when:**

- About to drop a palette widget for a simple control (button, slider, toggle, label)
- Reading an existing network with deep internal nesting and trying to understand what it does
- Profiling cook times and looking for sources of background load
- Planning a layout where many widgets will live side-by-side

---

## Visual verification — `capture_top` is ground truth

**Source:** [The Great Inversion (Dylan Roscover, March 2026)](https://derivative.ca/community-post/great-inversion/74207) | Date: March 2026 | **Confidence:** HIGH (cross-referenced as an architectural rule in CLAUDE.md and `rules/td-python.md`; this entry adds the "necessary not sufficient" framing on top)

**"If it looks correct, it is correct."** TD is a visual program; the output of a TOP/render is the only ground truth. Code that runs without errors and parameters that read as expected do not, by themselves, prove the network produces the intended image/animation.

This reinforces and extends existing rules:

- Project `CLAUDE.md` § Critical Rule 9: "Always check for errors and warnings after creating operators" — *necessary, not sufficient.*
- `rules/td-python.md` § Operator Referencing: "Always verify references resolve correctly" — *necessary, not sufficient.*
- `rules/td-python.md` § Module-Level Code Hazard: defers state-access to method-call time — *preventive, doesn't confirm output.*

**Add: after any meaningful change to a render path or visual operator chain, call `capture_top` on the affected output before declaring the change done.**

### When to capture (mandatory)

- After modifying a GLSL shader (vertex or pixel) — colors, transforms, culls, alpha behavior
- After re-wiring a render graph (changing render TOP inputs, swapping select TOPs, inserting overTOP/addTOP)
- After parameter changes that affect what gets rendered (camera distance, scale, light intensity, alpha threshold)
- After composite changes (Over/Add/Multiply TOPs reordered or replaced)
- After ANY claim of "done" on a visual feature — even if `get_op_errors` returns 0 and parameters read as expected

### When you can skip the capture

- The change is purely data-side (CHOP processing that doesn't affect any TOP downstream)
- The render path is verifiably unchanged (the modified operator is upstream of a known-stable null/select boundary that you've separately confirmed)
- You're at a non-visual checkpoint (extension code, parameter wiring without a render consumer yet attached)

### Rule

`errors=0` + "parameter reads correct" is **necessary but not sufficient**. The image is the proof. If you didn't capture, you don't know.

A small extension: when comparing before/after on a non-trivial change, capture *both* and surface the diff. Don't ask the user to remember what the previous frame looked like.

---

## Known gaps (deliberately empty)

These are publicly unresolvable or unmeasured as of 2026-05-31. Capture during real production work via the growth protocol's pre-ask gates (`skill-growth-protocol.md § Pre-ask filters`):

| Gap | Where it surfaces |
|---|---|
| Quantified cook-cost difference per operator count — the 33:1 ratio is structural, but no measured per-frame cost delta is documented | First time a project's cook budget is profiled with widget-heavy vs primitive-heavy UI side by side |
| When the abstraction-cost calculation flips — which palette widgets ARE worth their internal operator count (gesture handling, accessibility, theming) | First time a primitive-built UI hits a feature that's non-trivial to reimplement |
| `capture_top` performance budget for high-FPS work — at what cook rate does per-change capture become its own bottleneck? | First time visual verification is enforced on a 120 Hz / VR / installation project |
| Whether visual verification should be automated (cron-snapshot during long runs) vs always on-demand | First time a stuck operator's wrong output goes unnoticed for hours |

When any of these resolves in real work and survives the growth-protocol gates, it moves into the appropriate section above.

---

## Performance optimization — diagnostic-driven, not a fixed order

**Sources (all primary Derivative):**
- [docs.derivative.ca/Optimize](https://docs.derivative.ca/Optimize) — official UserGuide page
- [learn.derivative.ca — Optimization curriculum lesson](https://learn.derivative.ca/courses/100-fundamentals/lessons/108-resources/topic/optimization/)
- [derivative.ca community-post: TouchDesigner Optimization Strategies](https://derivative.ca/community-post/touchdesigner-optimization-strategies/70986)

**Confidence:** HIGH — three independent Derivative-published sources converge on the same principles.

**Important framing correction:** Online research syntheses (e.g. AI search-engine summaries) sometimes present a *fixed optimizing order* like "resolution → transparency → particles → cook → CPU/Python". **Derivative does not document a fixed order.** Their guidance is **diagnostic-driven** — measure first, then act on where the bottleneck actually is. Following a generic order without measurement wastes effort optimizing things that aren't the bottleneck.

### The actual documented diagnostic workflow

1. **Performance Monitor first.** Open it (`Dialogs → Performance Monitor` or `Alt+Y`) to see CPU time per operator per frame. Look at the top of the list — those are your real bottlenecks. *"The Performance Monitor gives you the CPU time consumed by each operator that cooks in one single frame."*

2. **Trail CHOP on Perform CHOP** for time-history. *"You can perform CHOP followed by a Trail CHOP and turn on Frame Time and Cook channels to look at a time-history of performance."* Useful for catching intermittent stalls vs steady cost.

3. **GPU-bottleneck test (64×64):** drop render resolution to 64×64. If framerate jumps significantly → GPU-bound (work on render-side: fewer transparent passes, lower resolutions, fewer particles, simpler shaders). If little change → CPU-bound (work on cook-side: Python, CHOPs, cook chain breadth). *"Try turning down your render resolution 64x64 and see if things speed up. If they do then you know it's GPU related."*

4. **Python audit.** *"Python scripts can be very expensive. If they are showing up as taking significant time in the Performance Monitor, it may be worth seeing if they can be optimized at all. In many cases, chunks of python code can be replaced with a small network of TouchDesigner CHOPs or DATs, which may be an order of magnitude faster. If you can, avoid scripts running every frame."*

5. **Null CHOP Selective mode** to gate downstream cooking. *"The Null CHOP in Selective mode can be used to reduce downstream cooking in CHOP chains when the input to the Null CHOP doesn't change. However, the Null CHOP itself will always cook on data changes in this mode, so use with caution."*

6. **System hygiene.** *"Turn off all virus checkers and spy-ware services while running TouchDesigner. These services can often use lots of CPU cycles and access the hard drive frequently."*

### Why diagnostic-driven beats fixed-order

Two different projects with the same framerate problem can have completely different bottlenecks: one might be Python-bound from a per-frame DAT script, the other GPU-bound from a misconfigured Render TOP with unnecessary transparency. The fixed-order rule would have you optimize resolution first in BOTH cases — wasted effort in the Python-bound project. Performance Monitor + the 64×64 GPU test resolve it in seconds.

**Rule:** profile first, optimize the actual bottleneck. Don't apply a generic order without measurement.

### Offload blocking Python with subprocess

**Source:** [docs.derivative.ca/Python_Tips](https://docs.derivative.ca/Python_Tips) (run/subprocess context) | Page last edited: 2022-03-13 | **Confidence:** MEDIUM (Derivative wiki + community-blog convention — verify in your TD version)

Blocking Python in a callback or extension freezes TD's cook — spawn a `subprocess` and read results via OSC/DAT/file rather than blocking the main thread.

Typical offenders: synchronous HTTP requests, large file reads/writes, model inference (`transformers`, `torch`, `onnxruntime`), database queries, anything with a network round-trip. If the Python call doesn't return in <1 frame budget, it blocks the cook — visible as instant freeze + dropped frames, sometimes a TD "not responding" dialog.

The offload pattern:

1. Launch a separate Python process via `subprocess.Popen` (or a long-running worker started at project init).
2. Pass inputs through stdin / a file / a JSON payload on disk.
3. The worker writes results to a known channel: an OSC message back to an `oscinDAT`, a file polled by a `monitorsDAT`, or a row appended to a CSV that an `infoDAT` watches.
4. The TD side reads results when ready — no blocking call on the main thread.

This pattern applies to **user-written Python**. TD's own heavy main-thread operations (e.g. `project.save()` on a large project, large topology changes) cause the same family of freeze (main-thread block) but cannot be offloaded with `subprocess` — that lever applies only to code we control. Cross-link: `td-gotchas.md` § "Topology change + large cook = TD hangs — bypass during refactor" documents the related-but-distinct case where the block originates inside TD itself; the fix there is `bypass` / `allowCooking`, not subprocess.

**See also:** the Thread Manager pattern in `skills/td-api-reference/SKILL.md` § "Thread Manager" — TD's in-process worker pool. Subprocess is the heavier-isolation alternative when the workload would otherwise depend on packages that conflict with TD's bundled Python, or when crash-isolation matters (a `subprocess` crash doesn't take TD down).

**Check first when:**

- A callback or extension method needs HTTP / disk-heavy / inference work
- Symptoms include sudden FPS drops timed with specific user actions (button click, file open)
- The work depends on packages that don't ship with TD's Python or conflict with it
- You want crash isolation (worker crash doesn't kill TD)

---

## Parallel pipelines — the "bypasses broken X" anti-pattern

**Source:** RADON_TREE project, 2026-06-17 | **Confidence:** HIGH (own observation: full rip-out cycle from diagnosis through verification of single-pipeline restoration)

**Symptom.** A TD project contains two scripts orchestrating the same state machine. One is the original intended system (typically a frame-driven `executeDAT`, a callback chain on a CHOP, or an `onCook` handler). The other is a duplicate script (often a `panelexec` with `run(..., delayFrames=N)` callbacks) marked with a comment along the lines of `# bypasses broken X` / `# autonomous pipeline` / `# parallel flow`. Bugs that look like race conditions appear: state flips back and forth, timing is off by ~1 frame, fade tweens don't fire, transient values from one pipeline get clobbered by the other.

**Root cause.** Both pipelines write to the same storage keys (state flags, frame stamps, animation values) on the same COMP. Per-frame order of operations across TD's callback queue, frame-start callbacks, and operator cook order is non-deterministic — one pipeline's write wins one frame and loses the next. Hardcoded `delayFrames=N` constants in the bypass tend to drift off by 1-2 frames from real durations (e.g. video length, project FPS), producing intermittent visible glitches that are hard to localize.

**Why the bypass exists.** The original "broken X" was usually broken by 1-3 small unrelated bugs (a missing `try/except` on a renamed channel; a `min(1.0, t)` that didn't clamp negative `t` and so blew up from stale storage between sessions; a typo'd path). The patch-author chose to bypass rather than fix, because the bypass was an additive change that "worked" locally during a deadline crunch, while fixing X meant understanding code they hadn't written. Over weeks, additional features land on the bypass, hardening the duplication.

**Detection (audit cue).** Grep all DAT contents for comments containing `bypass`, `broken`, `autonomous`, `parallel`, `shadow`, `temporary`, or any framing that admits the existing system is being routed around. Treat each such comment as a `// TODO: rip this out` marker — it almost always is. A second audit signal: more than one place writes to the same storage key controlling a state-machine flag (multi-source storage as a state gate is itself a bug — cross-link `td-gotchas.md` if/when that rule lands).

**Fix protocol (in order — don't skip steps).**

1. **Snapshot first.** Name a rollback file outside the auto-bump series (e.g. `<projectname>_PRE_<refactor>.toe`). The auto-bump series will overwrite normal saves; a named file is your guarantee of return.
2. **Inventory the bypass.** Build a feature-matrix table: what does the bypass do that the original system doesn't? Categorize as "must backport", "redundant with original", "incidental side-effect we can drop".
3. **Identify why X was deemed broken.** There is usually 1-3 small fixable bugs, often unrelated to the stated reason in the bypass comment. Probe the original system in isolation (cook it, watch its log, watch its storage writes) to surface the real fault.
4. **Fix the original — verify end-to-end.** Don't just fix the code; observe the original failure mode disappear (e.g. the log resumes growing, the tween animates, the state transition fires).
5. **Backport bypass-only features into the original.** Use the inventory table from step 2.
6. **Rip out the bypass in one commit.** Don't leave it dormant "in case we need it" — it will be re-enabled by accident.
7. **Decision-doc the rip in `<project>/docs/<feature>-removal-decision.md`** so future-you (or a colleague) knows *why* the duplication is gone and what the migration looked like. Keep the doc project-side, not skill-side.

**Worked example.** A project's `restart_btn_exec` (panelexec DAT) had a ~60-line block labeled `# SHADOW_FLOW_MARKER — autonomous intro-video pipeline (bypasses broken ticker)`. It scheduled three `run()` callbacks at hardcoded frame delays (`LOADING_FRAMES + VIDEO_FRAMES - 30`, etc.) to orchestrate an intro video and post-intro pose. In parallel, a frame-driven `executeDAT` (the "ticker") had been written to do the same job. Symptoms: 1-frame glitch between loading film and intro film, intro video looping then freezing on last frame, camera landing at wrong pose after fade.

Probing the ticker in isolation revealed two tiny bugs: `chop['facing'].eval()` halting `onFrameStart` because the channel had been renamed (silently swallowed by TD's callback error handler — log grew until the missing-channel line, then stopped), and `_dim_t = min(1.0, _dim_el / dur)` not clamping negative `_dim_t` (stale `_dim_start_frame` from previous session → negative elapsed → eased value exploded to millions, dimming a material's alpha to zero permanently). One `try/except` and one `max(0, ...)` repaired the ticker. The bypass's hardcoded `delayFrames` constants were drifting 1 frame off the real video length, producing the loop glitch. Four lines of bypass-only behavior (`iv.par.cuepoint = 0`, `iv.par.play = True/False`, `_video_inner_fade = 1.0`) backported to the ticker's activation block. The 60-line bypass came out in one commit. The flow ran clean afterward.

**Check first when:**

- A DAT comment contains "bypass", "broken", "shadow", "parallel", "autonomous", "temporary" + a name
- Multiple scripts in the same COMP/project write to the same storage flag
- Symptoms include 1-frame timing glitches, intermittent state oscillation, or "it works once then breaks on the second trigger"
- A project has accumulated patches over months and you're triaging "why is this so flaky"

# Text TOP — fonts, sizing, rendering quality

> **Trigger:** before configuring fonts, sizes, weights, or display methods on
> a Text TOP — OR when text renders pixelated / wrong-size / oddly-spaced on
> Mac. Three production-verified Mac/TD traps live here: `keepfontratio`
> silent-ignore, Automatic-Polygon-on-Mac rendering bug, and strokewidth-mode
> coupling. Plus dossier-derived patterns flagged MEDIUM (Spec DAT, resolution,
> word-wrap ordering).

> **File type — domain knowledge.** TD's Text TOP behavior (parameter semantics,
> rendering pipeline, Mac-specific bugs). Companion meta-pattern files live in
> `approach-patterns.md` (Fallback / Start weak) and `skill-growth-protocol.md`.

---

## `keepfontratio` silently ignores `fontsizey`

**Source:** [Text TOP — Derivative wiki](https://docs.derivative.ca/Text_TOP), verified in production 2026-05-31 | **Confidence:** HIGH (user observed: setting `fontsizey` from 30 → 14 → 10 with `keepfontratio=True` produced zero visual change; toggling `keepfontratio=False` made fontsizex/fontsizey independently controllable in the same TOP, same session)

Per Derivative docs: *"Keep Font Ratio – Ignores Y value in Font Size. Sets
both X and Y size to Font Size X."* When `keepfontratio=True`, `fontsizex`
drives both dimensions; `fontsizey` is silently ignored.

**Rule:** for non-square font scaling — or any explicit Y-axis size control —
set `keepfontratio=False` first, then set `fontsizex` and `fontsizey`
independently.

**Symptom this prevents:** "I'm setting `fontsizey` but the render doesn't
change." `get_parameter` reports the new value; render ignores it.

**Check first when:**

- A `set_parameter` on `fontsizey` succeeds but visual size is unchanged
- You want non-square Text TOP scaling (tall-and-narrow, wide-and-short)
- Inspecting a Text TOP whose `fontsizex` and `fontsizey` look out of proportion to the rendered glyph aspect

---

## Display Method = Scalable on macOS (avoid Automatic → Polygon)

**Source:** Derivative dev forum (multiple staff replies), [Text TOP — Derivative wiki](https://docs.derivative.ca/Text_TOP), verified in production 2026-05-31 | **Confidence:** HIGH (user observed: Automatic-default Text TOP at 13pt rendered visibly pixelated on M1 Pro; switching to `dispmethod='scalable'` made glyphs sharp / anti-aliased on the same TOP in the same capture session)

Per Derivative dev forum: Automatic Display Method **switches to Polygon mode
at font sizes above ~10pt**. Polygon mode has documented rendering bugs on
certain macOS GPUs — glyphs appear pixelated, blurry, or with channel-swap
artifacts despite correct parameters. Per Derivative dev: **"Scalable is the
most correct, as that is our most modern font rendering system."** A 2020
build changed the *default* to Bitmap because of the macOS Polygon issue, but
projects ported from older builds may still have Automatic set, and Automatic
remains a valid (silently-broken-on-Mac) choice.

**Rule:** set `dispmethod='scalable'` explicitly on every Text TOP on macOS,
especially at font sizes >10pt. Don't trust Automatic.

**Symptom this prevents:** pixelated HUD text on macOS that renders sharp on
Windows from the same `.toe`.

**Cross-link:** `mac-gotchas.md` § "Text TOP Display Method = Polygon broken
on some macOS GPUs" for the Mac-specific version.

**Check first when:**

- A Text TOP renders pixelated / blurry on Mac but is fine on Windows
- Heading text (>10pt) looks worse than body text (<10pt) in the same composite
- A `capture_top` shows visible pixel stairs despite "normal" font sizes

---

## `strokewidth` only affects `dispmethod='stroke'`

**Source:** [Text TOP — Derivative wiki](https://docs.derivative.ca/Text_TOP), verified in production 2026-05-31 (applied as constraint in build planning) | **Confidence:** HIGH (rejected `strokewidth=2` for fake-bold effect after verifying mode coupling; used larger `fontsize` for weight differential instead, with visible hierarchy result in the rendered output)

Per Derivative docs: `strokewidth` *"Controls the width of the outline when
using Stroke Display Method."* In Polygon / Bitmap / Scalable modes,
`strokewidth` is a **no-op** — it's only active when `dispmethod='stroke'`
(which renders outline-only glyphs, not solid fills).

**Rule:** don't use `strokewidth` for "fake bold" or weight differentials in
non-Stroke modes. For weight: use `bold=True` or `typeface='Bold'` (limited
by font-family bold-face availability — Courier has Regular/Bold/Italic/Bold
Italic, no Heavy/Black). For weight *differential* between elements in the
same composite: use two Text TOPs at different `fontsize` (visual hierarchy
via size, not stroke).

**Symptom this prevents:** "I set `strokewidth=2` but the text doesn't look
any bolder."

---

## Specification DAT for per-row styling (alternative to multi-Text-TOP composites)

**Source:** [Text TOP — Derivative wiki](https://docs.derivative.ca/Text_TOP) + Elburz / interactiveimmersive.io tutorial | **Confidence:** MEDIUM (docs documents `x`/`y`/`text` as the required Spec DAT columns and that "headings are parameter names that are to be overridden when rendering a line of text"; community-standard practice is to add `font`, `bold`, `fontcolor`, etc. as extra columns; **not user-tested in this skill's production work yet** — in 2026-05-31 build we chose the multi-Text-TOP composite path instead)

A **Specification DAT** attached to a Text TOP renders one text element per
row, with column headers = parameter names that override per row. Required
columns per docs: `x`, `y`, `text`. Extra columns reportedly accept the
parameter names directly (`font`, `fontsize`, `fontcolor`, `bold`, etc.)
based on community practice.

**Pattern:** to vary font / weight / color / position per element within a
single Text TOP, build a table DAT with columns like
`x, y, text, font, bold, fontcolor`, then attach via
`textTOP.par.specdat = 'table_op'`.

**When this fits:** static heading + static body styling differences — more
compact than two Text TOPs + Over TOP composite.

**When to prefer multi-Text-TOP composite instead (what we did 2026-05-31):**
when body text is dynamic (driven by `mod()`/expression that cooks each frame)
and heading is static, multi-TOP is simpler than wiring expression-output
back into Spec DAT rows on each cook.

**Not yet verified in production:**

- Exact list of parameter names that work as Spec DAT columns (Derivative-authored docs only explicitly list x/y/text as required; the broader override mechanism is community-reported)
- Whether the text-parameter expression (e.g. `mod('info_module').build()`) still runs when Spec DAT is set
- Best practice for dynamic per-row content updates (presumably DAT script callbacks)

---

## Resolution affects glyph fidelity for large fontsizes

**Source:** Derivative forum (multiple threads, evergreen) | **Confidence:** MEDIUM (community-reported and consistent with general raster logic — **not user-tested in this skill's production work** at large-fontsize edge cases; our 9pt and 13pt work on 1280×720 Text TOPs stayed well under any plausible threshold)

For "big fontsize" (specific cutoff not docs-stated), the Text TOP's own
`resolutionw / resolutionh` must give glyphs enough pixels to render — too
small a TOP causes cropping or low-fidelity rasterization. The Text TOP uses
its own TOP-resolution as the "box" within which word-wrap, auto-fit, and
alignment all operate.

**Rule:** when targeting fontsize > ~40pt on a Text TOP whose `resolutionw/h`
is small (<512px), raise the TOP resolution before debugging "blurry" or
"cropped" symptoms.

---

## Word Wrap + Auto-Size ordering

**Source:** [Text TOP — Derivative wiki](https://docs.derivative.ca/Text_TOP) | **Confidence:** MEDIUM (docs-stated mechanic — **not user-tested in this skill's production work**)

Per docs: *"When using Word Wrap and Auto-Size together, the text will first
word-wrap based on the specified font size, then auto size the resulting
block of text."*

**Rule:** with both Word Wrap and Auto-Size on, set the initial `fontsize` to
the intended wrap width — auto-size only adjusts the post-wrap block to fit
the TOP. Don't expect auto-size to expand text beyond what word-wrap allowed
at the initial size.

---

## Known gaps (deliberately empty)

These are publicly unresolvable or unmeasured as of 2026-05-31. Capture
during real production work via the growth protocol's pre-ask gates
(`skill-growth-protocol.md § Pre-ask filters`):

| Gap | Where it surfaces |
|---|---|
| Exact font-size threshold where Automatic switches to Polygon (10pt? platform-dependent?) | First time a fontsize sweep crosses the threshold and the rendering visibly changes |
| Whether `bold=True` + `typeface='Bold'` is redundant or compounding | First time a font with multiple bold weights is used + observed |
| Spec DAT — empirical column-name acceptance list + dynamic-content workflow | First production use of Spec DAT for non-trivial per-row styling |
| Mac GPU model matrix for the Polygon-Display-Method bug — does M3 / M4 still hit it? | First time the project ships on non-M1 Mac hardware |
| FPS cost delta between Scalable and Bitmap on M1 Pro at production scale | First time Text TOPs become a measurable cook hotspot |
| `linespacing` units — `pixels` vs `fractions` semantics at small values (we set `linespacing=20 pixels` and observed effect; smaller values 1.2-6 had no visible delta — undocumented threshold or unit-interpretation behavior unclear) | First time fine-tuned linespacing matters for a tight layout |

When any of these resolves in real work and survives the growth-protocol
gates (observed-failure-and-fix YES, one-sentence-rule YES,
user-novelty-signal YES), it moves into the appropriate section above.

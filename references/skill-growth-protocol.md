# Skill Growth Protocol v0.1 (TouchDesigner skill)

Purpose: capture empirical learnings from real TD projects so the skill grows
over time — in flow, not batched. Single-user today; structure is team-share
ready (no client names, no project-specific values, plain English).

Adapted from the Lens Studio skill's growth-protocol v0.6 — same mechanic,
TD-flavored examples and single-user tone.

## When you solve something via probe

Before you move on:
1. `grep references/*.md` for 3–5 keywords from the solution.
2. If there are hits: read and prove why this is different. If not different → no discovery.
3. If no hit (or proven different): discovery → in-flow ask directly.

## The Generalization rule — rewrite before you save

Before a discovery is written to `references/`: transform the project-specific finding into a universal rule.

### Step 1: Identify the core

What's the GENERAL pattern behind the specific finding?

Example:
- **Specific:** "Tim Gerritsen's `glslSplat_vertex` shader uses 17 samplers and renders red/blue corruption on M1 Pro."
- **General:** "Any GLSL TOP/MAT shader with ≥17 input samplers fails silently with channel-swapped color on macOS/MoltenVK. The compile-error path is *not* triggered — the symptom is visual, not compiler."

### Step 2: Remove everything project-specific

Checklist BEFORE you write to disk:

❌ Remove: client names, project names, specific asset filenames (`RADON_Tree.ply`, etc.)
❌ Remove: exact project measurements that only apply to this case (Ty=-0.6 for this tree)
❌ Remove: internal project paths (`/project1/GaussianSplatting/...`) — replace with placeholders or general patterns
❌ Remove: dates and deadlines tied to a specific delivery
✅ Keep: the general pattern
✅ Keep: typical ranges and rules of thumb
✅ Keep: why it happens (root cause: MoltenVK Argument Buffers incomplete in TD's compile path)
✅ Keep: how to detect and solve it

### Step 3: Test with the "future-TD-project" question

Read through what you're about to commit and ask:

"If I (or a future colleague, if/when this skill goes team-wide) start a *different* TD project next month and hit a related-but-not-identical situation — does this entry guide them to the right fix without me being there to interpret?"

If yes → ready to commit.
If no → rewrite until the answer is yes.

### Worked example

**BEFORE** (project-specific, do NOT commit):

> "For the RADON tree splat, Tim's vertex shader at `/project1/GaussianSplatting/GaussianSplat/glslSplat_vertex` produced red and blue corrupt colors on my M1 Pro. I patched it by adding `color.rgb = vec3(1.0);` after the texelFetch."

**AFTER** (generalizable, ready to commit):

> "macOS/MoltenVK GLSL compilation caps input samplers at 16. Shaders with 17+ samplers compile but render channel-swapped color (typically red/blue) with no compile error — diagnosis is visual, not compiler. Workarounds: (1) rewrite shader to ≤16 samplers, (2) force a constant color in-shader as creative workaround if color fidelity isn't required, (3) seek a community fork (e.g. atarilover123's GaussianSplat_TD reportedly does this for Tim Gerritsen's component — to verify)."

## In-flow ask — default

When a discovery passes the grep check: say it DIRECTLY to the user, in the middle of the flow.

Template (warm tone, jargon-free, single-user — say "you" not "the team"):

> "We've learned something new here.
>
> [1–2 sentences about what, plain English — avoid API names, file paths, grep output, "discovery" words]
>
> This is worth saving so future-you (and any future TD project) won't fall into the same trap. Today this knowledge isn't in the skill files yet, so the next time the same symptom appears, you'd be re-diagnosing from scratch.
>
> **Is it OK if I save it as a learning to the skill files? Quick, doesn't break our flow.**
>
> Yes / no / save for later"

Voice nuances:
- "Save so future-you won't fall in" > "save" (frames the value)
- "Won't fall into" > "will fall into" (humble — we don't know 100%)
- "As a learning" frames what it becomes when it lands
- "Doesn't break our flow" — reassurance that the discovery pause is fast

Internal BEFORE this ask:
- The Generalization rule walk (3 steps) runs silently
- The grep check runs silently — only if the rule is NOT found anywhere do we move on to the ask
- Probe results and technical evidence stay in agent state, not in the user message

AFTER the user says yes, the NEXT message comes with:
- A concrete diff
- File path + section
- Commit message
- Second-stage approval before commit + push

The user's response steers:
- **Yes** → open the right `references/*.md`, add the entry, show the diff, wait for approval, commit. ~2 min cycle.
- **No** → discard, move on.
- **Save for later** → write to `SKILL-DISCOVERIES.md` as backup. Surface at next natural break.

Each accepted discovery gets its own small commit. Granular history; easy to roll back something specific.

### Closing message after commit (plain, no jargon)

When commit+push has run: close the loop in plain language. NO `origin`, NO `granular commit`, `rollback`, or `git`-words.

Template:

> "Done, it's saved now. If we later notice the entry doesn't quite fit, we can easily roll it back.
>
> Back to [concrete ongoing work] — say when you're ready to continue."

## Format for entry

- **What:** [one sentence, plain English — NOT an API path or jargon line]
- **Value for user:** [what is gained — time saved, trap avoided, something feels better. ONE line, concrete. Mandatory.]
- **How it was found:** [the probe chain in brief, internal]
- **Generalizable?** [yes/no + why]
- **Suggested text for references file:** [neutrally written, project-agnostic, plain English where possible]

## CHANGELOG.md — always part of a discovery commit

When a discovery is committed (yes path above): the same commit MUST include a prepend to `CHANGELOG.md` at repo root, under the section `## Improvements and newly acquired knowledge`.

Without a CHANGELOG entry, the discovery has no cumulative visibility — it only lives in git log. The CHANGELOG is the skill's biography.

Entry format (auto-extracted):

```markdown
### 💡 YYYY-MM-DD — [project: <cwd-derived>]
- **<title in plain English>**: <1-2 sentence description, jargon-free>
- Value for user: <what is gained — time saved, trap avoided, or something feels better. Plain English.>
- File: `<path>` § <section>
- Type: [discovery] / [docs] / [convention]
```

**Language rule:** all artifacts written to disk (CHANGELOG entries, `references/*.md` edits) are in **plain English**. The in-flow ask itself can render in the user's spoken language at runtime — but the on-disk OUTPUT must be English. Section-title references inside descriptions may quote Swedish section names verbatim with an English gloss in parentheses.

Auto-extraction:
- `💡` — discovery emoji prefix (always)
- `YYYY-MM-DD` — current date, no time
- `<cwd-derived>` — from `$PWD` (`~/Projects/<name>` → `<name>`)
- `<title>` — plain-English summary; translate API jargon
- `<description>` — 1–2 sentences from the agent's internal "What:" field
- `<value>` — direct from "Value for user:" field
- `<path>` — relative path of the edited file
- `<section>` — markdown section where the entry landed

A single commit covers BOTH the `references/` edit AND the CHANGELOG prepend. No separate commits.

Per release (when a version tag is created):
- Move `## Improvements and newly acquired knowledge` entries to a new `[vX.Y.Z] — YYYY-MM-DD` section
- Commit as `chore(release): consolidate vX.Y.Z changelog`

## Emoji conventions

- `💡` — discovery / new learning (most CHANGELOG entries)
- `🌱` — structural change (repo skeleton, framework, scaffolding)
- `🔧` — refactor or convention change (no new knowledge, just reorganization)
- `🚨` — correction (something previously documented was wrong)

The Lens Studio skill uses only `💡`; this TD skill adds `🌱` and friends to distinguish growth from scaffolding. Drop the extras if/when team-share lands and uniform LS-style parity is preferred.

## SKILL-DISCOVERIES.md — backup path

Only for "save for later" or cases where the user is in the middle of something creative and doesn't want to break the flow. At the next natural break (end of phase, ⌘S handshake, end of pair-test cycle): say "N candidates in `SKILL-DISCOVERIES.md`. Want me to run through them now?"

For future team-share: discoveries from read-only colleagues (without push access) would stay in `SKILL-DISCOVERIES.md` until someone with push moves them over. At the move: the CHANGELOG prepend is done in the same commit cycle.

## Never

- Client names or project-specific values
- Hypotheses not empirically verified
- Things that already exist in `references/`
- Auto-push to main (single-user can push, but always with an explicit "yes" first)
- Discovery ask for things that haven't passed the grep check (otherwise it becomes noise)
- Discovery commit without CHANGELOG prepend (always both or neither)

## Repo status

- Local: `~/Projects/touch-designer-skill/`
- Remote: TBD (user creates GitHub repo)
- Single-user today; team-share path documented in `references/project-bootstrap.md`

## Changelog (of the protocol itself)

- v0.1 (2026-05-30): initial TD adaptation from LS skill-growth-protocol v0.6.
  Stripped Valtech/Snap-specific examples; replaced with TD examples (16-sampler
  cap, Gaussian splat). Removed concierge/onboarding-protocol references (LS-only).
  Kept all three Generalization steps, in-flow ask template, CHANGELOG-prepend
  mandate, SKILL-DISCOVERIES backup path, Never list. Added the `🌱/🔧/🚨` emoji
  conventions for non-discovery entries (LS uses only `💡`).

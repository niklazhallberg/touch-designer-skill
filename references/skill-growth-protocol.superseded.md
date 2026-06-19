# Skill Growth Protocol v0.2 (TouchDesigner skill)

Purpose: capture empirical learnings from real TD projects so the skill grows
over time — in flow, not batched. Single-user today; structure is team-share
ready (no client names, no project-specific values, plain English).

Adapted from the Lens Studio skill's growth-protocol v0.6 — same mechanic,
TD-flavored examples and single-user tone.

## HARD TRIGGER — when to force a growth check (do not skip)

The protocol below is reflexive, not optional. Run the trigger check **before continuing the next action**, not at end of task. "Batched" capture is a known failure mode — the user has had to remind in the past. Do NOT wait for the user to ask.

A trigger fires when ANY of these is true after solving something:

- Took **3+ probe → fix cycles** to reach the working state (signals empirical territory, not docs-knowledge)
- Reality **contradicted your initial model** (you said "X should work", X didn't, you found out why)
- You used a **non-obvious workaround** (something a fresh agent reading the docs wouldn't guess)
- You ran `restart_td` or any other "reset" because state didn't clear cleanly
- User expressed surprise, asked "why did that happen?", or "how do we avoid this next time?"

When triggered, immediately run the steps below ("When you solve something via probe") BEFORE the next user-facing message. Multiple triggers can batch into one ask if they happened in the same flow, but don't let them accumulate across turns.

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

## Pre-ask filters (silent) — all three must answer YES before any in-flow ask

The grep check (§ "When you solve something via probe") is filter 0 — does the rule already exist? If not, three more silent gates run before the agent surfaces the discovery to the user. **Any NO drops the discovery silently** — no ask, no save-for-later, no CHANGELOG entry. The SKILL-DISCOVERIES path is reserved for "YES but bad timing," not "no signal at all."

### Gate 1 — Did I observe both the failure AND the fix working?

- **YES** requires: agent saw the failing state (error message, wrong output, perf metric below threshold) AND saw the post-fix state confirm the fix end-to-end.
- **NO** when: fix wasn't empirically verified, the failure was inferred rather than seen, or the fix is "I think this might work / it compiled cleanly / didn't throw."

### Gate 2 — Can I write the general rule in one sentence (≤25 words)?

- **YES** requires: a single declarative sentence that names the trigger, the symptom, and the workaround. Write it mentally and count.
- **NO** when: the finding has too many caveats, the conditions are too specific, or the agent finds itself starting "well, it depends on..."

### Gate 3 — Did the user signal genuine novelty?

- **YES** when: user expressed surprise ("åh!", "what?", "I didn't know that"), asked "why did that happen?" or "how do we avoid this next time?", OR the agent itself was wrong/blindsided and corrected by reality.
- **NO** when: the work was routine and predictable, the fix was something the user already knew, or it was just a normal step in the build.

All three YES → proceed to § In-flow ask. Any NO → silent drop, move on.

## Source confidence — own empiry vs external research

Gate 1 (observed failure + fix end-to-end) accepts two source types, but the resulting entry must declare which it is. Both can be saved; the reader must always see what kind of evidence is behind a claim. Don't average the two into a single "HIGH" — be explicit.

### Own empiry (you observed it in this skill's production work)

- **Confidence: HIGH** in the `Source:` line of the references-file entry
- Format: `**Source:** <project>, <YYYY-MM-DD> | **Confidence:** HIGH (<one-line evidence note: probe captured, stress-test, before-after capture, etc.>)`
- **No re-check obligation** — the agent that wrote the entry saw the fix work end-to-end. The world hasn't moved underneath us between writing and reading.

### External research (forum thread, research paper, vendor announcement, blog)

- **Confidence: MEDIUM max** in the `Source:` line — never HIGH from external alone
- Format: `**Source:** [<link title>](<URL>) | Date: <when source was published> | **Confidence:** MEDIUM (<one-line evidence note: vendor statement, primary-source-verified, etc.>)`
- **MUST include a re-check obligation** — a closing line like `**Status: verify before relying — source dated YYYY-MM-DD; re-check vendor release notes / forum if this trips a user`
- Reason: we did not see the failure-and-fix ourselves; the world may have moved (build numbers, library versions, vendor policies). The reader needs to know to verify before depending on it.

### Dual-sourced (own empiry + external corroboration)

- **Confidence: HIGH** — the external source confirms what we independently observed
- Format: cite both — `**Source:** <project>, <YYYY-MM-DD> (own observation: <one-line>) + [<external link>](<URL>) (corroborating reference) | **Confidence:** HIGH (dual-sourced)`
- No re-check obligation (we saw it), but include the external link for future readers who want depth or want to follow the wider conversation.

**The distinction matters because** "we saw it fail and fixed it" is a different kind of evidence from "someone on a forum said this is how it works." Both are useful inputs to a skill knowledge base, but the reader's confidence in *applying the rule without verification* depends on knowing which it is. Future maintainers reading a HIGH-confidence entry should be safe to act on it; a MEDIUM-confidence entry tells them to verify first.

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

## Consolidation — keep the skill from bloating

Adding entries forever produces a graveyard of similar-but-not-identical notes. Two consolidation triggers, both gated by explicit user yes — **never auto-merge**.

### Trigger A — at new-discovery time (per-cluster, conversation-driven)

Before recording a new discovery, the agent greps CHANGELOG for entries that hit ≥2 of the same keywords from the new finding. If 2+ existing entries match:

> "We've found something new. Looks like there are already 2–3 similar entries in the changelog about [theme]. Want me to consolidate all of them into a single principle in `references/<file>.md` instead of adding another?"

- **Yes** → write the consolidated principle to the target references file, mark the original CHANGELOG entries with a `→ consolidated in references/<file>.md § <section> (YYYY-MM-DD)` suffix, add ONE new CHANGELOG entry recording the consolidation itself.
- **No** → add the new entry as usual.

### Trigger B — at session start (periodic, hook-flagged)

The session-sync hook keeps a count of `### 💡` entries in `CHANGELOG.md`. When the count crosses the next multiple of 10 (10, 20, 30, …) since the last flagging, the hook prints ONE line:

> "🔍 N total learnings — periodic consolidation review recommended  
>   (ask the agent: 'kör consolidation review' when you have a moment)"

**The hook does nothing else.** No analysis, no grouping, no auto-suggestions, no opening of files. The actual review runs in conversation:

1. User: "kör consolidation review" (or any natural prompt)
2. Agent: scans CHANGELOG, groups `💡` entries by the `File:` line they cite, lists files with ≥3 entries as candidate clusters
3. Per cluster: shows the entries, proposes a consolidated principle, asks the user
4. User per cluster: yes → write consolidated + mark originals; no → skip; defer → leave for next time

### What "consolidated" means in practice

- Original CHANGELOG entries are **NOT deleted** (preserves granular history).
- They get a one-line suffix: `→ consolidated in references/mac-gotchas.md § <section> (YYYY-MM-DD)`.
- A new principle appears in the target `references/*.md` file, written project-agnostic per the Generalization rule.
- A new `💡` entry records the consolidation itself (so the biography shows the merge as a learning).

### Never (consolidation edition)

- Auto-consolidate without explicit user yes (same gate as discovery commit).
- Delete original CHANGELOG entries — only annotate.
- Consolidate across unrelated themes just to clear the queue — if it doesn't read as ONE principle, leave them separate.
- Use the hook to *do* anything beyond count + flag. Anything smarter breaks the simplicity contract.

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

- v0.3 (2026-06-07): added § Source confidence — own empiry vs external research. Distinguishes Gate-1 evidence types: own empiry → HIGH no re-check; external → MEDIUM max + obligatory re-check line; dual-sourced → HIGH with both citations. Previous protocol left implicit how external research should be represented in `Source:` lines; entries from external sources started appearing without re-check obligations, making it impossible for readers to tell "we know" from "someone reported".
- v0.2 (2026-05-31): added § Pre-ask filters (three concrete YES/NO gates:
  observed-failure-and-fix, one-sentence-rule, user-novelty-signal) between
  § Generalization and § In-flow ask. Added § Consolidation (two triggers —
  per-discovery cluster detection at write time + periodic 10-entry
  count-and-flag at session start) between § In-flow ask and § Format-for-entry.
  Hook gains a ~12-line count-and-flag block; actual consolidation runs in
  conversation. Self-poisoning risk (adding forever, never merging) closed.
- v0.1 (2026-05-30): initial TD adaptation from LS skill-growth-protocol v0.6.
  Stripped Valtech/Snap-specific examples; replaced with TD examples (16-sampler
  cap, Gaussian splat). Removed concierge/onboarding-protocol references (LS-only).
  Kept all three Generalization steps, in-flow ask template, CHANGELOG-prepend
  mandate, SKILL-DISCOVERIES backup path, Never list. Added the `🌱/🔧/🚨` emoji
  conventions for non-discovery entries (LS uses only `💡`).

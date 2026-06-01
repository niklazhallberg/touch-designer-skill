# templates/build-prompts/

Build prompts go here when they're worth keeping as patterns. Same promotion bar as `templates/components/`: real production use → companion documentation → re-import would beat rebuild.

A **build prompt** is the FIRST message a user pastes to a fresh Claude Code session in a new TD project. It primes the build: vision, picked architecture, phased plan, success criteria, references.

## Convention (verified the hard way 2026-06-01)

Two failure modes were observed in the first real bootstrap. Both are preventable in the prompt template.

### 1. Pre-answer the Plan-mode interview

A fresh Claude Code session enters Plan mode automatically and runs an interview before execution. Common questions:

- **Scope** — "plan all phases now or just phase 0?"
- **Missing refs / unknowns** — when the prompt cites paths that don't exist in the new project (because they're skill-relative, not project-relative)
- **Tooling preferences** — MCP tools, edit tools, etc.

The build prompt should pre-answer the predictable ones in a small header so the session can either confirm and run, or skip the interview entirely. Example header at the top of every build prompt:

```markdown
## Pre-answers for the Plan-mode interview

- **Plan scope:** Phase 0 only. Re-plan Phase 1+ after Phase 0's empirical findings (which they are, named below).
- **Reference paths:** All `references/X.md` and `rules/X.md` mentions are skill-relative — they live at `~/.claude/skills/touch-designer-skill/`. Read from there, don't expect them project-locally. Project's own `.claude/rules/X.md` is a project-local Embody mirror of the same content.
- **Empirical unknowns to resolve in-flow:** [list specific to this build]
- **MCP availability:** Live (Envoy + Embody verified at startup).
```

This skips most interview questions and lets the session start coding immediately.

### 2. Use the verified path-citation form

When citing skill content from a build prompt, use the qualified form per `references/project-bootstrap.md § "How to cite skill paths from project-facing documents"`:

- `references/*.md` (central-only) → `~/.claude/skills/touch-designer-skill/references/X.md`
- `rules/*.md` (Embody-mirrored) → prefer project-local `.claude/rules/X.md`
- `skills/*/SKILL.md` (Embody-mirrored) → prefer project-local `.claude/skills/<name>/SKILL.md`

Unqualified `references/X.md` reads as project-relative in the receiving session and resolves to nothing.

## Promotion rule for new templates

A build prompt lands in this directory when:

1. It's been used end-to-end in a real production build (not synthetic).
2. The structure (phases, success criteria, empirical-question list, pre-answer header) is generic enough that a second project would lift it.
3. There's a one-line description of when to use this template vs. write from scratch.

If a prompt is highly specific to its project (e.g. Heatmap_Body_Tracker's thermal LUT details), it stays in that project's `prompts/` folder and doesn't promote. Only the **structural shell** generalizes.

## Current templates

_(empty — first templates promote when a second project re-uses the Heatmap_Body_Tracker structure.)_

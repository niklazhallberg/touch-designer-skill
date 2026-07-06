# TouchDesigner Skill for Claude Code

<!-- TODO: add badges once decisions are made. Example:
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform: Apple Silicon](https://img.shields.io/badge/platform-Apple%20Silicon-black)
-->

A **self-improving Claude Code skill** that lets Claude build, modify, and debug
**TouchDesigner** projects on Apple Silicon — driving TouchDesigner live through the
**Embody + Envoy MCP** bridge, and getting a little sharper after every project.

<!-- TODO: add a short demo GIF or screenshot here. For a visual tool like
TouchDesigner this is the single highest-impact addition — a 5-10s clip of Claude
creating/wiring operators says more than three paragraphs. Drop it in docs/ and link:
![Demo](docs/demo.gif) -->

## What this is

TouchDesigner is a node-based visual programming environment for real-time
graphics and installations. This repo is a Claude Code *skill*: a bundle of
recipes, rules, and hard-won gotchas that Claude loads when it detects a
TouchDesigner context (a `.toe` file, an `.embody/` folder, or the phrase
"TouchDesigner"). With the Embody component loaded inside a `.toe` project,
Claude can inspect the network, create and wire operators, run Python, and debug
issues — instead of you doing every click by hand.

It was built around one artist's workflow, but everything here is written to be
project-agnostic: patterns, decision rules ("when to use X vs Y"), and gotchas
that generalize across TouchDesigner projects. If you work in TD on a Mac, you
should be able to clone it and adapt it to your own setup.

## How it's self-improving

The "self-improving" part is a concrete, documented mechanism — not autonomous
model training. During real project sessions, Claude captures generalizable
discoveries *in-flow* and appends them to the knowledge banks, following the
**skill-growth protocol** (see [`references/skill-growth-protocol.md`](references/skill-growth-protocol.md)):

- New learnings are written into `references/` and logged in
  [`CHANGELOG.md`](CHANGELOG.md), which acts as the skill's biography.
- Each learning is tagged by evidence strength — own empirical testing (trusted),
  external source (marked "verify before relying"), or both (corroborated).
- A `SessionStart` hook (`scripts/session-sync.sh`) pulls the latest banks and
  announces new learnings at the start of a session, so improvements travel
  across machines via git.

The net effect: the skill accumulates TouchDesigner knowledge over time instead
of re-deriving the same gotchas every project.

## Requirements

- **macOS on Apple Silicon** (M-series). Several patterns here are Mac-specific,
  and some TouchDesigner features (e.g. POPs) crash on Intel/AMD Macs.
- **TouchDesigner 2025.x** <!-- TODO: confirm the minimum build you want to state,
  e.g. 2025.32820 — POPs require a 2025 build. -->
- **[Claude Code](https://docs.claude.com/en/docs/claude-code)**
- **Embody** — the TouchDesigner component (`.tox`) that hosts the Claude
  integration inside a project and starts the Envoy MCP bridge.
  <!-- TODO: confirm and link the official source you rely on, e.g.
  https://github.com/dylanroscover/Embody/releases -->
- **Envoy MCP bridge** — ships with Embody; runs on localhost
  <!-- TODO: confirm default port, referenced as 9870 in the changelog -->.
  Note: the bridge is localhost-only and unauthenticated, and `execute_python`
  runs unsandboxed as the TouchDesigner process — treat it accordingly.

## Install on a new machine

```sh
git clone https://github.com/niklazhallberg/touch-designer-skill \
  ~/.claude/skills/touch-designer-skill
```

Then add the `SessionStart` hook to `~/.claude/settings.json` — see the header of
[`scripts/session-sync.sh`](scripts/session-sync.sh) for the exact JSON snippet.

## Start a new TouchDesigner project

```sh
cd ~/Projects/
~/.claude/skills/touch-designer-skill/scripts/td-new my-project
cd my-project
```

Then, in TouchDesigner: **Save As** → `my-project.toe` → drag in **Embody.tox** →
set `Aiclient=claude`. Now run `claude` in the project folder and Claude can drive
the project through Embody/Envoy.

`td-new` scaffolds the folder, initializes git with a sensible `.gitignore`, and
drops in a per-project settings stub — see [`templates/td-project/`](templates/td-project/)
for exactly what it copies.

## What's in here

- **`SKILL.md`** — the front door; loaded when Claude detects a TD context.
- **`skills/`** — workflow recipes, loaded on demand (`create-operator`,
  `debug-operator`, `manage-annotations`, …).
- **`rules/`** — operational rules (parameter design, network layout, TD-Python
  gotchas, MCP safety).
- **`references/`** — knowledge banks loaded on trigger: the skill-growth
  protocol, TD-specific gotchas, patterns, and per-component notes.
- **`scripts/td-new`** — scaffolds a new TD project in seconds.
- **`scripts/session-sync.sh`** — the `SessionStart` hook (pull latest, announce
  new learnings, silent on failure).
- **`templates/td-project/`** — what `td-new` copies into a fresh project.
- **`CHANGELOG.md`** — the biography of what the skill has learned over time.
- **`ROADMAP.md`** — deferred work, each item with the trigger that brings it
  back into scope.

## How it works — repo vs. project

The skill (this repo) holds *cross-project* knowledge. Each TouchDesigner project
keeps its own project-specific files, most of them auto-generated by Embody.

| Lives in this repo (central, user-level)       | Lives per TD project (auto-generated by Embody)                               |
| ---------------------------------------------- | ----------------------------------------------------------------------------- |
| `SKILL.md`, `skills/`, `rules/`, `references/` | `<project>.toe`, `.mcp.json`, `.embody/envoy-bridge.py`, `.embody/envoy.json` |
| `CHANGELOG.md` (biography)                      | `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`, `.claude/rules/` (Embody regen)  |
| `scripts/td-new`, `scripts/session-sync.sh`    | `.venv/`, `Backup/`, `TDImportCache/`, `logs/` (runtime)                      |
| `templates/td-project/` (the starter shell)    | `.claude/settings.local.json` (per-machine permissions allowlist)             |

See [`references/project-bootstrap.md`](references/project-bootstrap.md) for the
full split and Embody sourcing.

## What does NOT belong in this repo

Project-specific pipeline specs, current-phase plans, baked-asset conventions, and
anything that only generalizes to one TD project belong in **that project's own
repo** (`docs/` or `.claude/notes/`), not here. The skill is for cross-project
knowledge — patterns, decision rules, gotchas, growth-protocol entries. If an
entry can't be stated without a project name or scene-specific numbers, it's
project content, not skill content.

## Roadmap

Forward-looking and deferred work lives in [`ROADMAP.md`](ROADMAP.md), each item
tagged with the real-world trigger that should bring it back into scope.

## Contributing

<!-- TODO: decide how open you want this. A minimal version: -->
Issues and pull requests are welcome. The knowledge banks follow the
[skill-growth protocol](references/skill-growth-protocol.md) — if you add a
learning, tag it by evidence strength (own testing vs. external source) and log it
in `CHANGELOG.md` so its provenance stays clear.

## License

<!-- TODO: add a LICENSE file and update this line. MIT is the common choice for
tools like this. Without a license, the code is "all rights reserved" and others
can't legally use it. -->
Released under the MIT License — see [`LICENSE`](LICENSE).

## Acknowledgments

- [Derivative](https://derivative.ca) — TouchDesigner.
- **Embody** and the **Envoy** MCP bridge — the components that make live
  Claude ↔ TouchDesigner control possible.
  <!-- TODO: credit the author/link you rely on. -->
